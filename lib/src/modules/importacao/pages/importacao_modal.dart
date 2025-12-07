// 🚀 Importação Modal - iPoupei Mobile
//
// Modal completo para importação de extratos bancários
// Seleção de conta/cartão + file picker + processamento
// Integração total com ImportacaoService
//
// Baseado em: BottomSheet + file_picker + ImportacaoService

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transacao_importada_model.dart';
import '../services/importacao_service.dart';
import '../services/auto_categorization_service.dart';
import '../pages/importacao_final_page.dart';
import '../widgets/auto_categorization_button.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../cartoes/services/cartao_data_service.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../transacoes/components/smart_field.dart';
import '../../transacoes/pages/transacao_form_page.dart';
import '../../auth/components/loading_overlay.dart';
import '../../shared/theme/app_colors.dart';
import '../../../auth_integration.dart';

/// Modal para iniciar importação de transações
class ImportacaoModal extends StatefulWidget {
  const ImportacaoModal({super.key});

  @override
  State<ImportacaoModal> createState() => _ImportacaoModalState();

  /// Mostra o modal de importação
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImportacaoModal(),
    );
  }
}

class _ImportacaoModalState extends State<ImportacaoModal>
    with TickerProviderStateMixin {
  final _importacaoService = ImportacaoService.instance;
  final _contaService = ContaService.instance;
  final _cartaoService = CartaoService.instance;
  final _cartaoDataService = CartaoDataService.instance;
  final _categoriaService = CategoriaService.instance;

  // Estados principais
  String _tipoImportacao = ''; // 'conta' ou 'cartao'
  bool _loading = false;
  bool _processando = false;
  String _mensagemProcessamento = '';

  // Dados carregados
  List<ContaModel> _contas = [];
  List<CartaoModel> _cartoes = [];
  ContaModel? _contaSelecionada;
  CartaoModel? _cartaoSelecionado;
  DateTime? _faturaVencimento;

  // Arquivo selecionado
  File? _arquivo;
  String _nomeArquivo = '';
  Map<String, dynamic>? _deteccaoFormato;
  List<TransacaoImportada> _transacoesPreview = [];
  bool _isLoading = false;
  bool _mostrandoPreview = false;

  // Controles de edição em massa
  List<bool> _transacoesSelecionadas = [];
  bool _todasSelecionadas = false;
  bool _autoCategorizando = false;

  // Controllers para edição de transações
  final Map<int, Map<String, TextEditingController>> _controllers = {};
  final Map<int, Map<String, FocusNode>> _focusNodes = {};

  // Categorias e subcategorias
  List<CategoriaModel> _categorias = [];
  List<SubcategoriaModel> _subcategorias = [];

  // Services
  final _authIntegration = AuthIntegration.instance;

  // Animações
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de slide
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _carregarDados();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  /// Carrega contas e cartões
  Future<void> _carregarDados() async {
    setState(() => _loading = true);

    try {
      final contas = await _contaService.fetchContas();
      final cartoes = await _cartaoService.fetchCartoes();

      setState(() {
        _contas = contas.where((c) => c.ativo).toList();
        _cartoes = cartoes.where((c) => c.ativo).toList();
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados: $e');
      _mostrarErro('Erro ao carregar contas e cartões');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Seleciona tipo de importação
  void _selecionarTipo(String tipo) {
    setState(() {
      _tipoImportacao = tipo;
      _contaSelecionada = null;
      _cartaoSelecionado = null;
      _faturaVencimento = null;
      _arquivo = null;
      _nomeArquivo = '';
      _deteccaoFormato = null;
    });
  }

  /// Seleciona conta
  void _selecionarConta(ContaModel conta) {
    setState(() {
      _contaSelecionada = conta;
    });
  }

  /// Seleciona cartão
  void _selecionarCartao(CartaoModel cartao) {
    setState(() {
      _cartaoSelecionado = cartao;
      // Calcular fatura correta baseada na data atual e regras do cartão
      _calcularFaturaAlvo();
    });
  }

  /// Calcula fatura alvo correta baseada no cartão selecionado
  void _calcularFaturaAlvo() {
    if (_cartaoSelecionado == null) {
      _faturaVencimento = null;
      return;
    }

    try {
      // Usar a mesma lógica do DespesaCartaoPage
      final hoje = DateTime.now();
      final fatura = _cartaoDataService.calcularFaturaAlvo(_cartaoSelecionado!, hoje);
      _faturaVencimento = fatura.dataVencimento;

      debugPrint('💳 Fatura calculada para ${_cartaoSelecionado!.nome}: $_faturaVencimento');
    } catch (e) {
      debugPrint('❌ Erro ao calcular fatura: $e');
      // Fallback seguro
      final hoje = DateTime.now();
      _faturaVencimento = DateTime(hoje.year, hoje.month + 1, _cartaoSelecionado!.diaVencimento);
    }
  }

  /// Seleciona arquivo
  Future<void> _selecionarArquivo() async {
    try {
      debugPrint('🚀 INICIANDO FILE PICKER');

      // File picker simples
      final result = await FilePicker.platform.pickFiles();

      debugPrint('🔍 RESULTADO: ${result != null ? 'SUCESSO' : 'NULL'}');

      if (result != null) {
        debugPrint('📂 FILES ENCONTRADOS: ${result.files.length}');

        if (result.files.isNotEmpty) {
          final file = result.files.first;
          debugPrint('📄 NOME: ${file.name}');
          debugPrint('📄 PATH: ${file.path}');
          debugPrint('📄 SIZE: ${file.size}');

          // Step 3: Confirmar seleção
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ARQUIVO SELECIONADO: ${file.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Step 4: Armazenar arquivo e processar dados reais
          setState(() {
            _nomeArquivo = file.name;
            _arquivo = File(file.path!);
          });

          // Step 5: Processar arquivo real
          await _processarArquivoSelecionado(File(file.path!));
        }
      } else {
        debugPrint('❌ RESULTADO NULL - USER CANCELOU OU ERRO');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Nenhum arquivo selecionado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('💥💥💥 ERRO CRÍTICO: $e');
      debugPrint('📚 STACK: $stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ERRO: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _criarTransacoesFake() async {
    debugPrint('🎭 Criando transações fake...');

    final transacoesFake = [
      TransacaoImportada(
        id: '1',
        data: DateTime.now().subtract(const Duration(days: 1)),
        descricao: 'PIX Recebido João Silva',
        valor: 1500.00,
        tipo: 'receita',
        origem: 'TESTE',
        usuarioId: _authIntegration.authService.currentUser?.id ?? '',
        efetivado: false,
        observacoes: 'Freelance desenvolvimento',
        linhaBruta: 'PIX,João Silva,1500.00,${DateTime.now().subtract(const Duration(days: 1)).toIso8601String()}',
        indiceOriginal: 0,
        metadados: {'banco': 'Nubank', 'tipo_pix': 'CPF'},
      ),
      TransacaoImportada(
        id: '2',
        data: DateTime.now().subtract(const Duration(days: 2)),
        descricao: 'Supermercado Extra',
        valor: 285.50,
        tipo: 'despesa',
        origem: 'TESTE',
        usuarioId: _authIntegration.authService.currentUser?.id ?? '',
        efetivado: false,
        observacoes: 'Compras mensais',
        linhaBruta: 'DEBITO,SUPERMERCADO EXTRA,285.50,${DateTime.now().subtract(const Duration(days: 2)).toIso8601String()}',
        indiceOriginal: 1,
        metadados: {'categoria': 'Alimentação', 'cartao': '****1234'},
      ),
      TransacaoImportada(
        id: '3',
        data: DateTime.now().subtract(const Duration(days: 3)),
        descricao: 'Gasolina Posto Shell',
        valor: 120.00,
        tipo: 'despesa',
        origem: 'TESTE',
        usuarioId: _authIntegration.authService.currentUser?.id ?? '',
        efetivado: false,
        observacoes: 'Abastecimento',
        linhaBruta: 'DEBITO,POSTO SHELL,120.00,${DateTime.now().subtract(const Duration(days: 3)).toIso8601String()}',
        indiceOriginal: 2,
        metadados: {'categoria': 'Transporte', 'litros': '35.2'},
      ),
      TransacaoImportada(
        id: '4',
        data: DateTime.now().subtract(const Duration(days: 4)),
        descricao: 'Netflix Mensalidade',
        valor: 32.90,
        tipo: 'despesa',
        origem: 'TESTE',
        usuarioId: _authIntegration.authService.currentUser?.id ?? '',
        efetivado: false,
        observacoes: 'Assinatura streaming',
        linhaBruta: 'DEBITO AUTOMATICO,NETFLIX,32.90,${DateTime.now().subtract(const Duration(days: 4)).toIso8601String()}',
        indiceOriginal: 3,
        metadados: {'categoria': 'Lazer', 'recorrente': true},
      ),
      TransacaoImportada(
        id: '5',
        data: DateTime.now().subtract(const Duration(days: 5)),
        descricao: 'Transferência Poupança',
        valor: 500.00,
        tipo: 'receita',
        origem: 'TESTE',
        usuarioId: _authIntegration.authService.currentUser?.id ?? '',
        efetivado: false,
        observacoes: 'Resgate poupança',
        linhaBruta: 'TRANSFERENCIA,POUPANCA BB,500.00,${DateTime.now().subtract(const Duration(days: 5)).toIso8601String()}',
        indiceOriginal: 4,
        metadados: {'conta_origem': 'Poupança BB', 'tipo': 'resgate'},
      ),
    ];

    setState(() {
      _transacoesPreview = transacoesFake;
      _transacoesSelecionadas = List.filled(transacoesFake.length, false);
      _todasSelecionadas = false;
      _mostrandoPreview = true; // Ativar modo preview
    });

    debugPrint('✅ ${transacoesFake.length} transações fake criadas!');
    debugPrint('🎬 Modo preview ativado: $_mostrandoPreview');

    // Debug das transações criadas
    for (int i = 0; i < transacoesFake.length; i++) {
      final t = transacoesFake[i];
      debugPrint('💳 Transação $i: ${t.descricao} - R\$ ${t.valor} (${t.tipo})');
    }
  }

  /// Voltar para seleção de arquivo
  void _voltarParaSelecao() {
    debugPrint('🔙 Voltando para seleção de arquivo');
    setState(() {
      _mostrandoPreview = false;
      _transacoesPreview = [];
      _arquivo = null;
      _nomeArquivo = '';
    });
  }

  /// Processar arquivo selecionado e gerar preview das transações
  Future<void> _processarArquivoSelecionado(File file) async {
    try {
      setState(() {
        _isLoading = true;
        _transacoesPreview = [];
      });

      debugPrint('📄 Processando arquivo real: ${file.path}');

      // Detectar tipo de arquivo pela extensão
      final fileName = file.path.toLowerCase();
      List<TransacaoImportada> transacoesReais = [];

      if (fileName.endsWith('.csv')) {
        // Processar CSV
        transacoesReais = await _importacaoService.processarArquivoCSV(
          file,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else if (fileName.endsWith('.ofx') || fileName.endsWith('.qfx')) {
        // Processar OFX
        transacoesReais = await _importacaoService.processarArquivoOFX(
          file,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else if (fileName.endsWith('.pdf')) {
        // Processar PDF
        transacoesReais = await _importacaoService.processarArquivoPDF(
          file,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        // Processar Excel (Conectcar)
        transacoesReais = await _importacaoService.processarArquivoExcel(
          file,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else {
        throw Exception('Formato de arquivo não suportado. Use CSV, OFX, PDF ou Excel (.xlsx).');
      }

      debugPrint('✅ Transações processadas: ${transacoesReais.length}');

      setState(() {
        _transacoesPreview = transacoesReais;
        _transacoesSelecionadas = List.filled(transacoesReais.length, false); // Inicializar lista de seleções
        _isLoading = false;
        _mostrandoPreview = transacoesReais.isNotEmpty; // Mostrar preview se houver dados
      });

      // Mostrar sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${transacoesReais.length} transações encontradas!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erro no processamento: $e');

      setState(() {
        _isLoading = false;
        _transacoesPreview = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao processar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Detecta formato do arquivo
  Future<void> _detectarFormato(File file) async {
    try {
      final deteccao = await _importacaoService.detectarFormatoArquivo(file);

      setState(() {
        _deteccaoFormato = deteccao;
      });
    } catch (e) {
      debugPrint('❌ Erro na detecção de formato: $e');
      // Continua mesmo com erro na detecção
    }
  }

  /// Seleciona fatura com opções inteligentes
  Future<void> _selecionarFatura() async {
    if (_cartaoSelecionado == null) return;

    // Gerar lista de faturas disponíveis baseada no cartão selecionado
    final faturas = _gerarFaturasDisponiveis(_cartaoSelecionado!);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientCartao,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.brancoTransparente30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brancoTransparente20,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.credit_card_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selecionar Fatura',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _cartaoSelecionado!.nome,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sugestão atual
            if (_faturaVencimento != null) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.roxoTransparente10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.roxoTransparente20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.roxoHeader, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sugerido: ${_formatarMesAno(_faturaVencimento!)} (baseado na data atual)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.roxoHeader,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Lista de faturas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: faturas.length,
                itemBuilder: (context, index) {
                  final fatura = faturas[index];
                  final isSelected = _faturaVencimento?.toIso8601String().split('T')[0] == fatura['data']!.split('T')[0];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.gradientCartao
                          : null,
                      color: isSelected ? null : AppColors.cinzaClaro,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.cinzaBorda),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        fatura['display']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textoEscuro,
                        ),
                      ),
                      subtitle: Text(
                        'Vencimento: ${fatura['vencimento']!}',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : AppColors.textoSecundario,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.white)
                          : const Icon(Icons.radio_button_unchecked, color: AppColors.cinzaMedio),
                      onTap: () {
                        Navigator.pop(context, {
                          'display': fatura['display']!,
                          'data': fatura['data']!,
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null) {
      final dataCompleta = DateTime.parse(result['data']);

      setState(() {
        _faturaVencimento = dataCompleta;
      });

      debugPrint('💳 Fatura selecionada: ${result['display']} - Data: $dataCompleta');
    }
  }

  /// Gera lista de faturas disponíveis (3 meses anteriores + atual + 2 próximos)
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
        'data': fatura.dataVencimento.toIso8601String(),
      });
    }

    return faturas;
  }

  /// Formatar data brasileira (ex: "15/01/2025")
  String _formatarDataBr(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  /// Processa arquivo e inicia importação
  Future<void> _processarArquivo() async {
    if (_arquivo == null) {
      _mostrarErro('Selecione um arquivo');
      return;
    }

    if (_tipoImportacao == 'conta' && _contaSelecionada == null) {
      _mostrarErro('Selecione uma conta');
      return;
    }

    if (_tipoImportacao == 'cartao' && (_cartaoSelecionado == null || _faturaVencimento == null)) {
      _mostrarErro('Selecione um cartão e data de vencimento');
      return;
    }

    setState(() {
      _processando = true;
      _mensagemProcessamento = 'Analisando arquivo...';
    });

    try {
      List<TransacaoImportada> transacoes;

      // Processar baseado no tipo de arquivo
      final fileName = _nomeArquivo.toLowerCase();

      if (fileName.endsWith('.pdf')) {
        setState(() => _mensagemProcessamento = 'Processando PDF...');

        transacoes = await _importacaoService.processarArquivoPDF(
          _arquivo!,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else if (fileName.endsWith('.ofx') || fileName.endsWith('.qfx')) {
        setState(() => _mensagemProcessamento = 'Processando OFX...');

        transacoes = await _importacaoService.processarArquivoOFX(
          _arquivo!,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        setState(() => _mensagemProcessamento = 'Processando Excel...');

        transacoes = await _importacaoService.processarArquivoExcel(
          _arquivo!,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      } else {
        setState(() => _mensagemProcessamento = 'Processando CSV/TXT...');

        transacoes = await _importacaoService.processarArquivoCSV(
          _arquivo!,
          tipoImportacao: _tipoImportacao,
          contaId: _contaSelecionada?.id,
          cartaoId: _cartaoSelecionado?.id,
          faturaVencimento: _faturaVencimento,
        );
      }

      if (transacoes.isEmpty) {
        _mostrarErro('Nenhuma transação encontrada no arquivo');
        return;
      }

      setState(() => _mensagemProcessamento = 'Preparando revisão...');

      // Aplicar edições e filtrar apenas transações selecionadas
      final transacoesEditadas = _aplicarEdicoesESelecionar(transacoes);

      if (transacoesEditadas.isEmpty) {
        _mostrarErro('Nenhuma transação selecionada para importar');
        return;
      }

      // Navegar para tela de pré-seleção
      final resultado = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => ImportacaoFinalPage(
            transacoes: transacoesEditadas,
            conta: _contaSelecionada,
            cartao: _cartaoSelecionado,
            tipoImportacao: _tipoImportacao,
          ),
        ),
      );

      // Retornar resultado
      if (mounted && resultado != null) {
        Navigator.pop(context, resultado);
      }

    } catch (e) {
      debugPrint('❌ Erro no processamento: $e');
      _mostrarErro('Erro ao processar arquivo: $e');
    } finally {
      setState(() => _processando = false);
    }
  }

  /// Mostra erro
  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Constrói header do modal - Padrão Premium iPoupei
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientReceitas, // Usando gradiente profissional
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppColors.cardDestaque, // Sombra premium
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            // Handle do modal - Estilo profissional
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.brancoTransparente30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Título principal - Layout CartaoCard style
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brancoTransparente20,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardSuave,
                  ),
                  child: const Icon(
                    Icons.cloud_download_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar Transações',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Extratos bancários e faturas de cartão',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.brancoTransparente10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seletor de tipo
  Widget _buildTipoSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escolha o tipo de importação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione se deseja importar extrato de conta ou fatura de cartão',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTipoCard(
                  tipo: 'conta',
                  titulo: 'Conta Bancária',
                  subtitulo: 'Extrato de conta',
                  icon: Icons.account_balance_outlined,
                  cor: AppColors.azulHeader, // Cor contextual profissional
                  gradientColors: AppColors.blueGradient,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTipoCard(
                  tipo: 'cartao',
                  titulo: 'Cartão de Crédito',
                  subtitulo: 'Fatura do cartão',
                  icon: Icons.credit_card_outlined,
                  cor: AppColors.roxoHeader, // Cor contextual profissional
                  gradientColors: AppColors.purpleGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de tipo - Padrão CartaoCard Premium
  Widget _buildTipoCard({
    required String tipo,
    required String titulo,
    required String subtitulo,
    required IconData icon,
    required Color cor,
    required List<Color> gradientColors,
  }) {
    final selecionado = _tipoImportacao == tipo;

    return GestureDetector(
      onTap: () => _selecionarTipo(tipo),
      child: AnimatedScale(
        scale: selecionado ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: selecionado
                ? _buildGradienteTriplo(gradientColors) // Gradiente triplo premium
                : LinearGradient(
                    colors: [AppColors.cinzaClaro, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: selecionado
                ? null
                : Border.all(
                    color: AppColors.cinzaBorda,
                    width: 1,
                  ),
            boxShadow: selecionado
                ? [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: cor.withValues(alpha: 0.1),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : AppColors.cardSuave,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selecionado
                      ? AppColors.brancoTransparente20
                      : cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selecionado
                      ? [
                          BoxShadow(
                            color: AppColors.brancoTransparente10,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: selecionado ? Colors.white : cor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: selecionado ? Colors.white : AppColors.textoEscuro,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selecionado ? Colors.white70 : AppColors.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradiente triplo premium - Padrão CartaoCard
  LinearGradient _buildGradienteTriplo(List<Color> cores) {
    final corBase = cores[0];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        corBase,
        corBase.withValues(alpha: 0.8),
        corBase.withValues(alpha: 0.9),
      ],
    );
  }

  /// Constrói seletor de conta
  Widget _buildContaSelector() {
    if (_tipoImportacao != 'conta') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionar Conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...(_contas.map((conta) => _buildContaCard(conta))),
        ],
      ),
    );
  }

  /// Constrói card de conta (baseado no ContaCard original)
  Widget _buildContaCard(ContaModel conta) {
    final selecionada = _contaSelecionada?.id == conta.id;
    final corConta = conta.cor?.isNotEmpty == true
        ? Color(int.parse(conta.cor!.replaceAll('#', '0xFF')))
        : const Color(0xFF00BCD4); // AppColors.tealPrimary

    final iconeConta = _getIconeContaPorTipo(conta.tipo ?? '');

    return GestureDetector(
      onTap: () => _selecionarConta(conta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: selecionada
            ? [BoxShadow(
                color: corConta.withAlpha(78),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )]
            : [BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selecionada
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    corConta,
                    corConta.withAlpha(204),
                    corConta.withAlpha(234),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
            border: selecionada
              ? null
              : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              // Ícone com background elegante
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selecionada
                    ? Colors.white.withAlpha(52)
                    : corConta.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconeConta,
                  color: selecionada ? Colors.white : corConta,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Informações da conta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da conta
                    Text(
                      conta.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selecionada ? Colors.white : Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Tipo + Banco
                    Row(
                      children: [
                        Text(
                          _formatarTipoConta(conta.tipo ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: selecionada ? Colors.white70 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (conta.banco?.isNotEmpty == true) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: selecionada ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          Text(
                            conta.banco!,
                            style: TextStyle(
                              fontSize: 12,
                              color: selecionada ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Saldo
                    Text(
                      'Saldo: ${_formatarMoeda(conta.saldo)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: selecionada ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
              ),
            ),
              // Indicador de seleção
              if (selecionada)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF00BCD4),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retorna ícone baseado no tipo da conta (igual ao ContaCard)
  IconData _getIconeContaPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'corrente':
        return Icons.account_balance;
      case 'poupanca':
        return Icons.savings;
      case 'carteira':
        return Icons.account_balance_wallet;
      case 'investimento':
        return Icons.trending_up;
      case 'outros':
        return Icons.more_horiz;
      default:
        return Icons.account_balance_wallet;
    }
  }

  /// Formata tipo da conta para exibição
  String _formatarTipoConta(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'corrente':
        return 'Conta Corrente';
      case 'poupanca':
        return 'Poupança';
      case 'carteira':
        return 'Carteira';
      case 'investimento':
        return 'Investimento';
      case 'outros':
        return 'Outros';
      default:
        return 'Conta';
    }
  }

  /// Formata moeda
  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formatar data como Mês/Ano (ex: "Jan/25")
  String _formatarMesAno(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final mesAbrev = meses[data.month - 1];
    final anoAbrev = data.year.toString().substring(2);
    return '$mesAbrev/$anoAbrev';
  }

  /// Constrói seletor de cartão
  Widget _buildCartaoSelector() {
    if (_tipoImportacao != 'cartao') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionar Cartão',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...(_cartoes.map((cartao) => _buildCartaoCard(cartao))),

          // Seletor de fatura inteligente
          if (_cartaoSelecionado != null) ...[
            const SizedBox(height: 16),
            Text(
              'Fatura do Cartão',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textoEscuro,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selecionarFatura,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _faturaVencimento != null
                      ? AppColors.gradientCartao
                      : LinearGradient(
                          colors: [AppColors.cinzaClaro, Colors.white],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _faturaVencimento != null
                      ? AppColors.cardDestaque
                      : AppColors.cardSuave,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _faturaVencimento != null
                            ? AppColors.brancoTransparente20
                            : AppColors.roxoTransparente10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: _faturaVencimento != null
                            ? Colors.white
                            : AppColors.roxoHeader,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _faturaVencimento != null
                                ? _formatarMesAno(_faturaVencimento!)
                                : 'Selecionar fatura',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _faturaVencimento != null
                                  ? Colors.white
                                  : AppColors.textoEscuro,
                            ),
                          ),
                          if (_faturaVencimento != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Vence em ${_formatarDataBr(_faturaVencimento!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 2),
                            Text(
                              'Toque para escolher',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _faturaVencimento != null
                          ? Colors.white70
                          : AppColors.cinzaMedio,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Constrói card de cartão (baseado no CartaoCard original)
  Widget _buildCartaoCard(CartaoModel cartao) {
    final selecionado = _cartaoSelecionado?.id == cartao.id;
    final corCartao = cartao.cor?.isNotEmpty == true
        ? Color(int.parse(cartao.cor!.replaceAll('#', '0xFF')))
        : const Color(0xFF7C3AED); // AppColors.roxoPrimario fallback

    return GestureDetector(
      onTap: () => _selecionarCartao(cartao),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: selecionado
            ? [BoxShadow(
                color: corCartao.withAlpha(78),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )]
            : [BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selecionado
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    corCartao,
                    corCartao.withAlpha(204),
                    corCartao.withAlpha(234),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
            border: selecionado
              ? null
              : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              // Ícone com background elegante
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selecionado
                    ? Colors.white.withAlpha(52)
                    : corCartao.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: selecionado ? Colors.white : corCartao,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Informações do cartão
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do cartão
                    Text(
                      cartao.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selecionado ? Colors.white : Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Bandeira + Banco
                    Row(
                      children: [
                        if (cartao.bandeira?.isNotEmpty == true) ...[
                          Text(
                            cartao.bandeira!,
                            style: TextStyle(
                              fontSize: 12,
                              color: selecionado ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (cartao.banco?.isNotEmpty == true) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: selecionado ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                            Text(
                              cartao.banco!,
                              style: TextStyle(
                                fontSize: 12,
                                color: selecionado ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ] else if (cartao.banco?.isNotEmpty == true) ...[
                          Text(
                            cartao.banco!,
                            style: TextStyle(
                              fontSize: 12,
                              color: selecionado ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Limite
                    Text(
                      'Limite: ${_formatarMoeda(cartao.limite)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: selecionado ? Colors.white70 : Colors.grey[600],
                      ),
                    ),

                    // Fatura calculada corretamente
                    if (selecionado && _faturaVencimento != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Fatura: ${_formatarMesAno(_faturaVencimento!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Indicador de seleção
              if (selecionado)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói seletor de arquivo
  Widget _buildArquivoSelector() {
    if (_tipoImportacao.isEmpty) return const SizedBox.shrink();

    final podeSelecionar = (_tipoImportacao == 'conta' && _contaSelecionada != null) ||
                           (_tipoImportacao == 'cartao' && _cartaoSelecionado != null && _faturaVencimento != null);

    if (!podeSelecionar) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecionar Arquivo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha o arquivo com as transações para importar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _selecionarArquivo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _arquivo != null
                    ? AppColors.gradientSaldo // Gradiente de sucesso profissional
                    : LinearGradient(
                        colors: [AppColors.cinzaClaro, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: _arquivo == null
                    ? Border.all(
                        color: AppColors.cinzaBorda,
                        width: 2,
                      )
                    : null,
                boxShadow: _arquivo != null
                    ? [
                        BoxShadow(
                          color: AppColors.verdeSucesso.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.verdeSucesso.withValues(alpha: 0.1),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : AppColors.cardSuave,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _arquivo != null
                          ? AppColors.brancoTransparente20
                          : AppColors.azulTransparente10,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _arquivo != null
                          ? [
                              BoxShadow(
                                color: AppColors.brancoTransparente10,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _arquivo != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _arquivo != null ? Colors.white : AppColors.azulHeader,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _arquivo != null ? _nomeArquivo : 'Toque para selecionar arquivo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _arquivo != null ? Colors.white : AppColors.textoEscuro,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_arquivo == null) ...[
                    Text(
                      'Formatos suportados',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFormatChip('CSV'),
                        _buildFormatChip('TXT'),
                        _buildFormatChip('PDF'),
                        _buildFormatChip('OFX'),
                        _buildFormatChip('XLSX'),
                        _buildFormatChip('XLS'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.azulTransparente10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.azulTransparente20),
                      ),
                      child: Text(
                        '💡 Arquivos podem estar em Downloads, Documentos ou WhatsApp',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.azulHeader,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else if (_deteccaoFormato != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brancoTransparente20,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brancoTransparente10,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Formato: ${_deteccaoFormato!['bankName'] ?? 'Detectado'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],

                  // Info de detecção de formato
                  if (_deteccaoFormato != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Detectado: ${_deteccaoFormato!['bankName']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Cards de transações preview
                  if (_transacoesPreview.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Transações Encontradas (${_transacoesPreview.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_transacoesPreview.take(3).map((transacao) =>
                      _buildTransacaoPreviewCard(transacao)
                    ).toList()),
                    if (_transacoesPreview.length > 3) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brancoTransparente10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.brancoTransparente20),
                        ),
                        child: Text(
                          '+${_transacoesPreview.length - 3} transações adicionais',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],

                  // Botão de ação final
                  if (_transacoesPreview.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: _finalizarImportacao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeHeader,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Importar ${_transacoesPreview.length} Transações',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói card de preview da transação - Estilo premium COM INTERAÇÕES
  Widget _buildTransacaoPreviewCard(TransacaoImportada transacao) {
    final isReceita = transacao.tipo == 'receita';
    final corBase = isReceita ? AppColors.verdeHeader : AppColors.vermelhoHeader;
    final icone = isReceita ? Icons.trending_up : Icons.trending_down;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.brancoTransparente10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brancoTransparente20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editarTransacao(transacao),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ícone com cor do tipo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: corBase.withAlpha(52),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icone,
                    color: corBase,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Dados da transação
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transacao.descricao,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transacao.data.day.toString().padLeft(2, '0')}/${transacao.data.month.toString().padLeft(2, '0')}/${transacao.data.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Valor
                Text(
                  'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: corBase,
                  ),
                ),

                const SizedBox(width: 8),

                // Botão de excluir
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _excluirTransacao(transacao),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close,
                        color: Colors.white60,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Editar transação importada
  Future<void> _editarTransacao(TransacaoImportada transacao) async {
    debugPrint('✏️ Editando transação: ${transacao.descricao}');

    final result = await showDialog<TransacaoImportada>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Transação'),
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo descrição
              TextFormField(
                initialValue: transacao.descricao,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: TextStyle(color: AppColors.textoSecundario),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.azulHeader),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Atualizar descrição
                },
              ),
              const SizedBox(height: 16),

              // Campo valor
              TextFormField(
                initialValue: transacao.valor.toStringAsFixed(2).replaceAll('.', ','),
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  labelStyle: TextStyle(color: AppColors.textoSecundario),
                  prefixStyle: TextStyle(color: AppColors.textoSecundario),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.azulHeader),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  // Atualizar valor
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundario)),
          ),
          ElevatedButton(
            onPressed: () {
              // Retornar transação editada
              Navigator.pop(context, transacao);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulHeader,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      debugPrint('✅ Transação editada com sucesso');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transação editada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Excluir transação importada
  Future<void> _excluirTransacao(TransacaoImportada transacao) async {
    debugPrint('🗑️ Excluindo transação: ${transacao.descricao}');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Transação'),
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Tem certeza que deseja excluir esta transação?\n\n"${transacao.descricao}"\nR\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundario)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelhoHeader,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _transacoesPreview.removeWhere((t) => t.id == transacao.id);
      });

      debugPrint('✅ Transação excluída');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Transação excluída'),
            backgroundColor: AppColors.vermelhoHeader,
          ),
        );
      }
    }
  }

  /// Finalizar importação e salvar transações
  Future<void> _finalizarImportacao() async {
    debugPrint('🎯 Finalizando importação de ${_transacoesPreview.length} transações');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finalizar Importação'),
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Confirma a importação de ${_transacoesPreview.length} transações?\n\nElas serão adicionadas ao seu controle financeiro.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundario)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeHeader,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmar Importação', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Simular salvamento (substitua pela implementação real)
        await Future.delayed(const Duration(seconds: 2));

        // Fechar modal e mostrar sucesso
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${_transacoesPreview.length} transações importadas com sucesso!'),
              backgroundColor: AppColors.verdeHeader,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        debugPrint('✅ Importação finalizada com sucesso');

      } catch (e) {
        debugPrint('❌ Erro na importação: $e');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro na importação: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Constrói chip de formato - Estilo premium
  Widget _buildFormatChip(String format) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.azulTransparente10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.azulTransparente20,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulTransparente10,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        format,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.azulHeader,
          letterSpacing: 0.3,
        ),
      ),
    );
  }


  /// Constrói botão de processar
  Widget _buildProcessarButton() {
    final podeProcessar = _arquivo != null &&
                          ((_tipoImportacao == 'conta' && _contaSelecionada != null) ||
                           (_tipoImportacao == 'cartao' && _cartaoSelecionado != null && _faturaVencimento != null));

    if (!podeProcessar) return const SizedBox.shrink();

    final gradientColors = _tipoImportacao == 'conta'
        ? AppColors.blueGradient  // Gradiente contextual profissional
        : AppColors.purpleGradient; // Gradiente contextual profissional

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _processarArquivo,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brancoTransparente20,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brancoTransparente10,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.upload_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Processar Arquivo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: LoadingOverlay(
        isLoading: _processando,
        message: _mensagemProcessamento,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientReceitas,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.cardDestaque,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Carregando dados...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textoSecundario,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _mostrandoPreview
                      ? _buildPreviewScreen()
                      : SingleChildScrollView(
                          key: ValueKey(_tipoImportacao),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(),
                              _buildTipoSelector(),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  key: ValueKey('${_tipoImportacao}_${_contaSelecionada?.id}_${_cartaoSelecionado?.id}'),
                                  children: [
                                    _buildContaSelector(),
                                    _buildCartaoSelector(),
                                    _buildArquivoSelector(),
                                    _buildProcessarButton(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                ),
        ),
      ),
    );
  }

  /// Tela de preview das transações importadas - Interface de Edição em Massa
  Widget _buildPreviewScreen() {
    debugPrint('🎬 CONSTRUINDO PREVIEW SCREEN');
    debugPrint('   📦 Total transações: ${_transacoesPreview.length}');
    debugPrint('   🎯 Preview ativo: $_mostrandoPreview');

    return Column(
      children: [
        // Header compacto com controles
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            gradient: AppColors.gradientReceitas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              // Botão voltar
              IconButton(
                onPressed: () {
                  setState(() {
                    _mostrandoPreview = false;
                    _transacoesPreview.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brancoTransparente20,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(width: 12),

              // Título compacto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Transações',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${_transacoesPreview.length} encontradas',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),

              // Botões de ação em massa
              Row(
                children: [
                  // Aplicar categoria em massa
                  IconButton(
                    onPressed: _mostrarAplicarCategoriaEmMassa,
                    icon: const Icon(Icons.category_outlined, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brancoTransparente20,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Selecionar todas
                  IconButton(
                    onPressed: _toggleSelecionarTodas,
                    icon: Icon(
                      _todasSelecionadas ? Icons.check_box : Icons.check_box_outline_blank,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brancoTransparente20,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Botão de auto-categorização (brilhante e pulsante)
        Builder(builder: (context) {
          final totalTransacoes = _transacoesPreview.length;
          final categorizadasCount = _contarTransacoesCategorizadas();
          final faltamCategorizar = totalTransacoes - categorizadasCount;

          debugPrint('🔥 [BUTTON DEBUG] Building: total=$totalTransacoes, categorizadas=$categorizadasCount, faltam=$faltamCategorizar');

          return AutoCategorizationButton(
            onPressed: _executarAutoCategorizacao,
            isProcessing: _autoCategorizando,
            totalTransacoes: totalTransacoes,
            categorizadasCount: categorizadasCount,
          );
        }),

        // Lista de transações editáveis
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _transacoesPreview.length,
            itemBuilder: (context, index) {
              return _buildTransacaoEditavel(index);
            },
          ),
        ),

        // Botão fixo de importar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(52),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Resumo compacto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_transacoesSelecionadas.where((s) => s).length}/${_transacoesPreview.length} selecionadas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoEscuro,
                      ),
                    ),
                    Text(
                      'R\$ ${_calcularValorSelecionadas().toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Botão de importar
              ElevatedButton(
                onPressed: _transacoesPreview.isNotEmpty
                    ? () async {
                        // ✅ Navegar para tela de pré-seleção
                        final resultado = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImportacaoFinalPage(
                              transacoes: _transacoesPreview,
                              conta: _contaSelecionada,
                              cartao: _cartaoSelecionado,
                              tipoImportacao: _tipoImportacao,
                            ),
                          ),
                        );

                        // Retornar resultado
                        if (mounted && resultado != null) {
                          Navigator.pop(context, resultado);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Importar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Toggle seleção de todas as transações
  void _toggleSelecionarTodas() {
    setState(() {
      _todasSelecionadas = !_todasSelecionadas;
      _transacoesSelecionadas = List.filled(_transacoesPreview.length, _todasSelecionadas);
    });
  }

  /// Mostrar modal para aplicar categoria em massa
  void _mostrarAplicarCategoriaEmMassa() {
    final selecionadas = _transacoesSelecionadas.where((s) => s).length;
    if (selecionadas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma transação')),
      );
      return;
    }

    // TODO: Implementar modal de seleção de categoria
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aplicar categoria para $selecionadas transações (em desenvolvimento)')),
    );
  }

  /// Widget de transação editável individual
  Widget _buildTransacaoEditavel(int index) {
    final transacao = _transacoesPreview[index];
    final isReceita = transacao.tipo == 'receita';
    final controllers = _getOrCreateControllersForIndex(index);
    final focusNodes = _getOrCreateFocusNodesForIndex(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header com checkbox e contador
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isReceita
                  ? AppColors.verdeSucesso.withAlpha(26)
                  : AppColors.vermelhoErro.withAlpha(26),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _temCategoriaCompleta(index),
                  onChanged: (value) {
                    setState(() {
                      _transacoesSelecionadas[index] = value ?? false;
                      _atualizarSelecaoTodas();
                    });
                  },
                  activeColor: isReceita ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                ),
                const SizedBox(width: 8),
                Text(
                  '${index + 1}/${_transacoesPreview.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isReceita ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReceita ? AppColors.verdeSucesso : AppColors.vermelhoErro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isReceita ? 'RECEITA' : 'DESPESA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Campos editáveis usando SmartFields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descrição
                SmartField(
                  controller: controllers['descricao'],
                  focusNode: focusNodes['descricao'],
                  label: 'Descrição',
                  hint: isReceita
                    ? 'Ex: Salário, Freelance, Venda...'
                    : 'Ex: Supermercado, Gasolina, Farmácia...',
                  icon: Icons.description,
                  transactionContext: transacao.tipo,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _transacoesPreview[index] = _transacoesPreview[index].copyWith(
                      descricao: value,
                    );
                  },
                  onEditingComplete: () {
                    // Se o valor for zero, vai direto para categoria, senão vai para valor
                    if (_parseMoneyValue(controllers['valor']!.text) <= 0) {
                      _selecionarCategoriaImportacao(index);
                    } else {
                      focusNodes['valor']!.requestFocus();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Valor e Data em linha
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SmartField(
                        controller: controllers['valor'],
                        focusNode: focusNodes['valor'],
                        label: 'Valor',
                        icon: Icons.attach_money,
                        transactionContext: transacao.tipo,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [MoneyInputFormatter()],
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          final valorDouble = _parseMoneyValue(value);
                          _transacoesPreview[index] = _transacoesPreview[index].copyWith(
                            valor: valorDouble,
                          );
                        },
                        onEditingComplete: () {
                          final valorParsed = _parseMoneyValue(controllers['valor']!.text);
                          if (valorParsed > 0) {
                            // Pula data e vai direto para categoria
                            _selecionarCategoriaImportacao(index);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SmartField(
                        controller: controllers['data'],
                        label: 'Data',
                        transactionContext: transacao.tipo,
                        readOnly: true,
                        icon: Icons.calendar_today,
                        onTap: () => _selecionarDataImportacao(index),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Categoria e Subcategoria em linha
                Row(
                  children: [
                    Expanded(
                      child: SmartField(
                        controller: controllers['categoria'],
                        label: 'Categoria',
                        transactionContext: transacao.tipo,
                        readOnly: true,
                        icon: Icons.category,
                        onTap: () => _selecionarCategoriaImportacao(index),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SmartField(
                        controller: controllers['subcategoria'],
                        label: 'Subcategoria',
                        transactionContext: transacao.tipo,
                        readOnly: true,
                        icon: Icons.label,
                        onTap: () => _selecionarSubcategoriaImportacao(index),
                      ),
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

  /// Card individual de transação - Estilo Tinder com contador
  Widget _buildTransacaoCard(TransacaoImportada transacao, int index) {
    debugPrint('🎴 BUILD CARD $index:');
    debugPrint('   📝 Descrição: "${transacao.descricao}"');
    debugPrint('   💰 Valor: R\$ ${transacao.valor}');
    debugPrint('   📅 Data: ${transacao.data}');
    debugPrint('   🏷️ Tipo: ${transacao.tipo}');

    final isReceita = transacao.tipo == 'receita';
    final cor = isReceita ? AppColors.verdeSucesso : AppColors.vermelhoErro;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cor,
            cor.withValues(alpha: 0.8),
            cor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com contador estilo Tinder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brancoTransparente20,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${index + 1}/${_transacoesPreview.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.brancoTransparente20,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // TODO: Implementar edição
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Editar transação: ${transacao.descricao}'),
                              backgroundColor: AppColors.azul,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.brancoTransparente20,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _transacoesPreview.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Transação removida'),
                              backgroundColor: AppColors.vermelhoErro,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informações da transação
            Text(
              transacao.descricao,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${transacao.data.day.toString().padLeft(2, '0')}/${transacao.data.month.toString().padLeft(2, '0')}/${transacao.data.year}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              transacao.tipo.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtém ou cria controllers para uma transação específica
  Map<String, TextEditingController> _getOrCreateControllersForIndex(int index) {
    if (!_controllers.containsKey(index)) {
      final transacao = _transacoesPreview[index];
      _controllers[index] = {
        'descricao': TextEditingController(text: transacao.descricao),
        'valor': TextEditingController(text: _formatarValorParaInput(transacao.valor)),
        'data': TextEditingController(text: _formatarDataBr(transacao.data)),
        'categoria': TextEditingController(text: transacao.categoriaId ?? ''),
        'subcategoria': TextEditingController(text: transacao.subcategoriaId ?? ''),
      };
    }
    return _controllers[index]!;
  }

  /// Obtém ou cria focus nodes para uma transação específica
  Map<String, FocusNode> _getOrCreateFocusNodesForIndex(int index) {
    if (!_focusNodes.containsKey(index)) {
      _focusNodes[index] = {
        'descricao': FocusNode(),
        'valor': FocusNode(),
        'data': FocusNode(),
        'categoria': FocusNode(),
        'subcategoria': FocusNode(),
      };
    }
    return _focusNodes[index]!;
  }

  /// Formata valor para input monetário
  String _formatarValorParaInput(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }


  /// Parse money value from formatted string
  double _parseMoneyValue(String value) {
    String cleanValue = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '');

    cleanValue = cleanValue.replaceAll(',', '.');

    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Atualiza seleção de "todas"
  /// Verifica se a transação tem categoria preenchida (subcategoria é opcional)
  bool _temCategoriaCompleta(int index) {
    if (index >= _transacoesPreview.length) {
      debugPrint('🔥 [CATEGORIA DEBUG] [$index] Índice fora dos limites');
      return false;
    }

    final transacao = _transacoesPreview[index];
    final categoriaId = transacao.categoriaId;
    final categoriaPreenchida = categoriaId != null && categoriaId.isNotEmpty;

    debugPrint('🔥 [CATEGORIA DEBUG] [$index] "${transacao.descricao}" -> categoriaId: "$categoriaId" -> tem categoria: $categoriaPreenchida');

    // 🎯 FLEXIBILIZADA: Considera categorizada se tem pelo menos categoria
    // Subcategoria é desejável mas não obrigatória
    return categoriaPreenchida;
  }

  /// Conta quantas transações já estão categorizadas
  int _contarTransacoesCategorizadas() {
    debugPrint('🔥 [COUNT DEBUG] Contando transações categorizadas...');
    debugPrint('🔥 [COUNT DEBUG] Total transações: ${_transacoesPreview.length}');

    int count = 0;
    for (int i = 0; i < _transacoesPreview.length; i++) {
      final transacao = _transacoesPreview[i];
      final temCategoria = _temCategoriaCompleta(i);
      debugPrint('🔥 [COUNT DEBUG] [$i] "${transacao.descricao}" -> categoriaId: ${transacao.categoriaId} -> tem categoria: $temCategoria');
      if (temCategoria) {
        count++;
      }
    }
    debugPrint('🔥 [COUNT DEBUG] Resultado: $count/${_transacoesPreview.length} categorizadas');
    return count;
  }

  /// Executa auto-categorização inteligente
  Future<void> _executarAutoCategorizacao() async {
    debugPrint('🚀 [AUTO-CAT] INICIANDO auto-categorização...');
    debugPrint('🚀 [AUTO-CAT] Total transações para categorizar: ${_transacoesPreview.length}');

    setState(() => _autoCategorizando = true);

    try {
      debugPrint('📂 [AUTO-CAT] Carregando categorias...');
      // Carregar categorias e subcategorias
      final categorias = await _categoriaService.fetchCategorias();
      final subcategorias = await _categoriaService.fetchSubcategorias();

      debugPrint('📚 [AUTO-CAT] Total categorias carregadas: ${categorias.length}');
      debugPrint('📚 [AUTO-CAT] Total subcategorias carregadas: ${subcategorias.length}');

      if (categorias.isEmpty) {
        debugPrint('⚠️ [AUTO-CAT] PROBLEMA: Nenhuma categoria carregada!');
        throw Exception('Nenhuma categoria encontrada. Verifique a conexão com o banco de dados.');
      }

      for (final cat in categorias) {
        debugPrint('   - ${cat.nome} (ID: ${cat.id}, Tipo: ${cat.tipo})');
      }

      debugPrint('🤖 [AUTO-CAT] Executando auto-categorização...');

      // Executar auto-categorização
      final transacoesCategorizadas = await AutoCategorizationService.instance.categorizarAutomaticamente(
        transacoes: _transacoesPreview,
        categorias: categorias,
        subcategorias: subcategorias,
      );

      // Atualizar transações e controllers
      setState(() {
        _transacoesPreview = transacoesCategorizadas;

        // Atualizar controllers de categoria/subcategoria
        for (int i = 0; i < _transacoesPreview.length; i++) {
          final transacao = _transacoesPreview[i];
          final controllers = _getOrCreateControllersForIndex(i);

          debugPrint('🎯 [CARD $i] "${transacao.descricao}" → categoriaId: ${transacao.categoriaId}, subcategoriaId: ${transacao.subcategoriaId}');

          // Atualizar controller de categoria
          if (transacao.categoriaId != null && transacao.categoriaId!.isNotEmpty) {
            debugPrint('   🔍 Buscando categoria com ID: ${transacao.categoriaId}');

            CategoriaModel? categoria;
            try {
              categoria = categorias.firstWhere((c) => c.id == transacao.categoriaId);
              debugPrint('   ✅ Categoria encontrada: ${categoria.nome} (${categoria.id})');
            } catch (e) {
              debugPrint('   ❌ Categoria ID ${transacao.categoriaId} não encontrada na lista!');
              categoria = null;
            }

            if (categoria != null) {
              controllers['categoria']?.text = categoria.nome;
              debugPrint('   ✅ Categoria no card: ${categoria.nome} (${categoria.id})');
            } else {
              debugPrint('   ❌ Categoria não encontrada - card ficará sem categoria');
            }
          }

          // Atualizar controller de subcategoria
          if (transacao.subcategoriaId != null && transacao.subcategoriaId!.isNotEmpty) {
            final subcategoria = subcategorias.firstWhere(
              (s) => s.id == transacao.subcategoriaId,
              orElse: () => SubcategoriaModel(
                id: '',
                nome: '',
                categoriaId: '',
                ativo: false,
                usuarioId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            if (subcategoria.id.isNotEmpty) {
              controllers['subcategoria']?.text = subcategoria.nome;
              debugPrint('   ✅ Subcategoria no card: ${subcategoria.nome} (${subcategoria.id}, categoriaId: ${subcategoria.categoriaId})');
            } else {
              debugPrint('   ❌ Subcategoria ID ${transacao.subcategoriaId} não encontrada!');
            }
          }
        }
      });

      // Mostrar resultado
      final categorizadas = _contarTransacoesCategorizadas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ $categorizadas transação(ões) categorizadas automaticamente!'),
            backgroundColor: AppColors.verdeSucesso,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro na auto-categorização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao categorizar: $e'),
            backgroundColor: AppColors.vermelhoErro,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _autoCategorizando = false);
    }
  }

  void _atualizarSelecaoTodas() {
    _todasSelecionadas = _transacoesSelecionadas.every((s) => s);
  }

  /// Calcula valor total das transações selecionadas
  double _calcularValorSelecionadas() {
    double total = 0.0;
    for (int i = 0; i < _transacoesPreview.length; i++) {
      if (i < _transacoesSelecionadas.length && _transacoesSelecionadas[i]) {
        total += _transacoesPreview[i].valor;
      }
    }
    return total;
  }

  /// Aplica edições do preview e retorna apenas transações selecionadas
  List<TransacaoImportada> _aplicarEdicoesESelecionar(List<TransacaoImportada> transacoesOriginais) {
    final transacoesEditadas = <TransacaoImportada>[];

    for (int i = 0; i < _transacoesPreview.length; i++) {
      // Verificar se está selecionada
      if (i < _transacoesSelecionadas.length && _transacoesSelecionadas[i]) {
        final transacaoOriginal = i < transacoesOriginais.length
            ? transacoesOriginais[i]
            : _transacoesPreview[i];

        // Aplicar edições se houver controllers para esse índice
        final controllers = _controllers[i];
        if (controllers != null) {
          final transacaoEditada = TransacaoImportada(
            id: transacaoOriginal.id,
            data: controllers['data']?.text.isNotEmpty == true
                ? DateTime.tryParse(controllers['data']!.text) ?? transacaoOriginal.data
                : transacaoOriginal.data,
            descricao: controllers['descricao']?.text.isNotEmpty == true
                ? controllers['descricao']!.text
                : transacaoOriginal.descricao,
            valor: controllers['valor']?.text.isNotEmpty == true
                ? (double.tryParse(controllers['valor']!.text) ?? transacaoOriginal.valor)
                : transacaoOriginal.valor,
            tipo: transacaoOriginal.tipo,
            origem: transacaoOriginal.origem,
            usuarioId: transacaoOriginal.usuarioId,
            contaId: transacaoOriginal.contaId,
            cartaoId: transacaoOriginal.cartaoId,
            categoriaId: transacaoOriginal.categoriaId,
            subcategoriaId: transacaoOriginal.subcategoriaId,
            efetivado: transacaoOriginal.efetivado,
            observacoes: controllers['observacoes']?.text.isNotEmpty == true
                ? controllers['observacoes']!.text
                : transacaoOriginal.observacoes,
            linhaBruta: transacaoOriginal.linhaBruta,
            indiceOriginal: transacaoOriginal.indiceOriginal,
            metadados: transacaoOriginal.metadados,
            faturaVencimento: transacaoOriginal.faturaVencimento,
          );
          transacoesEditadas.add(transacaoEditada);
        } else {
          // Sem edições, usar a original
          transacoesEditadas.add(transacaoOriginal);
        }
      }
    }

    return transacoesEditadas;
  }

  /// Seleciona data para importação
  Future<void> _selecionarDataImportacao(int index) async {
    final transacao = _transacoesPreview[index];
    final controllers = _getOrCreateControllersForIndex(index);

    final data = await showDatePicker(
      context: context,
      initialDate: transacao.data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() {
        _transacoesPreview[index] = transacao.copyWith(data: data);
        controllers['data']!.text = _formatarDataBr(data);
      });
    }
  }

  /// Seleciona categoria para importação (modal igual ao transacao_form_page.dart)
  Future<void> _selecionarCategoriaImportacao(int index) async {
    final transacao = _transacoesPreview[index];
    final controllers = _getOrCreateControllersForIndex(index);

    if (_categorias.isEmpty) {
      await _carregarCategorias();
    }

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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

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

            Expanded(
              child: ListView.builder(
                itemCount: _categorias.where((c) => c.tipo == transacao.tipo).length,
                itemBuilder: (context, catIndex) {
                  final categoriasFiltradas = _categorias.where((c) => c.tipo == transacao.tipo).toList();
                  final cat = categoriasFiltradas[catIndex];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cat.cor != null && cat.cor!.isNotEmpty
                              ? Color(int.parse(cat.cor!.replaceAll('#', '0xFF')))
                              : (transacao.tipo == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: cat.icone.isNotEmpty
                              ? _getIconeByName(cat.icone, size: 20, color: Colors.white)
                              : const Icon(Icons.category, color: Colors.white, size: 20),
                        ),
                      ),
                      title: Text(cat.nome),
                      onTap: () => Navigator.pop(context, cat),
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
        _transacoesPreview[index] = transacao.copyWith(categoriaId: categoria.id);
        controllers['categoria']!.text = categoria.nome;
        controllers['subcategoria']!.text = ''; // Reset subcategoria
      });

      // Carregar subcategorias da categoria selecionada
      await _carregarSubcategoriasPorCategoria(categoria.id);

      // Aguardar um pouco para garantir que o setState foi processado
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar se tem subcategorias e navegar automaticamente
      if (mounted && _subcategorias.isNotEmpty) {
        debugPrint('🔔 Categoria selecionada, navegando para subcategoria... (${_subcategorias.length} encontradas)');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _selecionarSubcategoriaImportacao(index);
          }
        });
      }
    }
  }

  /// Seleciona subcategoria para importação
  Future<void> _selecionarSubcategoriaImportacao(int index) async {
    final transacao = _transacoesPreview[index];
    final controllers = _getOrCreateControllersForIndex(index);

    if (transacao.categoriaId == null || transacao.categoriaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria primeiro')),
      );
      return;
    }

    if (_subcategorias.isEmpty) {
      await _carregarSubcategoriasPorCategoria(transacao.categoriaId!);
    }

    if (_subcategorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta categoria não possui subcategorias')),
      );
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

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

            Expanded(
              child: ListView.builder(
                itemCount: _subcategorias.length,
                itemBuilder: (context, subIndex) {
                  final sub = _subcategorias[subIndex];

                  // Buscar categoria pai para usar sua cor e ícone
                  CategoriaModel? categoriaPai;
                  try {
                    categoriaPai = _categorias.firstWhere(
                      (c) => c.id == sub.categoriaId,
                    );
                  } catch (e) {
                    // Se não encontrar categoria pai, criar fallback
                    debugPrint('⚠️ Categoria pai não encontrada para subcategoria ${sub.nome} (categoriaId: ${sub.categoriaId})');
                    categoriaPai = null;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (categoriaPai?.cor != null && categoriaPai!.cor!.isNotEmpty)
                              ? Color(int.parse(categoriaPai.cor!.replaceAll('#', '0xFF')))
                              : (transacao.tipo == 'receita' ? AppColors.tealPrimary : AppColors.vermelhoHeader),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: (categoriaPai?.icone.isNotEmpty ?? false)
                              ? _getIconeByName(categoriaPai!.icone, size: 18, color: Colors.white)
                              : const Icon(Icons.category, size: 18, color: Colors.white),
                        ),
                      ),
                      title: Text(sub.nome),
                      onTap: () => Navigator.pop(context, sub),
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
        _transacoesPreview[index] = transacao.copyWith(subcategoriaId: subcategoria.id);
        controllers['subcategoria']!.text = subcategoria.nome;
      });
    }
  }

  /// Carrega categorias
  Future<void> _carregarCategorias() async {
    try {
      final categorias = await _categoriaService.fetchCategorias();
      setState(() {
        _categorias = categorias.where((c) => c.ativo).toList();
      });
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar categorias: $e');
      // Criar categorias mock para demonstração
      setState(() {
        _categorias = [
          CategoriaModel(
            id: 'cat1',
            usuarioId: 'user1',
            nome: 'Alimentação',
            cor: '#FF5722',
            icone: 'restaurant',
            tipo: 'despesa',
            ativo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoriaModel(
            id: 'cat2',
            usuarioId: 'user1',
            nome: 'Transporte',
            cor: '#2196F3',
            icone: 'directions_car',
            tipo: 'despesa',
            ativo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CategoriaModel(
            id: 'cat3',
            usuarioId: 'user1',
            nome: 'Salário',
            cor: '#4CAF50',
            icone: 'work',
            tipo: 'receita',
            ativo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      });
    }
  }

  /// Carrega subcategorias por categoria
  Future<void> _carregarSubcategoriasPorCategoria(String categoriaId) async {
    try {
      debugPrint('🔄 Carregando subcategorias para categoria: $categoriaId');
      debugPrint('📝 CategoriaId válido: ${categoriaId.isNotEmpty} (length: ${categoriaId.length})');

      // Buscar subcategorias específicas da categoria selecionada usando o service real
      final subcategorias = await _categoriaService.fetchSubcategorias(
        categoriaId: categoriaId
      );

      debugPrint('✅ Carregadas ${subcategorias.length} subcategorias para categoria $categoriaId');

      setState(() {
        _subcategorias = subcategorias.where((s) => s.ativo).toList();
        debugPrint('📋 ${_subcategorias.length} subcategorias ativas carregadas para categoria $categoriaId');
      });

    } catch (e) {
      debugPrint('⚠️ Erro ao carregar subcategorias para categoria $categoriaId: $e');
      setState(() {
        _subcategorias = [];
      });
    }
  }

  /// Helper para renderizar ícones das categorias
  Widget _getIconeByName(String icone, {required double size, Color? color}) {
    return CategoriaIcons.renderIcon(icone, size, color: color);
  }
}

/// MoneyInputFormatter - para formatação de valores monetários
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