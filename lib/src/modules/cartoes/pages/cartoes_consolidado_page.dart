import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/cartao_model.dart';
import '../models/fatura_model.dart';
import '../widgets/cartao_card.dart';
import '../widgets/fatura_selector.dart';
import '../services/cartao_service.dart';
import '../services/cartao_data_service.dart';
import '../services/fatura_service.dart';
import '../services/fatura_detection_service.dart';
import 'gestao_cartoes_mobile.dart';
import 'cartao_form_page.dart';
import 'cartoes_sugeridos_page.dart';
import 'cartoes_arquivados_page.dart';
import '../../../database/local_database.dart';
import 'despesa_cartao_page.dart';
import 'pagamento_fatura_page.dart';
import '../../../routes/main_navigation.dart';
import '../../../shared/components/ui/app_button.dart';
import '../../transacoes/pages/transacao_form_page.dart';
import '../../transacoes/pages/transferencia_form_page.dart';
import '../../transacoes/pages/transacoes_page.dart';
import '../../relatorios/services/graficos_categoria_service.dart';
import '../../../shared/services/navigation_context_service.dart';

/// Página principal de cartões com design moderno
/// Baseada na tela mais bonita do app - modo consolidado + empilhado
class CartoesConsolidadoPage extends StatefulWidget {
  const CartoesConsolidadoPage({super.key});

  @override
  State<CartoesConsolidadoPage> createState() => _CartoesConsolidadoPageState();
}

class _CartoesConsolidadoPageState extends State<CartoesConsolidadoPage> with SingleTickerProviderStateMixin {
  // Estado da página
  String _viewMode = 'consolidado'; // consolidado, empilhado
  DateTime _periodoAtual = DateTime.now();
  bool _carregando = true;
  String? _erro;

  // === CONTROLE DO FAB ===
  bool _fabExpanded = false;

  // === CONTROLE DA ORDENAÇÃO ===
  String _ordenacao = 'padrao'; // 'padrao', 'nome_az', 'nome_za', 'gasto_maior', 'gasto_menor'

  // Dados consolidados
  double _totalUtilizado = 0.0;
  double _limiteTotal = 0.0;
  int _cartoesAtivos = 0;
  int _faturasVencendo = 0;
  int _faturasVencidas = 0; // ✅ NOVA: Faturas vencidas de outros meses
  List<CartaoModel> _cartoes = [];
  final Map<String, FaturaModel?> _faturasAtuais = {};

  // === GRÁFICO DE CATEGORIAS ===
  final GraficosCategoriaService _graficosService = GraficosCategoriaService.instance;
  List<Map<String, dynamic>> _gastosPorCategoria = [];
  int _touchedIndex = -1;
  final Map<String, double> _valoresUtilizados = {};
  final Map<String, double> _gastosPeriodo = {};
  final Map<String, double> _proximasFaturas = {};

  // Serviços
  final CartaoService _cartaoService = CartaoService.instance;
  final CartaoDataService _cartaoDataService = CartaoDataService.instance;
  final FaturaService _faturaService = FaturaService();
  final FaturaDetectionService _faturaDetectionService = FaturaDetectionService.instance;

  // Animação
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _carregarDados();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Carregar cartões ativos
      _cartoes = await _cartaoService.listarCartoesAtivos();

      if (_cartoes.isEmpty) {
        setState(() {
          _carregando = false;
        });
        return;
      }

      // Carregar dados consolidados
      await _carregarDadosConsolidados();

      // Carregar dados do gráfico de categorias
      await _carregarDadosGraficoCategorias();

      // Ordenar cartões por maior gasto primeiro
      _ordenarCartoesPorGasto();

      setState(() {
        _carregando = false;
      });

      _animationController.forward();
      
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() {
        _erro = 'Erro ao carregar cartões: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _carregarDadosConsolidados() async {
    // ✅ USAR MÉTODO CORRETO DO CartaoDataService
    final totais = await _cartaoDataService.calcularTotaisCartoes();

    _totalUtilizado = totais['totalUtilizado'] ?? 0.0;
    _limiteTotal = totais['limiteTotal'] ?? 0.0;
    _cartoesAtivos = 0;
    _faturasVencendo = 0;
    _faturasVencidas = 0;

    final mesAtual = DateFormat('yyyy-MM').format(_periodoAtual);

    for (final cartao in _cartoes) {
      if (!cartao.ativo) {
        continue;
      }

      _cartoesAtivos++;

      try {
        final valorUtilizado = await _cartaoDataService.calcularLimiteUtilizado(cartao.id);
        _valoresUtilizados[cartao.id] = valorUtilizado;

        final gastoPeriodo = await _buscarGastoPeriodoCartao(cartao.id, mesAtual);
        _gastosPeriodo[cartao.id] = gastoPeriodo;

        final proximaMes = DateTime(_periodoAtual.year, _periodoAtual.month + 1);
        final proximoMesStr = DateFormat('yyyy-MM').format(proximaMes);
        final proximaFatura = await _buscarGastoPeriodoCartao(cartao.id, proximoMesStr);
        _proximasFaturas[cartao.id] = proximaFatura;

        final faturaAtual = await _faturaDetectionService.detectarFaturaAtual(
          cartao,
          mesReferencia: _periodoAtual
        );

        _faturasAtuais[cartao.id] = faturaAtual;

        if (faturaAtual != null) {
          // Verificar se fatura está vencendo (próximos 5 dias) E tem valor em aberto
          if (!faturaAtual.paga && faturaAtual.valorRestante > 0.01 && faturaAtual.isProximaVencimento) {
            _faturasVencendo++;
          }

          // ✅ Verificar faturas vencidas de outros meses
          await _verificarFaturasVencidasOutrosMeses(cartao.id);
        }

      } catch (e) {
        debugPrint('❌ Erro ao carregar dados do cartão ${cartao.nome}: $e');
        // Em caso de erro, usar dados estimados
        final valorEstimado = cartao.limite * 0.35;
        _valoresUtilizados[cartao.id] = valorEstimado;
        _gastosPeriodo[cartao.id] = valorEstimado;
      }
    }
  }

  /// 📊 Ordenar cartões por maior gasto primeiro, depois alfabético
  /// 📊 APLICAR ORDENAÇÃO NOS CARTÕES
  List<CartaoModel> _aplicarOrdenacao(List<CartaoModel> cartoes) {
    final cartoesOrdenados = List<CartaoModel>.from(cartoes);

    switch (_ordenacao) {
      case 'nome_az':
        cartoesOrdenados.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        break;
      case 'nome_za':
        cartoesOrdenados.sort((a, b) => b.nome.toLowerCase().compareTo(a.nome.toLowerCase()));
        break;
      case 'gasto_maior':
        cartoesOrdenados.sort((a, b) {
          final gastoA = _gastosPeriodo[a.id] ?? 0.0;
          final gastoB = _gastosPeriodo[b.id] ?? 0.0;
          return gastoB.compareTo(gastoA);
        });
        break;
      case 'gasto_menor':
        cartoesOrdenados.sort((a, b) {
          final gastoA = _gastosPeriodo[a.id] ?? 0.0;
          final gastoB = _gastosPeriodo[b.id] ?? 0.0;
          return gastoA.compareTo(gastoB);
        });
        break;
      case 'padrao':
      default:
        // Mantém ordem padrão (por ID ou ordem de inserção)
        break;
    }

    return cartoesOrdenados;
  }

  void _ordenarCartoesPorGasto() {
    _cartoes.sort((a, b) {
      final gastoA = _gastosPeriodo[a.id] ?? 0.0;
      final gastoB = _gastosPeriodo[b.id] ?? 0.0;

      // Se ambos têm gasto, ordenar por maior gasto
      if (gastoA > 0 && gastoB > 0) {
        return gastoB.compareTo(gastoA);
      }

      // Se apenas um tem gasto, ele vem primeiro
      if (gastoA > 0) return -1;
      if (gastoB > 0) return 1;

      // Se nenhum tem gasto, ordenar alfabeticamente
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
  }

  /// 📊 Carregar dados do gráfico de categorias dos cartões
  Future<void> _carregarDadosGraficoCategorias() async {
    try {
      final dataInicio = DateTime(_periodoAtual.year, _periodoAtual.month, 1);
      final dataFim = DateTime(_periodoAtual.year, _periodoAtual.month + 1, 0);

      _gastosPorCategoria = await _graficosService.buscarDespesasPorCategoria(
        dataInicio,
        dataFim,
      );
    } catch (e) {
      debugPrint('❌ Erro ao carregar gráfico de categorias: $e');
      _gastosPorCategoria = [];
    }
  }

  /// 📊 Constrói seções do PieChart com animações de toque
  List<PieChartSectionData> _buildPieChartSections() {
    final cores = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];
    final total = _gastosPorCategoria.fold(0.0, (sum, cat) => sum + (cat['total_valor'] as double));

    return _gastosPorCategoria.take(6).map((categoria) {
      final index = _gastosPorCategoria.indexOf(categoria);
      final cor = cores[index % cores.length];
      final valor = (categoria['total_valor'] as double);
      final percentual = total > 0 ? (valor / total) * 100 : 0;
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: isTouched ? cor.withValues(alpha: 0.8) : cor,
        value: valor,
        title: '${percentual.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: isTouched ? [
            const Shadow(
              color: Colors.black45,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ] : null,
        ),
        borderSide: BorderSide(
          color: isTouched ? Colors.white : Colors.transparent,
          width: isTouched ? 2 : 0,
        ),
      );
    }).toList();
  }

  /// 🧭 Navegar para TransacoesPage com filtro de categoria
  Future<void> _navegarParaTransacoesComFiltroCategoria(String nomeCategoria) async {
    debugPrint('🧭 Navegando para transações com filtro: categoria=$nomeCategoria, cartões');

    // Navegar diretamente para TransacoesPage com filtros (preserva navegação anterior)
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransacoesPage(
            modoInicial: TransacoesPageMode.cartoes, // Modo cartões
            filtrosIniciais: {
              // Filtrar por categoria específica se necessário
              // Nota: o modo cartões já filtra automaticamente por cartões
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBarOriginal(),
      body: Stack(
        children: [
          _carregando
            ? _buildLoadingState()
            : _erro != null
              ? _buildErrorState()
              : _cartoes.isEmpty
                ? _buildEmptyState()
                : _buildContent(),
          _buildFABOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.roxoHeader,
        foregroundColor: Colors.white,
        elevation: _fabExpanded ? 8 : 6,
        onPressed: () {
          setState(() => _fabExpanded = !_fabExpanded);
        },
        child: AnimatedRotation(
          turns: _fabExpanded ? 0.125 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(_fabExpanded ? Icons.close : Icons.add),
        ),
      ),
    );
  }

  /// Header com seletor de período (sem AppBar)
  Widget _buildHeaderComSeletor() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.roxoHeader,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildSeletorPeriodo(),
    );
  }

  /// Seletor de período extraído da antiga AppBar
  Widget _buildSeletorPeriodo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: _periodoAnterior,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(52),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatarPeriodo(_periodoAtual),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: _proximoPeriodo,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }

  /// AppBar original (manter para referência se precisar)
  PreferredSizeWidget _buildAppBarOriginal() {
    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      title: const Text(
        'Gerenciar Cartões',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _viewMode == 'consolidado' ? Icons.view_module : Icons.view_list,
            color: Colors.white,
          ),
          onPressed: _toggleViewMode,
          tooltip: _viewMode == 'consolidado' ? 'Cards pequenos' : 'Cards grandes',
        ),

        IconButton(
          icon: const Icon(Icons.credit_card, color: Colors.white),
          onPressed: _abrirCartoesSugeridos,
          tooltip: 'Importar Cartões',
        ),

        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _abrirNovoCartao,
          tooltip: 'Criar Novo Cartão',
        ),

        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: const Icon(Icons.more_vert, color: Colors.white),
          tooltip: 'Menu',
          itemBuilder: (context) => [
            // ✅ OPÇÕES FUNCIONAIS
            // TODO: Implementar busca
            // const PopupMenuItem(
            //   value: 'buscar',
            //   child: Row(
            //     children: [
            //       Icon(Icons.search),
            //       SizedBox(width: 8),
            //       Text('Buscar'),
            //     ],
            //   ),
            // ),
            // TODO: Implementar gestão geral
            // const PopupMenuItem(
            //   value: 'gestao_geral',
            //   child: Row(
            //     children: [
            //       Icon(Icons.analytics),
            //       SizedBox(width: 8),
            //       Text('Gestão Geral'),
            //     ],
            //   ),
            // ),
            // Ver Faturas
            const PopupMenuItem(
              value: 'ver_faturas',
              child: Row(
                children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 8),
                  Text('Ver Faturas'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'nova_despesa',
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart),
                  SizedBox(width: 8),
                  Text('Nova Despesa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'arquivados',
              child: Row(
                children: [
                  Icon(Icons.archive),
                  SizedBox(width: 8),
                  Text('Cartões Arquivados'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Atualizar'),
                ],
              ),
            ),
            // TODO: Implementar configurações
            // const PopupMenuItem(
            //   value: 'config',
            //   child: Row(
            //     children: [
            //       Icon(Icons.settings),
            //       SizedBox(width: 8),
            //       Text('Configurações'),
            //     ],
            //   ),
            // ),

            // ➖ Divisor para ordenação
            const PopupMenuDivider(),

            // 📋 Header de ordenação
            PopupMenuItem(
              enabled: false,
              child: Text(
                'ORDENAÇÃO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // 🔤 Padrão
            PopupMenuItem(
              value: 'ordenar_padrao',
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: _ordenacao == 'padrao' ? Colors.blue : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Padrão',
                    style: TextStyle(
                      color: _ordenacao == 'padrao' ? Colors.blue : null,
                      fontWeight: _ordenacao == 'padrao' ? FontWeight.bold : null,
                    ),
                  ),
                  if (_ordenacao == 'padrao') ...[
                    const Spacer(),
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                  ],
                ],
              ),
            ),

            // 🔤 A-Z
            PopupMenuItem(
              value: 'ordenar_nome_az',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha,
                    color: _ordenacao == 'nome_az' ? Colors.blue : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nome A-Z',
                    style: TextStyle(
                      color: _ordenacao == 'nome_az' ? Colors.blue : null,
                      fontWeight: _ordenacao == 'nome_az' ? FontWeight.bold : null,
                    ),
                  ),
                  if (_ordenacao == 'nome_az') ...[
                    const Spacer(),
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                  ],
                ],
              ),
            ),

            // 🔤 Z-A
            PopupMenuItem(
              value: 'ordenar_nome_za',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha,
                    color: _ordenacao == 'nome_za' ? Colors.blue : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nome Z-A',
                    style: TextStyle(
                      color: _ordenacao == 'nome_za' ? Colors.blue : null,
                      fontWeight: _ordenacao == 'nome_za' ? FontWeight.bold : null,
                    ),
                  ),
                  if (_ordenacao == 'nome_za') ...[
                    const Spacer(),
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                  ],
                ],
              ),
            ),

            // 💰 Maior gasto
            PopupMenuItem(
              value: 'ordenar_gasto_maior',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    color: _ordenacao == 'gasto_maior' ? Colors.blue : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Maior Gasto',
                    style: TextStyle(
                      color: _ordenacao == 'gasto_maior' ? Colors.blue : null,
                      fontWeight: _ordenacao == 'gasto_maior' ? FontWeight.bold : null,
                    ),
                  ),
                  if (_ordenacao == 'gasto_maior') ...[
                    const Spacer(),
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                  ],
                ],
              ),
            ),

            // 💰 Menor gasto
            PopupMenuItem(
              value: 'ordenar_gasto_menor',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: _ordenacao == 'gasto_menor' ? Colors.blue : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Menor Gasto',
                    style: TextStyle(
                      color: _ordenacao == 'gasto_menor' ? Colors.blue : null,
                      fontWeight: _ordenacao == 'gasto_menor' ? FontWeight.bold : null,
                    ),
                  ),
                  if (_ordenacao == 'gasto_menor') ...[
                    const Spacer(),
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ Período navegável (como no offline)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _periodoAnterior,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatarPeriodo(_periodoAtual),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _proximoPeriodo,
                  ),
                ],
              ),
              
              // ✅ Total de gastos do período
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Faturas',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  _carregando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        CurrencyFormatter.format(_calcularTotalGastosPeriodo()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, String value, IconData icon, {bool isSmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: isSmall ? 14 : 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmall ? 12 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _viewMode == 'consolidado'
          ? _buildModoConsolidado()
          : _buildModoEmpilhado(),
    );
  }

  /// Header do modo consolidado
  Widget _buildHeaderConsolidado() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primeira linha - Valores principais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total Utilizado
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Utilizado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_totalUtilizado),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              // Limite Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Limite Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_limiteTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Segunda linha - Status dos cartões e faturas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status dos cartões
              Text(
                '$_cartoesAtivos cartão${_cartoesAtivos != 1 ? 'es' : ''} ativo${_cartoesAtivos != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              
              // Status das faturas
              Text(
                _buildStatusFaturas(),
                style: TextStyle(
                  fontSize: 12,
                  color: _faturasVencidas > 0 ? Colors.red : 
                         _faturasVencendo > 0 ? Colors.orange : Colors.grey,
                  fontWeight: (_faturasVencendo > 0 || _faturasVencidas > 0) ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barra de progresso de utilização
          if (_limiteTotal > 0) ...[
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_totalUtilizado / _limiteTotal).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _totalUtilizado / _limiteTotal > 0.8
                          ? Colors.red
                          : _totalUtilizado / _limiteTotal > 0.6
                              ? Colors.orange
                              : Colors.green,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((_totalUtilizado / _limiteTotal) * 100).toStringAsFixed(1)}% do limite total utilizado',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  String _buildStatusFaturas() {
    final List<String> status = [];
    
    if (_faturasVencendo > 0) {
      status.add('$_faturasVencendo fatura${_faturasVencendo != 1 ? 's' : ''} vencendo');
    }
    
    if (_faturasVencidas > 0) {
      status.add('$_faturasVencidas vencida${_faturasVencidas != 1 ? 's' : ''}');
    }
    
    if (status.isEmpty) {
      return 'Nenhuma fatura vencendo';
    }
    
    return status.join(' | ');
  }

  Widget _buildModoConsolidado() {
    final cartoesOrdenados = _aplicarOrdenacao(_cartoes);
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: cartoesOrdenados.length + 2, // +2 para header + botões
        itemBuilder: (context, index) {
          // Primeiro item é o header
          if (index == 0) {
            return _buildHeaderConsolidado();
          }

          // Último item são os botões
          if (index == cartoesOrdenados.length + 1) {
            return _buildBotoesInferiores();
          }

          // Demais itens são os cartões
          final cartao = cartoesOrdenados[index - 1];
          final valorUtilizadoUI = _valoresUtilizados[cartao.id] ?? 0.0;
          final proximaFaturaUI = _proximasFaturas[cartao.id] ?? 0.0;

          return CartaoCard(
            cartao: cartao,
            valorUtilizado: valorUtilizadoUI,
            gastoPeriodo: proximaFaturaUI, // Agora é próxima fatura
            periodoAtual: _formatarProximoPeriodo(_periodoAtual), // Próximo mês
            faturaAtual: _faturasAtuais[cartao.id],
            onPagarFatura: () => _pagarFatura(cartao),
            onTap: () => _abrirGestaoCartao(cartao),
            onMenuAction: (action) => _executarAcaoCartao(action, cartao),
          );
        },
      ),
    );
  }

  Widget _buildModoEmpilhado() {
    final cartoesOrdenados = _aplicarOrdenacao(_cartoes);
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: cartoesOrdenados.length + 2, // +2 para header + botões
        itemBuilder: (context, index) {
          // Primeiro item é o header
          if (index == 0) {
            return _buildHeaderConsolidado();
          }

          // Último item são os botões
          if (index == cartoesOrdenados.length + 1) {
            return _buildBotoesInferiores();
          }

          // Demais itens são os mini cards
          final cartao = cartoesOrdenados[index - 1];
          return CartaoCard(
            cartao: cartao,
            isCompact: true,
            valorUtilizado: _valoresUtilizados[cartao.id] ?? 0.0,
            gastoPeriodo: _gastosPeriodo[cartao.id] ?? 0.0,
            onTap: () => _abrirGestaoCartao(cartao),
            onMenuAction: (action) => _executarAcaoCartao(action, cartao),
          );
        },
      ),
    );
  }

  /// 🆕 MINI CARD COMPACTO - NOME + GASTO DO MÊS

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'Carregando cartões...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _erro!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregarDados,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum cartão encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Comece adicionando seus cartões de crédito para controlar suas faturas e gastos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          
          // Botão PRINCIPAL - Importar cartões (seguindo estratégia do iPoupei Device)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: _abrirCartoesSugeridos,
              icon: const Icon(Icons.download),
              label: const Text(
                'Importar Cartões Populares',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxoHeader,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botão SECUNDÁRIO - Criar personalizado (menos destaque)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: _abrirNovoCartao,
              icon: const Icon(Icons.add),
              label: const Text(
                'Criar Cartão Personalizado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.roxoHeader,
                side: const BorderSide(color: AppColors.roxoHeader, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 FLOATING ACTION BUTTON COM MENU DE OPÇÕES
  /// 🎯 OVERLAY E MENU DO FAB (COBRE TELA TODA)
  Widget _buildFABOverlay() {
    if (_carregando || !_fabExpanded) return const SizedBox.shrink();

    return Stack(
      children: [
        // Overlay transparente cobrindo toda a tela
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _fabExpanded = false),
            child: Container(
              color: Colors.black.withAlpha(78),
            ),
          ),
        ),

        // Menu de opções expandido
        Positioned(
          right: 16,
          bottom: 80, // Acima do FAB principal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFABOption(
                icon: Icons.credit_card,
                label: 'Novo Cartão',
                color: Colors.purple,
                onTap: _navegarParaNovoCartaoFab,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.swap_horiz,
                label: 'Transferência',
                color: Colors.blue,
                onTap: _navegarParaNovaTransferencia,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.add,
                label: 'Receita',
                color: AppColors.verdeSucesso,
                onTap: _navegarParaNovaReceita,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.remove,
                label: 'Despesa',
                color: AppColors.vermelhoErro,
                onTap: _navegarParaNovaDespesaFab,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.shopping_bag,
                label: 'Despesa Cartão',
                color: Colors.orange,
                onTap: _navegarParaNovaDespesaCartaoFab,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔧 OPÇÃO DO FAB
  Widget _buildFABOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(52),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.cinzaEscuro,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Botão circular
        Material(
          color: color,
          elevation: 4,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == 'consolidado' ? 'empilhado' : 'consolidado';
    });
    
    // Reiniciar animação
    _animationController.reset();
    _animationController.forward();
  }

  // ✅ Métodos de navegação de período
  void _periodoAnterior() async {
    setState(() {
      _periodoAtual = DateTime(_periodoAtual.year, _periodoAtual.month - 1);
    });
    await _carregarDados();
  }

  void _proximoPeriodo() async {
    setState(() {
      _periodoAtual = DateTime(_periodoAtual.year, _periodoAtual.month + 1);
    });
    await _carregarDados();
  }

  String _formatarPeriodo(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  String _formatarProximoPeriodo(DateTime data) {
    final proximaMes = DateTime(data.year, data.month + 1);
    return _formatarPeriodo(proximaMes);
  }


  void _abrirGestaoCartao(CartaoModel cartao) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestaoCartoesMobilePage(cartao: cartao),
      ),
    ).then((_) {
      // Recarregar dados ao voltar
      _carregarDados();
    });
  }

  void _abrirNovoCartao() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartaoFormPage(modo: 'criar'),
      ),
    );

    if (result != null) {
      _carregarDados();
    }
  }

  void _abrirCartoesSugeridos() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartoesSugeridosPage(),
      ),
    );

    // Se cartões foram importados, recarregar dados
    if (result == true) {
      _carregarDados();
    }
  }

  void _executarAcaoCartao(String action, CartaoModel cartao) {
    switch (action) {
      case 'editar':
      case 'gestao':
        _editarCartao(cartao);
        break;
      case 'pagar':
      case 'pagar_fatura':
        _pagarFatura(cartao);
        break;
      case 'arquivar':
        _arquivarCartao(cartao);
        break;
      case 'excluir':
        _excluirCartao(cartao);
        break;
      case 'extrato':
        _mostrarExtrato(cartao);
        break;
      case 'ver_faturas':
        _verFaturas(cartao);
        break;
      case 'add_despesa':
        _adicionarDespesaCartao(cartao);
        break;
    }
  }

  void _mostrarExtrato(CartaoModel cartao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Extrato do ${cartao.nome} em desenvolvimento')),
    );
  }

  void _verFaturas(CartaoModel cartao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Faturas do ${cartao.nome} em desenvolvimento')),
    );
  }

  void _adicionarDespesaCartao(CartaoModel cartao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adicionar despesa ao ${cartao.nome} em desenvolvimento')),
    );
  }

  void _editarCartao(CartaoModel cartao) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartaoFormPage(modo: 'editar', cartao: cartao),
      ),
    ).then((result) {
      if (result != null) {
        _carregarDados();
      }
    });
  }

  void _pagarFatura(CartaoModel cartao) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Buscando faturas...'),
          ],
        ),
      ),
    );
    
    try {
      // ✅ NOVA LÓGICA: Buscar fatura mais prioritária
      final faturaPrioritaria = await _buscarFaturaMaisPrioritaria(cartao);
      
      // Fechar loading
      Navigator.pop(context);
      
      if (faturaPrioritaria == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nenhuma fatura em aberto encontrada para ${cartao.nome}'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      // Navegar para a fatura mais prioritária
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PagamentoFaturaPage(
            fatura: faturaPrioritaria,
            cartao: cartao,
          ),
        ),
      ).then((result) {
        // Se o pagamento foi realizado com sucesso, recarregar dados
        if (result == true) {
          _carregarDados();
        }
      });

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('❌ Erro ao pagar fatura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar faturas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarModalPagamento(CartaoModel cartao, FaturaModel fatura) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payment, color: Colors.green),
            const SizedBox(width: 8),
            Text('Pagar Fatura - ${cartao.nome}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valor Total: R\$ ${fatura.valorTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text('Vencimento: ${fatura.dataVencimento.toString().split(' ')[0]}'),
            Text('Status: ${fatura.status}'),
            if (fatura.valorPago > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Valor já pago: R\$ ${fatura.valorPago.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.blue),
              ),
              Text(
                'Saldo restante: R\$ ${(fatura.valorTotal - fatura.valorPago).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processarPagamentoCompleto(cartao, fatura);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pagar Integral'),
          ),
        ],
      ),
    );
  }

  Future<void> _processarPagamentoCompleto(CartaoModel cartao, FaturaModel fatura) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processando pagamento...'),
            ],
          ),
        ),
      );

      // Processar pagamento usando FaturaService
      final sucesso = await _faturaService.pagarFaturaCompleta(
        fatura.id,
        DateTime.now(),
      );

      // Fechar loading
      Navigator.pop(context);

      if (sucesso) {
        // Recarregar dados para atualizar a UI
        await _carregarDados();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Fatura do ${cartao.nome} paga com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Erro ao processar pagamento. Tente novamente.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _arquivarCartao(CartaoModel cartao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cartao.ativo ? 'Arquivar' : 'Reativar'} Cartão'),
        content: Text(
          cartao.ativo 
            ? 'Deseja arquivar o cartão "${cartao.nome}"?'
            : 'Deseja reativar o cartão "${cartao.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(cartao.ativo ? 'Arquivar' : 'Reativar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        if (cartao.ativo) {
          await _cartaoService.arquivarCartao(cartao.id);
        } else {
          await _cartaoService.reativarCartao(cartao.id);
        }
        _carregarDados();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                cartao.ativo 
                  ? 'Cartão arquivado com sucesso!'
                  : 'Cartão reativado com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _excluirCartao(CartaoModel cartao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Cartão'),
        content: Text(
          'Deseja excluir permanentemente o cartão "${cartao.nome}"?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _cartaoService.excluirCartao(cartao.id);
        _carregarDados();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cartão excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ✅ NAVEGAÇÃO
  void _navegarParaGestaoGeral() {
    if (_cartoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum cartão disponível')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestaoCartoesMobilePage(cartao: _cartoes.first),
      ),
    );
  }

  void _navegarParaBusca() {
    // TODO: Implementar tela de busca
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Busca em desenvolvimento')),
    );
  }

  void _navegarParaFaturas() {
    // TODO: Implementar tela de faturas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestão de faturas em desenvolvimento')),
    );
  }

  void _navegarParaCartoesArquivados() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartoesArquivadosPage(),
      ),
    );
  }

  void _navegarParaRelatorios() {
    // TODO: Implementar tela de relatórios
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatórios em desenvolvimento')),
    );
  }

  void _navegarParaConfiguracoes() {
    // TODO: Implementar tela de configurações
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações em desenvolvimento')),
    );
  }

  /// ✅ MENU ACTIONS
  void _handleMenuAction(String value) {
    switch (value) {
      // case 'buscar':
      //   _navegarParaBusca();
      //   break;
      // case 'gestao_geral':
      //   _navegarParaGestaoGeral();
      //   break;
      case 'ver_faturas':
        _navegarParaFaturas();
        break;
      case 'nova_despesa':
        _abrirNovaDespesa();
        break;
      case 'arquivados':
        _navegarParaCartoesArquivados();
        break;
      case 'refresh':
        _carregarDados();
        break;
      // case 'config':
      //   _navegarParaConfiguracoes();
      //   break;

      // 📊 Casos de ordenação
      case 'ordenar_padrao':
        setState(() {
          _ordenacao = 'padrao';
        });
        break;
      case 'ordenar_nome_az':
        setState(() {
          _ordenacao = 'nome_az';
        });
        break;
      case 'ordenar_nome_za':
        setState(() {
          _ordenacao = 'nome_za';
        });
        break;
      case 'ordenar_gasto_maior':
        setState(() {
          _ordenacao = 'gasto_maior';
        });
        break;
      case 'ordenar_gasto_menor':
        setState(() {
          _ordenacao = 'gasto_menor';
        });
        break;
    }
  }

  void _abrirNovaDespesa() async {
    // Navegar para a página de nova despesa no cartão
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DespesaCartaoPage(),
      ),
    );

    // Se uma despesa foi criada, recarregar os dados
    if (result == true) {
      _carregarDados();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Despesa criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 💳 NAVEGAR PARA NOVO CARTÃO DO FAB
  void _navegarParaNovoCartaoFab() async {
    setState(() => _fabExpanded = false);
    _abrirNovoCartao();
  }

  /// ↔️ NAVEGAR PARA NOVA TRANSFERÊNCIA
  void _navegarParaNovaTransferencia() async {
    setState(() => _fabExpanded = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransferenciaFormPage(),
      ),
    );

    if (resultado == true) {
      _carregarDados(); // Atualizar dados
    }
  }

  /// 💰 NAVEGAR PARA NOVA RECEITA
  void _navegarParaNovaReceita() async {
    setState(() => _fabExpanded = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransacaoFormPage(
          modo: 'criar',
          tipo: 'receita',
        ),
      ),
    );

    if (resultado == true) {
      _carregarDados(); // Atualizar dados
    }
  }

  /// 💸 NAVEGAR PARA NOVA DESPESA
  void _navegarParaNovaDespesaFab() async {
    setState(() => _fabExpanded = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransacaoFormPage(
          modo: 'criar',
          tipo: 'despesa',
        ),
      ),
    );

    if (resultado == true) {
      _carregarDados(); // Atualizar dados
    }
  }

  /// 💳 NAVEGAR PARA NOVA DESPESA CARTÃO
  void _navegarParaNovaDespesaCartaoFab() async {
    setState(() => _fabExpanded = false);
    _abrirNovaDespesa(); // Usar método existente
  }

  /// BottomNavigationBar igual ao main_navigation.dart  


  /// 💰 CALCULAR TOTAL DOS GASTOS DO PERÍODO (SOMA DE TODOS OS CARTÕES)
  double _calcularTotalGastosPeriodo() {
    return _gastosPeriodo.values.fold(0.0, (sum, value) => sum + value);
  }

  /// 🎯 BUSCAR FATURA MAIS PRIORITÁRIA (ATRASADA → VENCENDO → ATUAL)
  Future<FaturaModel?> _buscarFaturaMaisPrioritaria(CartaoModel cartao) async {
    try {
      // Buscar todas as faturas do cartão (últimos 6 meses + próximos 3 meses)
      final faturas = <FaturaModel>[];
      final agora = DateTime.now();
      
      for (int i = -6; i <= 3; i++) {
        final mesReferencia = DateTime(agora.year, agora.month + i);
        final faturaDoMes = await _faturaDetectionService.detectarFaturaAtual(
          cartao,
          mesReferencia: mesReferencia
        );

        if (faturaDoMes != null && faturaDoMes.valorTotal > 0.01) {
          faturas.add(faturaDoMes);
        }
      }

      if (faturas.isEmpty) {
        return null;
      }
      
      // Filtrar apenas faturas em aberto com valor restante
      final faturasEmAberto = faturas
          .where((f) => !f.paga && f.valorRestante > 0.01)
          .toList();

      if (faturasEmAberto.isEmpty) {
        return null;
      }
      
      // Ordenar por prioridade: vencidas (mais antigas primeiro) → vencendo → futuras
      faturasEmAberto.sort((a, b) {
        final agora = DateTime.now();
        final aVencida = a.dataVencimento.isBefore(agora);
        final bVencida = b.dataVencimento.isBefore(agora);
        
        // Faturas vencidas têm prioridade máxima
        if (aVencida && !bVencida) return -1;
        if (!aVencida && bVencida) return 1;
        
        // Se ambas vencidas, a mais antiga primeiro
        if (aVencida && bVencida) {
          return a.dataVencimento.compareTo(b.dataVencimento);
        }
        
        // Se nenhuma vencida, a que vence primeiro
        return a.dataVencimento.compareTo(b.dataVencimento);
      });

      return faturasEmAberto.first;

    } catch (e) {
      debugPrint('❌ Erro ao buscar fatura: $e');
      return null;
    }
  }

  /// ✅ BUSCAR GASTO DO PERÍODO REAL POR CARTÃO - BASEADO NO REACT
  Future<double> _buscarGastoPeriodoCartao(String cartaoId, String periodo) async {
    try {
      final db = await LocalDatabase.instance.database;
      if (db == null) {
        return 0.0;
      }
      
      // ✅ QUERY BASEADA NO REACT: busca transações categorizadas do período
      final inicioMes = '${periodo}-01';
      final fimMes = '${periodo}-31';
      
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(t.valor), 0) as total
        FROM transacoes t
        INNER JOIN categorias c ON t.categoria_id = c.id
        WHERE t.cartao_id = ?
          AND COALESCE(t.fatura_vencimento, t.data) BETWEEN ? AND ?
          AND t.tipo = 'despesa'
          AND (t.transferencia IS NULL OR t.transferencia = 0)
          AND c.ativo = 1
          AND c.tipo = 'despesa'
      ''', [cartaoId, inicioMes, fimMes]);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;

    } catch (e) {
      return 0.0;
    }
  }

  /// ✅ Verificar faturas vencidas de outros meses
  Future<void> _verificarFaturasVencidasOutrosMeses(String cartaoId) async {
    try {
      final agora = DateTime.now();
      final mesAtualFormatado = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';

      // Buscar faturas vencidas de meses anteriores ao atual
      final db = await LocalDatabase.instance.database;
      if (db == null) return;

      final result = await db.rawQuery('''
        SELECT DISTINCT
          fatura_vencimento,
          COUNT(*) as total_transacoes,
          SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END) as valor_pago,
          SUM(valor) as valor_total
        FROM transacoes
        WHERE cartao_id = ?
          AND fatura_vencimento IS NOT NULL
          AND fatura_vencimento < ?
          AND tipo = 'despesa'
          AND (transferencia IS NULL OR transferencia = 0)
        GROUP BY fatura_vencimento
        HAVING (SUM(valor) - SUM(CASE WHEN efetivado = 1 THEN valor ELSE 0 END)) > 0.01
        ORDER BY fatura_vencimento DESC
        LIMIT 12
      ''', [cartaoId, '$mesAtualFormatado-01']);

      for (final fatura in result) {
        final faturaVencimento = fatura['fatura_vencimento'] as String;
        final valorTotal = (fatura['valor_total'] as num?)?.toDouble() ?? 0.0;
        final valorPago = (fatura['valor_pago'] as num?)?.toDouble() ?? 0.0;
        final valorRestante = valorTotal - valorPago;
        
        // Verificar se está realmente vencida
        final dataVencimento = DateTime.parse(faturaVencimento);
        if (dataVencimento.isBefore(agora) && valorRestante > 0.01) {
          _faturasVencidas++;
        }
      }

    } catch (e) {
      debugPrint('❌ Erro ao verificar faturas vencidas: $e');
    }
  }

  /// Navegar para cartões sugeridos
  Future<void> _navegarParaCartoesSugeridos() async {
    try {
      final resultado = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CartoesSugeridosPage(),
        ),
      );

      // Recarregar dados se cartão foi criado
      if (resultado == true && mounted) {
        await _carregarDados();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💳 Cartão adicionado com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir cartões sugeridos: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    }
  }

  /// Botões inferiores - VOLTAR (esquerda) e NOVO CARTÃO (direita)
  Widget _buildBotoesInferiores() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Botão VOLTAR (lado esquerdo)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigation(initialIndex: 2), // Índice 2 = Relatórios
                    ),
                    (route) => false,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.roxoHeader, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, color: AppColors.roxoHeader),
                  SizedBox(width: 8),
                  Text(
                    'VOLTAR',
                    style: TextStyle(
                      color: AppColors.roxoHeader,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botão NOVO CARTÃO (lado direito)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _navegarParaCartoesSugeridos(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxoHeader,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'NOVO CARTÃO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
