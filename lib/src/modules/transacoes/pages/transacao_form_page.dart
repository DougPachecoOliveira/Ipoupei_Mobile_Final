// 📝 Transação Form Page - iPoupei Mobile
// 
// Página de formulário para criar/editar transações
// Suporte a receitas, despesas e parcelas
// 
// Baseado em: Form Pattern + Material Design

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transacao_model.dart';
import '../services/transacao_service.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../../shared/components/loading/ipoupei_loading_system.dart';
import '../components/smart_field.dart';
import '../../transacoes/components/smart_field.dart' as TransacaoSmartField;
// import '../../../shared/utils/money_input_formatter.dart'; // TODO: Criar formatter
import '../components/conditional_transaction_fields.dart';
// import '../components/smart_money_field.dart'; // Não usado
import '../components/status_switch.dart';
import '../components/tipo_selector.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../categorias/data/categoria_icons.dart';

class TransacaoFormPage extends StatefulWidget {
  final String modo; // 'criar' ou 'editar'
  final String? tipo; // 'receita', 'despesa' para criação
  final TransacaoModel? transacao;

  const TransacaoFormPage({
    super.key,
    required this.modo,
    this.tipo,
    this.transacao,
  });

  @override
  State<TransacaoFormPage> createState() => _TransacaoFormPageState();
}

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

class _TransacaoFormPageState extends State<TransacaoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _transacaoService = TransacaoService.instance;
  final _contaService = ContaService.instance;
  final _categoriaService = CategoriaService.instance;
  
  // Controllers
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _parcelasController = TextEditingController();
  final _dataController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _subcategoriaController = TextEditingController();
  final _contaController = TextEditingController();
  
  // 🎯 CONTROLADORES DE NAVEGAÇÃO (IGUAL CARTÃO)
  final _scrollController = ScrollController();
  
  // Focus Nodes para navegação automática
  final _descricaoFocusNode = FocusNode();
  final _valorFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();
  final _salvarButtonFocusNode = FocusNode();
  final _dataFocusNode = FocusNode();
  final _categoriaFocusNode = FocusNode();
  final _subcategoriaFocusNode = FocusNode();
  final _parcelasFocusNode = FocusNode();
  final _repeticoesFocusNode = FocusNode();
  
  // Controllers para recorrência
  late TextEditingController _repeticoesController;
  late TextEditingController _frequenciaController;
  
  // Estados principais
  String _tipoSelecionado = 'despesa';
  String _tipoTransacao = 'extra'; // 'extra', 'parcelada', 'previsivel'
  bool _loading = false;
  
  // Estados de seleção
  String? _contaSelecionada;
  String? _categoriaSelecionada;
  String? _subcategoriaSelecionada;
  String? _cartaoSelecionado;
  String? _contaDestinoSelecionada;
  DateTime? _dataSelecionada;
  bool _efetivado = true;
  bool _statusManualmenteAlterado = false; // Flag para controlar override manual
  bool _temParcelas = false; // Compatibilidade com código antigo
  bool _ehRecorrente = false;
  
  // Estados de recorrência/parcelamento
  int _numeroParcelas = 12;
  String _frequenciaParcelada = 'mensal';
  String _frequenciaPrevisivel = 'mensal';
  
  // ✅ VARIÁVEL PARA FORÇAR REBUILD DOS SMARTFIELDS
  int _rebuildKey = 0;
  
  // 📅 OPÇÕES DE FREQUÊNCIA (React + Extensões)
  final List<Map<String, String>> _opcoesFrequencia = [
    {'value': 'semanal', 'label': 'Semanal', 'descricao': 'A cada 7 dias', 'maxRepeticoes': '260'},
    {'value': 'quinzenal', 'label': 'Quinzenal', 'descricao': 'A cada 15 dias', 'maxRepeticoes': '130'},
    {'value': 'mensal', 'label': 'Mensal', 'descricao': 'A cada mês', 'maxRepeticoes': '60'},
    {'value': 'bimestral', 'label': 'Bimestral', 'descricao': 'A cada 2 meses', 'maxRepeticoes': '30'},
    {'value': 'trimestral', 'label': 'Trimestral', 'descricao': 'A cada 3 meses', 'maxRepeticoes': '20'},
    {'value': 'semestral', 'label': 'Semestral', 'descricao': 'A cada 6 meses', 'maxRepeticoes': '10'},
    {'value': 'anual', 'label': 'Anual', 'descricao': 'A cada ano', 'maxRepeticoes': '5'},
  ];
  
  /// 🔢 OBTER MÁXIMO DE REPETIÇÕES BASEADO NA FREQUÊNCIA
  int _getMaxRepeticoes() {
    final opcao = _opcoesFrequencia.firstWhere((f) => f['value'] == _frequenciaPrevisivel);
    return int.parse(opcao['maxRepeticoes']!);
  }
  int _totalRecorrencias = 12;
  bool _primeiroEfetivado = false; // Por padrão, primeira não efetivada
  
  // 🎨 ESTADOS DE UI E PREVIEW (IGUAL CARTÃO)
  Map<String, dynamic>? _preview;
  bool _salvarEContinuar = false;
  ContaModel? _contaEscolhida;
  CategoriaModel? _categoriaEscolhida;
  CategoriaModel? _subcategoriaEscolhida;
  
  // Dados carregados
  List<ContaModel> _contas = [];
  List<CategoriaModel> _categorias = [];
  List<SubcategoriaModel> _subcategorias = [];

  @override
  void initState() {
    super.initState();
    _repeticoesController = TextEditingController(text: _totalRecorrencias.toString());
    _frequenciaController = TextEditingController(text: _opcoesFrequencia.firstWhere((f) => f['value'] == _frequenciaPrevisivel)['label']);
    _inicializarFormulario();
    _setupNavigationListeners(); // 🎯 NOVA FUNCIONALIDADE
    _carregarContas();
    _carregarCategorias();
    _carregarSubcategorias();
    
    // ✅ GARANTIR QUE CAMPOS INICIAIS SEJAM EXIBIDOS CORRETAMENTE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          debugPrint('🔄 PostFrameCallback: Forçando rebuild inicial dos campos');
        });
      }
    });
  }
  
  void _inicializarFormulario() {
    // ✅ INICIALIZAR CAMPOS PADRÃO SEMPRE
    _parcelasController.text = '2';
    _frequenciaController.text = 'Mensal';
    _repeticoesController.text = '12';
    
    if (widget.modo == 'criar' && widget.tipo != null) {
      _tipoSelecionado = widget.tipo!;
      _dataSelecionada = DateTime.now(); // Data atual apenas para criação
      // ✅ Aplicar auto-status baseado na data inicial
      _atualizarStatusPorData(_dataSelecionada!);
    } else if (widget.modo == 'editar' && widget.transacao != null) {
      final transacao = widget.transacao!;
      _descricaoController.text = transacao.descricao;
      _valorController.text = _formatarValorParaInput(transacao.valor);
      _observacoesController.text = transacao.observacoes ?? '';
      _tipoSelecionado = transacao.tipo;
      _contaSelecionada = transacao.contaId;
      _dataSelecionada = transacao.data;
      _efetivado = transacao.efetivado;
      
      // ✅ PREENCHER CATEGORIA E SUBCATEGORIA
      _categoriaSelecionada = transacao.categoriaId;
      _subcategoriaSelecionada = transacao.subcategoriaId;
      
      // ✅ ATUALIZAR CONTROLLERS DE CATEGORIA E CONTA (para interface)
      _atualizarControllersCategoria();
      _atualizarContaConta();
      
      // ✅ PREENCHER CARTÃO SE FOR DESPESA DE CARTÃO
      if (transacao.cartaoId != null) {
        _cartaoSelecionado = transacao.cartaoId;
      }
      
      // ✅ PREENCHER CONTA DESTINO SE FOR TRANSFERÊNCIA
      if (transacao.contaDestinoId != null) {
        _contaDestinoSelecionada = transacao.contaDestinoId;
      }
      
      if (transacao.numeroTotalParcelas != null && transacao.numeroTotalParcelas! > 1) {
        _temParcelas = true;
        _parcelasController.text = transacao.numeroTotalParcelas.toString();
      }
      
      // ✅ VERIFICAR SE É RECORRENTE
      if (transacao.recorrente || transacao.grupoRecorrencia != null) {
        _ehRecorrente = true;
        if (transacao.numeroRecorrencia != null) {
          _repeticoesController.text = transacao.numeroRecorrencia.toString();
        }
      }
    }
    
    // Garantir que _dataSelecionada tenha um valor padrão se ainda for null
    _dataSelecionada ??= DateTime.now();

    // ✅ Para casos onde data não foi definida antes, aplicar auto-status
    if (widget.modo == 'criar' && !_statusManualmenteAlterado) {
      _atualizarStatusPorData(_dataSelecionada!);
    }

    // Inicializar data controller após configurar a data
    _dataController.text = _formatarDataBr(_dataSelecionada!);
  }

  /// Carrega objetos de categoria e subcategoria baseados nos IDs selecionados
  Future<void> _atualizarControllersCategoria() async {
    if (_categoriaSelecionada != null) {
      // Buscar categoria pelo ID
      final categorias = await _categoriaService.listarCategorias();
      _categoriaEscolhida = categorias.firstWhere(
        (c) => c.id == _categoriaSelecionada,
        orElse: () => categorias.first,
      );
      
      // Atualizar controller de categoria
      _categoriaController.text = _categoriaEscolhida?.nome ?? '';
      
      // Buscar subcategoria se selecionada
      if (_subcategoriaSelecionada != null && _categoriaEscolhida != null) {
        final subcategorias = await _categoriaService.listarSubcategorias(_categoriaEscolhida!.id);
        try {
          _subcategoriaEscolhida = subcategorias.firstWhere(
            (s) => s.id == _subcategoriaSelecionada,
          );
        } catch (e) {
          _subcategoriaEscolhida = subcategorias.isNotEmpty ? subcategorias.first : null;
        }
        
        // Atualizar controller de subcategoria
        _subcategoriaController.text = _subcategoriaEscolhida?.nome ?? '';
      }
      
      // Força rebuild da interface
      if (mounted) setState(() {});
    }
  }

  /// Carrega objeto de conta baseado no ID selecionado
  Future<void> _atualizarContaConta() async {
    if (_contaSelecionada != null) {
      // Buscar conta pelo ID
      final contas = await _contaService.fetchContas();
      try {
        _contaEscolhida = contas.firstWhere(
          (c) => c.id == _contaSelecionada,
        );
      } catch (e) {
        _contaEscolhida = contas.isNotEmpty ? contas.first : null;
      }
      
      // Atualizar controller de conta
      _contaController.text = _contaEscolhida?.nome ?? '';
      
      // Força rebuild da interface
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    // Controllers originais
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    _parcelasController.dispose();
    _contaController.dispose();
    _repeticoesController.dispose(); // ✅ NOVO CONTROLLER
    
    // 🎯 NOVOS CONTROLADORES (IGUAL CARTÃO)
    _scrollController.dispose();
    _descricaoFocusNode.dispose();
    _valorFocusNode.dispose();
    _observacoesFocusNode.dispose();
    _salvarButtonFocusNode.dispose();
    _parcelasFocusNode.dispose();
    _repeticoesFocusNode.dispose(); // ✅ NOVO FOCUSNODE
    
    super.dispose();
  }

  /// 🔄 CARREGAR CONTAS  
  Future<void> _carregarContas() async {
    try {
      // 🔄 PRIMEIRA CHAMADA: Garante sincronização com Supabase
      await _contaService.fetchContas();
      
      // 🔄 SEGUNDA CHAMADA: Pega dados já sincronizados
      final contas = await _contaService.fetchContas();
      debugPrint('📊 Contas carregadas: ${contas.length}');
      
      setState(() {
        _contas = contas.where((c) => c.ativo).toList();
        debugPrint('📊 Contas ativas: ${_contas.length}');
        
        // Debug específico das contas principais
        final contasPrincipais = _contas.where((c) => c.contaPrincipal == true).toList();
        debugPrint('🎯 Contas principais: ${contasPrincipais.map((c) => c.nome).join(", ")}');
        
        // Selecionar conta principal se existir, senão deixa sem pré-seleção
        if (_contaSelecionada == null && _contas.isNotEmpty) {
          final contaPrincipal = _contas.firstWhere(
            (c) => c.contaPrincipal == true,
            orElse: () => ContaModel(
              id: '', 
              usuarioId: '', 
              nome: '', 
              tipo: '', 
              saldoInicial: 0, 
              saldo: 0, 
              ativo: true,
              contaPrincipal: false,
              incluirSomaTotal: true,
              ordem: 0,
              origemDiagnostico: false,
              createdAt: DateTime.now(), 
              updatedAt: DateTime.now()
            ),
          );
          
          // Só pré-seleciona se encontrou uma conta principal
          if (contaPrincipal.id.isNotEmpty) {
            _contaSelecionada = contaPrincipal.id;
            _contaEscolhida = contaPrincipal;
            _contaController.text = contaPrincipal.nome;
          }
        } else if (_contaSelecionada != null) {
          // Atualizar objeto escolhido se ID já estava definido
          _contaEscolhida = _contas.firstWhere(
            (c) => c.id == _contaSelecionada,
            orElse: () => _contas.first,
          );
          _contaController.text = _contaEscolhida!.nome; // ✅ Atualizar controller
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contas: $e')),
        );
      }
    }
  }

  /// 🎯 SETUP NAVEGAÇÃO AUTOMÁTICA (IGUAL CARTÃO)
  void _setupNavigationListeners() {
    // Listeners de navegação automática - REMOVIDO para evitar conflitos
    // O foco agora é controlado apenas pelos onEditingComplete dos campos
  }

  /// 💰 PARSE VALOR MONETÁRIO (IGUAL CARTÃO) 
  double _parseMoneyValue(String value) {
    if (value.isEmpty) return 0.0;
    
    // Remove R$, espaços e pontos de milhar
    String cleanValue = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '');
    
    // Substitui vírgula por ponto para decimal
    cleanValue = cleanValue.replaceAll(',', '.');
    
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// 🎨 OBTER COR DA CATEGORIA SELECIONADA
  Color _getCategoriaCorSelecionada() {
    if (_categoriaSelecionada == null || _categorias.isEmpty) {
      return _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader;
    }
    
    final categoria = _categorias.firstWhere(
      (c) => c.id == _categoriaSelecionada, 
      orElse: () => CategoriaModel(
        id: '', 
        nome: '', 
        ativo: true, 
        tipo: '', 
        usuarioId: '', 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now()
      )
    );
    
    if (categoria.cor != null && categoria.cor!.isNotEmpty) {
      return Color(int.parse(categoria.cor!.replaceAll('#', '0xFF')));
    }
    
    return _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader;
  }

  /// 📅 SELECIONAR DATA (IGUAL CARTÃO)
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (data != null) {
      debugPrint('🔔 Nova data selecionada: ${_formatarDataBr(data)}');
      setState(() {
        _dataSelecionada = data;
        _dataController.text = _formatarDataBr(data);
        // ✅ Usar método centralizado para atualizar status
        _atualizarStatusPorData(data);
      });
      _atualizarPreview();
      
      // Após selecionar a data, ir automaticamente para a categoria
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          debugPrint('🔔 Navegando para categoria após selecionar data...');
          _selecionarCategoria();
        }
      });
    }
  }

  /// 📅 FORMATAR DATA BRASILEIRA
  String _formatarDataBr(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  /// 📅 VERIFICAR SE É A MESMA DATA (ignorando horas)
  bool _isMesmaData(DateTime data1, DateTime data2) {
    return data1.year == data2.year &&
           data1.month == data2.month &&
           data1.day == data2.day;
  }

  /// 🎯 ATUALIZAR STATUS BASEADO NA DATA (Sistema Inteligente)
  void _atualizarStatusPorData(DateTime data) {
    // Só atualiza automaticamente se usuário não alterou manualmente
    if (!_statusManualmenteAlterado) {
      _efetivado = data.isBefore(DateTime.now()) || _isMesmaData(data, DateTime.now());
      debugPrint('📊 Auto-status por data: $_efetivado (data: ${_formatarDataBr(data)})');
    } else {
      debugPrint('🚫 Status não atualizado - usuário alterou manualmente');
    }
  }

  /// 🎨 ATUALIZAR PREVIEW (IGUAL CARTÃO)
  void _atualizarPreview() {
    if (!_temDadosMinimos()) {
      setState(() => _preview = null);
      return;
    }

    final valor = _parseMoneyValue(_valorController.text);
    
    setState(() {
      _preview = {
        'tipo': _tipoSelecionado,
        'descricao': _descricaoController.text.trim(),
        'valor': valor,
        'conta': _contaEscolhida?.nome ?? 'Não selecionada',
        'categoria': _categoriaEscolhida?.nome ?? 'Não selecionada',
        'subcategoria': _subcategoriaEscolhida?.nome,
        'data': _dataSelecionada!,
        'efetivado': _efetivado,
        'observacoes': _observacoesController.text.trim(),
      };
    });
  }

  /// ✅ VERIFICAR DADOS MÍNIMOS (IGUAL CARTÃO)
  bool _temDadosMinimos() {
    return _descricaoController.text.trim().isNotEmpty && 
           _valorController.text.isNotEmpty &&
           _parseMoneyValue(_valorController.text) > 0 &&
           _contaEscolhida != null &&
           _categoriaEscolhida != null;
  }

  /// ✅ PODE HABILITAR BOTÃO SALVAR (IGUAL CARTÃO)
  bool get _podeHabilitar {
    return !_loading &&
          _contaSelecionada != null &&
          _valorController.text.isNotEmpty &&
          _descricaoController.text.trim().isNotEmpty &&
          _parseMoneyValue(_valorController.text) > 0;
  }

  /// 📂 CARREGAR CATEGORIAS
  Future<void> _carregarCategorias() async {
    try {
      final categorias = await _categoriaService.fetchCategorias();
      setState(() {
        _categorias = categorias.where((c) => c.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));

        // Não pré-selecionar categoria - deixar usuário escolher
      });
    } catch (e) {
      // Se não conseguir carregar categorias, deixar null para criar automaticamente
      log('⚠️ Não foi possível carregar categorias: $e');
      setState(() {
        _categorias = [];
        _categoriaSelecionada = null;
      });
    }
  }

  /// 🏷️ CARREGAR SUBCATEGORIAS
  Future<void> _carregarSubcategorias() async {
    try {
      final subcategorias = await _categoriaService.fetchCategorias();
      // As subcategorias vêm misturadas com as categorias no mesmo serviço
      // Filtrar apenas as que tem categoria_id (são subcategorias)
      setState(() {
        _subcategorias = [];  // Será populado quando selecionar categoria
      });
    } catch (e) {
      log('⚠️ Não foi possível carregar subcategorias: $e');
      setState(() {
        _subcategorias = [];
      });
    }
  }

  /// 🔗 CARREGAR SUBCATEGORIAS POR CATEGORIA
  Future<void> _carregarSubcategoriasPorCategoria(String categoriaId) async {
    try {
      log('🔄 Carregando subcategorias para categoria: $categoriaId');
      log('📝 CategoriaId válido: ${categoriaId.isNotEmpty} (length: ${categoriaId.length})');
      
      // Buscar subcategorias específicas da categoria selecionada
      final subcategorias = await _categoriaService.fetchSubcategorias(
        categoriaId: categoriaId
      );
      
      log('✅ Carregadas ${subcategorias.length} subcategorias para categoria $categoriaId');
      
      setState(() {
        _subcategorias = subcategorias.where((s) => s.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));

        // Reset da seleção de subcategoria ao trocar categoria
        _subcategoriaSelecionada = null;
        
        // ✅ NÃO AUTO-SELECIONAR SUBCATEGORIA - DEIXAR USUÁRIO ESCOLHER
        log('📋 ${_subcategorias.length} subcategorias carregadas para categoria $categoriaId');
      });
      
    } catch (e) {
      log('⚠️ Erro ao carregar subcategorias para categoria $categoriaId: $e');
      setState(() {
        _subcategorias = [];
        _subcategoriaSelecionada = null;
      });
    }
  }

  /// 💰 FORMATAR VALOR PARA INPUT
  String _formatarValorParaInput(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// 💰 CONVERTER INPUT PARA DOUBLE
  double _converterInputParaDouble(String input) {
    if (input.isEmpty) return 0.0;
    
    String cleaned = input.replaceAll(RegExp(r'[^0-9,.]'), '');
    cleaned = cleaned.replaceAll(',', '.');
    
    return double.tryParse(cleaned) ?? 0.0;
  }


  /// 🏦 SELECIONAR CONTA (IGUAL CARTÃO - SCROLLÁVEL)
  Future<void> _selecionarConta() async {
    if (_contas.isEmpty) return;
    
    final conta = await showModalBottomSheet<ContaModel>(
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
            // Handle do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecionar Conta',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Lista scrollável de contas (ordenada: principal primeiro)
            Expanded(
              child: ListView.builder(
                itemCount: _contas.length,
                itemBuilder: (context, index) {
                  // Ordenar contas: principal primeiro, depois por nome
                  final contasOrdenadas = [..._contas];
                  contasOrdenadas.sort((a, b) {
                    if (a.contaPrincipal && !b.contaPrincipal) return -1;
                    if (!a.contaPrincipal && b.contaPrincipal) return 1;
                    return a.nome.compareTo(b.nome);
                  });

                  final conta = contasOrdenadas[index];
                  final isSelected = _contaSelecionada == conta.id;
                  
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
                          color: conta.cor != null && conta.cor!.isNotEmpty
                              ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: conta.icone != null && conta.icone!.isNotEmpty
                              ? _getIconeByName(conta.icone!, size: 20, color: Colors.white)
                              : const Icon(Icons.account_balance, color: Colors.white, size: 20),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            conta.nome,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (conta.contaPrincipal) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber, width: 1),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        'Saldo: R\$ ${conta.saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected 
                          ? Icon(
                              Icons.check_circle,
                              color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, conta),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (conta != null) {
      setState(() {
        _contaSelecionada = conta.id;
        _contaEscolhida = conta; // ✅ ADICIONAR ESTA LINHA
        _contaController.text = conta.nome; // Atualizar controller
      });
      _atualizarPreview(); // Atualizar preview
      
      // ✅ SCROLL FINAL após selecionar conta + remover foco
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Primeiro remover qualquer foco ativo
          FocusScope.of(context).unfocus();
          debugPrint('🔔 Foco removido após selecionar conta');
          
          // Aguardar um pouco e fazer scroll
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _scrollController.hasClients) {
              debugPrint('🔔 Fazendo scroll final para mostrar preview...');
              debugPrint('🔔 ScrollController hasClients: ${_scrollController.hasClients}');
              debugPrint('🔔 ScrollController position: ${_scrollController.position.pixels}');
              debugPrint('🔔 ScrollController maxScrollExtent: ${_scrollController.position.maxScrollExtent}');
              
              // Scroll para o final para mostrar preview e botões - AJUSTE FINAL
              final targetPosition = _scrollController.position.maxScrollExtent * 0.90; // ✅ AJUSTE PERFEITO
              _scrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 1000), // Mais tempo
                curve: Curves.easeInOut,
              ).then((_) {
                debugPrint('🔔 Scroll final concluído para posição: $targetPosition');
              }).catchError((error) {
                debugPrint('🚨 Erro no scroll: $error');
              });
            } else {
              debugPrint('🚨 ScrollController não disponível!');
            }
          });
        }
      });
    }
  }

  /// 📂 SELECIONAR CATEGORIA (IGUAL CARTÃO - SCROLLÁVEL) 
  Future<void> _selecionarCategoria() async {
    if (_categorias.isEmpty) return;
    
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
            // Handle do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecionar Categoria',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Lista scrollável de categorias
            Expanded(
              child: ListView.builder(
                itemCount: _categorias.where((c) => c.tipo == _tipoSelecionado).length,
                itemBuilder: (context, index) {
                  final categoriasFiltradas = _categorias.where((c) => c.tipo == _tipoSelecionado).toList()
                    ..sort((a, b) => a.nome.compareTo(b.nome));
                  final categoria = categoriasFiltradas[index];
                  
                  final isSelected = _categoriaSelecionada == categoria.id;
                  
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
                              : (_tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader),
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
    
    if (categoria != null) {
      setState(() {
        _categoriaSelecionada = categoria.id;
        _categoriaEscolhida = categoria; // ✅ ADICIONAR ESTA LINHA
        _categoriaController.text = categoria.nome;
        _subcategoriaSelecionada = null; // Reset subcategoria
        _subcategoriaEscolhida = null; // ✅ RESET SUBCATEGORIA ESCOLHIDA TAMBÉM
        _subcategoriaController.text = '';
      });
      _atualizarPreview();
      
      // ✅ AGUARDAR CARREGAMENTO DAS SUBCATEGORIAS ANTES DE DECIDIR O PRÓXIMO PASSO
      await _carregarSubcategoriasPorCategoria(categoria.id);
      
      // ✅ AGUARDAR UM POUCO PARA GARANTIR QUE O setState FOI PROCESSADO
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Após carregar subcategorias, ir automaticamente para subcategoria OU conta
      if (mounted) {
        debugPrint('🔔 Verificando subcategorias... (${_subcategorias.length} encontradas)');
        if (_subcategorias.isNotEmpty) {
          debugPrint('🔔 Categoria selecionada, navegando para subcategoria... (${_subcategorias.length} encontradas)');
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _selecionarSubcategoria();
            }
          });
        } else {
          debugPrint('🔔 Sem subcategorias, navegando direto para conta...');
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _selecionarConta();
            }
          });
        }
      }
    }
  }

  /// 🏷️ SELECIONAR SUBCATEGORIA (IGUAL CARTÃO - SCROLLÁVEL)
  Future<void> _selecionarSubcategoria() async {
    // Se não tem categoria selecionada, não faz nada
    if (_categoriaSelecionada == null) return;
    
    // Se não tem subcategorias carregadas, tenta carregar
    if (_subcategorias.isEmpty) {
      debugPrint('🔔 Tentando carregar subcategorias para categoria: $_categoriaSelecionada');
      await _carregarSubcategoriasPorCategoria(_categoriaSelecionada!);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Se ainda não tem subcategorias, mostra mensagem e vai para conta
    if (_subcategorias.isEmpty) {
      debugPrint('🔔 Nenhuma subcategoria encontrada, indo para conta...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma subcategoria disponível para esta categoria'),
          duration: Duration(seconds: 2),
        ),
      );
      // Vai direto para seleção de conta
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _selecionarConta();
        }
      });
      return;
    }
    
    final subcategoria = await showModalBottomSheet<SubcategoriaModel>(
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
            // Handle do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecionar Subcategoria',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Lista scrollável de subcategorias
            Expanded(
              child: ListView.builder(
                itemCount: _subcategorias.length,
                itemBuilder: (context, index) {
                  final subcategoria = _subcategorias[index];
                  final isSelected = _subcategoriaSelecionada == subcategoria.id;
                  
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
                              : (_tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader),
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
        _subcategoriaSelecionada = subcategoria.id;
        // Converter SubcategoriaModel para CategoriaModel para compatibilidade
        _subcategoriaEscolhida = CategoriaModel(
          id: subcategoria.id,
          usuarioId: subcategoria.usuarioId,
          nome: subcategoria.nome,
          icone: _categoriaEscolhida?.icone ?? 'category',
          cor: _categoriaEscolhida?.cor ?? '#999999',
          ativo: subcategoria.ativo,
          tipo: _categoriaEscolhida?.tipo ?? 'ambos',
          createdAt: subcategoria.createdAt,
          updatedAt: subcategoria.updatedAt,
        );
        _subcategoriaController.text = subcategoria.nome;
      });
      _atualizarPreview();
      
      // Após selecionar subcategoria, verificar fluxo automático apenas
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // ✅ APENAS NO FLUXO AUTOMÁTICO: se tem conta favorita, pular para observações
          if (_contaSelecionada != null && _contaEscolhida != null) {
            debugPrint('🔔 Subcategoria selecionada, conta favorita já existe (${_contaEscolhida!.nome}), indo para observações...');
            _observacoesFocusNode.requestFocus();
          } else {
            debugPrint('🔔 Subcategoria selecionada, navegando para conta...');
            _selecionarConta();
          }
        }
      });
    }
  }


  /// 💾 SALVAR TRANSAÇÃO
  Future<void> _salvarTransacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final descricao = _descricaoController.text.trim();
      final valor = _converterInputParaDouble(_valorController.text);
      final observacoes = _observacoesController.text.trim();
      // Usar os novos campos em vez do antigo sistema
      // final numParcelas = _temParcelas ? int.tryParse(_parcelasController.text) : null;

      if (widget.modo == 'criar') {
        List<TransacaoModel> transacoesCriadas = [];

        // ✅ GARANTIR QUE CATEGORIA EXISTE
        String categoriaId = _categoriaSelecionada ?? '';
        
        if (categoriaId.isEmpty) {
          // Criar categoria padrão se não existir nenhuma selecionada
          categoriaId = await _transacaoService.criarCategoriaSeNecessario(
            _tipoSelecionado == 'receita' ? 'Receita Geral' : 'Despesa Geral', 
            _tipoSelecionado
          );
        }
        
        // ✅ VALIDAR SUBCATEGORIA SE SELECIONADA
        String? subcategoriaId = _subcategoriaSelecionada;
        if (subcategoriaId != null && subcategoriaId.isNotEmpty) {
          final subcategoriaValida = _subcategorias.any((s) => 
            s.id == subcategoriaId && s.categoriaId == categoriaId
          );
          
          if (!subcategoriaValida) {
            log('⚠️ Subcategoria inválida para categoria $categoriaId, removendo seleção');
            subcategoriaId = null; // Remove subcategoria inválida
          } else {
            log('✅ Subcategoria $subcategoriaId validada para categoria $categoriaId');
          }
        }

        if (_tipoSelecionado == 'receita') {
          // ✅ USAR MÉTODO COMPLETO DE RECEITA COM TODOS OS CAMPOS
          transacoesCriadas = await _transacaoService.criarReceita(
            descricao: descricao,
            valor: valor,
            data: _dataSelecionada!,
            contaId: _contaSelecionada!,
            categoriaId: categoriaId,
            subcategoriaId: subcategoriaId,
            tipoReceita: _tipoTransacao,
            efetivado: _efetivado, // ✅ CORRIGIDO: Usar valor do toggle automático
            observacoes: observacoes.isEmpty ? null : observacoes,
            numeroParcelas: _tipoTransacao == 'parcelada' ? _numeroParcelas : null,
            frequenciaParcelada: _tipoTransacao == 'parcelada' ? _frequenciaParcelada : null,
            frequenciaPrevisivel: _tipoTransacao == 'previsivel' ? _frequenciaPrevisivel : null,
            numeroRepeticoes: _tipoTransacao == 'previsivel' ? _totalRecorrencias : null, // ✅ NOVO PARÂMETRO
          );
        } else {
          // ✅ USAR MÉTODO COMPLETO DE DESPESA COM TODOS OS CAMPOS
          transacoesCriadas = await _transacaoService.criarDespesa(
            descricao: descricao,
            valor: valor,
            data: _dataSelecionada!,
            contaId: _contaSelecionada!,
            categoriaId: categoriaId,
            subcategoriaId: subcategoriaId,
            tipoDespesa: _tipoTransacao,
            efetivado: _efetivado, // ✅ CORRIGIDO: Usar valor do toggle automático
            observacoes: observacoes.isEmpty ? null : observacoes,
            numeroParcelas: _tipoTransacao == 'parcelada' ? _numeroParcelas : null,
            frequenciaParcelada: _tipoTransacao == 'parcelada' ? _frequenciaParcelada : null,
            frequenciaPrevisivel: _tipoTransacao == 'previsivel' ? _frequenciaPrevisivel : null,
            numeroRepeticoes: _tipoTransacao == 'previsivel' ? _totalRecorrencias : null, // ✅ NOVO PARÂMETRO
          );
        }

        final quantidadeTexto = transacoesCriadas.length > 1 
            ? '${transacoesCriadas.length} transações de'
            : '';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$quantidadeTexto ${_formatarTipoTransacao(_tipoSelecionado).toLowerCase()} "$descricao" criada!')),
          );
        }
      } else {
        // ✅ MODO EDIÇÃO - Usar update completo com todos os campos
        String categoriaId = _categoriaSelecionada ?? '';
        
        if (categoriaId.isEmpty) {
          // Criar categoria padrão se não existir nenhuma selecionada
          categoriaId = await _transacaoService.criarCategoriaSeNecessario(
            _tipoSelecionado == 'receita' ? 'Receita Geral' : 'Despesa Geral', 
            _tipoSelecionado
          );
        }
        
        // ✅ VALIDAR SUBCATEGORIA SE SELECIONADA
        String? subcategoriaId = _subcategoriaSelecionada;
        if (subcategoriaId != null && subcategoriaId.isNotEmpty) {
          final subcategoriaValida = _subcategorias.any((s) => 
            s.id == subcategoriaId && s.categoriaId == categoriaId
          );
          
          if (!subcategoriaValida) {
            log('⚠️ Subcategoria inválida para categoria $categoriaId, removendo seleção');
            subcategoriaId = null; // Remove subcategoria inválida
          }
        }

        await _transacaoService.updateTransacao(
          transacaoId: widget.transacao!.id,
          descricao: descricao,
          valor: valor,
          data: _dataSelecionada,
          contaId: _contaSelecionada,
          efetivado: _efetivado,
          observacoes: observacoes.isEmpty ? null : observacoes,
          categoriaId: categoriaId,
          subcategoriaId: subcategoriaId,
          cartaoId: _cartaoSelecionado,
          contaDestinoId: _contaDestinoSelecionada,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_formatarTipoTransacao(_tipoSelecionado)} "$descricao" atualizada!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar transação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 🎨 WIDGET SELETOR DE TIPO
  Widget _buildSeletorTipo() {
    // ✅ OCULTAR quando vem de botões segregados (igual cartão)
    if (widget.modo == 'criar' && widget.tipo != null) {
      return const SizedBox.shrink(); // Oculto quando tipo pré-definido
    }
    
    if (widget.modo == 'editar') {
      // No modo edição, mostrar apenas como informação
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_getIconePorTipo(_tipoSelecionado), color: _getCorPorTipo(_tipoSelecionado)),
            const SizedBox(width: 12),
            Text(
              _formatarTipoTransacao(_tipoSelecionado),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo da Transação',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOpcaoTipo('receita', 'Receita', Icons.add_circle, AppColors.tealPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOpcaoTipo('despesa', 'Despesa', Icons.remove_circle, AppColors.vermelhoHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpcaoTipo(String tipo, String label, IconData icone, Color cor) {
    final selecionado = _tipoSelecionado == tipo;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoSelecionado = tipo;
          // Atualizar categoria baseada no tipo selecionado
          final categoriasPorTipo = _categorias.where((c) => c.tipo == tipo).toList()
            ..sort((a, b) => a.nome.compareTo(b.nome));
          if (categoriasPorTipo.isNotEmpty) {
            _categoriaSelecionada = categoriasPorTipo.first.id;
            _carregarSubcategoriasPorCategoria(categoriasPorTipo.first.id);
          } else {
            _categoriaSelecionada = null;
            _subcategoriaSelecionada = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado ? cor.withAlpha(26) : Colors.grey[100],
          border: Border.all(
            color: selecionado ? cor : Colors.grey[300]!,
            width: selecionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: selecionado ? cor : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selecionado ? cor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 HELPER FUNCTIONS
  IconData _getIconePorTipo(String tipo) {
    switch (tipo) {
      case 'receita':
        return Icons.add_circle;
      case 'despesa':
        return Icons.remove_circle;
      default:
        return Icons.help_outline;
    }
  }

  Color _getCorPorTipo(String tipo) {
    switch (tipo) {
      case 'receita':
        return AppColors.tealPrimary;
      case 'despesa':
        return AppColors.vermelhoHeader;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatarTipoTransacao(String tipo) {
    switch (tipo) {
      case 'receita':
        return 'Receita';
      case 'despesa':
        return 'Despesa';
      default:
        return tipo;
    }
  }

  Widget _getIconeByName(String icone, {required double size, Color? color}) {
    // Importar o sistema correto de ícones
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

  /// 🎨 BUILD PREVIEW AUTOMÁTICO (IGUAL CARTÃO)
  Widget _buildPreview() {
    if (_preview == null || !_temDadosMinimos()) {
      return const SizedBox.shrink();
    }

    final cor = _getCorPorTipo(_preview!['tipo']);
    final icone = _getIconePorTipo(_preview!['tipo']);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withAlpha(25), // ~10% opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withAlpha(77)), // ~30% opacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: cor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview da ${_formatarTipoTransacao(_preview!['tipo'])}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Descrição e Valor
          Row(
            children: [
              Expanded(
                child: Text(
                  _preview!['descricao'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'R\$ ${(_preview!['valor'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Conta (com ícone do banco) e Categoria (com ícone)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Ícone + cor da conta
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _contaEscolhida?.cor != null && _contaEscolhida!.cor!.isNotEmpty
                                ? Color(int.parse(_contaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: _contaEscolhida?.icone != null && _contaEscolhida!.icone!.isNotEmpty
                                ? _getIconeByName(_contaEscolhida!.icone!, size: 14, color: Colors.white)
                                : const Icon(Icons.account_balance, color: Colors.white, size: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _preview!['conta'],
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Ícone + cor da categoria
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _categoriaEscolhida?.cor != null && _categoriaEscolhida!.cor!.isNotEmpty
                                ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                : (_tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: _categoriaEscolhida?.icone != null && _categoriaEscolhida!.icone.isNotEmpty
                                ? _getIconeByName(_categoriaEscolhida!.icone, size: 12, color: Colors.white)
                                : const Icon(Icons.category, color: Colors.white, size: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _preview!['categoria'],
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    // Subcategoria separada
                    if (_preview!['subcategoria'] != null) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          '↳ ${_preview!['subcategoria']}',
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '📅 ${_formatarData(_preview!['data'])}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    _preview!['efetivado'] ? '✅ Efetivada' : '⏳ Pendente',
                    style: TextStyle(
                      fontSize: 13,
                      color: _preview!['efetivado'] ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Detalhes específicos por tipo de transação
          if (_tipoTransacao == 'parcelada') ...[
            const SizedBox(height: 8),
            _buildDetalhesParcelamento(),
          ] else if (_tipoTransacao == 'previsivel') ...[
            const SizedBox(height: 8),
            _buildDetalhesRecorrencia(),
          ],
          
          if (_preview!['observacoes']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              '📝 ${_preview!['observacoes']}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// 📅 FORMATAR DATA
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  /// 🔢 CAMPOS CONDICIONAIS - CADA TIPO TEM SEUS PRÓPRIOS CAMPOS
  List<Widget> _buildCamposCondicionais() {
    if (_tipoTransacao == 'parcelada') {
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SmartField(
                key: ValueKey('parcelas_${_tipoTransacao}_$_rebuildKey'), // ✅ KEY ÚNICA
                controller: _parcelasController,
                focusNode: _parcelasFocusNode,
                label: 'Parcelas',
                hint: '2',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                isCartaoContext: false,
                transactionContext: _tipoSelecionado,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  // ✅ ATUALIZAR VARIÁVEL ESPECÍFICA PARA PARCELAS
                  _numeroParcelas = int.tryParse(value) ?? 2;
                  _atualizarPreview();
                },
                onEditingComplete: () {
                  debugPrint('🔔 Parcelas completas, navegando para categoria...');
                  FocusScope.of(context).unfocus();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      _selecionarCategoria();
                    }
                  });
                },
                validator: (value) {
                  if (_tipoTransacao == 'parcelada') {
                    if (value == null || value.trim().isEmpty) {
                      return 'Número de parcelas é obrigatório';
                    }
                    final parcelas = int.tryParse(value);
                    if (parcelas == null || parcelas <= 0) {
                      return 'Número inválido de parcelas';
                    }
                    if (parcelas > 48) {
                      return 'Máximo 48 parcelas';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Setinhas para ajustar parcelas (igual cartão)
            Column(
              children: [
                GestureDetector(
                  onTap: () => _ajustarParcelas(1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
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
                      color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
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
    } else if (_tipoTransacao == 'previsivel') {
      // 🔄 CAMPOS PARA TRANSAÇÃO RECORRENTE
      return [
        const SizedBox(height: 16),
        // Linha 1: Frequência
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SmartField(
                key: ValueKey('frequencia_${_tipoTransacao}_$_rebuildKey'), // ✅ KEY ÚNICA
                controller: _frequenciaController,
                label: 'Frequência',
                hint: 'Escolha a frequência',
                icon: Icons.schedule,
                readOnly: true,
                isCartaoContext: false,
                transactionContext: _tipoSelecionado,
                onTap: _selecionarFrequencia,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: SmartField(
                key: ValueKey('repeticoes_${_tipoTransacao}_$_rebuildKey'), // ✅ KEY ÚNICA
                controller: _repeticoesController,
                focusNode: _repeticoesFocusNode,
                label: 'Repetições',
                hint: 'Máx ${_getMaxRepeticoes()}',
                icon: Icons.repeat,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                isCartaoContext: false,
                transactionContext: _tipoSelecionado,
                textInputAction: TextInputAction.next,
                onEditingComplete: () {
                  debugPrint('🔔 Repetições preenchidas, navegando para categoria...');
                  FocusScope.of(context).unfocus(); 
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      debugPrint('🔔 Abrindo modal de categoria após repetições...');
                      _selecionarCategoria();
                    }
                  });
                },
                onChanged: (value) {
                  // ✅ ATUALIZAR VARIÁVEL ESPECÍFICA PARA RECORRÊNCIA
                  if (_tipoTransacao == 'previsivel') {
                    final maxRepeticoes = _getMaxRepeticoes();
                    _totalRecorrencias = int.tryParse(value) ?? 12;
                    if (_totalRecorrencias > maxRepeticoes) {
                      _totalRecorrencias = maxRepeticoes;
                      _repeticoesController.text = maxRepeticoes.toString();
                    }
                  }
                  _atualizarPreview();
                },
                validator: (value) {
                  if (_tipoTransacao == 'previsivel') {
                    final repeticoes = int.tryParse(value ?? '');
                    final maxRepeticoes = _getMaxRepeticoes();
                    if (repeticoes == null || repeticoes <= 0) {
                      return 'Inválido';
                    }
                    if (repeticoes > maxRepeticoes) {
                      return 'Máx $maxRepeticoes';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Setinhas para ajustar repetições (igual parcelas)
            Column(
              children: [
                GestureDetector(
                  onTap: () => _ajustarRepeticoes(1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
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
                      color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
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
    return [];
  }

  /// 📅 SELECIONAR FREQUÊNCIA PARA RECORRENTE
  Future<void> _selecionarFrequencia() async {
    final frequencia = await showModalBottomSheet<String>(
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
            // Handle do modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecionar Frequência',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Lista de frequências
            Expanded(
              child: ListView.builder(
                itemCount: _opcoesFrequencia.length,
                itemBuilder: (context, index) {
                  final opcao = _opcoesFrequencia[index];
                  final isSelected = _frequenciaPrevisivel == opcao['value'];
                  
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
                          color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.schedule, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        opcao['label']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(opcao['descricao']!),
                      onTap: () => Navigator.pop(context, opcao['value']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (frequencia != null) {
      setState(() {
        _frequenciaPrevisivel = frequencia;
        
        // Atualizar controller de frequência
        _frequenciaController.text = _opcoesFrequencia.firstWhere((f) => f['value'] == frequencia)['label']!;
        
        // ✅ SEMPRE USAR MÁXIMO DA NOVA FREQUÊNCIA
        final maxRepeticoes = _getMaxRepeticoes();
        _totalRecorrencias = maxRepeticoes;
        _repeticoesController.text = maxRepeticoes.toString();
        
        debugPrint('🔔 Frequência atualizada: $_frequenciaPrevisivel, Repetições: $_totalRecorrencias');
      });
      _atualizarPreview();
      
      // Navegar direto para categoria após selecionar frequência
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          debugPrint('🔔 Frequência selecionada, navegando direto para categoria...');
          _selecionarCategoria();
        }
      });
    }
  }

  /// 🔢 AJUSTAR PARCELAS (IGUAL CARTÃO)
  void _ajustarParcelas(int delta) {
    final currentValue = int.tryParse(_parcelasController.text) ?? 2;
    final newValue = (currentValue + delta).clamp(1, 60); // Entre 1 e 60 parcelas
    _parcelasController.text = newValue.toString();
    _atualizarPreview();
  }

  /// 🔢 AJUSTAR REPETIÇÕES (RECORRENTE)
  void _ajustarRepeticoes(int delta) {
    final currentValue = int.tryParse(_repeticoesController.text) ?? 12;
    final maxRepeticoes = _getMaxRepeticoes();
    final newValue = (currentValue + delta).clamp(1, maxRepeticoes);
    _totalRecorrencias = newValue;
    _repeticoesController.text = newValue.toString();
    _atualizarPreview();
  }

  /// 💳 DETALHES DO PARCELAMENTO
  Widget _buildDetalhesParcelamento() {
    final valor = _parseMoneyValue(_valorController.text);
    final parcelas = int.tryParse(_parcelasController.text) ?? 2;
    final valorParcela = valor / parcelas;
    
    // Calcular datas das parcelas
    final dataInicio = _dataSelecionada ?? DateTime.now();
    final dataFim = DateTime(dataInicio.year, dataInicio.month + parcelas - 1, dataInicio.day);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 ${parcelas}x de R\$ ${valorParcela.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          '📅 ${_formatarData(dataInicio)} até ${_formatarData(dataFim)}',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  /// 🔄 DETALHES DA RECORRÊNCIA
  Widget _buildDetalhesRecorrencia() {
    final valor = _parseMoneyValue(_valorController.text);
    
    // Usar frequência e repetições selecionadas
    final frequenciaLabel = _opcoesFrequencia.firstWhere((f) => f['value'] == _frequenciaPrevisivel)['label'];
    final vezes = _totalRecorrencias;
    final valorTotal = valor * vezes;
    
    // Calcular período baseado na frequência
    final dataInicio = _dataSelecionada ?? DateTime.now();
    DateTime dataFim;
    
    switch (_frequenciaPrevisivel) {
      case 'semanal':
        dataFim = dataInicio.add(Duration(days: 7 * vezes));
        break;
      case 'quinzenal':
        dataFim = dataInicio.add(Duration(days: 15 * vezes));
        break;
      case 'bimestral':
        dataFim = DateTime(dataInicio.year, dataInicio.month + (2 * vezes), dataInicio.day);
        break;
      case 'trimestral':
        dataFim = DateTime(dataInicio.year, dataInicio.month + (3 * vezes), dataInicio.day);
        break;
      case 'semestral':
        dataFim = DateTime(dataInicio.year, dataInicio.month + (6 * vezes), dataInicio.day);
        break;
      case 'anual':
        dataFim = DateTime(dataInicio.year + vezes, dataInicio.month, dataInicio.day);
        break;
      case 'mensal':
      default:
        dataFim = DateTime(dataInicio.year, dataInicio.month + vezes, dataInicio.day);
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            '🔄 Recorrente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$vezes pagamentos ${frequenciaLabel?.toLowerCase()}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            'Total: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            '${_formatarData(dataInicio)} até ${_formatarData(dataFim)}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      );
  }


  @override
  Widget build(BuildContext context) {
    final titulo = widget.modo == 'criar' 
        ? 'Nova ${_formatarTipoTransacao(_tipoSelecionado)}'
        : 'Editar ${_formatarTipoTransacao(_tipoSelecionado)}';

    return IPoupeiProcessingOverlay(
      isProcessing: _loading,
      message: widget.modo == 'criar' ? 'Criando transação...' : 'Salvando alterações...',
      context: _tipoSelecionado == 'receita' ? IPoupeiLoadingContext.saving : IPoupeiLoadingContext.processing,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true, // ✅ CENTRALIZADO igual cartão
          actions: [
            TextButton(
              onPressed: _podeHabilitar ? _salvarTransacao : null,
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
              // Seletor de tipo (apenas na criação - receita/despesa)
              _buildSeletorTipo(),
              
              // Seletor de tipo de transação com TipoSelector (3 cards logo abaixo do AppBar)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TipoSelectorExtensions.tipoTransacao(
                  tipoSelecionado: _tipoTransacao,
                  onChanged: (tipo) {
                    setState(() {
                      _tipoTransacao = tipo;
                      _temParcelas = _tipoTransacao == 'parcelada'; // Compatibilidade
                      
                      // Limpar seleções de categoria ao trocar tipo
                      _categoriaSelecionada = null;
                      _categoriaEscolhida = null;
                      _subcategoriaSelecionada = null;
                      _subcategoriaEscolhida = null;
                      _categoriaController.clear();
                      _subcategoriaController.clear();
                      
                      // ✅ SEMPRE PRÉ-PREENCHER CAMPOS PARA GARANTIR NAVEGAÇÃO
                      if (tipo == 'parcelada') {
                        // ✅ SEMPRE PREENCHER CAMPO DE PARCELAMENTO
                        _parcelasController.text = '2';
                        _numeroParcelas = 2;
                        
                        // Limpar campos de recorrência (não serão mostrados)
                        _frequenciaController.clear();
                        _repeticoesController.clear();
                        _frequenciaPrevisivel = 'mensal';
                        _totalRecorrencias = 12;
                        
                        debugPrint('🔄 PARCELADA: Campo preenchido com "${_parcelasController.text}" parcelas');
                        
                      } else if (tipo == 'previsivel') {
                        // ✅ SEMPRE PREENCHER CAMPOS DE RECORRÊNCIA
                        _frequenciaPrevisivel = 'mensal';
                        _frequenciaController.text = 'Mensal';
                        _totalRecorrencias = 12;
                        _repeticoesController.text = '12';
                        
                        // Limpar campos de parcelamento (não serão mostrados)
                        _parcelasController.clear();
                        _numeroParcelas = 2;
                        
                        debugPrint('🔄 RECORRENTE: Frequência="${_frequenciaController.text}", Repetições="${_repeticoesController.text}"');
                        
                      } else {
                        // ✅ TIPO EXTRA - LIMPAR CAMPOS CONDICIONAIS
                        _parcelasController.clear();
                        _frequenciaController.clear();
                        _repeticoesController.clear();
                        
                        // Resetar variáveis
                        _numeroParcelas = 2;
                        _frequenciaPrevisivel = 'mensal';
                        _totalRecorrencias = 12;
                        
                        debugPrint('🔄 EXTRA: Todos os campos limpos');
                      }
                      
                      // ✅ INCREMENTAR KEY PARA FORÇAR REBUILD DOS SMARTFIELDS
                      _rebuildKey++;
                    });
                    
                    // ✅ FORÇAR REBUILD DOS SMARTFIELDS APÓS MUDANÇA
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) {
                        setState(() {
                          debugPrint('🔄 Rebuild key incrementada para: $_rebuildKey');
                        });
                      }
                    });
                    
                    _atualizarPreview(); // Atualizar preview quando trocar tipo
                  },
                  tipoReceita: _tipoSelecionado,
                ),
              ),

              // Form Fields (dentro do scroll igual cartão)
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
                        autofocus: true, // ✅ FOCO AUTOMÁTICO NA ABERTURA
                        label: 'Descrição',
                        hint: _tipoSelecionado == 'receita' 
                            ? 'Ex: Salário, Freelance, Venda...'
                            : 'Ex: Supermercado, Gasolina, Farmácia...',
                        icon: Icons.description, // ✅ ÍCONE CORRETO
                        isCartaoContext: false, // ✅ CONTEXT TRANSAÇÃO
                        transactionContext: _tipoSelecionado,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () {
                          debugPrint('🔔 onEditingComplete chamado para descrição');
                          FocusScope.of(context).unfocus(); // Remove foco atual
                          _valorFocusNode.requestFocus();
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
                        label: 'Valor', // ✅ DINÂMICO
                        hint: 'R\$ 0,00',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MoneyInputFormatter()],
                        isCartaoContext: false,
                        transactionContext: _tipoSelecionado,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          debugPrint('🔔 onEditingComplete chamado para valor');
                          final valorParsed = _parseMoneyValue(_valorController.text);
                          debugPrint('🔔 Valor parseado: $valorParsed');
                          if (valorParsed > 0) {
                            if (_tipoTransacao == 'parcelada') {
                              debugPrint('🔔 Valor válido, navegando para parcelas...');
                              FocusScope.of(context).unfocus();
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  _parcelasFocusNode.requestFocus();
                                }
                              });
                            } else if (_tipoTransacao == 'previsivel') {
                              debugPrint('🔔 Valor válido, navegando para frequência...');
                              FocusScope.of(context).unfocus(); 
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  debugPrint('🔔 Abrindo modal de frequência...');
                                  _selecionarFrequencia();
                                }
                              });
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
                      const SizedBox(height: 16),

                      // Toggle Pago/Recebido
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _efetivado 
                              ? (_tipoSelecionado == 'receita' ? AppColors.tealPrimary.withAlpha(26) : AppColors.vermelhoHeader.withAlpha(26))
                              : Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _efetivado 
                                ? (_tipoSelecionado == 'receita' ? AppColors.tealPrimary.withAlpha(78) : AppColors.vermelhoHeader.withAlpha(78))
                                : Colors.grey.withAlpha(78),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _efetivado ? Icons.check_circle : Icons.schedule,
                              color: _efetivado 
                                  ? (_tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _efetivado 
                                        ? (_tipoSelecionado == 'receita' ? 'Já recebido' : 'Já pago')
                                        : (_tipoSelecionado == 'receita' ? 'A receber' : 'A pagar'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _efetivado 
                                          ? (_tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _efetivado 
                                        ? 'O valor foi efetivado na conta'
                                        : 'O valor ainda não foi efetivado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _efetivado,
                              onChanged: (value) {
                                setState(() {
                                  _efetivado = value;
                                  // ✅ Marcar que usuário alterou manualmente
                                  _statusManualmenteAlterado = true;
                                });
                                debugPrint('🎯 Status alterado manualmente: $value');
                                _atualizarPreview();
                              },
                              activeColor: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
                              inactiveThumbColor: Colors.grey[400],
                              inactiveTrackColor: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campos condicionais baseados no tipo de transação
                      ..._buildCamposCondicionais(),

                      // Data da transação
                      SmartField(
                        controller: _dataController,
                        focusNode: _dataFocusNode,
                        label: 'Data da transação',
                        hint: 'DD/MM/AAAA',
                        icon: Icons.calendar_today, // ✅ SEM OUTLINE
                        readOnly: true,
                        onTap: _selecionarData,
                        isCartaoContext: false,
                        transactionContext: _tipoSelecionado,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Data é obrigatória';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Categoria e Subcategoria (lado a lado igual ao cartão)
                      Row(
                        children: [
                          Expanded(
                            child: SmartField(
                              controller: _categoriaController,
                              focusNode: _categoriaFocusNode,
                              label: 'Categoria',
                              hint: 'Ex: Alimentação',
                              icon: Icons.local_offer_outlined,
                              leadingIcon: _categoriaEscolhida != null
                                  ? _buildSmallColoredIcon(
                                      icone: _categoriaEscolhida!.icone,
                                      cor: _categoriaEscolhida!.cor != null && _categoriaEscolhida!.cor!.isNotEmpty
                                          ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                          : null,
                                      fallbackColor: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
                                    )
                                  : null,
                              readOnly: true,
                              onTap: _selecionarCategoria,
                              isCartaoContext: false,
                              transactionContext: _tipoSelecionado,
                              showDot: false, // Nunca mostrar dot pois sempre usamos leadingIcon quando selecionado
                              dotColor: _categoriaSelecionada != null && _categorias.isNotEmpty
                                  ? _getCategoriaCorSelecionada()
                                  : (_tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader),
                              validator: (value) {
                                // Categoria é opcional - será criada automaticamente
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
                              icon: Icons.bookmark_outline,
                              leadingIcon: _subcategoriaEscolhida != null
                                  ? _buildSmallColoredIcon(
                                      icone: _categoriaEscolhida!.icone, // Subcategoria usa ícone da categoria pai
                                      cor: _categoriaEscolhida!.cor != null && _categoriaEscolhida!.cor!.isNotEmpty
                                          ? Color(int.parse(_categoriaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                          : null,
                                      fallbackColor: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
                                      size: 16, // Um pouco menor para subcategoria
                                    )
                                  : null,
                              readOnly: true,
                              onTap: _categoriaSelecionada != null ? _selecionarSubcategoria : null,
                              isCartaoContext: false,
                              transactionContext: _tipoSelecionado,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Conta (igual ao cartão no formulário)
                      SmartField(
                        controller: _contaController,
                        label: 'Conta',
                        hint: 'Selecionar conta',
                        icon: _contaSelecionada != null && _contaEscolhida != null
                            ? null // Remove ícone padrão quando preenchido
                            : Icons.account_balance,
                        leadingIcon: _contaSelecionada != null && _contaEscolhida != null
                            ? _buildSmallColoredIcon(
                                icone: _contaEscolhida!.icone,
                                cor: _contaEscolhida!.cor != null && _contaEscolhida!.cor!.isNotEmpty
                                    ? Color(int.parse(_contaEscolhida!.cor!.replaceAll('#', '0xFF')))
                                    : null,
                                fallbackColor: Colors.blue,
                              )
                            : null,
                        readOnly: true,
                        onTap: _selecionarConta,
                        isCartaoContext: false,
                        transactionContext: _tipoSelecionado,
                        showDot: _contaSelecionada != null && _contaEscolhida == null, // Só mostra dot se não tem ícone colorido
                        dotColor: _contaEscolhida?.cor != null && _contaEscolhida!.cor!.isNotEmpty
                            ? Color(int.parse(_contaEscolhida!.cor!.replaceAll('#', '0xFF')))
                            : Colors.blue,
                        validator: (value) {
                          if (_contaSelecionada == null) {
                            return 'Conta é obrigatória';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Observações
                      SmartField(
                        controller: _observacoesController,
                        focusNode: _observacoesFocusNode,
                        label: 'Observações (opcional)',
                        hint: 'Informações adicionais...',
                        icon: Icons.note,
                        maxLines: 3,
                        isCartaoContext: false,
                        transactionContext: _tipoSelecionado, // ✅ Seguir cor do tipo
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () {
                          debugPrint('🔔 Observações completas, indo para botão salvar...');
                          _salvarButtonFocusNode.requestFocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      // 🎨 PREVIEW AUTOMÁTICO (IGUAL CARTÃO)
                      _buildPreview(),

                      const SizedBox(height: 24),

                      // Botões com AppButton
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.outline(
                              text: 'Cancelar',
                              onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                              size: AppButtonSize.medium,
                              fullWidth: true,
                              customColor: _tipoSelecionado == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _tipoSelecionado == 'receita'
                                ? AppButtonExtensions.receita(
                                    text: widget.modo == 'criar' ? 'Criar Receita' : 'Salvar',
                                    onPressed: _loading ? null : _salvarTransacao,
                                    size: AppButtonSize.medium,
                                    fullWidth: true,
                                    isLoading: _loading,
                                    icon: widget.modo == 'criar' ? Icons.add_circle : Icons.save,
                                  )
                                : AppButtonExtensions.despesa(
                                    text: widget.modo == 'criar' ? 'Criar Despesa' : 'Salvar',
                                    onPressed: _loading ? null : _salvarTransacao,
                                    size: AppButtonSize.medium,
                                    fullWidth: true,
                                    isLoading: _loading,
                                    icon: widget.modo == 'criar' ? Icons.remove_circle : Icons.save,
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      
                      // ✅ PADDING EXTRA PARA BOTÕES DE NAVEGAÇÃO
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
