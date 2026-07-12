// 📊 Relatórios Page - iPoupei Mobile
// 
// Página principal de relatórios financeiros
// Dashboard com resumos e análises
// 
// Baseado em: Material Design + Analytics Dashboard

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../cartoes/pages/cartoes_consolidado_page.dart';
import 'resumo_executivo_page.dart';
import 'evolucao_mensal_page.dart';
import 'relatorio_categoria_page.dart';
import 'relatorio_conta_page.dart';
import '../../diagnostico/widgets/diagnostico_dashboard_widget.dart';
import '../../../shared/components/sidebar.dart';
import '../widgets/insights_rapidos_widget.dart';
import '../../../shared/services/navigation_context_service.dart';
import '../widgets/graficos_categoria_widget.dart';
import '../widgets/valor_hora_widget.dart';
import '../../planejamento/widgets/resumo_orcamento_widget.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/responsive_sizes.dart';
import '../../importacao/widgets/importar_dados_widget.dart';
import '../../transacoes/pages/transacao_form_page.dart';
import '../../transacoes/pages/transferencia_form_page.dart';
import '../../cartoes/pages/despesa_cartao_page.dart';
import '../../transacoes/pages/transacoes_page.dart';
import '../../contas/pages/contas_page.dart';
import '../../../database/hard_reset_service.dart';
import '../../../shared/widgets/interactive_loading_widget.dart';
import '../../../shared/widgets/forcar_sync_widget.dart';

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

  // Variáveis para o FAB
  bool _fabExpanded = false;

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
    final colors = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;
    final nome = user?.userMetadata?['nome'] ??
                 user?.userMetadata?['full_name'] ??
                 'Usuário';
    final avatarUrl = user?.userMetadata?['avatar_url'] ??
                     user?.userMetadata?['picture'];

    // Obter iniciais do nome
    String getInitials(String name) {
      final parts = name.trim().split(' ');
      if (parts.isEmpty) return 'U';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    return AppBar(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      elevation: 0,
      toolbarHeight: 42, // 56 * 0.75 = 42
      leading: GestureDetector(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: Container(
          margin: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: colors.primaryContainer,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    getInitials(nome),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ),
      title: _buildSeletorMesCompacto(),
      centerTitle: true,
      actions: [
        // Botão de alternar ordem ocultado
        // IconButton(
        //   icon: Icon(
        //     Icons.swap_vert,
        //     color: Colors.white,
        //     size: 20,
        //   ),
        //   tooltip: 'Alternar ordem dos botões',
        //   onPressed: _alternarBotoes,
        // ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Menu de opções em desenvolvimento',
                  style: const TextStyle(fontSize: 14),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: Colors.white,
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
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
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
    debugPrint('🚀 Navegando para: $tipo (usando bottom navigation)');

    switch (tipo) {
      case TipoResumoFinanceiro.contas:
        // Navegar para aba Contas (índice 0)
        Navigator.pushReplacementNamed(context, '/contas');
        break;

      case TipoResumoFinanceiro.receitas:
        // Configurar contexto para receitas e navegar para aba Transações
        navigationContext.setContextoReceitas();
        Navigator.pushReplacementNamed(context, '/transacoes');
        break;

      case TipoResumoFinanceiro.despesas:
        // Configurar contexto para despesas e navegar para aba Transações
        navigationContext.setContextoDespesas();
        Navigator.pushReplacementNamed(context, '/transacoes');
        break;

      case TipoResumoFinanceiro.transferencias:
        // Navegar para aba Transações (índice 4)
        Navigator.pushReplacementNamed(context, '/transacoes');
        break;

      case TipoResumoFinanceiro.cartoes:
        // Navegar para aba Cartões (índice 1)
        Navigator.pushReplacementNamed(context, '/cartoes');
        break;
    }
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
      drawer: const Sidebar(),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          RefreshIndicator(
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

              // Widget de Resumo do Orçamento
              ResumoOrcamentoWidget(
                dataAtual: _mesAtual,
                modoAnual: _modoAno,
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
                onPagarFatura: (cartaoId) => _navegarParaPagamentoFatura(cartaoId),
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

              // Seção do Diagnóstico Financeiro
              const DiagnosticoDashboardWidget(),

              const SizedBox(height: 16),
              // const SizedBox(height: 16),
              //
              // // 🔧 Ferramentas de Diagnóstico
              // _buildFerramentasDiagnostico(),

              // Widget "Quanto Vale Minha Hora" (após diagnóstico)
              ValorHoraWidget(
                mesReferencia: _mesAtual,
              ),
            ],
              ),
            ),
          ),
          _buildFABOverlay(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  /// 🎯 OVERLAY E MENU DO FAB (COBRE TELA TODA)
  Widget _buildFABOverlay() {
    if (!_fabExpanded) return const SizedBox.shrink();

    return Stack(
      children: [
        // Overlay que cobre toda a tela
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _fabExpanded = false),
            child: Container(
              color: Colors.black.withAlpha(78),
            ),
          ),
        ),
        // Menu de opções posicionado no canto inferior direito
        Positioned(
          bottom: 80,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFABOption(
                icon: Icons.swap_horiz,
                label: "Transferência",
                color: Colors.blue,
                onTap: _navegarParaNovaTransferencia,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.add,
                label: "Receita",
                color: AppColors.verdeSucesso,
                onTap: _navegarParaNovaReceita,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.remove,
                label: "Despesa",
                color: AppColors.vermelhoErro,
                onTap: _navegarParaNovaDespesa,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.credit_card,
                label: "Despesa Cartão",
                color: Colors.orange,
                onTap: _navegarParaNovaDespesaCartao,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🚀 FAB principal simplificado
  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: _fabExpanded ? 8 : 6,
      onPressed: () {
        setState(() => _fabExpanded = !_fabExpanded);
      },
      heroTag: 'relatorios_fab',
      child: AnimatedRotation(
        turns: _fabExpanded ? 0.125 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(_fabExpanded ? Icons.close : Icons.add),
      ),
    );
  }

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
            onTap: () {
              setState(() => _fabExpanded = false);
              onTap();
            },
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

  /// Métodos de navegação do FAB
  void _navegarParaNovaTransferencia() async {
    setState(() => _fabExpanded = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransferenciaFormPage(),
      ),
    );

    if (resultado == true) {
      _carregarResumo();
    }
  }

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
      _carregarResumo();
    }
  }

  void _navegarParaNovaDespesa() async {
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
      _carregarResumo();
    }
  }

  void _navegarParaNovaDespesaCartao() async {
    setState(() => _fabExpanded = false);

    // ✅ Usar página específica para despesas de cartão
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const DespesaCartaoPage(),
      ),
    );

    if (resultado == true) {
      _carregarResumo();
    }
  }

  /// 🔧 FERRAMENTAS DE DIAGNÓSTICO
  Widget _buildFerramentasDiagnostico() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.build,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ferramentas de Diagnóstico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Use essas ferramentas quando houver problemas de sincronização ou cache.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Hard Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _mostrarConfirmacaoHardReset,
                icon: const Icon(Icons.refresh),
                label: const Text('🔧 Hard Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Apaga todos os dados locais e recarrega tudo do servidor.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🚨 CONFIRMAÇÃO DO HARD RESET
  void _mostrarConfirmacaoHardReset() {
    debugPrint('🔧 [DEBUG] _mostrarConfirmacaoHardReset chamado');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hard Reset'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta operação irá:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Apagar TODOS os dados locais'),
            Text('• Recarregar tudo do Supabase'),
            Text('• Resolver problemas de cache'),
            Text('• Demorar até 1 minuto'),
            SizedBox(height: 16),
            Text(
              '⚠️ Certifique-se de ter conexão estável com internet.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executarHardReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Reset'),
          ),
        ],
      ),
    );
  }

  /// 🔧 EXECUTAR HARD RESET
  void _executarHardReset() async {
    // Mostra o loading interativo (sem await)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InteractiveLoadingWidget(
        progressStream: HardResetService.instance.progressStream,
        onCompleted: () {
          Navigator.of(context).pop();
          _mostrarSucessoReset();
        },
      ),
    );

    // Inicia o hard reset
    final sucesso = await HardResetService.instance.performHardReset();

    if (!sucesso) {
      // Se o reset falhou, o erro já foi mostrado pelo InteractiveLoadingWidget
      // Apenas recarregamos a tela atual
      _carregarResumo();
    } else {
      // Recarrega todos os dados da tela
      _carregarResumo();
    }
  }

  /// ✅ MOSTRAR SUCESSO DO RESET
  void _mostrarSucessoReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Reset Concluído!'),
          ],
        ),
        content: const Text(
          'Todos os dados foram recarregados com sucesso.\n\n'
          'A aplicação está sincronizada com o servidor.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
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
