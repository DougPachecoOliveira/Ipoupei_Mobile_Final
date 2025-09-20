import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../services/cartao_service.dart';
import '../services/fatura_service.dart';
import '../services/cartao_data_service.dart';
import '../services/fatura_detection_service.dart';
import '../services/pagamento_fatura_service.dart';
import '../services/fatura_operations_service.dart';
import 'faturas_list_page.dart';
import '../../transacoes/services/transacao_service.dart';
import '../../../database/local_database.dart';
import '../../../auth_integration.dart';
import '../../../sync/sync_manager.dart';
import 'cartao_form_page.dart';
import '../widgets/cartao_card.dart';
import 'pagamento_fatura_page.dart';

class GestaoCartoesMobilePage extends StatefulWidget {
  final CartaoModel cartao;

  const GestaoCartoesMobilePage({
    super.key,
    required this.cartao,
  });

  @override
  State<GestaoCartoesMobilePage> createState() => _GestaoCartoesMobilePageState();
}

class _GestaoCartoesMobilePageState extends State<GestaoCartoesMobilePage> {
  DateTime _mesAtual = DateTime.now();
  bool _carregando = true;
  String? _erro;
  
  // Dados do cartão - apenas valores reais
  double _gastoMedio = 0.0;
  double _economia = 0.0;
  int _diasParaVencimento = 0;
  double _gastoMesAtual = 0.0;
  double _valorUtilizado = 0.0;
  FaturaModel? _faturaAtual;
  List<Map<String, dynamic>> _evolucaoGastos = [];
  List<Map<String, String>> _gastosPorCategoria = [];
  List<Map<String, dynamic>> _gastosPorDiaReais = [];

  final CartaoService _cartaoService = CartaoService.instance;
  final FaturaService _faturaService = FaturaService();
  final TransacaoService _transacaoService = TransacaoService.instance;
  final CartaoDataService _cartaoDataService = CartaoDataService.instance;
  final FaturaDetectionService _faturaDetectionService = FaturaDetectionService.instance;
  final PagamentoFaturaService _pagamentoService = PagamentoFaturaService.instance;
  final SyncManager _syncManager = SyncManager.instance;
  
  // Cache para evitar reprocessamento
  String? _ultimoMesCarregado;
  Map<String, dynamic>? _cacheResumo;
  DateTime? _ultimoCacheTime;
  static const _cacheDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _inicializarLocale();
  }

  Future<void> _inicializarLocale() async {
    try {
      await initializeDateFormatting('pt_BR', null);
    } catch (e) {
      debugPrint('Erro ao inicializar locale: $e');
    }
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    
    try {
      // Load current invoice and enhanced data
      await _carregarFaturaAtual();
      await _carregarDadosEnhanced();
      
      setState(() {
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da gestão: $e');
      setState(() {
        _carregando = false;
        _erro = e.toString();
      });
    }
  }

  /// Enhanced data loading with real card information
  Future<void> _carregarDadosEnhanced() async {
    try {
      // Use card real data when available
      final limite = widget.cartao.limite ?? 0;
      
      // Busca resumo consolidado real do mês atual
      final mesAtual = DateFormat('yyyy-MM').format(_mesAtual);
      
      // ✅ VERIFICAR CACHE PRIMEIRO
      final agora = DateTime.now();
      final cacheValido = _ultimoMesCarregado == mesAtual && 
                         _cacheResumo != null &&
                         _ultimoCacheTime != null &&
                         agora.difference(_ultimoCacheTime!) < _cacheDuration;
      
      Map<String, dynamic> resumo;
      if (cacheValido) {
        debugPrint('✅ Usando cache para mês: $mesAtual');
        resumo = _cacheResumo!;
      } else {
        debugPrint('🔄 Carregando dados para mês: $mesAtual');
        resumo = await _cartaoDataService.fetchResumoConsolidado(mesAtual);
        
        // Salvar no cache
        _ultimoMesCarregado = mesAtual;
        _cacheResumo = resumo;
        _ultimoCacheTime = agora;
      }
      
      // ✅ CORRIGIDO: Usar o mesmo método do consolidado para valor utilizado
      final valorUtilizadoReal = await _cartaoDataService.calcularLimiteUtilizado(widget.cartao.id);
      _valorUtilizado = valorUtilizadoReal;
      _gastoMesAtual = resumo['total_gasto_periodo']?.toDouble() ?? 0.0;
      
      debugPrint('💳 Valor utilizado: R\$ ${_valorUtilizado.toStringAsFixed(2)} (Método correto do consolidado)');
      debugPrint('💰 Gasto período: R\$ ${_gastoMesAtual.toStringAsFixed(2)}');
      
      // Debug: Verificar se existem transações do cartão
      await _debugTransacoesCartao();
      
      // Busca gasto médio dos últimos 3 meses se houver dados históricos
      try {
        final historico = await _buscarHistoricoGastos();
        if (historico.isNotEmpty) {
          _gastoMedio = historico.fold(0.0, (sum, valor) => sum + valor) / historico.length;
        } else {
          _gastoMedio = limite * 0.45; // Fallback
        }
      } catch (e) {
        _gastoMedio = limite * 0.45; // Fallback
      }
      
      _economia = _gastoMedio - _gastoMesAtual;
      
      // Days to due date
      if (_faturaAtual != null) {
        _diasParaVencimento = _faturaAtual!.diasAteVencimento;
      } else {
        _diasParaVencimento = widget.cartao.diaVencimento ?? 15;
      }
      
      // Load real data
      await _carregarGastosPorCategoriaReais();
      await _carregarEvolucaoGastosReais();
      await _carregarGastosPorDiaReais();
      
    } catch (e) {
      debugPrint('Erro ao carregar dados enhanced: $e');
      // Fallback para dados mockados em caso de erro
      await _carregarDadosFallback();
    }
  }
  
  /// Fallback para dados mockados quando dados reais falham
  Future<void> _carregarDadosFallback() async {
    final limite = widget.cartao.limite ?? 0;
    // ✅ CORRIGIDO: Usar método correto mesmo no fallback
    try {
      _valorUtilizado = await _cartaoDataService.calcularLimiteUtilizado(widget.cartao.id);
    } catch (e) {
      _valorUtilizado = limite * 0.35; // Só como último recurso
    }
    _gastoMedio = limite * 0.45;
    _gastoMesAtual = _valorUtilizado;
    _economia = _gastoMedio - _gastoMesAtual;
    
    _diasParaVencimento = _faturaAtual?.diasAteVencimento ?? widget.cartao.diaVencimento ?? 15;
    
    await _carregarGastosPorCategoriaReais();
    await _carregarEvolucaoGastosReais();
    await _carregarGastosPorDiaReais();
  }
  
  /// Debug: Verificar transações do cartão no banco local
  Future<void> _debugTransacoesCartao() async {
    try {
      final db = LocalDatabase.instance.database;
      final userId = AuthIntegration.instance.authService.currentUser?.id;
      
      if (userId == null) {
        debugPrint('❌ Debug: Usuário não autenticado');
        return;
      }
      if (db == null) {
        debugPrint('❌ Debug: Database não inicializado');
        return;
      }
      
      // Contar total de transações do cartão
      final totalTransacoes = await db.query(
        'transacoes',
        where: 'cartao_id = ? AND usuario_id = ?',
        whereArgs: [widget.cartao.id, userId],
      );
      
      debugPrint('🔍 Debug: ${totalTransacoes.length} transações encontradas para o cartão ${widget.cartao.id}');
      
      // Mostrar as primeiras 3 transações se houver
      if (totalTransacoes.isNotEmpty) {
        for (int i = 0; i < totalTransacoes.length && i < 3; i++) {
          final t = totalTransacoes[i];
          debugPrint('  💰 ${t['descricao']}: R\$ ${t['valor']} (${t['data']})');
        }
      } else {
        debugPrint('  ⚠️ Nenhuma transação encontrada - usando dados mockados');
      }
      
    } catch (e) {
      debugPrint('❌ Erro no debug de transações: $e');
    }
  }
  
  /// Busca histórico de gastos dos últimos meses para calcular média real
  Future<List<double>> _buscarHistoricoGastos() async {
    final historico = <double>[];
    
    for (int i = 1; i <= 3; i++) {
      final mesAnterior = DateTime(_mesAtual.year, _mesAtual.month - i, 1);
      final mesFormatado = DateFormat('yyyy-MM').format(mesAnterior);
      
      try {
        final resumoMes = await _cartaoDataService.fetchResumoConsolidado(mesFormatado);
        final valorMes = resumoMes['valorUtilizado']?.toDouble() ?? 0.0;
        if (valorMes > 0) {
          historico.add(valorMes);
        }
      } catch (e) {
        debugPrint('Erro ao buscar histórico do mês $mesFormatado: $e');
      }
    }
    
    return historico;
  }
  
  /// Carrega gastos reais por categoria
  Future<void> _carregarGastosPorCategoriaReais() async {
    try {
      final faturaVencimento = _faturaAtual?.dataVencimento.toIso8601String().split('T')[0] 
          ?? DateFormat('yyyy-MM-dd').format(DateTime(_mesAtual.year, _mesAtual.month + 1, widget.cartao.diaVencimento ?? 15));
      
      debugPrint('🔍 Buscando gastos por categoria - Cartão: ${widget.cartao.id}, Fatura: $faturaVencimento');
      
      final gastosReais = await _cartaoDataService.fetchGastosPorCategoria(widget.cartao.id, faturaVencimento);
      debugPrint('📊 Gastos por categoria encontrados: ${gastosReais.length}');
      
      if (gastosReais.isNotEmpty) {
        final totalGastos = gastosReais.fold(0.0, (sum, gasto) => sum + (gasto['valor_total'] as num).toDouble());
        
        _gastosPorCategoria = gastosReais.map((gasto) {
          final valor = (gasto['valor_total'] as num).toDouble();
          final percentual = totalGastos > 0 ? ((valor / totalGastos) * 100).toStringAsFixed(1) : '0.0';
          
          return {
            'categoria': gasto['categoria_nome'] as String? ?? 'Sem categoria',
            'valor': CurrencyFormatter.format(valor),
            'percentual': percentual,
          };
        }).toList();
      } else {
        // Se não há dados reais, usar lista vazia
        _gastosPorCategoria = [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar gastos por categoria reais: $e');
      _gastosPorCategoria = [];
    }
  }
  
  /// Carrega evolução real de gastos dos últimos meses
  Future<void> _carregarEvolucaoGastosReais() async {
    try {
      _evolucaoGastos.clear();
      
      for (int i = 5; i >= 0; i--) {
        final mesData = DateTime(_mesAtual.year, _mesAtual.month - i, 1);
        final mesFormatado = DateFormat('yyyy-MM').format(mesData);
        final mesNome = DateFormat('MMM', 'pt_BR').format(mesData);
        
        try {
          final resumoMes = await _cartaoDataService.fetchResumoConsolidado(mesFormatado);
          final valorMes = resumoMes['valorUtilizado']?.toDouble() ?? 0.0;
          
          _evolucaoGastos.add({
            'mes': mesNome,
            'valor': valorMes,
            'isAtual': i == 0,
          });
        } catch (e) {
          // Se não tem dados para um mês, adiciona 0
          _evolucaoGastos.add({
            'mes': mesNome,
            'valor': 0.0,
            'isAtual': i == 0,
          });
        }
      }
      
      // Se não conseguiu nenhum dado real, usa mockados
      if (_evolucaoGastos.every((m) => (m['valor'] as double) == 0.0)) {
        _evolucaoGastos = [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar evolução de gastos reais: $e');
      _evolucaoGastos = [];
    }
  }
  
  /// Carrega gastos reais por dia da semana
  Future<void> _carregarGastosPorDiaReais() async {
    try {
      // Por enquanto, usar lista vazia até implementar busca real
      // TODO: Implementar busca real de transações por dia da semana
      _gastosPorDiaReais = [];
    } catch (e) {
      debugPrint('Erro ao carregar gastos por dia reais: $e');
      _gastosPorDiaReais = [];
    }
  }
  

  Future<void> _carregarFaturaAtual() async {
    try {
      // ✅ NOVA LÓGICA: Detectar fatura do mês atual sempre
      debugPrint('🔍 Detectando fatura atual para cartão: ${widget.cartao.nome} - Mês: ${_mesAtual.month}/${_mesAtual.year}');
      
      // ✅ BUSCAR FATURA REAL (igual tela Faturas) - DADOS CONSISTENTES
      _faturaAtual = await _cartaoDataService.buscarFaturaReal(
        widget.cartao.id, 
        mesReferencia: _mesAtual
      );
      
      if (_faturaAtual != null) {
        debugPrint('✅ Fatura detectada: ${_faturaAtual!.valorTotalFormatado} - Status: ${_faturaAtual!.paga ? "PAGA" : "EM ABERTO"}');
        debugPrint('📊 Valor total: R\$ ${_faturaAtual!.valorTotal} - Valor restante: R\$ ${_faturaAtual!.valorRestante}');
      } else {
        debugPrint('⚠️ Nenhuma fatura encontrada para o período ${_mesAtual.month}/${_mesAtual.year}');
        
        // Tentar buscar qualquer transação não efetivada do cartão para debug
        final transacoesPendentes = await LocalDatabase.instance.database?.query(
          'transacoes',
          where: 'cartao_id = ? AND efetivado = 0',
          whereArgs: [widget.cartao.id],
        );
        
        if (transacoesPendentes != null && transacoesPendentes.isNotEmpty) {
          debugPrint('📋 Encontradas ${transacoesPendentes.length} transações pendentes no cartão');
          for (final t in transacoesPendentes.take(3)) {
            debugPrint('  - ${t['descricao']}: R\$ ${t['valor']} (Fatura: ${t['fatura_vencimento']})');
          }
        } else {
          debugPrint('📋 Nenhuma transação pendente encontrada no cartão');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao detectar fatura atual: $e');
      _faturaAtual = null;
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBar(),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_erro!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDados,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back, 
                color: Colors.white, 
                size: 24
              ),
            ),
          ),
          
          const Text(
            'Gestão Geral',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          Row(
            children: [
              GestureDetector(
                onTap: _mesAnterior,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.chevron_left, 
                    color: Colors.white, 
                    size: 24
                  ),
                ),
              ),
              
              Text(
                _formatarMesAno(_mesAtual),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              GestureDetector(
                onTap: _proximoMes,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.chevron_right, 
                    color: Colors.white, 
                    size: 24
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'adicionar_cartao':
                _abrirModalAdicionarCartao();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'adicionar_cartao',
              child: Row(
                children: [
                  Icon(Icons.add_card, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Adicionar Cartão'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCardCartaoComAcoes(),
          const SizedBox(height: 12),
          _buildResumoMetricas(),
          const SizedBox(height: 12),
          _buildCardInsights(),
          const SizedBox(height: 12),
          _buildGraficos(),
          const SizedBox(height: 12),
          _buildBotaoVoltar(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardCartaoComAcoes() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card do cartão usando CartaoCard (mini card da página consolidado)
          CartaoCard(
            cartao: widget.cartao,
            valorUtilizado: _valorUtilizado,
            gastoPeriodo: _gastoMesAtual,
            faturaAtual: _faturaAtual,
            periodoAtual: _formatarMesAno(_mesAtual),
            onTap: () {},
            onPagarFatura: _abrirPagamentoFatura,
            onMenuAction: (action) {
              switch (action) {
                case 'pagar':
                  _abrirPagamentoFatura();
                  break;
                case 'gestao_completa':
                  // Já estamos na gestão completa
                  break;
                case 'editar':
                  _editarCartao();
                  break;
                case 'ver_faturas':
                  _verFaturas();
                  break;
                case 'extrato':
                  _verExtrato();
                  break;
                case 'add_despesa':
                  _adicionarDespesa();
                  break;
                case 'arquivar':
                  _arquivarCartao();
                  break;
                default:
                  _mostrarEmDesenvolvimento();
              }
            },
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildChipsElegantes(),
          ),
          
        ],
      ),
    );
  }

  Widget _buildChipsElegantes() {
    return Column(
      children: [
        Row(
          children: [
            // Lógica híbrida inteligente
            if (_faturaAtual != null && _faturaAtual!.paga)
              // Se fatura do mês atual está paga, mostrar opção para reabrir
              Expanded(child: _buildChipElegante(
                icone: Icons.refresh,
                titulo: 'REABRIR FATURA',
                cor: Colors.orange,
                onTap: _reabrirFatura,
              ))
            else
              // Sempre mostrar "PAGAR FATURA" buscando globalmente
              Expanded(child: _buildChipElegante(
                icone: Icons.payment,
                titulo: 'PAGAR FATURA',
                cor: _devePagarFatura() ? Colors.red : Colors.blue,
                onTap: _abrirPagamentoFatura,
              )),
            const SizedBox(width: 12),
            Expanded(child: _buildChipElegante(
              icone: Icons.edit,
              titulo: 'EDITAR',
              cor: Colors.blue,
              onTap: _editarCartao,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildChipElegante(
              icone: Icons.receipt_long,
              titulo: 'FATURAS',
              cor: Colors.purple,
              onTap: _verFaturas,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildChipElegante({
    required IconData icone,
    required String titulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 28,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  FaturaModel? _obterFaturaExibicao() {
    if (_faturaAtual == null) return null;
    
    final hoje = DateTime.now();
    final vencimento = _faturaAtual!.dataVencimento;
    final diasParaVencimento = vencimento.difference(hoje).inDays;
    
    if (diasParaVencimento > 60) {
      return null;
    }
    
    return _faturaAtual;
  }

  bool _devePagarFatura() {
    if (_faturaAtual == null) return false;
    
    // Não deve pagar se já está paga
    if (_faturaAtual!.paga) return false;
    
    // Deve pagar se há valor em aberto
    if (_faturaAtual!.valorRestante <= 0.01) return false;
    
    final hoje = DateTime.now();
    final vencimento = _faturaAtual!.dataVencimento;
    final diasRestantes = vencimento.difference(hoje).inDays;
    
    // Vermelho (urgente) se vencida ou vence nos próximos 7 dias
    return diasRestantes <= 7;
  }

  /// ✅ VERIFICAR SE HÁ FATURA PARA MOSTRAR O BOTÃO (MESMO SEM URGÊNCIA)
  bool _temFaturaParaPagar() {
    debugPrint('🔍 _temFaturaParaPagar() - Verificando condições:');
    
    if (_faturaAtual == null) {
      debugPrint('   ❌ _faturaAtual é null');
      return false;
    }
    
    debugPrint('   📊 Fatura: ${_faturaAtual!.valorTotalFormatado} - Paga: ${_faturaAtual!.paga}');
    debugPrint('   💰 Valor restante: R\$ ${_faturaAtual!.valorRestante}');
    
    // Não mostrar se já está paga
    if (_faturaAtual!.paga) {
      debugPrint('   ❌ Fatura já está paga');
      return false;
    }
    
    // Mostrar se há valor em aberto
    if (_faturaAtual!.valorRestante <= 0.01) {
      debugPrint('   ❌ Valor restante muito baixo: ${_faturaAtual!.valorRestante}');
      return false;
    }
    
    // Não mostrar faturas muito futuras (mais de 60 dias)
    final diasRestantes = _faturaAtual!.diasAteVencimento;
    debugPrint('   📅 Dias até vencimento: $diasRestantes');
    if (diasRestantes > 60) {
      debugPrint('   ❌ Fatura muito futura (>60 dias)');
      return false;
    }
    
    debugPrint('   ✅ Fatura pode ser paga - mostrando botão PAGAR');
    return true;
  }

  /// ✅ VERIFICAR SE HÁ FATURA PAGA PARA REABRIR
  bool _temFaturaParaReabrir() {
    debugPrint('🔍 _temFaturaParaReabrir() - Verificando condições:');
    
    if (_faturaAtual == null) {
      debugPrint('   ❌ _faturaAtual é null');
      return false;
    }
    
    debugPrint('   📊 Fatura: ${_faturaAtual!.valorTotalFormatado} - Paga: ${_faturaAtual!.paga}');
    debugPrint('   💰 Valor total: R\$ ${_faturaAtual!.valorTotal}');
    
    // Mostrar apenas se está paga
    if (!_faturaAtual!.paga) {
      debugPrint('   ❌ Fatura não está paga');
      return false;
    }
    
    // Verificar se há transações efetivadas na fatura
    if (_faturaAtual!.valorTotal <= 0.01) {
      debugPrint('   ❌ Valor total muito baixo: ${_faturaAtual!.valorTotal}');
      return false;
    }
    
    debugPrint('   ✅ Fatura pode ser reaberta - mostrando botão REABRIR');
    return true;
  }

  void _mesAnterior() async {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
      _carregando = true; // Mostrar loading durante sincronização
    });
    
    // ✅ SINCRONIZAR TRANSAÇÕES DO PERÍODO APENAS SE ONLINE
    if (_syncManager.isOnline) {
      try {
        await _syncManager.syncTransactionsForPeriod(_mesAtual);
      } catch (e) {
        debugPrint('⚠️ Erro na sincronização: $e');
      }
    }
    
    _carregarDados();
  }

  void _proximoMes() async {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
      _carregando = true; // Mostrar loading durante sincronização
    });
    
    // ✅ SINCRONIZAR TRANSAÇÕES DO PERÍODO APENAS SE ONLINE
    if (_syncManager.isOnline) {
      try {
        await _syncManager.syncTransactionsForPeriod(_mesAtual);
      } catch (e) {
        debugPrint('⚠️ Erro na sincronização: $e');
      }
    }
    
    _carregarDados();
  }

  String _formatarMesAno(DateTime data) {
    final meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final ano = data.year.toString().substring(2);
    return '${meses[data.month - 1]}/$ano';
  }

  Widget _buildResumoMetricas() {
    final limite = widget.cartao.limite ?? 0;
    final disponivel = limite - _valorUtilizado;
    final percentualUtilizacao = limite > 0 ? (_valorUtilizado / limite) * 100 : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Gasto Mês Atual',
              valor: CurrencyFormatter.format(_gastoMesAtual),
              cor: _gastoMesAtual > _gastoMedio ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Economia/Excesso',
              valor: CurrencyFormatter.format(_economia),
              cor: _economia > 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Utilização',
              valor: '${percentualUtilizacao.toStringAsFixed(1)}%',
              cor: percentualUtilizacao > 80 ? Colors.red : percentualUtilizacao > 60 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaCard({
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInsights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'iP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Insights Inteligentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ..._buildInsightsReais(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInsightsReais() {
    List<Widget> insights = [];
    final limite = widget.cartao.limite ?? 0;
    final percentualUtilizacao = limite > 0 ? (_valorUtilizado / limite) * 100 : 0;
    final valorDisponivel = limite - _valorUtilizado;
    
    // Insight sobre economia/excesso
    if (_economia > 0) {
      insights.add(Text(
        '• 🎉 Parabéns! Você economizou ${CurrencyFormatter.format(_economia)} este mês comparado à sua média.',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ));
    } else {
      insights.add(Text(
        '• ⚠️ Você gastou ${CurrencyFormatter.format(_economia.abs())} a mais que sua média este mês.',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ));
    }
    
    insights.add(const SizedBox(height: 8));
    
    // Insight sobre categoria com maior gasto
    if (_gastosPorCategoria.isNotEmpty) {
      final maiorCategoria = _gastosPorCategoria.first;
      insights.add(Text(
        '• 📊 Sua categoria com maior gasto é "${maiorCategoria['categoria']}" com ${maiorCategoria['valor']}.',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ));
    }
    
    insights.add(const SizedBox(height: 16));
    
    // Seção de alertas
    insights.add(const Text(
      '⚠️ Dicas e Alertas:',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ));
    
    insights.add(const SizedBox(height: 8));
    
    // Alert sobre utilização do limite
    if (percentualUtilizacao > 80) {
      insights.add(const Text(
        '• 🚨 Atenção! Você está usando mais de 80% do seu limite.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.3,
        ),
      ));
    } else if (percentualUtilizacao > 60) {
      insights.add(const Text(
        '• 💡 Você está usando mais de 60% do seu limite. Considere moderar os gastos.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.3,
        ),
      ));
    } else {
      insights.add(Text(
        '• ✅ Boa! Você tem ${CurrencyFormatter.format(valorDisponivel)} ainda disponíveis no seu limite.',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.3,
        ),
      ));
    }
    
    // Insight sobre vencimento da fatura
    if (_faturaAtual != null) {
      final diasVencimento = _faturaAtual!.diasAteVencimento;
      if (diasVencimento <= 3 && diasVencimento >= 0) {
        insights.add(const SizedBox(height: 6));
        insights.add(const Text(
          '• ⏰ Sua fatura vence nos próximos 3 dias!',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.3,
          ),
        ));
      }
    }
    
    return insights;
  }

  Widget _buildGraficos() {
    return Column(
      children: [
        if (_evolucaoGastos.isNotEmpty) _buildGraficoEvolucao(),
        if (_evolucaoGastos.isNotEmpty) const SizedBox(height: 12),
        if (_gastosPorCategoria.isNotEmpty) _buildGraficoCategorias(),
        if (_gastosPorCategoria.isNotEmpty) const SizedBox(height: 12),
        _buildGraficoGastosPorDia(),
      ],
    );
  }

  Widget _buildGraficoEvolucao() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Evolução dos Gastos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '7 meses',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              height: 200,
              child: LineChart(
                _buildLineChartData(),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOutCubic,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    _economia > 0 ? Icons.trending_down : Icons.trending_up,
                    color: _economia > 0 ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _economia > 0 
                        ? 'Tendência de economia de ${CurrencyFormatter.format(_economia)} comparado à média'
                        : 'Gasto acima da média em ${CurrencyFormatter.format(_economia.abs())}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _economia > 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    // Normalizar valores para o gráfico
    double maxY = 0;
    for (int i = 0; i < _evolucaoGastos.length; i++) {
      final valor = _evolucaoGastos[i]['valor'] as double;
      if (valor > maxY) maxY = valor;
    }
    
    // Adicionar 20% de margem
    maxY = maxY * 1.2;
    
    return LineChartData(
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: _evolucaoGastos.asMap().entries.map((entry) {
            final index = entry.key.toDouble();
            final valor = entry.value['valor'] as double;
            return FlSpot(index, valor);
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              if (index < _evolucaoGastos.length) {
                final isAtual = _evolucaoGastos[index]['isAtual'] as bool;
                return FlDotCirclePainter(
                  radius: isAtual ? 6 : 4,
                  color: isAtual ? Colors.red : Colors.blue,
                  strokeWidth: isAtual ? 2 : 0,
                  strokeColor: Colors.white,
                );
              }
              return FlDotCirclePainter(radius: 4, color: Colors.blue);
            },
          ),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < _evolucaoGastos.length) {
                final mes = _evolucaoGastos[index]['mes'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    mes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'R\$${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black87,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index >= 0 && index < _evolucaoGastos.length) {
                final mes = _evolucaoGastos[index]['mes'] as String;
                final isAtual = _evolucaoGastos[index]['isAtual'] as bool;
                return LineTooltipItem(
                  '$mes${isAtual ? ' (Atual)' : ''}\n${CurrencyFormatter.format(spot.y)}',
                  TextStyle(
                    color: isAtual ? Colors.red[200] : Colors.white,
                    fontWeight: isAtual ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300],
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }

  Widget _buildGraficoCategorias() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gastos por Categoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                // Gráfico de pizza
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      _buildPieChartData(),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeInOutCubic,
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Legenda
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._gastosPorCategoria.map((categoria) {
                        final cores = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];
                        final index = _gastosPorCategoria.indexOf(categoria);
                        final cor = cores[index % cores.length];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: cor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoria['categoria']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      categoria['valor']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PieChartData _buildPieChartData() {
    final cores = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];
    final total = _gastosPorCategoria.fold(0.0, (sum, cat) => sum + CurrencyFormatter.parseFromString(cat['valor']!));
    
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: _gastosPorCategoria.take(6).map((categoria) {
        final index = _gastosPorCategoria.indexOf(categoria);
        final cor = cores[index % cores.length];
        final valor = CurrencyFormatter.parseFromString(categoria['valor']!);
        final percentual = (valor / total) * 100;
        
        return PieChartSectionData(
          color: cor,
          value: valor,
          title: '${percentual.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGraficoGastosPorDia() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gastos por Dia da Semana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              height: 200,
              child: BarChart(
                _buildBarChartData(),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOutCubic,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _gastosPorDiaReais.isNotEmpty 
                        ? 'Maior gasto: ${_gastosPorDiaReais.reduce((a, b) => a['valor'] > b['valor'] ? a : b)['dia']}'
                        : 'Dados não disponíveis',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildBarChartData() {
    final ranking = _gastosPorDiaReais.asMap().entries.toList()
      ..sort((a, b) => (b.value['valor'] as double).compareTo(a.value['valor'] as double));

    return BarChartData(
      maxY: _gastosPorDiaReais.isEmpty ? 100 : _gastosPorDiaReais.map((e) => e['valor'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
      barGroups: _gastosPorDiaReais.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final valor = data['valor'] as double;
        
        // Determinar a cor baseada no ranking
        final isTop1 = ranking[0].value == data;
        final isTop3 = ranking.take(3).any((r) => r.value == data);
        
        Color cor = Colors.grey;
        if (isTop1) {
          cor = Colors.red;
        } else if (isTop3) {
          cor = Colors.orange;
        } else {
          cor = Colors.green;
        }
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: valor,
              color: cor,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'R\$${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < _gastosPorDiaReais.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _gastosPorDiaReais[index]['dia'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _gastosPorDiaReais.isEmpty ? 20 : _gastosPorDiaReais.map((e) => e['valor'] as double).reduce((a, b) => a > b ? a : b) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300],
            strokeWidth: 1,
            dashArray: [3, 3],
          );
        },
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.black87,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (groupIndex < _gastosPorDiaReais.length) {
              final data = _gastosPorDiaReais[groupIndex];
              final dia = data['dia'] as String;
              final valor = data['valor'] as double;
              
              // Determinar o ranking
              final ranking = _gastosPorDiaReais.asMap().entries.toList()
                ..sort((a, b) => (b.value['valor'] as double).compareTo(a.value['valor'] as double));
              final posicao = ranking.indexWhere((r) => r.value == data) + 1;
              
              return BarTooltipItem(
                '$dia\n${CurrencyFormatter.format(valor)}\n${posicao}º lugar',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildBotaoVoltar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 8),
              Text(
                'Voltar aos Cartões',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 NOVA FUNCIONALIDADE: Buscar fatura mais prioritária para pagamento
  /// - Prioridade 1: Faturas vencidas (mais antiga primeiro)
  /// - Prioridade 2: Faturas que vencem em até 7 dias
  /// - Prioridade 3: Demais faturas em aberto
  Future<FaturaModel?> _buscarFaturaMaisPrioritaria() async {
    try {
      debugPrint('🔍 Buscando fatura mais prioritária para cartão: ${widget.cartao.id}');
      
      // Buscar faturas dos últimos 6 meses + próximos 3 meses
      final hoje = DateTime.now();
      final inicioRange = DateTime(hoje.year, hoje.month - 6, 1);
      final fimRange = DateTime(hoje.year, hoje.month + 3, 30);
      
      final faturas = <FaturaModel>[];
      
      // Buscar faturas do período
      var mesAtual = inicioRange;
      while (mesAtual.isBefore(fimRange)) {
        try {
          final faturasMes = await _cartaoDataService.buscarFaturasCartao(
            widget.cartao.id, 
            mesReferencia: mesAtual
          );
          
          if (faturasMes.isNotEmpty) {
            faturas.addAll(faturasMes);
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao buscar faturas do mês ${mesAtual.month}/${mesAtual.year}: $e');
        }
        
        mesAtual = DateTime(mesAtual.year, mesAtual.month + 1, 1);
      }
      
      debugPrint('📋 Total de faturas encontradas: ${faturas.length}');
      
      // Filtrar apenas faturas não pagas com saldo > R$ 0,01
      final faturasEmAberto = faturas.where((fatura) {
        final temSaldo = fatura.valorRestante > 0.01;
        final naoPaga = !fatura.paga;
        return temSaldo && naoPaga;
      }).toList();
      
      debugPrint('💰 Faturas em aberto: ${faturasEmAberto.length}');
      
      if (faturasEmAberto.isEmpty) {
        debugPrint('✅ Nenhuma fatura em aberto encontrada');
        return null;
      }
      
      // Classificar faturas por prioridade
      faturasEmAberto.sort((a, b) {
        final diasA = a.diasAteVencimento;
        final diasB = b.diasAteVencimento;
        
        // Prioridade 1: Faturas vencidas (dias negativos) - mais antiga primeiro
        final aVencida = diasA < 0;
        final bVencida = diasB < 0;
        
        if (aVencida && bVencida) {
          return diasA.compareTo(diasB); // Mais antiga (menor valor) primeiro
        }
        
        if (aVencida && !bVencida) return -1; // A vencida tem prioridade
        if (!aVencida && bVencida) return 1;  // B vencida tem prioridade
        
        // Prioridade 2: Faturas que vencem em até 7 dias
        final aUrgente = diasA >= 0 && diasA <= 7;
        final bUrgente = diasB >= 0 && diasB <= 7;
        
        if (aUrgente && bUrgente) {
          return diasA.compareTo(diasB); // Que vence antes tem prioridade
        }
        
        if (aUrgente && !bUrgente) return -1; // A urgente tem prioridade
        if (!aUrgente && bUrgente) return 1;  // B urgente tem prioridade
        
        // Prioridade 3: Demais faturas por data de vencimento
        return diasA.compareTo(diasB);
      });
      
      final faturaPrioritaria = faturasEmAberto.first;
      final diasVencimento = faturaPrioritaria.diasAteVencimento;
      
      String prioridade;
      if (diasVencimento < 0) {
        prioridade = "VENCIDA (${diasVencimento.abs()} dias atrás)";
      } else if (diasVencimento <= 7) {
        prioridade = "URGENTE (vence em $diasVencimento dias)";
      } else {
        prioridade = "NORMAL (vence em $diasVencimento dias)";
      }
      
      debugPrint('🎯 Fatura mais prioritária: ${faturaPrioritaria.id}');
      debugPrint('📅 Vencimento: ${faturaPrioritaria.dataVencimentoFormatada}');
      debugPrint('⚡ Prioridade: $prioridade');
      debugPrint('💰 Valor: ${faturaPrioritaria.valorTotalFormatado}');
      
      return faturaPrioritaria;
      
    } catch (e) {
      debugPrint('❌ Erro ao buscar fatura prioritária: $e');
      return null;
    }
  }

  void _abrirModalAdicionarCartao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartaoFormPage(modo: 'criar'),
      ),
    ).then((result) {
      if (result != null) {
        _carregarDados();
      }
    });
  }

  void _abrirPagamentoFatura() async {
    debugPrint('🚀 [DEBUG] _abrirPagamentoFatura chamado');
    
    // 🔥 NOVA LÓGICA: Buscar fatura mais prioritária para pagamento
    try {
      final faturaPrioritaria = await _buscarFaturaMaisPrioritaria();
      
      if (faturaPrioritaria == null) {
        debugPrint('✅ [DEBUG] Nenhuma fatura para pagamento encontrada');
        
        // Mensagem sutil na base da tela
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nenhuma fatura a pagar no momento',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      debugPrint('✅ [DEBUG] Fatura prioritária encontrada: ${faturaPrioritaria.id}');
      debugPrint('💰 [DEBUG] Valor da fatura: ${faturaPrioritaria.valorTotalFormatado}');
      debugPrint('📅 [DEBUG] Vencimento: ${faturaPrioritaria.dataVencimentoFormatada}');
      
      // ✅ NAVEGAÇÃO PARA PÁGINA COMPLETA DE PAGAMENTO
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PagamentoFaturaPage(
            cartao: widget.cartao,
            fatura: faturaPrioritaria,
          ),
        ),
      );

      // Se retornou sucesso, recarregar dados com feedback positivo
      if (resultado == true) {
        debugPrint('✅ Pagamento processado com sucesso - recarregando dados');
        
        // Feedback positivo após pagamento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pagamento realizado! Atualizando dados...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
        
        await _carregarDados();
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao buscar fatura prioritária: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Não foi possível carregar faturas no momento',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// ✅ REABRIR FATURA PAGA (específica do mês atual)
  void _reabrirFatura() async {
    debugPrint('🎯 UI: _reabrirFatura INICIADA');
    debugPrint('🎯 UI: _faturaAtual = ${_faturaAtual?.id}');
    
    if (_faturaAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nenhuma fatura encontrada para ${_formatarMesAno(_mesAtual)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Verificar se realmente está paga
    if (!_faturaAtual!.paga) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Esta fatura ainda não foi paga',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Mostrar confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reabrir Fatura ${_formatarMesAno(_mesAtual)}'),
        content: Text(
          'Deseja reabrir a fatura de ${_faturaAtual!.dataVencimentoFormatada} (${_faturaAtual!.valorTotalFormatado})?\n\n'
          '• Isso irá desfazer o pagamento\n'
          '• As transações voltarão a ficar pendentes\n'
          '• Você poderá editar e pagar novamente',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reabrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmacao != true) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      debugPrint('🔄 Reabrindo fatura: ${_faturaAtual!.id}');

      // Chamar serviço para reabrir fatura
      final resultado = await FaturaOperationsService.instance.reabrirFatura(
        cartaoId: widget.cartao.id,
        faturaVencimento: _faturaAtual!.dataVencimento.toIso8601String().split('T')[0],
      );

      // Fechar loading
      Navigator.pop(context);

      if (resultado['success'] == true) {
        // Feedback positivo e elegante
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Fatura reaberta! Sincronizando dados...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );

        // Pequeno delay para o usuário ver a mensagem antes da sincronização
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Recarregar dados silenciosamente
        await _carregarDados();
        
        // Confirmação final sutil depois que os dados carregaram
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Dados atualizados', style: TextStyle(fontSize: 13)),
                ],
              ),
              backgroundColor: Colors.blue[600],
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(resultado['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('❌ Erro ao reabrir fatura: $e');
      
      // Verificar se o erro é realmente crítico ou apenas warning
      final errorMsg = e.toString().toLowerCase();
      final isCriticalError = !errorMsg.contains('success') && !errorMsg.contains('completed');
      
      if (isCriticalError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Houve um problema ao reabrir a fatura. Tente novamente.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () => _reabrirFatura(),
            ),
          ),
        );
      } else {
        // Se não é erro crítico, apenas recarregar dados
        await _carregarDados();
      }
    }
  }

  void _editarCartao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartaoFormPage(modo: 'editar', cartao: widget.cartao),
      ),
    ).then((result) {
      if (result != null) {
        _carregarDados();
      }
    });
  }

  void _verFaturas() {
    debugPrint('📋 Navegando para lista de faturas');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaturasListPage(cartao: widget.cartao),
      ),
    );
  }

  void _verExtrato() {
    // TODO: Implementar página de extrato do cartão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extrato do cartão em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _adicionarDespesa() {
    // TODO: Implementar modal de nova despesa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adicionar despesa em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _arquivarCartao() {
    // TODO: Implementar arquivamento do cartão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arquivar cartão em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _mostrarEmDesenvolvimento() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }


}