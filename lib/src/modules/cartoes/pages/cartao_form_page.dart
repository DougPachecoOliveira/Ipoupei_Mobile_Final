// 📝 Cartão Form Page - iPoupei Mobile
// 
// Página de formulário para criar/editar cartões
// Baseado na estrutura da conta_form_page.dart
// 
// Baseado em: Form Pattern + Material Design + SmartFields
//
// 🔄 ÚLTIMAS ALTERAÇÕES:
// ✅ Criada com base na conta_form_page para UX consistente
// ✅ SmartFields para navegação automática
// ✅ MoneyInputFormatter para limite
// ✅ Validação em tempo real
// ✅ Seleção de bandeiras e cores

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cartao_model.dart';
import '../services/cartao_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
// Removido import do SmartField para não quebrar outros modais
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/cartao_color_palette.dart';
import '../../auth/components/loading_overlay.dart';

/// MoneyInputFormatter para formatação de moeda
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

/// DayInputFormatter para limitar dias de 1 a 31
class DayInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Permite apenas dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int? day = int.tryParse(digitsOnly);
    if (day == null) {
      return oldValue;
    }

    // Se o usuário digitou um número maior que 31, mantém o valor anterior
    if (day > 31) {
      return oldValue;
    }

    // Limita a 2 dígitos máximo
    if (digitsOnly.length > 2) {
      digitsOnly = digitsOnly.substring(0, 2);
      day = int.parse(digitsOnly);
      if (day > 31) {
        return oldValue;
      }
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}

class CartaoFormPage extends StatefulWidget {
  final String modo; // 'criar' ou 'editar'
  final CartaoModel? cartao;

  const CartaoFormPage({
    super.key,
    required this.modo,
    this.cartao,
  });

  @override
  State<CartaoFormPage> createState() => _CartaoFormPageState();
}

class _CartaoFormPageState extends State<CartaoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _cartaoService = CartaoService.instance;
  final _contaService = ContaService.instance;
  
  // Controllers
  final _nomeController = TextEditingController();
  final _limiteController = TextEditingController();
  final _diaFechamentoController = TextEditingController();
  final _diaVencimentoController = TextEditingController();
  final _bandeiraController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Focus Nodes para navegação automática
  final _nomeFocusNode = FocusNode();
  final _limiteFocusNode = FocusNode();
  final _diaFechamentoFocusNode = FocusNode();
  final _diaVencimentoFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();
  
  // Scroll controller removido - não necessário sem SmartFields
  
  // Estados
  String? _bandeiraSelecionada;
  String? _contaDebitoId;
  String? _contaSelecionada; // ID da conta selecionada para débito
  String _corSelecionada = '#000000'; // Cor preta como padrão
  List<ContaModel> _contas = [];
  bool _isLoading = false;
  Map<String, String> _erros = {};

  @override
  void initState() {
    super.initState();
    _inicializarDados();
    _carregarContas();
    _adicionarListenersPreview();
    
    // Foco automático no primeiro campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nomeFocusNode.requestFocus();
    });
  }
  
  /// Adicionar listeners para atualizar preview em tempo real
  void _adicionarListenersPreview() {
    _nomeController.addListener(() => setState(() {}));
    _limiteController.addListener(() => setState(() {}));
    _diaFechamentoController.addListener(() => setState(() {}));
    _diaVencimentoController.addListener(() => setState(() {}));
  }
  
  @override
  void dispose() {
    _nomeController.dispose();
    _limiteController.dispose();
    _diaFechamentoController.dispose();
    _diaVencimentoController.dispose();
    _bandeiraController.dispose();
    _observacoesController.dispose();
    
    _nomeFocusNode.dispose();
    _limiteFocusNode.dispose();
    _diaFechamentoFocusNode.dispose();
    _diaVencimentoFocusNode.dispose();
    _observacoesFocusNode.dispose();
    
    // _scrollController.dispose(); // removido
    super.dispose();
  }

  void _inicializarDados() {
    final cartao = widget.cartao;
    
    if (cartao != null) {
      _nomeController.text = cartao.nome;
      
      // Formatar limite para moeda
      if (cartao.limite > 0) {
        final limiteFormatado = (cartao.limite * 100).toInt();
        final formatter = MoneyInputFormatter();
        final formatted = formatter.formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: limiteFormatado.toString()),
        );
        _limiteController.text = formatted.text;
      }
      
      _diaFechamentoController.text = cartao.diaFechamento?.toString() ?? '';
      _diaVencimentoController.text = cartao.diaVencimento?.toString() ?? '';
            _observacoesController.text = cartao.observacoes ?? '';
      
      _bandeiraSelecionada = cartao.bandeira;
      _bandeiraController.text = cartao.bandeira ?? '';
      _contaDebitoId = cartao.contaDebitoId;
      _contaSelecionada = cartao.contaDebitoId; // ✅ Sincronizar para exibição
      _corSelecionada = cartao.cor ?? '#000000'; // Cor preta como padrão
    }
  }

  Future<void> _carregarContas() async {
    try {
      final contas = await _contaService.fetchContas(incluirArquivadas: false);
      setState(() => _contas = contas);
    } catch (e) {
      // Ignora erro - página funcionará sem débito automático
    }
  }

  bool get _isFormValid {
    return _nomeController.text.trim().isNotEmpty &&
           _limiteController.text.isNotEmpty &&
           _diaFechamentoController.text.isNotEmpty &&
           _diaVencimentoController.text.isNotEmpty &&
           _bandeiraSelecionada != null && _bandeiraSelecionada!.isNotEmpty; // ✅ BANDEIRA OBRIGATÓRIA
  }

  bool get _temAlteracoes {
    // Modo criação sempre permite salvar se válido
    if (widget.modo == 'criar') return _isFormValid;
    
    // Modo edição: verifica se algo mudou
    if (widget.cartao == null) return false;
    final cartao = widget.cartao!;
    
    // Extrai limite atual
    double limiteAtual = 0.0;
    if (_limiteController.text.isNotEmpty) {
      final numbersOnly = _limiteController.text.replaceAll(RegExp(r'[^0-9,]'), '');
      if (numbersOnly.isNotEmpty) {
        final cleanNumber = numbersOnly.replaceAll(',', '.');
        limiteAtual = double.tryParse(cleanNumber) ?? 0.0;
      }
    }
    
    final resultado = _nomeController.text.trim() != cartao.nome ||
           limiteAtual != cartao.limite ||
           (int.tryParse(_diaFechamentoController.text) ?? 0) != (cartao.diaFechamento ?? 0) ||
           (int.tryParse(_diaVencimentoController.text) ?? 0) != (cartao.diaVencimento ?? 0) ||
           _observacoesController.text.trim() != (cartao.observacoes ?? '') ||
           _bandeiraSelecionada != cartao.bandeira ||
           _contaDebitoId != cartao.contaDebitoId || // ✅ Já está aqui
           _corSelecionada != cartao.cor;
           
    // Debug log para verificar mudanças
    if (widget.modo == 'editar' && _contaDebitoId != cartao.contaDebitoId) {
      print('🔍 DEBUG: Conta débito mudou - Atual: $_contaDebitoId, Original: ${cartao.contaDebitoId}');
    }
    
    return resultado;
  }

  Future<void> _salvarCartao() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ VALIDAÇÕES AVANÇADAS DE REGRAS DE NEGÓCIO
    final diaFechamento = int.tryParse(_diaFechamentoController.text) ?? 0;
    final diaVencimento = int.tryParse(_diaVencimentoController.text) ?? 0;
    
    final validationErrors = <String>[];
    
    // Regra 0: Bandeira é obrigatória
    if (_bandeiraSelecionada == null || _bandeiraSelecionada!.isEmpty) {
      validationErrors.add('Selecione a bandeira do cartão');
    }
    
    // Regra 1: Dia de fechamento não pode ser igual ao dia de vencimento
    if (diaFechamento == diaVencimento) {
      validationErrors.add('O dia de fechamento não pode ser igual ao dia de vencimento');
    }
    
    // Regra 2: Vencimento deve ser pelo menos 5 dias após o fechamento
    // (considerando ciclo do mês)
    int diasEntre;
    if (diaVencimento > diaFechamento) {
      diasEntre = diaVencimento - diaFechamento;
    } else {
      // Vencimento no mês seguinte
      diasEntre = (31 - diaFechamento) + diaVencimento;
    }
    
    if (diasEntre < 5) {
      validationErrors.add('O vencimento deve ser pelo menos 5 dias após o fechamento');
    }
    
    // Regra 3: Aviso sobre dias problemáticos no final do mês (warning, não bloqueante)
    final warnings = <String>[];
    if (diaFechamento > 28) {
      warnings.add('Dias de fechamento após 28 podem variar em meses com menos dias');
    }
    
    if (diaVencimento > 28) {
      warnings.add('Dias de vencimento após 28 podem variar em meses com menos dias');
    }
    
    // Se houver erros críticos de validação, mostrar e parar
    if (validationErrors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro de Validação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Por favor, corrija os seguintes pontos:', 
                       style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...validationErrors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.red)),
                    Expanded(child: Text(error)),
                  ],
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Se houver warnings, mostrar mas permitir continuar
    if (warnings.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Atenção'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pontos de atenção:', 
                       style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.orange)),
                    Expanded(child: Text(warning)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              const Text('Deseja continuar mesmo assim?',
                       style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldContinue) return;
    }

    setState(() {
      _isLoading = true;
      _erros.clear();
    });

    try {
      // Extrair valor do formato moeda
      final limiteText = _limiteController.text;
      double limite = 0.0;
      
      if (limiteText.isNotEmpty) {
        final numbersOnly = limiteText.replaceAll(RegExp(r'[^0-9,]'), '');
        if (numbersOnly.isNotEmpty) {
          final cleanNumber = numbersOnly.replaceAll(',', '.');
          limite = double.tryParse(cleanNumber) ?? 0.0;
        }
      }

      // Validar dados
      _erros = _cartaoService.validarCartao(
        nome: _nomeController.text,
        limite: limite,
        diaFechamento: int.tryParse(_diaFechamentoController.text) ?? 0,
        diaVencimento: int.tryParse(_diaVencimentoController.text) ?? 0,
      );

      // Verificar nome duplicado
      final nomeDuplicado = await _cartaoService.verificarNomeDuplicado(
        _nomeController.text,
        cartaoIdExcluir: widget.cartao?.id,
      );

      if (nomeDuplicado) {
        _erros['nome'] = 'Já existe um cartão com este nome';
      }

      if (_erros.isNotEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Criar ou atualizar
      CartaoModel resultado;
      
      if (widget.modo == 'criar') {
        resultado = await _cartaoService.criarCartao(
          nome: _nomeController.text.trim(),
          limite: limite,
          diaFechamento: int.parse(_diaFechamentoController.text),
          diaVencimento: int.parse(_diaVencimentoController.text),
          bandeira: _bandeiraSelecionada,
          contaDebitoId: _contaDebitoId,
          cor: _corSelecionada,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
        );
      } else {
        final cartaoAtualizado = widget.cartao!.copyWith(
          nome: _nomeController.text.trim(),
          limite: limite,
          diaFechamento: int.parse(_diaFechamentoController.text),
          diaVencimento: int.parse(_diaVencimentoController.text),
          bandeira: _bandeiraSelecionada,
          contaDebitoId: _contaDebitoId,
          cor: _corSelecionada,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
        );

        await _cartaoService.atualizarCartao(cartaoAtualizado);
        resultado = cartaoAtualizado;
      }

      // Retornar resultado
      if (mounted) Navigator.of(context).pop(resultado);

    } catch (e) {
      setState(() {
        _erros['geral'] = 'Erro ao salvar: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.modo == 'criar' ? 'Novo Cartão' : 'Editar Cartão',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Card Preview Dinâmico
          _buildCardPreview(),
          
          // Formulário
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFormulario(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Botões de ação
          _buildBotoesAcao(),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome do cartão (estilo minimalista da imagem)
            _buildCampoMinimalista(
              controller: _nomeController,
              focusNode: _nomeFocusNode,
              label: 'Nome do Cartão',
              hint: 'BTG+ Mastercard',
              icon: Icons.credit_card,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _limiteFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Limite do cartão
            _buildCampoMinimalista(
              controller: _limiteController,
              focusNode: _limiteFocusNode,
              label: 'Limite do Cartão',
              hint: '8.000,00',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              inputFormatters: [MoneyInputFormatter()],
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _diaFechamentoFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Limite é obrigatório';
                }
                
                final numbersOnly = value.replaceAll(RegExp(r'[^0-9,]'), '');
                if (numbersOnly.isEmpty) {
                  return 'Digite um valor válido';
                }
                
                final cleanNumber = numbersOnly.replaceAll(',', '.');
                final limite = double.tryParse(cleanNumber) ?? 0.0;
                if (limite <= 0) {
                  return 'Limite deve ser maior que zero';
                }
                
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Datas em linha
            Row(
              children: [
                Expanded(
                  child: _buildCampoMinimalista(
                    controller: _diaFechamentoController,
                    focusNode: _diaFechamentoFocusNode,
                    label: 'Dia Fechamento',
                    hint: '22',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      DayInputFormatter(),
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      _diaVencimentoFocusNode.requestFocus();
                      // Verificar se pode abrir modal após preencher fechamento
                      _verificarEAbrirModalBandeiraTardio();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      final dia = int.tryParse(value) ?? 0;
                      if (dia < 1 || dia > 31) {
                        return 'Entre 1 e 31';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildCampoMinimalista(
                    controller: _diaVencimentoController,
                    focusNode: _diaVencimentoFocusNode,
                    label: 'Dia Vencimento',
                    hint: '2',
                    icon: Icons.event,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      DayInputFormatter(),
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _verificarEAbrirModalBandeira(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      final dia = int.tryParse(value) ?? 0;
                      if (dia < 1 || dia > 31) {
                        return 'Entre 1 e 31';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bandeira (estilo minimalista como conta padrão)
            _buildBandeiraField(),

            const SizedBox(height: 16),

            // Conta padrão para pagamento (SmartField minimalista)
            _buildContaPadraoField(),
            const SizedBox(height: 16),

            // Cor do cartão
            _buildSeletorCor(),

            const SizedBox(height: 24),
            
            // Resumo das alterações (se houver)
            if (_temAlteracoes) ...[
              _buildResumoAlteracoes(),
              const SizedBox(height: 16),
            ],

            // Observações
            TextFormField(
              controller: _observacoesController,
              focusNode: _observacoesFocusNode,
              decoration: InputDecoration(
                labelText: 'Observações',
                hintText: 'Notas adicionais...',
                prefixIcon: Icon(Icons.note, color: AppColors.roxoHeader),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cinzaBorda),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.roxoHeader, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cinzaBorda),
                ),
                filled: false,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),

            // Erro geral
            if (_erros.containsKey('geral'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erros['geral']!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      );
  }

  /// Campo bandeira estilo minimalista
  Widget _buildBandeiraField() {
    return _buildCampoMinimalista(
      controller: _bandeiraController,
      label: 'Bandeira *',
      hint: 'Selecione a bandeira',
      icon: Icons.payment,
      readOnly: true,
      onTap: _showBandeiraSelector,
      validator: (value) {
        if (_bandeiraSelecionada == null || _bandeiraSelecionada!.isEmpty) {
          return 'Selecione a bandeira do cartão';
        }
        return null;
      },
    );
  }

  Widget _buildBandeiraDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bandeira',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _bandeiraSelecionada,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.payment, color: AppColors.roxoHeader),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cinzaBorda),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.roxoHeader, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cinzaBorda),
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Selecionar...')),
            ...CartaoModel.bandeirasPadrao.map((bandeira) =>
                DropdownMenuItem(value: bandeira, child: Text(bandeira))),
          ],
          onChanged: (value) => setState(() => _bandeiraSelecionada = value),
        ),
      ],
    );
  }

  /// Campo conta padrão estilo SmartField minimalista
  Widget _buildContaPadraoField() {
    final contaSelecionada = _contaSelecionada != null
        ? _contas.firstWhere(
            (c) => c.id == _contaSelecionada,
            orElse: () => ContaModel(
              id: '',
              usuarioId: '',
              nome: '',
              saldo: 0.0,
              saldoInicial: 0.0,
              tipo: 'corrente',
              ativo: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
        : null;

    final displayText = contaSelecionada?.nome ?? '';
    
    return _buildCampoMinimalista(
      controller: TextEditingController(text: displayText),
      label: 'Conta Padrão para Pagamento',
      hint: 'Selecione uma conta (opcional)',
      icon: Icons.account_balance,
      readOnly: true,
      onTap: _showContaPadraoSelector,
      validator: null, // Campo opcional
    );
  }


  Widget _buildSeletorCor() {
    // Cores dos bancos brasileiros (igual à imagem)
    final coresDisponiveis = [
      {'nome': 'Roxo Nubank', 'valor': '#8A05BE'},
      {'nome': 'Laranja Inter', 'valor': '#FF6500'},
      {'nome': 'Amarelo C6', 'valor': '#FFD700'},
      {'nome': 'Verde PicPay', 'valor': '#21C25E'},
      {'nome': 'Vermelho Santander', 'valor': '#DC143C'},
      {'nome': 'Azul BTG', 'valor': '#1E3A8A'},
      {'nome': 'Preto XP', 'valor': '#000000'},
      {'nome': 'Cinza Padrão', 'valor': '#6B7280'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor do Cartão',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Primeira linha - cores principais
        Row(
          children: coresDisponiveis.take(6).map((cor) {
            final isSelected = _corSelecionada == cor['valor'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _corSelecionada = cor['valor']!);
                },
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(cor['valor']!.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // Segunda linha - cores extras
        Row(
          children: [
            ...coresDisponiveis.skip(6).map((cor) {
              final isSelected = _corSelecionada == cor['valor'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _corSelecionada = cor['valor']!),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(cor['valor']!.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              );
            }).toList(),
            // Botão "+ Cores" 
            Expanded(
              child: GestureDetector(
                onTap: _mostrarModalCoresExtendidas,
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cinzaBorda),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.grey, size: 16),
                      Text(
                        'Cores',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Espaços vazios para alinhar (reduzido de 4 para 3)
            ...List.generate(3, (index) => const Expanded(child: SizedBox())),
          ],
        ),
      ],
    );
  }

  /// Card Preview Dinâmico (igual à imagem)
  Widget _buildCardPreview() {
    final nome = _nomeController.text.trim().isEmpty 
        ? (widget.cartao?.nome ?? 'Nome do Cartão') 
        : _nomeController.text.trim();
    
    final limite = _limiteController.text.isEmpty 
        ? (widget.cartao?.limite ?? 0.0)
        : _extrairLimiteFormatado();
    
    final fechamento = _diaFechamentoController.text.isEmpty 
        ? (widget.cartao?.diaFechamento?.toString() ?? '15')
        : _diaFechamentoController.text;
        
    final vencimento = _diaVencimentoController.text.isEmpty 
        ? (widget.cartao?.diaVencimento?.toString() ?? '10')
        : _diaVencimentoController.text;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardSuave,
      ),
      child: Row(
        children: [
          // Bolinha colorida
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(int.parse(_corSelecionada.replaceAll('#', '0xFF'))),
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Info do cartão
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _bandeiraSelecionada != null 
                          ? AppColors.roxoHeader.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _bandeiraSelecionada ?? 'Selecione a bandeira',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _bandeiraSelecionada != null 
                            ? AppColors.roxoHeader 
                            : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limite',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'R\$ ${limite.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fechamento/Vencimento',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$fechamento/$vencimento',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extrair limite formatado do controller
  double _extrairLimiteFormatado() {
    final limiteText = _limiteController.text;
    if (limiteText.isEmpty) return 0.0;
    
    final numbersOnly = limiteText.replaceAll(RegExp(r'[^0-9,]'), '');
    if (numbersOnly.isEmpty) return 0.0;
    
    final cleanNumber = numbersOnly.replaceAll(',', '.');
    return double.tryParse(cleanNumber) ?? 0.0;
  }

  /// Campo minimalista igual à imagem
  Widget _buildCampoMinimalista({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label pequeno em cima
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Campo com ícone e linha inferior
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 0, right: 12),
              child: Icon(
                icon,
                color: AppColors.roxoHeader,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 20,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.roxoHeader, width: 2),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.5),
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          ),
        ),
      ],
    );
  }


  /// Widget com resumo das alterações (igual à versão offline)
  Widget _buildResumoAlteracoes() {
    if (widget.modo == 'criar') {
      // Retorna widget vazio para modo criação
      return const SizedBox();
    }

    final alteracoes = _detectarAlteracoes();
    if (alteracoes.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roxoHeader.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.roxoHeader.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.roxoHeader, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Alterações Detectadas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alteracoes.map((alteracao) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $alteracao',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Verificar se os campos essenciais estão preenchidos e abrir modal de bandeira automaticamente
  void _verificarEAbrirModalBandeira() {
    // Verificar se todos os campos essenciais estão preenchidos
    if (_nomeController.text.trim().isNotEmpty &&
        _limiteController.text.trim().isNotEmpty &&
        _diaFechamentoController.text.trim().isNotEmpty &&
        _diaVencimentoController.text.trim().isNotEmpty &&
        (_bandeiraSelecionada == null || _bandeiraSelecionada!.isEmpty)) {
      
      // Aguardar um pouco para que o campo termine de processar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showBandeiraSelector();
        }
      });
    } else {
      // Se a bandeira já foi selecionada, move para observações
      _observacoesFocusNode.requestFocus();
    }
  }
  
  /// Verificação tardia para abrir modal após preencher fechamento
  void _verificarEAbrirModalBandeiraTardio() {
    // Aguardar mais tempo para que o próximo campo (vencimento) seja preenchido
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && 
          _nomeController.text.trim().isNotEmpty &&
          _limiteController.text.trim().isNotEmpty &&
          _diaFechamentoController.text.trim().isNotEmpty &&
          _diaVencimentoController.text.trim().isNotEmpty &&
          (_bandeiraSelecionada == null || _bandeiraSelecionada!.isEmpty)) {
        _showBandeiraSelector();
      }
    });
  }

  /// Selector de bandeira (Bottom Sheet)
  void _showBandeiraSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle drag
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const Text(
                'Selecionar Bandeira',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Bandeiras disponíveis
                    ...CartaoModel.bandeirasPadrao.map((bandeira) {
                      final isSelected = _bandeiraSelecionada == bandeira;
                      return ListTile(
                        leading: Icon(Icons.payment, color: AppColors.roxoHeader),
                        title: Text(bandeira),
                        trailing: isSelected 
                            ? Icon(Icons.check, color: AppColors.roxoHeader)
                            : null,
                        onTap: () {
                          setState(() {
                            _bandeiraSelecionada = bandeira;
                            _bandeiraController.text = bandeira; // ✅ Atualizar controller também
                          });
                          Navigator.pop(context);
                          // Navegar automaticamente para observações após selecionar bandeira
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _observacoesFocusNode.requestFocus();
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selector de conta padrão (Bottom Sheet)
  void _showContaPadraoSelector() {
    if (_contas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma conta disponível')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle drag
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Conta Padrão para Pagamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta conta será sugerida automaticamente para pagamentos da fatura',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Opção "Nenhuma"
                    ListTile(
                      leading: const Icon(Icons.block, color: Colors.grey),
                      title: const Text('Nenhuma conta padrão'),
                      trailing: _contaSelecionada == null
                          ? Icon(Icons.check, color: AppColors.roxoHeader)
                          : null,
                      onTap: () {
                        setState(() {
                          _contaSelecionada = null;
                          _contaDebitoId = null; // ✅ Sincronizar para salvamento
                        });
                        Navigator.pop(context);
                      },
                    ),
                    
                    if (_contas.isNotEmpty) const Divider(),
                    
                    // Contas disponíveis
                    ..._contas.map((conta) {
                      final isSelected = _contaSelecionada == conta.id;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: conta.cor != null
                              ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
                              : AppColors.roxoHeader,
                          child: conta.cor == null 
                              ? const Icon(Icons.account_balance, size: 12, color: Colors.white)
                              : null,
                        ),
                        title: Text(conta.nome),
                        subtitle: conta.banco != null ? Text(conta.banco!) : null,
                        trailing: isSelected 
                            ? Icon(Icons.check, color: AppColors.roxoHeader)
                            : null,
                        onTap: () {
                          setState(() {
                            _contaSelecionada = conta.id;
                            _contaDebitoId = conta.id; // ✅ Sincronizar para salvamento
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Detectar alterações específicas
  List<String> _detectarAlteracoes() {
    if (widget.modo == 'criar') return [];
    
    final alteracoes = <String>[];
    final cartaoOriginal = widget.cartao!;
    
    if (_nomeController.text.trim() != cartaoOriginal.nome) {
      alteracoes.add('Nome alterado');
    }
    
    if (_extrairLimiteFormatado() != cartaoOriginal.limite) {
      alteracoes.add('Limite alterado');
    }
    
    if (int.tryParse(_diaFechamentoController.text) != cartaoOriginal.diaFechamento) {
      alteracoes.add('Dia de fechamento alterado');
    }
    
    if (int.tryParse(_diaVencimentoController.text) != cartaoOriginal.diaVencimento) {
      alteracoes.add('Dia de vencimento alterado');
    }
    
    if (_bandeiraSelecionada != cartaoOriginal.bandeira) {
      alteracoes.add('Bandeira alterada');
    }
    
    if (_contaDebitoId != cartaoOriginal.contaDebitoId) {
      alteracoes.add('Conta para débito alterada');
    }
    
    if (_corSelecionada != (cartaoOriginal.cor ?? '#8A05BE')) {
      alteracoes.add('Cor alterada');
    }
    
    return alteracoes;
  }

  /// Modal com todas as cores estendidas (70+ opções)
  void _mostrarModalCoresExtendidas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle drag
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Escolha uma cor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Lista de cores por categoria
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: CartaoColorPalette.categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = CartaoColorPalette.categorias[index];
                    final coresCategoria = CartaoColorPalette.getCoresPorCategoria(categoria.toLowerCase());
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título da categoria
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            categoria,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        
                        // Grid de cores da categoria
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: coresCategoria.length,
                          itemBuilder: (context, colorIndex) {
                            final nomeColor = coresCategoria.keys.elementAt(colorIndex);
                            final valorColor = coresCategoria.values.elementAt(colorIndex);
                            final isSelected = _corSelecionada == valorColor;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() => _corSelecionada = valorColor);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: CartaoColorPalette.hexToColor(valorColor),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão Cancelar
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Botão Salvar
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _temAlteracoes ? _salvarCartao : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxoHeader,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _temAlteracoes ? 4 : 0,
                shadowColor: AppColors.roxoHeader.withValues(alpha: 0.3),
              ),
              child: Text(
                widget.modo == 'criar' ? 'Criar Cartão' : 'Salvar Alterações',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}