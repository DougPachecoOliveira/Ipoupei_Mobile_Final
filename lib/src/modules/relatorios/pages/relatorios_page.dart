// 📊 Relatórios Page - iPoupei Mobile
// 
// Página principal de relatórios financeiros
// Dashboard com resumos e análises
// 
// Baseado em: Material Design + Analytics Dashboard

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/relatorio_service.dart';
import '../widgets/resumo_financeiro_widget.dart';
import '../widgets/faturas_pendentes_widget.dart';
import '../widgets/transacoes_pendentes_widget.dart';
import '../models/resumo_financeiro_model.dart';
import '../services/resumo_financeiro_service.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../cartoes/models/fatura_model.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../cartoes/services/cartao_data_service.dart';
import '../../cartoes/pages/pagamento_fatura_page.dart';
import 'resumo_executivo_page.dart';
import 'evolucao_mensal_page.dart';
import 'relatorio_categoria_page.dart';
import 'relatorio_conta_page.dart';
import '../../diagnostico/widgets/diagnostico_dashboard_widget.dart';
import '../../../shared/components/sidebar.dart';
import '../widgets/insights_rapidos_widget.dart';
import '../widgets/graficos_categoria_widget.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/responsive_sizes.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final _relatorioService = RelatorioService.instance;
  final _resumoFinanceiroService = ResumoFinanceiroService.instance;
  final _cartaoService = CartaoService.instance;
  final _cartaoDataService = CartaoDataService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ NOVA ESTRUTURA: Controle por mês como nas categorias
  DateTime _mesAtual = DateTime.now();
  bool _modoAno = false; // true = ano, false = mês

  Map<String, dynamic>? _resumoExecutivo;
  ResumoFinanceiroData? _resumoFinanceiro; // Para os insights
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  /// 🔄 CARREGAR RESUMO BASEADO NO MÊS SELECIONADO
  Future<void> _carregarResumo() async {
    setState(() => _loading = true);

    try {
      // Calcular início e fim baseado no mês/ano atual
      DateTime dataInicio, dataFim;

      if (_modoAno) {
        // Modo ano: janeiro a dezembro
        dataInicio = DateTime(_mesAtual.year, 1, 1);
        dataFim = DateTime(_mesAtual.year, 12, 31);
      } else {
        // Modo mês: primeiro ao último dia do mês
        dataInicio = DateTime(_mesAtual.year, _mesAtual.month, 1);
        dataFim = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      }

      // Carregar resumo executivo e dados financeiros em paralelo
      final results = await Future.wait([
        _relatorioService.fetchResumoExecutivo(
          dataInicio: dataInicio,
          dataFim: dataFim,
        ),
        _resumoFinanceiroService.carregarResumo(
          dataInicio: dataInicio,
          dataFim: dataFim,
        ),
      ]);

      setState(() {
        _resumoExecutivo = results[0] as Map<String, dynamic>;
        _resumoFinanceiro = results[1] as ResumoFinanceiroData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar resumo: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ⬅️ NAVEGAR PARA MÊS/ANO ANTERIOR
  void _mesAnterior() {
    setState(() {
      if (_modoAno) {
        _mesAtual = DateTime(_mesAtual.year - 1, _mesAtual.month, 1);
      } else {
        _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
      }
    });
    _carregarResumo();
  }

  /// ➡️ NAVEGAR PARA PRÓXIMO MÊS/ANO
  void _proximoMes() {
    setState(() {
      if (_modoAno) {
        _mesAtual = DateTime(_mesAtual.year + 1, _mesAtual.month, 1);
      } else {
        _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
      }
    });
    _carregarResumo();
  }

  /// 📅 ALTERNAR MODO MÊS/ANO
  void _selecionarAno() async {
    setState(() {
      _modoAno = !_modoAno; // Alterna entre modo mês e ano
    });
    _carregarResumo(); // Recarrega dados para o novo modo
  }

  /// 🎯 FORMATAR MÊS E ANO PARA EXIBIÇÃO
  String _formatarMesAno(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  /// 📅 CALCULAR DATA INÍCIO BASEADA NO MODO ATUAL
  DateTime get _dataInicio {
    if (_modoAno) {
      return DateTime(_mesAtual.year, 1, 1);
    } else {
      return DateTime(_mesAtual.year, _mesAtual.month, 1);
    }
  }

  /// 📅 CALCULAR DATA FIM BASEADA NO MODO ATUAL
  DateTime get _dataFim {
    if (_modoAno) {
      return DateTime(_mesAtual.year, 12, 31);
    } else {
      return DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
    }
  }

  /// 🔝 APPBAR COMPACTO SEGUINDO PADRÃO DO CONTAS PAGE
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.tealPrimary,
      elevation: 0,
      toolbarHeight: ResponsiveSizes.appBarHeight(context, base: 42), // 56 * 0.75 = 42
      leading: GestureDetector(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: Container(
          margin: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: AppColors.tealPrimary,
            child: Text(
              'UL', // TODO: Pegar iniciais do usuário logado
              style: AppTypography.onDark(context, AppTypography.bodyMedium(context)),
            ),
          ),
        ),
      ),
      title: _buildSeletorMesCompacto(),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
            size: ResponsiveSizes.appBarIconSize(context, base: 21),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Menu de opções em desenvolvimento',
                  style: AppTypography.bodyMedium(context),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 📅 SELETOR DE MÊS PADRONIZADO
  Widget _buildSeletorMesCompacto() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: ResponsiveSizes.appBarIconSize(context, base: 21),
          ),
          onPressed: _mesAnterior,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        InkWell(
          onTap: _selecionarAno,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _modoAno ? _mesAtual.year.toString() : _formatarMesAno(_mesAtual),
                  style: AppTypography.appBarTitle(context).copyWith(
                    fontSize: ResponsiveSizes.fontSizeForCards(
                      context: context,
                      base: 14, // 18 * 0.75 = ~14
                      small: 12,
                      large: 15,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveSizes.spacing(context: context, base: 4)),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: ResponsiveSizes.appBarIconSize(context, base: 16),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: ResponsiveSizes.appBarIconSize(context, base: 21),
          ),
          onPressed: _proximoMes,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 🎨 WIDGET CARD RESUMO
  Widget _buildCardResumo(String titulo, String valor, String subtitulo, IconData icone, Color cor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: cor, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 WIDGET CARD NAVEGAÇÃO PADRONIZADO
  Widget _buildCardNavegacao(String titulo, String descricao, IconData icone, Color cor, VoidCallback onTap) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: ResponsiveSizes.iconSize(context: context, base: 24),
                ),
              ),
              SizedBox(width: ResponsiveSizes.spacing(context: context, base: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTypography.h3(context),
                    ),
                    SizedBox(height: ResponsiveSizes.spacing(context: context, base: 4)),
                    Text(
                      descricao,
                      style: AppTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: ResponsiveSizes.iconSize(context: context, base: 16),
                color: AppColors.cinzaTexto,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 FORMATAR MOEDA
  String _formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  /// 🎨 FORMATAR PERCENTUAL
  String _formatarPercentual(double valor) {
    return '${valor.toStringAsFixed(1)}%';
  }

  /// 🚀 NAVEGAR PARA TRANSAÇÕES COM FILTRO
  void _navegarParaTransacoes(TipoResumoFinanceiro tipo) {
    String? filtroTipo;
    String titulo;

    switch (tipo) {
      case TipoResumoFinanceiro.contas:
        // Por enquanto navega para todas as transações
        // Depois pode filtrar por conta específica
        titulo = 'Transações de Contas';
        break;
      case TipoResumoFinanceiro.receitas:
        filtroTipo = 'receita';
        titulo = 'Receitas';
        break;
      case TipoResumoFinanceiro.despesas:
        filtroTipo = 'despesa';
        titulo = 'Despesas';
        break;
      case TipoResumoFinanceiro.transferencias:
        titulo = 'Transferências';
        break;
      case TipoResumoFinanceiro.cartoes:
        // Filtrar transações que tem cartao_id
        titulo = 'Transações de Cartão';
        break;
    }

    debugPrint('🚀 Navegando para: $titulo (filtro: $filtroTipo)');

    // Por enquanto, apenas mostra um SnackBar
    // Depois implementaremos a navegação real para a página de transações
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegação para $titulo - Em desenvolvimento'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 💳 NAVEGAR PARA GESTÃO DE CARTÕES
  void _navegarParaGestaoCartoes(String cartaoId) {
    debugPrint('💳 Navegando para gestão do cartão: $cartaoId');

    // Por enquanto, apenas mostra um SnackBar
    // Depois implementaremos a navegação real para a página de gestão de cartões
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegação para Gestão de Cartão ($cartaoId) - Em desenvolvimento'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Pagar Fatura',
          onPressed: () {
            // Ação futura: ir direto para pagamento
          },
        ),
      ),
    );
  }

  /// 📌 NAVEGAR PARA TRANSAÇÕES PENDENTES
  void _navegarParaTransacoesPendentes() {
    debugPrint('📌 Navegando para transações pendentes com filtro de vencidas');

    // Por enquanto, apenas mostra um SnackBar
    // Depois implementaremos a navegação real para a página de transações com filtro pendente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navegação para Transações Pendentes - Em desenvolvimento'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver Todas',
          onPressed: () {
            // Ação futura: filtro por efetivado = false + vencidas
          },
        ),
      ),
    );
  }

  /// 💳 Navegar para pagamento de fatura
  Future<void> _navegarParaPagamentoFatura(String cartaoId) async {
    debugPrint('💳 Navegando para pagamento da fatura do cartão: $cartaoId');

    try {
      // Buscar dados do cartão
      final cartao = await _cartaoService.buscarCartaoPorId(cartaoId);
      if (cartao == null) {
        debugPrint('❌ Cartão não encontrado: $cartaoId');
        return;
      }

      // Buscar fatura mais antiga pendente
      final faturaPrioritaria = await _buscarFaturaMaisAntigaPendente(cartao);

      if (faturaPrioritaria == null) {
        debugPrint('✅ Nenhuma fatura pendente encontrada para pagamento');

        if (mounted) {
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
        }
        return;
      }

      debugPrint('✅ Fatura prioritária encontrada: ${faturaPrioritaria.id}');
      debugPrint('💰 Valor da fatura: ${faturaPrioritaria.valorTotalFormatado}');
      debugPrint('📅 Vencimento: ${faturaPrioritaria.dataVencimentoFormatada}');

      // Navegar para página de pagamento
      if (!mounted) return;
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PagamentoFaturaPage(
            cartao: cartao,
            fatura: faturaPrioritaria,
          ),
        ),
      );

      // Se o pagamento foi realizado, atualizar dados
      if (resultado == true) {
        debugPrint('💰 Pagamento realizado - recarregando dados');
        _carregarResumo();
      }

    } catch (e) {
      debugPrint('❌ Erro ao navegar para pagamento de fatura: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar fatura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔍 Buscar fatura mais antiga pendente para pagamento
  Future<FaturaModel?> _buscarFaturaMaisAntigaPendente(CartaoModel cartao) async {
    try {
      debugPrint('🔍 Buscando fatura mais antiga para cartão: ${cartao.id}');

      // Buscar faturas dos últimos 6 meses
      final hoje = DateTime.now();
      final inicioRange = DateTime(hoje.year, hoje.month - 6, 1);
      final fimRange = DateTime(hoje.year, hoje.month + 3, 30);

      final faturas = <FaturaModel>[];

      // Buscar faturas do período
      var mesAtual = inicioRange;
      while (mesAtual.isBefore(fimRange)) {
        try {
          final faturasMes = await _cartaoDataService.buscarFaturasCartao(
            cartao.id,
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

      if (faturas.isEmpty) {
        debugPrint('📋 Nenhuma fatura encontrada');
        return null;
      }

      // Filtrar faturas pendentes com valor > 0
      final faturasPendentes = faturas.where((f) =>
        !f.paga && f.valorTotal > 0.01
      ).toList();

      debugPrint('📋 Faturas pendentes: ${faturasPendentes.length}');

      if (faturasPendentes.isEmpty) {
        debugPrint('✅ Nenhuma fatura pendente');
        return null;
      }

      // Ordenar por data de vencimento (mais antigas primeiro)
      faturasPendentes.sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));

      final faturaPrioritaria = faturasPendentes.first;
      debugPrint('🎯 Fatura mais antiga: ${faturaPrioritaria.id} - Venc: ${faturaPrioritaria.dataVencimentoFormatada}');

      return faturaPrioritaria;

    } catch (e) {
      debugPrint('❌ Erro ao buscar fatura mais antiga: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumo = _resumoExecutivo;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: const Sidebar(),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _carregarResumo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Widget de Resumo Financeiro (do iPoupeiDevice)
              ResumoFinanceiroWidget(
                dataInicio: _dataInicio,
                dataFim: _dataFim,
                onItemTap: _navegarParaTransacoes,
              ),

              const SizedBox(height: 12),

              // Widget de Insights Rápidos
              InsightsRapidosWidget(
                data: _resumoFinanceiro,
                dataInicio: _dataInicio,
                dataFim: _dataFim,
              ),

              const SizedBox(height: 12),

              // Widget de Faturas Pendentes (só aparece se houver faturas críticas)
              FaturasPendentesWidget(
                onPagarFatura: _navegarParaPagamentoFatura,
              ),

              const SizedBox(height: 12),

              // Widget de Transações Pendentes (só aparece se houver transações vencidas)
              TransacoesPendentesWidget(
                onTransacoesTap: _navegarParaTransacoesPendentes,
              ),

              const SizedBox(height: 16),

              // Gráficos de Categoria (Despesas e Receitas)
              GraficosCategoriaWidget(
                dataInicio: _dataInicio,
                dataFim: _dataFim,
              ),

              const SizedBox(height: 16),

              // Resumo executivo
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (resumo != null) ...[
                // Cards de resumo
                Row(
                  children: [
                    Expanded(
                      child: _buildCardResumo(
                        'Receitas',
                        _formatarMoeda((resumo['totais']?['receitas'] ?? 0.0) as double),
                        '${(resumo['quantidades']?['receitas'] ?? 0)} transação(ões)',
                        Icons.trending_up,
                        Colors.green[600]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCardResumo(
                        'Despesas',
                        _formatarMoeda((resumo['totais']?['despesas'] ?? 0.0) as double),
                        '${(resumo['quantidades']?['despesas'] ?? 0)} transação(ões)',
                        Icons.trending_down,
                        Colors.red[600]!,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildCardResumo(
                        'Saldo Período',
                        _formatarMoeda((resumo['totais']?['saldo_periodo'] ?? 0.0) as double),
                        'Receitas - Despesas',
                        Icons.account_balance,
                        (resumo['totais']?['saldo_periodo'] ?? 0.0) >= 0 
                            ? Colors.green[600]! 
                            : Colors.red[600]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCardResumo(
                        'Taxa Economia',
                        _formatarPercentual((resumo['indicadores']?['taxa_economia'] ?? 0.0) as double),
                        'Do que ganhou, poupou',
                        Icons.savings,
                        Colors.blue[600]!,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Relatórios disponíveis
                Text(
                  'Relatórios Disponíveis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildCardNavegacao(
                  'Resumo Executivo',
                  'Visão geral com os principais indicadores',
                  Icons.dashboard,
                  Colors.blue[600]!,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ResumoExecutivoPage(
                        dataInicio: _dataInicio,
                        dataFim: _dataFim,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                _buildCardNavegacao(
                  'Evolução Mensal',
                  'Gráficos de evolução ao longo do tempo',
                  Icons.show_chart,
                  Colors.green[600]!,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EvolucaoMensalPage(
                        dataInicio: _dataInicio,
                        dataFim: _dataFim,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                _buildCardNavegacao(
                  'Análise por Categoria',
                  'Onde você mais gasta e recebe',
                  Icons.pie_chart,
                  Colors.orange[600]!,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RelatorioCategoriaPage(
                        dataInicio: _dataInicio,
                        dataFim: _dataFim,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                _buildCardNavegacao(
                  'Análise por Conta',
                  'Performance de cada conta bancária',
                  Icons.account_balance,
                  Colors.purple[600]!,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RelatorioContaPage(
                        dataInicio: _dataInicio,
                        dataFim: _dataFim,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Seção do Diagnóstico Financeiro
                const DiagnosticoDashboardWidget(),

              ] else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum dado encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione algumas transações para ver seus relatórios aqui',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
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

// 🎯 Placeholder pages para relatórios específicos
class ResumoExecutivoPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const ResumoExecutivoPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo Executivo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Resumo Executivo - Em desenvolvimento'),
      ),
    );
  }
}

class EvolucaoMensalPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const EvolucaoMensalPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolução Mensal'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Evolução Mensal - Em desenvolvimento'),
      ),
    );
  }
}

class RelatorioCategoriaPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const RelatorioCategoriaPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise por Categoria'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Análise por Categoria - Em desenvolvimento'),
      ),
    );
  }
}

class RelatorioContaPage extends StatelessWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const RelatorioContaPage({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise por Conta'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Análise por Conta - Em desenvolvimento'),
      ),
    );
  }
}