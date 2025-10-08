import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_colors.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../transacoes/components/smart_field.dart';
import '../../transacoes/components/tipo_selector.dart';
import '../models/cartao_model.dart';
import '../services/cartao_data_service.dart';
import '../../transacoes/models/transacao_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../../database/local_database.dart';

enum TipoDespesa { simples, parcelada, recorrente }

/// MoneyInputFormatter - idêntico ao projeto device
class MoneyInputFormatter extends TextInputFormatter {
  final bool allowNegative;

  MoneyInputFormatter({this.allowNegative = true});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    try {
      final numbersOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (numbersOnly.isEmpty) {
        return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }

      final value = int.parse(numbersOnly);
      final formatted = (value / 100).toStringAsFixed(2).replaceAll('.', ',');
      
      final newText = 'R\$ $formatted';
      
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

class DespesaCartaoPage extends StatefulWidget {
  final CartaoModel? cartaoInicial;
  final TransacaoModel? transacaoParaEditar;

  const DespesaCartaoPage({
    Key? key,
    this.cartaoInicial,
    this.transacaoParaEditar,
  }) : super(key: key);

  @override
  State<DespesaCartaoPage> createState() => _DespesaCartaoPageState();
}

class _DespesaCartaoPageState extends State<DespesaCartaoPage> {
  final CartaoDataService _cartaoDataService = CartaoDataService.instance;
  final CategoriaService _categoriaService = CategoriaService.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataTransacaoController = TextEditingController();
  final _cartaoController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _subcategoriaController = TextEditingController();
  final _faturaController = TextEditingController();
  final _parcelasController = TextEditingController();
  final _frequenciaController = TextEditingController();
  final _observacoesController = TextEditingController();

  // FocusNodes para navegação
  final _descricaoFocusNode = FocusNode();
  final _valorFocusNode = FocusNode();
  final _parcelasFocusNode = FocusNode();
  final _dataFocusNode = FocusNode();
  final _categoriaFocusNode = FocusNode();
  final _subcategoriaFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();
  final _salvarButtonFocusNode = FocusNode();

  // Scroll controller para navegação automática
  final _scrollController = ScrollController();

  // Estados
  TipoDespesa _tipoDespesa = TipoDespesa.simples;
  bool _isLoading = false;
  bool _salvarEContinuar = false; // ✅ Usuario escolhe conscientemente
  DateTime _dataTransacao = DateTime.now();
  String? _frequenciaSelecionada;
  bool _faturaManualmenteSelecionada = false;

  // Configuração dos tipos de despesa para TipoSelector
  final List<TipoSelectorOption> _tiposDespesaCartao = [
    const TipoSelectorOption(
      id: 'simples',
      nome: 'Simples',
      icone: Icons.shopping_bag_outlined,
      descricao: 'Compra única',
      cor: AppColors.roxoPrimario,
    ),
    const TipoSelectorOption(
      id: 'parcelada',
      nome: 'Parcelada',
      icone: Icons.calendar_month,
      descricao: 'Dividir em parcelas',
      cor: Colors.purple,
    ),
    const TipoSelectorOption(
      id: 'recorrente',
      nome: 'Recorrente',
      icone: Icons.repeat,
      descricao: 'Repete todo mês',
      cor: AppColors.roxoPrimario,
    ),
  ];
  
  // Dados carregados
  List<CartaoModel> _cartoes = [];
  List<CategoriaModel> _categorias = [];
  List<CategoriaModel> _subcategorias = [];
  
  // Seleções
  CartaoModel? _cartaoSelecionado;
  CategoriaModel? _categoriaSelecionada;
  CategoriaModel? _categoriaEscolhida;
  CategoriaModel? _subcategoriaSelecionada;
  String? _faturaDestino; // Formato display (Set/25)
  DateTime? _faturaVencimentoCompleto; // Data completa para Supabase
  
  // Preview automático
  Map<String, dynamic>? _preview;

  @override
  void initState() {
    super.initState();
    
    // ✅ MODO EDIÇÃO: Carregar dados da transação
    if (widget.transacaoParaEditar != null) {
      _inicializarModoEdicao();
    } else {
      // ✅ MODO CRIAÇÃO: Usar cartão inicial e data atual
      _cartaoSelecionado = widget.cartaoInicial;
      _dataTransacao = DateTime.now();
      _dataTransacaoController.text = _formatarDataBr(_dataTransacao);
    }
    
    debugPrint('🔔 InitState: cartaoInicial = ${widget.cartaoInicial?.nome}');
    debugPrint('🔔 InitState: transacaoParaEditar = ${widget.transacaoParaEditar?.descricao}');
    debugPrint('🔔 InitState: dataTransacao = $_dataTransacao');
    
    if (_cartaoSelecionado != null) {
      _cartaoController.text = _cartaoSelecionado!.nome;
      debugPrint('🔔 InitState: Cartão definido, insumos completos');
    } else {
      debugPrint('🔔 InitState: Nenhum cartão inicial, aguardando carregamento...');
    }
    _parcelasController.text = '2'; // Valor padrão como no device
    _frequenciaController.text = '12'; // Valor padrão como no device
    
    // Adicionar listeners para atualizar estado dos botões e preview
    _valorController.addListener(() {
      setState(() {});
      _atualizarPreview();
    });
    _descricaoController.addListener(() => setState(() {}));
    _parcelasController.addListener(_atualizarPreview);
    _frequenciaController.addListener(_atualizarPreview);
    
    // Configurar listeners para navegação automática
    _setupNavigationListeners();
    
    _inicializar();
    
    // Dar foco ao campo descrição após um pequeno delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _descricaoFocusNode.requestFocus();
        }
      });
    });
  }

  Future<void> _inicializar() async {
    try {
      debugPrint('🚀 Inicializando databases...');
      
      // Garantir que o banco local está inicializado
      await LocalDatabase.instance.initialize();
      await LocalDatabase.instance.setCurrentUser(
        Supabase.instance.client.auth.currentUser?.id ?? 'unknown'
      );
      
      await _carregarCartoes();
      await _carregarCategorias();
      _atualizarFaturaSeNecessario();
    } catch (e) {
      debugPrint('❌ Erro na inicialização: $e');
    }
  }

  Future<void> _carregarCartoes() async {
    try {
      debugPrint('🔄 Carregando cartões...');
      final cartoes = await _cartaoDataService.fetchCartoes();
      debugPrint('📦 Cartões recebidos: ${cartoes.length}');
      
      setState(() {
        _cartoes = cartoes.where((c) => c.ativo).toList();
        debugPrint('📦 Cartões ativos: ${_cartoes.length}');
        
        if (_cartaoSelecionado == null && _cartoes.isNotEmpty) {
          // Selecionar o primeiro cartão ativo
          _cartaoSelecionado = _cartoes.first;
          _cartaoController.text = _cartaoSelecionado!.nome;
          debugPrint('💳 Cartão selecionado: ${_cartaoSelecionado?.nome}');
          
          // Calcular fatura após setState para garantir que UI está atualizada
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              debugPrint('💳 Recalculando fatura com cartão carregado...');
              _atualizarFaturaSeNecessario();
            }
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar cartões: $e');
    }
  }

  Future<void> _carregarCategorias() async {
    try {
      debugPrint('🔄 Carregando categorias...');
      final categorias = await _categoriaService.listarCategorias();
      debugPrint('📂 Categorias recebidas: ${categorias.length}');
      
      setState(() {
        _categorias = categorias.where((c) => c.ativo).toList();
        debugPrint('📂 Categorias ativas: ${_categorias.length}');
        
        if (_categorias.isNotEmpty) {
          debugPrint('📂 Primeira categoria: ${_categorias.first.nome}');
        }
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar categorias: $e');
    }
  }

  Future<void> _carregarSubcategorias(String categoriaId) async {
    try {
      final subcategorias = await _categoriaService.listarSubcategorias(categoriaId);
      
      setState(() {
        _subcategorias = subcategorias;
        _subcategoriaSelecionada = null;
      });
      debugPrint('✅ Subcategorias carregadas com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao carregar subcategorias: $e');
    }
  }

  void _calcularFaturaDestino() {
    debugPrint('🔔 _calcularFaturaDestino() CHAMADO');
    debugPrint('💳 _cartaoSelecionado: ${_cartaoSelecionado?.nome}');
    debugPrint('📅 _dataTransacao: $_dataTransacao');
    
    // ✅ VALIDAÇÃO COMPLETA: Precisa de cartão E data válida
    if (_cartaoSelecionado == null) {
      debugPrint('❌ Cartão não selecionado, não calculando fatura');
      setState(() {
        _faturaDestino = null;
        _faturaVencimentoCompleto = null;
        _faturaController.clear();
      });
      return;
    }
    
    if (_dataTransacao == null) {
      debugPrint('❌ Data da transação não definida, não calculando fatura');
      setState(() {
        _faturaDestino = null;
        _faturaVencimentoCompleto = null;
        _faturaController.clear();
      });
      return;
    }
    
    try {
      final fatura = _cartaoDataService.calcularFaturaAlvo(_cartaoSelecionado!, _dataTransacao);
      final faturaFormatada = _formatarMesAno(fatura.dataVencimento);
      
      debugPrint('💰 Fatura calculada: $faturaFormatada');
      debugPrint('📅 Data vencimento completa: ${fatura.dataVencimento}');
      
      setState(() {
        _faturaDestino = faturaFormatada; // Para display (Set/25)
        _faturaVencimentoCompleto = fatura.dataVencimento; // Para Supabase (data ISO)
        _faturaController.text = faturaFormatada;
        _faturaManualmenteSelecionada = false;
      });
      
      debugPrint('🎯 Fatura display: $_faturaDestino');
      debugPrint('🎯 Fatura ISO: ${_faturaVencimentoCompleto?.toIso8601String().split('T')[0]}');
      
      // Atualizar preview quando fatura mudar
      _atualizarPreview();
      
    } catch (e) {
      debugPrint('❌ Erro ao calcular fatura: $e');
    }
  }

  /// Método auxiliar para garantir que fatura é recalculada quando necessário
  void _atualizarFaturaSeNecessario() {
    debugPrint('🔄 _atualizarFaturaSeNecessario() - Verificando insumos...');
    debugPrint('   💳 _cartaoSelecionado: ${_cartaoSelecionado?.nome}');
    debugPrint('   📅 _dataTransacao: $_dataTransacao');
    debugPrint('   🎯 _faturaDestino atual: $_faturaDestino');
    debugPrint('   🎯 _faturaVencimentoCompleto atual: $_faturaVencimentoCompleto');
    
    if (_cartaoSelecionado != null && _dataTransacao != null) {
      debugPrint('✅ Ambos insumos disponíveis, calculando fatura...');
      _calcularFaturaDestino();
    } else {
      debugPrint('⏳ Insumos incompletos: cartão=${_cartaoSelecionado?.nome}, data=$_dataTransacao');
    }
  }

  /// Atualizar preview automaticamente (baseado no projeto offline)
  void _atualizarPreview() {
    if (!_temDadosMinimos()) {
      setState(() => _preview = null);
      return;
    }

    final valor = _parseMoneyValue(_valorController.text);
    if (valor <= 0) {
      setState(() => _preview = null);
      return;
    }

    Map<String, dynamic> preview = {
      'tipo': _tipoDespesa,
      'valor': valor,
      'cartao': _cartaoSelecionado,
      'fatura': _faturaDestino,
      'data': _dataTransacao,
      'descricao': _descricaoController.text.trim(),
    };

    if (_tipoDespesa == TipoDespesa.parcelada) {
      final parcelas = int.tryParse(_parcelasController.text) ?? 2;
      preview['numeroParcelas'] = parcelas;
      preview['valorParcela'] = valor / parcelas;
      preview['cronograma'] = _gerarCronogramaParcelamento(valor, parcelas);
    } else if (_tipoDespesa == TipoDespesa.recorrente) {
      final repeticoes = int.tryParse(_frequenciaController.text) ?? 12;
      preview['numeroRepeticoes'] = repeticoes;
      preview['valorTotal'] = valor * repeticoes;
    }

    setState(() => _preview = preview);
  }

  /// Verificar se tem dados mínimos para preview
  bool _temDadosMinimos() {
    return _cartaoSelecionado != null &&
           _valorController.text.isNotEmpty &&
           _descricaoController.text.trim().isNotEmpty &&
           _faturaDestino != null &&
           _faturaVencimentoCompleto != null;
  }

  /// Gerar cronograma de parcelamento (simplificado)
  String _gerarCronogramaParcelamento(double valor, int parcelas) {
    if (_faturaDestino == null) return '';
    
    final List<String> meses = [];
    final faturaAtual = _faturaDestino!;
    
    // Adicionar as primeiras 3 faturas
    meses.add(faturaAtual);
    
    if (parcelas > 1) {
      // Simular próximas faturas (seria ideal ter lógica real de cálculo)
      meses.add(_proximaFatura(faturaAtual, 1));
      if (parcelas > 2) {
        meses.add(_proximaFatura(faturaAtual, 2));
      }
    }
    
    if (parcelas > 3) {
      return '${meses.join(' • ')}... (${parcelas}x)';
    }
    
    return meses.join(' • ');
  }

  /// Calcular próxima fatura (simulação simples)
  String _proximaFatura(String faturaAtual, int mesesAFrente) {
    // Ex: Out/25 -> Nov/25
    final partes = faturaAtual.split('/');
    if (partes.length != 2) return faturaAtual;
    
    final meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    final mesAtual = partes[0];
    final ano = int.tryParse('20${partes[1]}') ?? DateTime.now().year;
    
    final indexAtual = meses.indexOf(mesAtual);
    if (indexAtual == -1) return faturaAtual;
    
    final novoIndex = (indexAtual + mesesAFrente) % 12;
    final novoAno = ano + ((indexAtual + mesesAFrente) ~/ 12);
    
    return '${meses[novoIndex]}/${novoAno.toString().substring(2)}';
  }

  /// Calcular fatura final (para período de parcelamento/recorrência)
  String _calcularFaturaFinal(int mesesAFrente) {
    if (_faturaDestino == null || mesesAFrente <= 0) return _faturaDestino ?? '';
    return _proximaFatura(_faturaDestino!, mesesAFrente);
  }

  /// Scroll suave para mostrar preview e área de botões
  void _scrollParaPreview() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _scrollController.hasClients) {
        debugPrint('🔄 Fazendo scroll automático para preview...');
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent * 0.95, // 95% para baixo (era 70% + 25%)
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _dataTransacaoController.dispose();
    _cartaoController.dispose();
    _categoriaController.dispose();
    _subcategoriaController.dispose();
    _faturaController.dispose();
    _parcelasController.dispose();
    _frequenciaController.dispose();
    _observacoesController.dispose();
    
    // Dispose dos FocusNodes
    _descricaoFocusNode.dispose();
    _valorFocusNode.dispose();
    _dataFocusNode.dispose();
    _categoriaFocusNode.dispose();
    _subcategoriaFocusNode.dispose();
    _observacoesFocusNode.dispose();
    _salvarButtonFocusNode.dispose();
    _scrollController.dispose();
    
    
    super.dispose();
  }

  void _setupNavigationListeners() {
    // Listener para quando valor perde o foco (adicional, caso o onEditingComplete falhe)
    _valorFocusNode.addListener(() {
      debugPrint('🔔 _valorFocusNode listener: hasFocus = ${_valorFocusNode.hasFocus}');
      if (!_valorFocusNode.hasFocus && _valorController.text.isNotEmpty) {
        final valorParsed = _parseMoneyValue(_valorController.text);
        debugPrint('🔔 Valor perdeu foco: $valorParsed');
        if (valorParsed > 0) {
          debugPrint('🔔 Valor perdeu foco - backup listener DESABILITADO');
          // Future.delayed(const Duration(milliseconds: 500), () {
          //   if (mounted) {
          //     debugPrint('🔔 Abrindo modal de categoria via focusNode listener...');
          //     _selecionarCategoria();
          //   }
          // });
        }
      }
    });

    // Listener para quando o campo data recebe foco, abrir automaticamente o seletor
    _dataFocusNode.addListener(() {
      if (_dataFocusNode.hasFocus) {
        debugPrint('🔔 Data recebeu foco, abrindo seletor...');
        Future.delayed(const Duration(milliseconds: 100), () {
          _selecionarDataTransacao();
        });
      }
    });

    // Listener para quando o campo categoria recebe foco - DESABILITADO para evitar loops
    // _categoriaFocusNode.addListener(() {
    //   if (_categoriaFocusNode.hasFocus) {
    //     debugPrint('🔔 Categoria recebeu foco, abrindo seletor...');
    //     Future.delayed(const Duration(milliseconds: 100), () {
    //       _selecionarCategoria();
    //     });
    //   }
    // });

    // Listener para quando o campo subcategoria recebe foco - DESABILITADO para evitar loops  
    // _subcategoriaFocusNode.addListener(() {
    //   if (_subcategoriaFocusNode.hasFocus && _subcategorias.isNotEmpty) {
    //     debugPrint('🔔 Subcategoria recebeu foco, abrindo seletor...');
    //     Future.delayed(const Duration(milliseconds: 100), () {
    //       _selecionarSubcategoria();
    //     });
    //   }
    // });
  }


  // Métodos de navegação personalizada
  void _navegarParaValor() {
    debugPrint('🔔 Navegando da descrição para valor');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _valorFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.roxoHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.transacaoParaEditar != null 
            ? 'Editar Despesa do Cartão'
            : 'Nova Despesa no Cartão',
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // ✅ CENTRALIZADO
        actions: [
          TextButton(
            onPressed: _podeHabilitar ? _salvarDespesa : null,
            child: Text(
              'SALVAR',
              style: TextStyle(
                color: _podeHabilitar ? Colors.white : AppColors.cinzaMedio,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Seletor de Tipo (TipoSelector retangular)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TipoSelector(
                tipos: _tiposDespesaCartao,
                tipoSelecionado: _getTipoString(_tipoDespesa),
                onChanged: widget.transacaoParaEditar != null 
                  ? (_) {} // ✅ BLOQUEADO NO MODO EDIÇÃO (função vazia)
                  : (tipo) {
                      setState(() {
                        _tipoDespesa = _getTipoEnum(tipo);
                      });
                      _atualizarPreview(); // Atualizar preview quando trocar tipo
                    },
              ),
            ),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16), // ✅ PADDING COMPLETO
                child: Column(
                  children: [
                    // Descrição
                    SmartField(
                      controller: _descricaoController,
                      focusNode: _descricaoFocusNode,
                      label: 'Descrição',
                      hint: _getPlaceholderDescricao(), // ✅ DINÂMICO
                      icon: Icons.description, // ✅ CORRETO
                      isCartaoContext: true,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () {
                        debugPrint('🔔 onEditingComplete chamado para descrição');
                        FocusScope.of(context).unfocus(); // Remove foco atual
                        _navegarParaValor();
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Descrição é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valor  
                    SmartField(
                      controller: _valorController,
                      focusNode: _valorFocusNode,
                      label: _getLabelValor(), // ✅ DINÂMICO
                      hint: 'R\$ 0,00',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyInputFormatter()],
                      isCartaoContext: true,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        debugPrint('🔔 onEditingComplete chamado para valor');
                        final valorParsed = _parseMoneyValue(_valorController.text);
                        debugPrint('🔔 Valor parseado: $valorParsed');
                        if (valorParsed > 0) {
                          if (_tipoDespesa == TipoDespesa.parcelada) {
                            debugPrint('🔔 Tipo parcelada, navegando para parcelas...');
                            FocusScope.of(context).requestFocus(_parcelasFocusNode);
                          } else {
                            debugPrint('🔔 Valor válido, navegando para categoria...');
                            // Estratégia direta: abrir modal da categoria imediatamente
                            FocusScope.of(context).unfocus(); 
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                debugPrint('🔔 Abrindo modal de categoria diretamente...');
                                _selecionarCategoria();
                              }
                            });
                          }
                        } else {
                          debugPrint('🔔 Valor inválido: $valorParsed');
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Valor é obrigatório';
                        }
                        final parsedValue = _parseMoneyValue(value);
                        if (parsedValue <= 0) {
                          return 'Valor deve ser maior que zero';
                        }
                        return null;
                      },
                    ),
                    
                    // Campo de Parcelas (movido aqui se for parcelada)
                    if (_tipoDespesa == TipoDespesa.parcelada) ..._buildCampoParcelasAposValor(),
                    const SizedBox(height: 16),

                    // Data da compra
                    SmartField(
                      controller: _dataTransacaoController,
                      focusNode: _dataFocusNode,
                      label: 'Data da compra',
                      hint: 'DD/MM/AAAA',
                      icon: Icons.calendar_today, // ✅ SEM OUTLINE
                      readOnly: true,
                      onTap: _selecionarDataTransacao,
                      isCartaoContext: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Data é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoria e Subcategoria (lado a lado como na imagem)
                    Row(
                      children: [
                        Expanded(
                          child: SmartField(
                            controller: _categoriaController,
                            focusNode: _categoriaFocusNode,
                            label: 'Categoria',
                            hint: 'Ex: Alimentação',
                            icon: _categoriaSelecionada != null && _categoriaEscolhida != null
                                ? null // Remove ícone padrão quando preenchido
                                : Icons.local_offer_outlined,
                            leadingIcon: _categoriaSelecionada != null && _categoriaEscolhida != null
                                ? _buildSmallColoredIcon(
                                    icone: _categoriaEscolhida!.icone,
                                    cor: _categoriaEscolhida!.cor != null && _categoriaEscolhida!.cor!.isNotEmpty
                                        ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                        : null,
                                    fallbackColor: AppColors.vermelhoHeader,
                                  )
                                : null,
                            readOnly: true,
                            onTap: _selecionarCategoria,
                            isCartaoContext: true,
                            showDot: _categoriaSelecionada != null && _categoriaEscolhida == null, // Só mostra dot se não tem ícone colorido
                            dotColor: _categoriaSelecionada?.cor != null 
                                ? Color(int.parse(_categoriaSelecionada!.cor!.replaceAll('#', '0xFF')))
                                : AppColors.roxoPrimario,
                            validator: (value) {
                              if (_categoriaSelecionada == null) {
                                return 'Categoria é obrigatória';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SmartField(
                            controller: _subcategoriaController,
                            focusNode: _subcategoriaFocusNode,
                            label: 'Subcategoria',
                            hint: 'Ex: Supermercado',
                            icon: _subcategoriaSelecionada != null
                                ? null // Remove ícone padrão quando preenchido
                                : Icons.bookmark_outline,
                            leadingIcon: _subcategoriaSelecionada != null && _categoriaEscolhida != null
                                ? _buildSmallColoredIcon(
                                    icone: _categoriaEscolhida!.icone, // Subcategoria usa ícone da categoria pai
                                    cor: _categoriaEscolhida!.cor != null && _categoriaEscolhida!.cor!.isNotEmpty
                                        ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                        : null,
                                    fallbackColor: AppColors.vermelhoHeader,
                                    size: 16, // Um pouco menor para subcategoria
                                  )
                                : null,
                            readOnly: true,
                            onTap: _subcategorias.isNotEmpty ? _selecionarSubcategoria : null,
                            isCartaoContext: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cartão
                    SmartField(
                      controller: _cartaoController,
                      label: 'Cartão',
                      hint: 'Selecionar cartão',
                      icon: _cartaoSelecionado != null
                          ? null // Remove ícone padrão quando preenchido
                          : Icons.credit_card_outlined,
                      leadingIcon: _cartaoSelecionado != null
                          ? _buildSmallColoredIcon(
                              icone: 'credit_card', // Sempre ícone de cartão
                              cor: _cartaoSelecionado!.cor != null && _cartaoSelecionado!.cor!.isNotEmpty
                                  ? Color(int.parse(_cartaoSelecionado!.cor!.replaceAll('#', '0xFF')))
                                  : null,
                              fallbackColor: AppColors.roxoPrimario,
                            )
                          : null,
                      readOnly: true,
                      onTap: widget.transacaoParaEditar != null 
                        ? null // ✅ BLOQUEADO NO MODO EDIÇÃO
                        : _selecionarCartao,
                      isCartaoContext: true,
                      showDot: false, // Nunca mostrar dot pois sempre tem leadingIcon quando preenchido
                      dotColor: _cartaoSelecionado?.cor != null 
                          ? Color(int.parse(_cartaoSelecionado!.cor!.replaceAll('#', '0xFF')))
                          : AppColors.roxoPrimario,
                      validator: (value) {
                        if (_cartaoSelecionado == null) {
                          return 'Cartão é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campos condicionais (Parcelas/Repetições)
                    ..._buildCamposCondicionais(),

                    // Fatura (só mostra se cartão for selecionado)
                    if (_cartaoSelecionado != null) ...[
                      Builder(
                        builder: (context) {
                          // Debug: verificar valores antes de renderizar
                          debugPrint('🎨 RENDER Fatura - controller.text: "${_faturaController.text}"');
                          debugPrint('🎨 RENDER Fatura - _faturaDestino: "$_faturaDestino"');
                          debugPrint('🎨 RENDER Fatura - isEmpty: ${_faturaController.text.isEmpty}');
                          
                          return SmartField(
                            controller: _faturaController,
                            label: 'Fatura',
                            hint: _faturaController.text.isEmpty ? 'Calculando fatura...' : 'Toque para alterar',
                            readOnly: true,
                            onTap: widget.transacaoParaEditar != null 
                              ? null // ✅ BLOQUEADO NO MODO EDIÇÃO
                              : _selecionarFatura,
                            isCartaoContext: true,
                            validator: (value) {
                              if (_faturaDestino == null || _faturaDestino!.isEmpty || _faturaVencimentoCompleto == null) {
                                return 'Fatura é obrigatória';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      // Explicação do comportamento automático
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          'A fatura é calculada automaticamente pela data da transação',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Observações (opcional)
                    SmartField(
                      controller: _observacoesController,
                      focusNode: _observacoesFocusNode,
                      label: 'Observações',
                      hint: 'Informações adicionais (opcional)',
                      icon: Icons.note_outlined,
                      maxLines: 3,
                      isCartaoContext: true,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () {
                        debugPrint('🔔 Observações concluídas, destacando botão SALVAR...');
                        FocusScope.of(context).unfocus();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            _salvarButtonFocusNode.requestFocus();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Preview automático
                    _buildPreview(),

                    const SizedBox(height: 24), // ✅ ESPAÇO MAIOR ANTES DOS BOTÕES
                    
                    // Toggle salvar e continuar
                    _buildToggleSalvarContinuar(),
                    
                    const SizedBox(height: 24),
                    
                    // Botões de ação (scrolláveis)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.roxoHeader),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.arrow_back, color: AppColors.roxoHeader, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'CANCELAR',
                                  style: TextStyle(
                                    color: AppColors.roxoHeader,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Focus(
                            focusNode: _salvarButtonFocusNode,
                            child: Builder(
                              builder: (context) {
                                final hasFocus = _salvarButtonFocusNode.hasFocus;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: hasFocus ? [
                                      BoxShadow(
                                        color: AppColors.roxoHeader.withAlpha(128), // 50% opacity
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ] : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _podeHabilitar ? _salvarDespesa : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasFocus 
                                        ? AppColors.roxoHeader.withAlpha(230) // Mais intenso quando focado
                                        : AppColors.roxoHeader,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: hasFocus ? const BorderSide(
                                          color: AppColors.branco,
                                          width: 2,
                                        ) : BorderSide.none,
                                      ),
                                    ),
                                    child: Text(
                                      'SALVAR',
                                      style: TextStyle(
                                        color: hasFocus ? AppColors.branco : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: hasFocus ? 16 : 15, // Maior quando focado
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Espaço extra no final para evitar corte
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Campo de parcelas após o valor (apenas para tipo parcelada)
  List<Widget> _buildCampoParcelasAposValor() {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: SmartField(
              controller: _parcelasController,
              focusNode: _parcelasFocusNode,
              label: 'Parcelas',
              hint: '2',
              icon: Icons.calendar_month,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              isCartaoContext: true,
              textInputAction: TextInputAction.next,
              onEditingComplete: () {
                debugPrint('🔔 Parcelas preenchidas, navegando para categoria...');
                FocusScope.of(context).unfocus(); 
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _selecionarCategoria();
                  }
                });
              },
              onChanged: (value) => setState(() {}), // Trigger rebuild
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Número de parcelas é obrigatório';
                }
                final parcelas = int.tryParse(value);
                if (parcelas == null || parcelas <= 0) {
                  return 'Número inválido de parcelas';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          // Setinhas para ajustar parcelas (igual form transações)
          Column(
            children: [
              GestureDetector(
                onTap: () => _ajustarParcelas(1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.roxoHeader,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _ajustarParcelas(-1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.roxoHeader,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // Campos condicionais baseados no tipo selecionado (só para recorrente)
  List<Widget> _buildCamposCondicionais() {
    if (_tipoDespesa == TipoDespesa.recorrente) {
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SmartField(
                controller: _frequenciaController,
                label: 'Repetir por quantos meses',
                hint: '12',
                icon: Icons.repeat,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                isCartaoContext: true,
                onChanged: (value) => setState(() {}), // Trigger rebuild
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Número de meses é obrigatório';
                  }
                  final meses = int.tryParse(value);
                  if (meses == null || meses <= 0) {
                    return 'Número inválido de meses';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Setinhas para ajustar repetições (igual form transações)
            Column(
              children: [
                GestureDetector(
                  onTap: () => _ajustarRepeticoes(1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.roxoHeader,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _ajustarRepeticoes(-1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.roxoHeader,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ];
    }
    
    return []; // Retorna lista vazia para tipos simples e parcelada
  }

  // Toggle salvar e continuar
  Widget _buildToggleSalvarContinuar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Salvar e continuar',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.cinzaTexto,
          ),
        ),
        Switch(
          value: _salvarEContinuar,
          onChanged: (value) => setState(() => _salvarEContinuar = value),
          activeColor: AppColors.roxoHeader,
        ),
      ],
    );
  }


  // Ajustar número de parcelas
  void _ajustarParcelas(int delta) {
    final currentValue = int.tryParse(_parcelasController.text) ?? 2;
    final newValue = (currentValue + delta).clamp(1, 60); // Entre 1 e 60 parcelas
    _parcelasController.text = newValue.toString();
    setState(() {});
  }

  // Ajustar número de repetições
  void _ajustarRepeticoes(int delta) {
    final currentValue = int.tryParse(_frequenciaController.text) ?? 12;
    final newValue = (currentValue + delta).clamp(1, 60); // Entre 1 e 60 meses
    _frequenciaController.text = newValue.toString();
    setState(() {});
  }

  // Helpers de UI - Placeholders dinâmicos baseados no tipo
  String _getPlaceholderDescricao() {
    switch (_tipoDespesa) {
      case TipoDespesa.recorrente:
        return 'Ex: Netflix, Spotify, Academia...';
      case TipoDespesa.parcelada:
        return 'Ex: Geladeira, Móveis, Eletrônicos...';
      default:
        return 'Ex: Supermercado, Gasolina, Farmácia...';
    }
  }

  String _getLabelValor() {
    switch (_tipoDespesa) {
      case TipoDespesa.parcelada:
        return 'Valor Total';
      default:
        return 'Valor';
    }
  }

  // Selector methods
  Future<void> _selecionarCartao() async {
    if (_cartoes.isEmpty) return;
    
    final cartao = await showModalBottomSheet<CartaoModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Selecionar Cartão',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _cartoes.length,
                itemBuilder: (context, index) {
                  final cartao = _cartoes[index];
                  final isSelected = _cartaoSelecionado?.id == cartao.id;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppColors.cinzaClaro : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cartao.cor != null && cartao.cor!.isNotEmpty
                              ? Color(int.parse(cartao.cor!.replaceAll('#', '0xFF')))
                              : AppColors.roxoPrimario,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(Icons.credit_card, color: Colors.white, size: 20),
                        ),
                      ),
                      title: Text(
                        cartao.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, cartao),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (cartao != null) {
      debugPrint('🔔 Cartão selecionado: ${cartao.nome}');
      setState(() {
        _cartaoSelecionado = cartao;
        _cartaoController.text = cartao.nome;
      });
      debugPrint('💳 _cartaoSelecionado definido, recalculando fatura...');
      _atualizarFaturaSeNecessario();
    } else {
      debugPrint('❌ Nenhum cartão foi selecionado no modal');
    }
  }

  Widget _getIconeByName(String icone, {required double size, Color? color}) {
    // Usar o sistema correto de ícones
    return CategoriaIcons.renderIcon(icone, size, color: color);
  }

  /// Helper para criar ícone pequeno colorido para campos preenchidos
  Widget _buildSmallColoredIcon({
    required String? icone,
    required Color? cor,
    required Color fallbackColor,
    double size = 18,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor ?? fallbackColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: icone != null && icone.isNotEmpty
            ? _getIconeByName(icone, size: size * 0.7, color: Colors.white)
            : Icon(Icons.folder, size: size * 0.7, color: Colors.white),
      ),
    );
  }

  Future<void> _selecionarCategoria() async {
    if (_categorias.isEmpty) return;
    
    debugPrint('🔔 Abrindo modal de categoria...');
    final categoria = await showModalBottomSheet<CategoriaModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Selecionar Categoria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _categorias.length,
                itemBuilder: (context, index) {
                  final categoria = _categorias[index];
                  final isSelected = _categoriaSelecionada?.id == categoria.id;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppColors.cinzaClaro : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: categoria.cor != null && categoria.cor!.isNotEmpty
                              ? Color(int.parse(categoria.cor!.replaceAll('#', '0xFF')))
                              : AppColors.vermelhoHeader,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: categoria.icone.isNotEmpty
                              ? _getIconeByName(categoria.icone, size: 20, color: Colors.white)
                              : const Icon(Icons.category, color: Colors.white, size: 20),
                        ),
                      ),
                      title: Text(
                        categoria.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, categoria),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    debugPrint('🔔 Modal de categoria fechado, resultado: ${categoria?.nome ?? 'null'}');
    
    if (categoria != null) {
      setState(() {
        _categoriaSelecionada = categoria;
        _categoriaEscolhida = categoria; // ✅ ADICIONAR ESTA LINHA
        _categoriaController.text = categoria.nome;
        _subcategoriaSelecionada = null;
        _subcategoriaController.clear();
      });
      
      debugPrint('🔔 Carregando subcategorias para: ${categoria.nome}');
      await _carregarSubcategorias(categoria.id);
      _atualizarPreview(); // Atualizar preview após selecionar categoria
      
      // Aguardar um frame para garantir que o modal anterior fechou completamente
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted && _subcategorias.isNotEmpty) {
        debugPrint('🔔 Abrindo modal de subcategoria (${_subcategorias.length} disponíveis)...');
        _selecionarSubcategoria();
      } else {
        debugPrint('🔔 Nenhuma subcategoria encontrada, continuando...');
      }
    }
  }

  Future<void> _selecionarSubcategoria() async {
    debugPrint('🔔 _selecionarSubcategoria() chamado');
    debugPrint('📂 Subcategorias disponíveis: ${_subcategorias.length}');
    
    if (_subcategorias.isEmpty) {
      debugPrint('❌ Nenhuma subcategoria disponível');
      return;
    }
    
    final subcategoria = await showModalBottomSheet<CategoriaModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Selecionar Subcategoria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _subcategorias.length,
                itemBuilder: (context, index) {
                  final subcategoria = _subcategorias[index];
                  final isSelected = _subcategoriaSelecionada?.id == subcategoria.id;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppColors.cinzaClaro : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _categoriaEscolhida?.cor != null && _categoriaEscolhida!.cor!.isNotEmpty
                              ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                              : AppColors.vermelhoHeader,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: _categoriaEscolhida?.icone != null && _categoriaEscolhida!.icone.isNotEmpty
                              ? _getIconeByName(_categoriaEscolhida!.icone, size: 18, color: Colors.white)
                              : const Icon(Icons.category, size: 18, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        subcategoria.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, subcategoria),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (subcategoria != null) {
      setState(() {
        _subcategoriaSelecionada = subcategoria;
        _subcategoriaController.text = subcategoria.nome;
      });
      
      _atualizarPreview(); // Atualizar preview após selecionar subcategoria
      
      // Após selecionar subcategoria, sempre fazer scroll para mostrar preview
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          debugPrint('🔔 Subcategoria selecionada! Fazendo scroll para preview...');
          _scrollParaPreview(); // SEMPRE fazer scroll após subcategoria
          
          // Depois decidir navegação baseada em dados completos
          Future.delayed(const Duration(milliseconds: 500), () { // Aguarda scroll completar
            if (mounted) {
              if (_temDadosMinimos() && _preview != null) {
                debugPrint('🔔 Dados completos! Indo para botão SALVAR...');
                _salvarButtonFocusNode.requestFocus();
              } else {
                debugPrint('🔔 Indo para observações...');
                _observacoesFocusNode.requestFocus();
              }
            }
          });
        }
      });
    }
  }

  Future<void> _selecionarDataTransacao() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataTransacao,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (data != null) {
      debugPrint('🔔 Nova data selecionada: ${_formatarDataBr(data)}');
      setState(() {
        _dataTransacao = data;
        _dataTransacaoController.text = _formatarDataBr(data);
      });
      
      debugPrint('🔔 Recalculando fatura para nova data...');
      _atualizarFaturaSeNecessario();
      
      // Após selecionar a data, ir automaticamente para a categoria
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _categoriaFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _selecionarFatura() async {
    if (_cartaoSelecionado == null) return;
    
    // Gerar lista de faturas disponíveis baseada no cartão selecionado
    final faturas = _gerarFaturasDisponiveis(_cartaoSelecionado!);
    
    final faturaSelecionada = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecionar Fatura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_faturaDestino != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.roxoTransparente10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.roxoHeader, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sugerido: $_faturaDestino (baseado na data ${_formatarDataBr(_dataTransacao)})',
                        style: const TextStyle(fontSize: 13, color: AppColors.roxoHeader, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Text(
              'A fatura será recalculada automaticamente se você alterar a data da transação',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: faturas.length,
                itemBuilder: (context, index) {
                  final fatura = faturas[index];
                  final isSelected = _faturaDestino == fatura['display'];
                  
                  return ListTile(
                    title: Text(fatura['display'] ?? ''),
                    subtitle: Text('Vencimento: ${fatura['vencimento'] ?? ''}'),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppColors.roxoHeader)
                        : null,
                    selected: isSelected,
                    onTap: () => Navigator.pop(context, fatura['display']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (faturaSelecionada != null) {
      // 🔍 Encontrar a data completa baseada no display selecionado
      final faturas = _gerarFaturasDisponiveis(_cartaoSelecionado!);
      final faturaCompleta = faturas.firstWhere(
        (f) => f['display'] == faturaSelecionada,
        orElse: () => <String, String>{},
      );
      
      final dataCompleta = faturaCompleta['data'] != null 
        ? DateTime.parse(faturaCompleta['data']!) 
        : null;
      
      debugPrint('🔍 FATURA SELECIONADA MANUALMENTE:');
      debugPrint('   📅 Display: $faturaSelecionada');
      debugPrint('   🎯 Data completa: $dataCompleta');
      
      setState(() {
        _faturaDestino = faturaSelecionada;
        _faturaVencimentoCompleto = dataCompleta; // ✅ Atualizar data completa também
        _faturaController.text = faturaSelecionada;
        _faturaManualmenteSelecionada = true;
      });
      
      // Atualizar preview
      _atualizarPreview();
    }
  }

  List<Map<String, String>> _gerarFaturasDisponiveis(CartaoModel cartao) {
    final List<Map<String, String>> faturas = [];
    final hoje = DateTime.now();
    
    // Gerar 6 meses de faturas (3 anteriores + atual + 2 próximas)
    for (int i = -3; i <= 2; i++) {
      final data = DateTime(hoje.year, hoje.month + i, cartao.diaVencimento);
      final fatura = _cartaoDataService.calcularFaturaAlvo(cartao, data);
      
      faturas.add({
        'display': _formatarMesAno(fatura.dataVencimento),
        'vencimento': _formatarDataBr(fatura.dataVencimento),
        'data': fatura.dataVencimento.toIso8601String(), // ✅ Data completa para conversão
      });
    }
    
    return faturas;
  }


  // Helper methods
  double _parseMoneyValue(String value) {
    // Remove R$ e converte vírgula para ponto
    final cleanValue = value.replaceAll('R\$', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  // Lógica para habilitar botão SALVAR
  bool get _podeHabilitar {
    return !_isLoading &&
          _cartaoSelecionado != null &&
          _valorController.text.isNotEmpty &&
          _descricaoController.text.trim().isNotEmpty &&
          _parseMoneyValue(_valorController.text) > 0;
  }

  // Conversão entre enum e string para TipoSelector
  String _getTipoString(TipoDespesa tipo) {
    switch (tipo) {
      case TipoDespesa.simples:
        return 'simples';
      case TipoDespesa.parcelada:
        return 'parcelada';
      case TipoDespesa.recorrente:
        return 'recorrente';
    }
  }

  TipoDespesa _getTipoEnum(String tipo) {
    switch (tipo) {
      case 'simples':
        return TipoDespesa.simples;
      case 'parcelada':
        return TipoDespesa.parcelada;
      case 'recorrente':
        return TipoDespesa.recorrente;
      default:
        return TipoDespesa.simples;
    }
  }

  /// ✅ VERIFICAR SE FATURA ESTÁ PAGA E PERGUNTAR AO USUÁRIO
  Future<bool> _verificarFaturaPagaEPerguntar() async {
    if (_faturaVencimentoCompleto == null || _cartaoSelecionado == null) {
      return false; // Sem fatura válida, prosseguir normalmente
    }
    
    try {
      final faturaVencimento = _faturaVencimentoCompleto!.toIso8601String().split('T')[0];
      
      debugPrint('🔍 VERIFICANDO STATUS DA FATURA:');
      debugPrint('   📅 Fatura display: $_faturaDestino');
      debugPrint('   📅 Fatura ISO: $faturaVencimento');
      debugPrint('   💳 Cartão: ${_cartaoSelecionado!.id}');
      
      final statusFatura = await _cartaoDataService.verificarStatusFatura(
        _cartaoSelecionado!.id, 
        faturaVencimento
      );
      
      debugPrint('📊 RESULTADO STATUS FATURA:');
      debugPrint('   status_paga: ${statusFatura['status_paga']}');
      debugPrint('   total_transacoes: ${statusFatura['total_transacoes']}');
      debugPrint('   transacoes_efetivadas: ${statusFatura['transacoes_efetivadas']}');
      debugPrint('   data_efetivacao: ${statusFatura['data_efetivacao']}');
      debugPrint('   conta_pagamento_nome: ${statusFatura['conta_pagamento_nome']}');
      
      final faturaPaga = statusFatura['status_paga'] == true;
      
      if (faturaPaga) {
        debugPrint('⚠️ FATURA JÁ ESTÁ PAGA: $_faturaDestino');
        
        // Mostrar modal com opções
        final opcaoEscolhida = await _mostrarModalFaturaPaga();
        
        switch (opcaoEscolhida) {
          case 'cancelar':
            return true; // Bloquear salvamento
          case 'reabrir':
            await _reabrirFatura(faturaVencimento);
            return false; // Prosseguir com salvamento
          case 'proxima':
            await _moverParaProximaFatura();
            return false; // Prosseguir com salvamento
          default:
            return true; // Cancelar por padrão
        }
      }
      
      return false; // Fatura não está paga, prosseguir
      
    } catch (error) {
      debugPrint('❌ Erro ao verificar status da fatura: $error');
      return false; // Em caso de erro, prosseguir
    }
  }

  /// 📋 MODAL COM OPÇÕES QUANDO FATURA JÁ ESTÁ PAGA
  Future<String?> _mostrarModalFaturaPaga() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Fatura Já Paga'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A fatura de $_faturaDestino já foi paga.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Como deseja proceder?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Cancelar
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancelar'),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.cinzaMedio),
            ),
          ),
          
          // Reabrir fatura
          TextButton(
            onPressed: () => Navigator.of(context).pop('reabrir'),
            child: const Text(
              'Reabrir Fatura',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          
          // Mover para próxima
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('proxima'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roxoHeader,
            ),
            child: const Text(
              'Próxima Fatura',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔓 REABRIR FATURA (desfazer pagamento)
  Future<void> _reabrirFatura(String faturaVencimento) async {
    try {
      debugPrint('🔓 Reabrindo fatura: $faturaVencimento');
      
      // Chamar o service implementado
      final resultado = await _cartaoDataService.reabrirFatura(
        _cartaoSelecionado!.id, 
        faturaVencimento
      );
      
      if (mounted) {
        if (resultado['success'] == true) {
          final transacoesAfetadas = resultado['transacoes_afetadas'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fatura $_faturaDestino reaberta!\n'
                '$transacoesAfetadas transações marcadas como pendentes'
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${resultado['error'] ?? 'Falha ao reabrir fatura'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('❌ Erro ao reabrir fatura: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reabrir fatura: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ⏭️ MOVER DESPESA PARA PRÓXIMA FATURA
  Future<void> _moverParaProximaFatura() async {
    try {
      debugPrint('⏭️ Movendo para próxima fatura...');
      
      // Encontrar próxima fatura não paga
      final proximaFatura = await _encontrarProximaFaturaNaoPaga();
      
      if (proximaFatura != null) {
        setState(() {
          _faturaVencimentoCompleto = proximaFatura['data'];
          _faturaDestino = proximaFatura['display'];
        });
        
        debugPrint('✅ Movido para fatura: ${proximaFatura['display']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Despesa será adicionada à fatura ${proximaFatura['display']}'),
              backgroundColor: AppColors.verdeSucesso,
            ),
          );
        }
      } else {
        throw Exception('Nenhuma fatura futura encontrada');
      }
      
    } catch (error) {
      debugPrint('❌ Erro ao mover para próxima fatura: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao calcular próxima fatura: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔍 ENCONTRAR PRÓXIMA FATURA NÃO PAGA
  Future<Map<String, dynamic>?> _encontrarProximaFaturaNaoPaga() async {
    if (_cartaoSelecionado == null) return null;
    
    try {
      // Começar da próxima fatura
      var dataAnalise = DateTime(_faturaVencimentoCompleto!.year, _faturaVencimentoCompleto!.month + 1);
      
      // Procurar até 12 meses à frente
      for (int i = 0; i < 12; i++) {
        final faturaVencimento = dataAnalise.toIso8601String().split('T')[0];
        
        final statusFatura = await _cartaoDataService.verificarStatusFatura(
          _cartaoSelecionado!.id, 
          faturaVencimento
        );
        
        final faturaPaga = statusFatura['status_paga'] == true;
        
        if (!faturaPaga) {
          return {
            'data': dataAnalise,
            'display': _formatarMesAno(dataAnalise),
            'vencimento': faturaVencimento,
          };
        }
        
        // Próximo mês
        dataAnalise = DateTime(dataAnalise.year, dataAnalise.month + 1);
      }
      
      return null; // Nenhuma fatura não paga encontrada
      
    } catch (error) {
      debugPrint('❌ Erro ao encontrar próxima fatura: $error');
      return null;
    }
  }

  Future<void> _salvarDespesa() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ✅ VERIFICAR SE A FATURA JÁ ESTÁ PAGA ANTES DE PROSSEGUIR
    if (await _verificarFaturaPagaEPerguntar()) {
      return; // Usuario cancelou ou ação foi tratada
    }

    setState(() => _isLoading = true);

    try {
      final valorTotal = _parseMoneyValue(_valorController.text);
      final numeroParcelas = _tipoDespesa == TipoDespesa.parcelada 
          ? int.tryParse(_parcelasController.text) ?? 1 
          : 1;

      Map<String, dynamic> resultado;

      if (_tipoDespesa == TipoDespesa.simples) {
        // 🔍 VERIFICAR SE FATURA ESTÁ CORRETA - SE NÃO, RECALCULAR
        if (_faturaVencimentoCompleto == null && _faturaDestino != null) {
          debugPrint('🚨 _faturaVencimentoCompleto está null, mas _faturaDestino existe. Recalculando...');
          _atualizarFaturaSeNecessario();
          
          // Aguardar um frame para o cálculo completar
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // 🔍 DEBUG: Valores sendo enviados
        final dataCompra = _dataTransacao.toIso8601String().split('T')[0];
        final faturaVencimento = _faturaVencimentoCompleto?.toIso8601String().split('T')[0] ?? '';
        
        debugPrint('🔍 SALVANDO DESPESA:');
        debugPrint('   📅 _dataTransacao: $_dataTransacao');
        debugPrint('   📅 dataCompra: $dataCompra');
        debugPrint('   💳 _faturaDestino (display): $_faturaDestino');
        debugPrint('   🎯 _faturaVencimentoCompleto: $_faturaVencimentoCompleto');
        debugPrint('   🎯 faturaVencimento (enviado): $faturaVencimento');
        debugPrint('   💳 cartaoId: ${_cartaoSelecionado!.id}');
        debugPrint('   📂 categoriaId: ${_categoriaSelecionada!.id}');
        debugPrint('   📂 subcategoriaId: ${_subcategoriaSelecionada?.id}');
        
        // Despesa simples
        resultado = await _cartaoDataService.criarDespesaCartao(
          cartaoId: _cartaoSelecionado!.id,
          categoriaId: _categoriaSelecionada!.id,
          subcategoriaId: _subcategoriaSelecionada?.id,
          descricao: _descricaoController.text.trim(),
          valorTotal: valorTotal,
          dataCompra: dataCompra,
          faturaVencimento: faturaVencimento,
          observacoes: _observacoesController.text.trim().isNotEmpty 
              ? _observacoesController.text.trim() 
              : null,
        );
      } else if (_tipoDespesa == TipoDespesa.parcelada) {
        // Despesa parcelada
        resultado = await _cartaoDataService.criarDespesaParcelada(
          cartaoId: _cartaoSelecionado!.id,
          categoriaId: _categoriaSelecionada!.id,
          subcategoriaId: _subcategoriaSelecionada?.id,
          descricao: _descricaoController.text.trim(),
          valorTotal: valorTotal,
          numeroParcelas: numeroParcelas,
          dataCompra: _dataTransacao.toIso8601String().split('T')[0],
          faturaVencimento: _faturaVencimentoCompleto?.toIso8601String().split('T')[0] ?? '',
          observacoes: _observacoesController.text.trim().isNotEmpty 
              ? _observacoesController.text.trim() 
              : null,
        );
      } else {
        // 🔍 DEBUG: Despesa recorrente/previsível
        final frequencia = _frequenciaSelecionada ?? 'mensal';
        final totalRecorrencias = _calcularTotalRecorrencias(frequencia);
        
        debugPrint('🔍 CRIANDO DESPESA RECORRENTE:');
        debugPrint('   📅 dataCompra: ${_dataTransacao.toIso8601String().split('T')[0]}');
        debugPrint('   💳 _faturaDestino (display): $_faturaDestino');
        debugPrint('   🎯 _faturaVencimentoCompleto: $_faturaVencimentoCompleto');
        debugPrint('   🎯 faturaVencimentoInicial (enviado): ${_faturaVencimentoCompleto?.toIso8601String().split('T')[0] ?? ''}');
        debugPrint('   🔄 frequencia: $frequencia');
        debugPrint('   🔢 totalRecorrencias: $totalRecorrencias');
        
        resultado = await _cartaoDataService.criarDespesaRecorrente(
          cartaoId: _cartaoSelecionado!.id,
          categoriaId: _categoriaSelecionada!.id,
          subcategoriaId: _subcategoriaSelecionada?.id,
          descricao: _descricaoController.text.trim(),
          valorMensal: valorTotal,
          totalRecorrencias: totalRecorrencias,
          dataInicial: _dataTransacao.toIso8601String().split('T')[0],
          faturaVencimentoInicial: _faturaVencimentoCompleto?.toIso8601String().split('T')[0] ?? '',
          observacoes: _observacoesController.text.trim().isNotEmpty 
              ? _observacoesController.text.trim() 
              : null,
          frequencia: frequencia,
          isParcela: false,
          primeiroEfetivado: false,
        );
      }

      if (resultado['success'] == true) {
        String mensagem;
        if (_tipoDespesa == TipoDespesa.simples) {
          mensagem = 'Despesa salva com sucesso!';
        } else if (_tipoDespesa == TipoDespesa.parcelada) {
          mensagem = 'Despesa parcelada em ${numeroParcelas}x criada com sucesso!';
        } else {
          mensagem = 'Despesa recorrente criada com sucesso!';
        }
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(resultado['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _calcularTotalRecorrencias(String frequencia) {
    switch (frequencia) {
      case 'semanal': return 12; // 3 meses
      case 'quinzenal': return 6; // 3 meses  
      case 'mensal': return 12; // 1 ano
      case 'anual': return 3; // 3 anos
      default: return 12;
    }
  }

  String _formatarDataBr(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarMesAno(DateTime data) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  /// Preview automático (baseado no projeto offline)
  Widget _buildPreview() {
    if (_preview == null || !_temDadosMinimos()) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roxoHeader.withAlpha(25), // ~10% opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.roxoHeader.withAlpha(77)), // ~30% opacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPreviewIcon(),
                color: AppColors.roxoHeader,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getPreviewTitle(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildPreviewContent(),
        ],
      ),
    );
  }

  /// Ícone do preview baseado no tipo
  IconData _getPreviewIcon() {
    switch (_tipoDespesa) {
      case TipoDespesa.recorrente:
        return Icons.repeat;
      case TipoDespesa.parcelada:
        return Icons.credit_card;
      default:
        return Icons.preview;
    }
  }

  /// Título do preview baseado no tipo
  String _getPreviewTitle() {
    switch (_tipoDespesa) {
      case TipoDespesa.recorrente:
        return 'Preview do Previsível';
      case TipoDespesa.parcelada:
        return 'Preview do Parcelamento';
      default:
        return 'Preview da Despesa';
    }
  }

  /// Conteúdo do preview baseado no tipo
  List<Widget> _buildPreviewContent() {
    if (_preview == null) return [];
    
    final List<Widget> content = [];
    
    // Informações básicas sempre mostradas
    content.add(
      Text(
        '📊 Será lançada na fatura: ${_preview!['fatura']}',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.cinzaTexto,
        ),
      ),
    );
    
    content.add(const SizedBox(height: 8));
    
    content.add(
      Text(
        '💳 Cartão: ${_preview!['cartao']?.nome ?? ''}',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.cinzaTexto,
        ),
      ),
    );
    
    // Categoria e Subcategoria
    if (_categoriaSelecionada != null) {
      content.add(const SizedBox(height: 8));
      content.add(
        Text(
          '🏷️ Categoria: ${_categoriaSelecionada!.nome}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.cinzaTexto,
          ),
        ),
      );
      
      if (_subcategoriaSelecionada != null) {
        content.add(const SizedBox(height: 4));
        content.add(
          Text(
            '   └ ${_subcategoriaSelecionada!.nome}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.cinzaMedio,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
    }
    
    // Data da compra
    content.add(const SizedBox(height: 8));
    content.add(
      Text(
        '📅 Data da compra: ${_formatarDataBr(_dataTransacao)}',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.cinzaTexto,
        ),
      ),
    );
    
    content.add(const SizedBox(height: 8));
    
    // Conteúdo específico por tipo
    if (_tipoDespesa == TipoDespesa.parcelada) {
      final parcelas = _preview!['numeroParcelas'] ?? 2;
      final valorParcela = _preview!['valorParcela'] ?? 0.0;
      final cronograma = _preview!['cronograma'] ?? '';
      
      content.add(
        Text(
          '💰 Será dividido em: ${parcelas}x de R\$ ${valorParcela.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.roxoHeader,
          ),
        ),
      );
      
      if (cronograma.isNotEmpty) {
        content.add(const SizedBox(height: 8));
        content.add(
          Text(
            '📅 Período: $cronograma',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
        );
      }
      
      // Informações de início e fim do parcelamento
      if (_faturaDestino != null) {
        final faturaFinal = _calcularFaturaFinal(parcelas - 1);
        content.add(const SizedBox(height: 4));
        content.add(
          Text(
            '🕐 De ${_faturaDestino} até $faturaFinal',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.cinzaMedio,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
    } else if (_tipoDespesa == TipoDespesa.recorrente) {
      final repeticoes = _preview!['numeroRepeticoes'] ?? 12;
      final valor = _preview!['valor'] ?? 0.0;
      final valorTotal = _preview!['valorTotal'] ?? 0.0;
      
      content.add(
        Text(
          '🔄 Valor mensal: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.roxoHeader,
          ),
        ),
      );
      
      content.add(const SizedBox(height: 4));
      
      content.add(
        Text(
          '📅 Repetições: $repeticoes meses',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.cinzaTexto,
          ),
        ),
      );
      
      content.add(const SizedBox(height: 4));
      
      content.add(
        Text(
          '💰 Total: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.verdeSucesso,
          ),
        ),
      );
      
      // Informações de período para recorrente
      if (_faturaDestino != null) {
        final faturaFinal = _calcularFaturaFinal(repeticoes - 1);
        content.add(const SizedBox(height: 8));
        content.add(
          Text(
            '🕐 De ${_faturaDestino} até $faturaFinal',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.cinzaMedio,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
    } else {
      // Despesa simples
      final valor = _preview!['valor'] ?? 0.0;
      content.add(
        Text(
          '💰 Valor: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.roxoHeader,
          ),
        ),
      );
    }
    
    return content;
  }

  /// Inicializa campos quando em modo edição
  Future<void> _inicializarModoEdicao() async {
    final transacao = widget.transacaoParaEditar!;
    
    // ✅ CARREGAR DADOS BÁSICOS DA TRANSAÇÃO
    _descricaoController.text = transacao.descricao;
    _valorController.text = _formatarValorParaInput(transacao.valor);
    _dataTransacao = transacao.data;
    _dataTransacaoController.text = _formatarDataBr(_dataTransacao);
    
    // ✅ CARREGAR CATEGORIA
    if (transacao.categoriaId != null) {
      try {
        final categorias = await _categoriaService.listarCategorias();
        try {
          _categoriaSelecionada = categorias.firstWhere(
            (c) => c.id == transacao.categoriaId,
          );
        } catch (e) {
          _categoriaSelecionada = categorias.isNotEmpty ? categorias.first : null;
        }
        
        if (_categoriaSelecionada != null) {
          _categoriaController.text = _categoriaSelecionada!.nome;
          
          // ✅ CARREGAR SUBCATEGORIA SE EXISTIR
          if (transacao.subcategoriaId != null) {
            try {
              final subcategorias = await _categoriaService.listarSubcategorias(
                _categoriaSelecionada!.id
              );
              final subcategoriaEncontrada = subcategorias.firstWhere(
                (s) => s.id == transacao.subcategoriaId,
                orElse: () => subcategorias.isNotEmpty ? subcategorias.first : subcategorias.first,
              );
              
              _subcategoriaSelecionada = subcategoriaEncontrada;
              _subcategoriaController.text = subcategoriaEncontrada.nome;
              _subcategorias = subcategorias.where((s) => s.ativo).toList();
            } catch (e) {
              debugPrint('⚠️ Subcategoria não encontrada: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Erro ao carregar categoria: $e');
      }
    }
    
    // ✅ CARREGAR CARTÃO
    if (transacao.cartaoId != null) {
      try {
        final cartoes = await _cartaoDataService.fetchCartoes();
        try {
          _cartaoSelecionado = cartoes.firstWhere(
            (c) => c.id == transacao.cartaoId,
          );
        } catch (e) {
          _cartaoSelecionado = cartoes.isNotEmpty ? cartoes.first : null;
        }
        
        if (_cartaoSelecionado != null) {
          _cartaoController.text = _cartaoSelecionado!.nome;
        }
      } catch (e) {
        debugPrint('❌ Erro ao carregar cartão: $e');
      }
    }
    
    // ✅ CONFIGURAR TIPO BASEADO NA TRANSAÇÃO
    if (transacao.numeroTotalParcelas != null && transacao.numeroTotalParcelas! > 1) {
      _tipoDespesa = TipoDespesa.parcelada;
      _parcelasController.text = transacao.numeroTotalParcelas.toString();
    } else if (transacao.recorrente) {
      _tipoDespesa = TipoDespesa.recorrente;
      if (transacao.numeroRecorrencia != null) {
        _frequenciaController.text = transacao.numeroRecorrencia.toString();
      }
    } else {
      _tipoDespesa = TipoDespesa.simples;
    }
    
    // ✅ ATUALIZAR PREVIEW
    _atualizarPreview();
    
    // ✅ FORÇAR REBUILD
    if (mounted) setState(() {});
  }

  /// Formatar valor para input (remove R$ e converte vírgula para ponto)
  String _formatarValorParaInput(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
