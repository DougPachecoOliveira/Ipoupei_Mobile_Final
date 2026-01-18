// 🏦 Gestão Conta Page - iPoupei Mobile
//
// Página de gestão completa da conta com insights e métricas
// UX idêntica ao iPoupei Device mas usando nossos stores
//
// Features:
// - AppBar com seletor de mês
// - Card da conta com botões de ação
// - Métricas resumo (3 cards)
// - Insights e dicas
// - Gráficos (evolução, entradas vs saídas, categorias)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/conta_model.dart';
import 'correcao_saldo_page.dart';
import 'conta_form_page.dart';
import 'contas_arquivadas_page.dart';
import '../../../shared/models/categoria_valor.dart';
import '../services/conta_analytics_service.dart';
import '../services/conta_service.dart';
import '../widgets/conta_card.dart';
import '../../relatorios/pages/relatorios_page.dart';
import '../../transacoes/pages/transferencia_form_page.dart';
import '../../transacoes/pages/transacoes_page.dart';
import 'contas_page.dart';
import '../../../routes/main_navigation.dart';
import '../../../shared/services/navigation_context_service.dart';
import '../../../shared/services/contas_refresh_notifier.dart';
import '../../../shared/components/navigation/app_bottom_navigation.dart';

/// Página de gestão completa da conta com insights e métricas
class GestaoContaPage extends StatefulWidget {
  final ContaModel conta;

  const GestaoContaPage({super.key, required this.conta});

  @override
  State<GestaoContaPage> createState() => _GestaoContaPageState();
}

class _GestaoContaPageState extends State<GestaoContaPage> {
  DateTime _mesAtual = DateTime.now();
  bool _carregando = true;
  String? _erro;

  // ✅ CONTA ATUAL (atualizada após edições)
  late ContaModel _contaAtual;

  // 📊 DADOS MOCKADOS (em produção viriam dos nossos stores)
  double _saldoMedio = 0.0;
  double _maiorEntrada = 0.0;
  double _maiorSaida = 0.0;
  double _entradaMesAtual = 0.0;
  double _saidaMesAtual = 0.0;
  List<Map<String, dynamic>> _evolucaoSaldo = [];
  List<Map<String, dynamic>> _entradasVsSaidas = [];
  List<CategoriaValor> _gastosPorCategoria = [];
  int _touchedIndex = -1; // Para animações do gráfico

  @override
  void initState() {
    super.initState();
    _contaAtual = widget.conta; // Inicializa com a conta passada

    // 🧭 Define contexto de navegação para filtros contextuais
    if (_contaAtual.id.isNotEmpty) {
      navigationContext.setContaSelecionada(_contaAtual.id);
      navigationContext.setMesSelecionado(_mesAtual);
    }

    _carregarDados();

    // 🔔 Escutar notificações de mudança em contas
    ContasRefreshNotifier.instance.refreshTrigger.addListener(_onContasMudaram);
  }

  @override
  void dispose() {
    // 🧹 Remover listener
    ContasRefreshNotifier.instance.refreshTrigger.removeListener(
      _onContasMudaram,
    );
    super.dispose();
  }

  /// 🔔 Callback quando contas mudaram (transação efetivada/desefetivada)
  void _onContasMudaram() {
    if (!mounted) return; // Evita erro se página foi fechada
    debugPrint(
      '🔔 GestaoContaPage: recebeu notificação de mudança, recarregando...',
    );
    _carregarDados();
  }

  /// 📡 CARREGAR TODOS OS DADOS DA GESTÃO DA CONTA - TOLERANTE A FALHAS
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    // CORREÇÃO CRÍTICA: Não usar Future.wait() que falha tudo se um der erro
    // Cada carregamento é independente e pode falhar sem afetar os outros

    final futures = [
      _recarregarContaAtual(), // ✅ PRIMEIRO: Recarrega dados da conta
      _carregarMetricasResumo(),
      _carregarEvolucaoSaldo(),
      _carregarEntradasVsSaidas(),
      _carregarGastosPorCategoria(),
    ];

    // Aguardar todos, mas capturar erros individuais
    await Future.wait(
      futures.map(
        (future) => future.catchError((error) {
          debugPrint('⚠️ Erro em carregamento individual: $error');
          // Retorna void para não quebrar o Future.wait
          return;
        }),
      ),
    );

    setState(() {
      _carregando = false;
      _erro = null; // Mesmo com erros parciais, mostra o que conseguiu carregar
    });
  }

  /// 🔄 RECARREGAR DADOS ATUALIZADOS DA CONTA
  Future<void> _recarregarContaAtual() async {
    try {
      debugPrint('🔄 Recarregando dados da conta ${_contaAtual.nome}...');

      // Busca contas atualizadas
      final contas = await ContaService.instance.fetchContas();

      // Busca a conta atualizada
      final contaAtualizada = contas.firstWhere(
        (c) => c.id == _contaAtual.id,
        orElse: () => _contaAtual,
      );

      // Atualiza a conta atual se houve mudanças
      if (contaAtualizada.contaPrincipal != _contaAtual.contaPrincipal ||
          contaAtualizada.nome != _contaAtual.nome ||
          contaAtualizada.saldo != _contaAtual.saldo) {
        setState(() {
          _contaAtual = contaAtualizada;
        });

        debugPrint(
          '✅ Conta atualizada: Principal=${contaAtualizada.contaPrincipal}, Nome=${contaAtualizada.nome}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao recarregar conta: $e');
    }
  }

  /// 📈 CARREGAR MÉTRICAS DE RESUMO (DADOS REAIS)
  Future<void> _carregarMetricasResumo() async {
    try {
      debugPrint(
        '🔄 Carregando métricas para conta ${_contaAtual.nome} (ID: ${_contaAtual.id})',
      );

      final metricas = await ContaAnalyticsService.instance.fetchMetricasResumo(
        contaId: _contaAtual.id,
        mesAtual: _mesAtual,
      );

      debugPrint('📊 Métricas recebidas: $metricas');

      // Aceita zeros como dados válidos (não há transações = zero)
      _saldoMedio = metricas['saldoMedio'] ?? 0.0;
      _maiorEntrada = metricas['maiorEntrada'] ?? 0.0;
      _maiorSaida = metricas['maiorSaida'] ?? 0.0;
      _entradaMesAtual = metricas['entradaMesAtual'] ?? 0.0;
      _saidaMesAtual = metricas['saidaMesAtual'] ?? 0.0;

      debugPrint(
        '✅ Dados carregados - Saldo médio: R\$ ${_saldoMedio.toStringAsFixed(2)}, Maior entrada: R\$ ${_maiorEntrada.toStringAsFixed(2)}, Maior saída: R\$ ${_maiorSaida.toStringAsFixed(2)}',
      );

      if (_saldoMedio == 0.0 && _maiorEntrada == 0.0 && _maiorSaida == 0.0) {
        debugPrint('ℹ️ Conta sem movimentação - exibindo zeros');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar métricas resumo: $e');
      // Somente em caso de erro no service, usar zeros
      _saldoMedio = 0.0;
      _maiorEntrada = 0.0;
      _maiorSaida = 0.0;
      _entradaMesAtual = 0.0;
      _saidaMesAtual = 0.0;
    }
  }

  /// 📊 CARREGAR EVOLUÇÃO DO SALDO (DADOS REAIS)
  Future<void> _carregarEvolucaoSaldo() async {
    try {
      debugPrint('📈 Carregando evolução do saldo...');

      final dadosEvolucao = await ContaAnalyticsService.instance
          .fetchEvolucaoSaldo(contaId: _contaAtual.id, mesAtual: _mesAtual);

      debugPrint('🔍 DEBUGANDO EVOLUÇÃO: dadosEvolucao = $dadosEvolucao');
      debugPrint('🔍 DEBUGANDO EVOLUÇÃO: length = ${dadosEvolucao.length}');

      setState(() {
        _evolucaoSaldo.clear();
        _evolucaoSaldo.addAll(dadosEvolucao);
      });
      debugPrint('✅ Evolução carregada: ${dadosEvolucao.length} registros');

      // Se não há dados de evolução, criar dados de 12 meses zerados para mostrar no gráfico
      if (_evolucaoSaldo.isEmpty) {
        final agora = DateTime.now();
        _evolucaoSaldo.addAll(
          List.generate(12, (i) {
            final mes = DateTime(agora.year, agora.month - (11 - i), 1);
            return {
              'mes': _formatarMesAbrev(mes),
              'saldo': 0.0, // Saldo zero para cada mês
              'isAtual': i == 11, // Último mês é atual
            };
          }),
        );
        debugPrint(
          'ℹ️ Sem movimentação histórica - mostrando linha zero dos últimos 12 meses',
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar evolução do saldo: $e');

      // Em caso de erro, mostrar linha zero dos últimos 12 meses
      _evolucaoSaldo.clear();
      final agora = DateTime.now();
      _evolucaoSaldo.addAll(
        List.generate(12, (i) {
          final mes = DateTime(agora.year, agora.month - (11 - i), 1);
          return {
            'mes': _formatarMesAbrev(mes),
            'saldo': 0.0, // Saldo zero por erro
            'isAtual': i == 11, // Último mês é atual
          };
        }),
      );
    }
  }

  /// 📅 FORMATAR MÊS ABREVIADO
  String _formatarMesAbrev(DateTime data) {
    final meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  /// 💰 CARREGAR ENTRADAS VS SAÍDAS (DADOS REAIS)
  Future<void> _carregarEntradasVsSaidas() async {
    try {
      debugPrint('💰 Carregando entradas vs saídas...');

      final dadosEntradas = await ContaAnalyticsService.instance
          .fetchEntradasVsSaidas(contaId: _contaAtual.id, mesAtual: _mesAtual);

      debugPrint('🔍 DEBUGANDO ENTRADAS: dadosEntradas = $dadosEntradas');
      debugPrint('🔍 DEBUGANDO ENTRADAS: length = ${dadosEntradas.length}');

      setState(() {
        _entradasVsSaidas.clear();
        _entradasVsSaidas.addAll(dadosEntradas);
      });
      debugPrint(
        '✅ Entradas vs saídas carregadas: ${dadosEntradas.length} registros',
      );

      // Se não há dados, criar entradas zeradas para mostrar no gráfico
      if (_entradasVsSaidas.isEmpty) {
        _entradasVsSaidas.addAll([
          {'tipo': 'Entradas', 'valor': 0.0, 'cor': '#4CAF50'},
          {'tipo': 'Saídas', 'valor': 0.0, 'cor': '#F44336'},
        ]);
        debugPrint('ℹ️ Sem transações no mês - mostrando zeros');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar entradas vs saídas: $e');

      // Em caso de erro, mostrar zeros
      _entradasVsSaidas.clear();
      _entradasVsSaidas.addAll([
        {'tipo': 'Entradas', 'valor': 0.0, 'cor': '#4CAF50'},
        {'tipo': 'Saídas', 'valor': 0.0, 'cor': '#F44336'},
      ]);
    }
  }

  /// 🏷️ CARREGAR GASTOS POR CATEGORIA (DADOS REAIS)
  Future<void> _carregarGastosPorCategoria() async {
    try {
      debugPrint('🏷️ Carregando gastos por categoria...');

      _gastosPorCategoria = await ContaAnalyticsService.instance
          .fetchGastosPorCategoria(
            contaId: _contaAtual.id,
            mesAtual: _mesAtual,
          );
      debugPrint(
        '✅ Gastos por categoria carregados: ${_gastosPorCategoria.length} categorias',
      );

      // Se não há dados, criar categorias zeradas para mostrar no gráfico
      if (_gastosPorCategoria.isEmpty) {
        _gastosPorCategoria = [
          CategoriaValor(nome: 'Alimentação', valor: 0.0, color: '#FF9800'),
          CategoriaValor(nome: 'Transporte', valor: 0.0, color: '#2196F3'),
          CategoriaValor(nome: 'Lazer', valor: 0.0, color: '#9C27B0'),
          CategoriaValor(nome: 'Saúde', valor: 0.0, color: '#4CAF50'),
          CategoriaValor(nome: 'Outros', valor: 0.0, color: '#607D8B'),
        ];
        debugPrint('ℹ️ Sem gastos por categoria - mostrando zeros');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar gastos por categoria: $e');

      // Em caso de erro, mostrar zeros
      _gastosPorCategoria = [
        CategoriaValor(nome: 'Alimentação', valor: 0.0, color: '#FF9800'),
        CategoriaValor(nome: 'Transporte', valor: 0.0, color: '#2196F3'),
        CategoriaValor(nome: 'Lazer', valor: 0.0, color: '#9C27B0'),
        CategoriaValor(nome: 'Saúde', valor: 0.0, color: '#4CAF50'),
        CategoriaValor(nome: 'Outros', valor: 0.0, color: '#607D8B'),
      ];
    }
  }

  /// ⬅️ NAVEGAR PARA MÊS ANTERIOR
  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
    });
    // 🧭 Atualiza contexto de navegação
    navigationContext.setMesSelecionado(_mesAtual);
    _carregarDados();
  }

  /// ➡️ NAVEGAR PARA PRÓXIMO MÊS
  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
    });
    // 🧭 Atualiza contexto de navegação
    navigationContext.setMesSelecionado(_mesAtual);
    _carregarDados();
  }

  /// 🎯 NAVEGAR PARA AÇÃO ESPECÍFICA
  void _navegarParaAcao(String acao) {
    switch (acao) {
      case 'editar_conta':
        _navegarParaEdicao();
        break;
      case 'ajustar_saldo':
        _abrirModalAjusteSaldo();
        break;
      case 'ver_transacoes':
        _navegarParaTransacoes();
        break;
      case 'transferir':
        _abrirModalTransferencia();
        break;
      case 'arquivar':
        _arquivarConta();
        break;
      case 'ver_arquivadas':
        _navegarParaArquivadas();
        break;
    }
  }

  void _navegarParaEdicao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContaFormPage(modo: 'editar', conta: _contaAtual),
      ),
    ).then((_) => _carregarDados());
  }

  Future<void> _abrirModalAjusteSaldo() async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CorrecaoSaldoPage(conta: _contaAtual);
      },
    );

    if (resultado == true) {
      await _carregarDados();
    }
  }

  void _navegarParaTransacoes() {
    // 🧭 Garante que o contexto está definido com a conta e mês atuais
    navigationContext.setContaSelecionada(_contaAtual.id);
    navigationContext.setMesSelecionado(_mesAtual);

    debugPrint(
      '🧭 Navegando para transações da conta: ${_contaAtual.nome} (${_contaAtual.id})',
    );
    debugPrint('🧭 Mês selecionado: ${_mesAtual.month}/${_mesAtual.year}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransacoesPage(
          filtrosIniciais: {
            'contas': [_contaAtual.id],
            'mes': _mesAtual,
          },
          showNavigationBar: true,
        ),
      ),
    );
  }

  void _abrirModalTransferencia() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransferenciaFormPage(
          // TODO: Implementar pré-seleção da conta atual quando disponível
        ),
      ),
    );

    if (resultado == true) {
      // Recarrega os dados da conta após a transferência
      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Transferência realizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _arquivarConta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar Conta'),
        content: Text(
          'Deseja arquivar a conta "${_contaAtual.nome}"?\n\nEla ficará oculta das visualizações principais mas pode ser restaurada a qualquer momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Arquiva a conta usando o serviço real
        await ContaService.instance.arquivarConta(_contaAtual.id);

        // Volta para a página anterior (lista de contas)
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Retorna true para indicar que houve mudança

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📦 Conta "${_contaAtual.nome}" arquivada com sucesso!',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao arquivar conta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navegarParaArquivadas() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const ContasArquivadasPage()),
        )
        .then((_) {
          // Quando voltar, pode recarregar se necessário
          _carregarDados();
        });
  }

  /// 📊 Constrói seções do PieChart com animações de toque
  List<PieChartSectionData> _buildPieChartSections() {
    final cores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    final total = _gastosPorCategoria.fold(0.0, (sum, cat) => sum + cat.valor);

    return _gastosPorCategoria.take(6).map((categoria) {
      final index = _gastosPorCategoria.indexOf(categoria);
      final cor = cores[index % cores.length];
      final valor = categoria.valor;
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
          shadows: isTouched
              ? [
                  const Shadow(
                    color: Colors.black45,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        borderSide: BorderSide(
          color: isTouched ? Colors.white : Colors.transparent,
          width: isTouched ? 2 : 0,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      appBar: _buildAppBarOriginal(),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.tealPrimary),
            )
          : _erro != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _erro!,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _carregarDados,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(onRefresh: _carregarDados, child: _buildBody()),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0, // Contas é o índice 0
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  /// 🔝 HEADER COM SELETOR DE MÊS (SEM APPBAR)
  Widget _buildHeaderSeletor() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.tealPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: _mesAnterior,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(52),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatarMesAno(_mesAtual),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _proximoMes,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 🔝 APPBAR ORIGINAL (BACKUP)
  PreferredSizeWidget _buildAppBarOriginal() {
    return AppBar(
      backgroundColor: AppColors.tealPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Botão voltar
          Transform.translate(
            offset: const Offset(-8, 0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),

          // Título
          const Text(
            'Gestão da Conta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Seletor de mês integrado
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _mesAnterior,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatarMesAno(_mesAtual),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _proximoMes,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📱 CORPO DA PÁGINA
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Card da conta + ações
          _buildCardContaComAcoes(),

          const SizedBox(height: 12),

          // 3 quadradinhos de resumo
          _buildResumoMetricas(),

          const SizedBox(height: 12),

          // Card de insights + dicas
          _buildCardInsights(),

          const SizedBox(height: 12),

          // Gráficos
          _buildGraficos(),

          // Botão Voltar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
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
                      'Voltar às Contas',
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
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 🏦 CARD DA CONTA COM AÇÕES
  Widget _buildCardContaComAcoes() {
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
          // Card da conta original
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: _buildCardConta(),
          ),

          // Chips de ações (sem padding lateral)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildChipsElegantes(),
          ),
        ],
      ),
    );
  }

  /// 🎴 CONTA CARD MODERNO - Igual ao CartaoCard
  Widget _buildContaCardModerno() {
    return ContaCard(
      conta: _contaAtual,
      entradaMensal: _entradaMesAtual,
      saidaMensal: _saidaMesAtual,
      saldoMedio: _saldoMedio,
      periodoAtual: _formatarMesAno(_mesAtual),
      showMovimentacao: true,
      showMetricas: true,
      isCompact: false,
      onTap: _mostrarMenuConta,
      onMenuTap: _mostrarMenuConta,
    );
  }

  /// 🎴 CARD DA CONTA ANTIGO (manter para backup)
  Widget _buildCardConta() {
    final cor = _parseColor(_contaAtual.cor ?? '#008080');
    final saldoNegativo = _contaAtual.saldo < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navegarParaRelatoriosComFiltro(),
          child: Container(
            height: 71,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.branco,
            ),
            child: Row(
              children: [
                // 🎨 FAIXA LATERAL COLORIDA (como no contas_page)
                Container(
                  width: 37,
                  decoration: BoxDecoration(
                    color: cor, // Cor da conta
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconFromSlug(_contaAtual.tipo),
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),

                // Conteúdo principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primeira linha: Nome + Saldo
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _contaAtual.nome,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cinzaEscuro,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(_contaAtual.saldo),
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: saldoNegativo
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Segunda linha: Banco + Menu
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_contaAtual.banco ?? 'Sem banco'} • Conta',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.cinzaTexto,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Menu três pontinhos
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _mostrarMenuConta(),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.more_horiz,
                                  color: AppColors.cinzaTexto,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  /// 🔗 CHIPS ELEGANTES DE AÇÕES (3x2 como no device)
  Widget _buildChipsElegantes() {
    return Column(
      children: [
        // Primeira linha: 3 chips
        Row(
          children: [
            Expanded(
              child: _buildChipElegante(
                icone: Icons.edit,
                titulo: 'EDITAR',
                cor: AppColors.azul,
                onTap: () => _navegarParaAcao('editar_conta'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChipElegante(
                icone: Icons.account_balance_wallet,
                titulo: 'SALDO',
                cor: AppColors.tealPrimary,
                onTap: () => _navegarParaAcao('ajustar_saldo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChipElegante(
                icone: Icons.swap_horiz,
                titulo: 'TRANSFERIR',
                cor: AppColors.roxoPrimario,
                onTap: () => _navegarParaAcao('transferir'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Segunda linha: 3 chips
        Row(
          children: [
            Expanded(
              child: _buildChipElegante(
                icone: Icons.analytics,
                titulo: 'TRANSAÇÕES',
                cor: AppColors.verdeSucesso,
                onTap: () => _navegarParaAcao('ver_transacoes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChipElegante(
                icone: Icons.archive,
                titulo: 'ARQUIVAR',
                cor: AppColors.cinzaTexto,
                onTap: () => _navegarParaAcao('arquivar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChipElegante(
                icone: Icons.folder_open,
                titulo: 'ARQUIVADAS',
                cor: AppColors.cinzaMedio,
                onTap: () => _navegarParaAcao('ver_arquivadas'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 CHIP ELEGANTE INDIVIDUAL (igual ao device)
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
            border: Border.all(color: AppColors.cinzaClaro, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone colorido (sem círculo)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor, size: 20),
              ),

              const SizedBox(height: 12),

              // Título
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cinzaEscuro,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 RESUMO MÉTRICAS (3 cards)
  Widget _buildResumoMetricas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Saldo Médio Período',
              valor: CurrencyFormatter.format(_saldoMedio),
              cor: AppColors.azul,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Maior Entrada',
              valor: CurrencyFormatter.format(_maiorEntrada),
              cor: AppColors.verdeSucesso,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricaCard(
              titulo: 'Maior Saída',
              valor: CurrencyFormatter.format(_maiorSaida),
              cor: AppColors.vermelhoErro,
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 CARD DE MÉTRICA INDIVIDUAL (igual ao device)
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Valor em cima (igual ao device)
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          // Título embaixo (igual ao device)
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, color: AppColors.cinzaTexto),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 💡 CARD DE INSIGHTS E DICAS
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com logo do iPoupei (igual ao device)
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azulHeader.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.azulHeader,
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
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Insights iPoupei',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Insights baseados nos dados
            ...(_generateInsights().map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      insight['icone'] as IconData,
                      color: insight['cor'] as Color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight['texto'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaTexto,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 📊 SEÇÃO DOS GRÁFICOS
  Widget _buildGraficos() {
    return Column(
      children: [
        // Gráfico de evolução do saldo
        _buildGraficoEvolucaoSaldo(),

        const SizedBox(height: 12),

        // Gráfico de entradas vs saídas
        _buildGraficoEntradasVsSaidas(),

        const SizedBox(height: 12),

        // Gráfico de categorias (se houver dados)
        if (_gastosPorCategoria.isNotEmpty) _buildGraficoCategorias(),
      ],
    );
  }

  /// 📈 GRÁFICO DE EVOLUÇÃO DO SALDO
  Widget _buildGraficoEvolucaoSaldo() {
    if (_evolucaoSaldo.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (igual ao device)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.azul.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: AppColors.azul,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Evolução do Saldo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Legenda do gráfico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendaItem(
                    'Saldo Real',
                    AppColors.tealPrimary,
                    isSolid: true,
                  ),
                  const SizedBox(width: 24),
                  _buildLegendaItem(
                    'Projeção',
                    AppColors.tealPrimary.withValues(alpha: 0.6),
                    isSolid: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Gráfico de linha (placeholder igual ao device)
            SizedBox(
              height: 200,
              child: _evolucaoSaldo.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_flat,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sem movimentações',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'nos últimos 12 meses',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 1,
                                dashArray: [3, 3],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < _evolucaoSaldo.length) {
                                    final item = _evolucaoSaldo[index];
                                    final mes = item['mes'] as String;
                                    return Text(
                                      mes.split(
                                        '/',
                                      )[0], // Só o mês (Set, Out, etc.)
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    CurrencyFormatter.formatCompact(value),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Linha sólida para dados reais (passado + atual)
                            LineChartBarData(
                              spots: _evolucaoSaldo
                                  .asMap()
                                  .entries
                                  .where(
                                    (entry) =>
                                        !(entry.value['isProjecao'] ?? false),
                                  )
                                  .map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final saldo =
                                        ((item['saldo'] as num?) ?? 0.0)
                                            .toDouble();
                                    return FlSpot(index.toDouble(), saldo);
                                  })
                                  .toList(),
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: AppColors.tealPrimary,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.tealPrimary.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.tealPrimary,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                            // Linha conectada para projeção (atual + futuro)
                            LineChartBarData(
                              spots: _evolucaoSaldo
                                  .asMap()
                                  .entries
                                  .where(
                                    (entry) =>
                                        (entry.value['isAtual'] ?? false) ||
                                        (entry.value['isProjecao'] ?? false),
                                  )
                                  .map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final saldo =
                                        ((item['saldo'] as num?) ?? 0.0)
                                            .toDouble();
                                    return FlSpot(index.toDouble(), saldo);
                                  })
                                  .toList(),
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: AppColors.tealPrimary.withValues(
                                alpha: 0.6,
                              ),
                              barWidth: 2,
                              dashArray: [8, 4], // Linha pontilhada
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.tealPrimary.withValues(
                                  alpha: 0.05,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  // Ponto atual fica sólido para conectar as linhas
                                  final isAtualIndex =
                                      index ==
                                      _evolucaoSaldo.indexWhere(
                                        (item) => item['isAtual'] ?? false,
                                      );
                                  return FlDotCirclePainter(
                                    radius: isAtualIndex ? 4 : 3,
                                    color: isAtualIndex
                                        ? AppColors.tealPrimary
                                        : AppColors.tealPrimary.withValues(
                                            alpha: 0.8,
                                          ),
                                    strokeWidth: isAtualIndex ? 2 : 1,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  AppColors.tealPrimary.withValues(alpha: 0.9),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final index = spot.x.toInt();
                                  if (index >= 0 &&
                                      index < _evolucaoSaldo.length) {
                                    final item = _evolucaoSaldo[index];
                                    final mes = item['mes'] as String;
                                    return LineTooltipItem(
                                      '$mes\n${CurrencyFormatter.format(spot.y)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return null;
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💸 GRÁFICO DE ENTRADAS VS SAÍDAS
  Widget _buildGraficoEntradasVsSaidas() {
    if (_entradasVsSaidas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (igual ao device)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.verdeSucesso.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: AppColors.verdeSucesso,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Entradas vs Saídas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gráfico de barras real
            SizedBox(
              height: 200,
              child: _entradasVsSaidas.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Legenda
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendaItem(
                                'Entradas',
                                AppColors.verdeSucesso,
                              ),
                              const SizedBox(width: 24),
                              _buildLegendaItem(
                                'Saídas',
                                AppColors.vermelhoErro,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_flat,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Sem movimentações',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'nos últimos 6 meses',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Legenda
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendaItem(
                              'Entradas',
                              AppColors.verdeSucesso,
                            ),
                            const SizedBox(width: 24),
                            _buildLegendaItem('Saídas', AppColors.vermelhoErro),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Gráfico de barras
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade300,
                                      strokeWidth: 1,
                                      dashArray: [3, 3],
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < _entradasVsSaidas.length) {
                                          final item = _entradasVsSaidas[index];
                                          final mes = item['mes'] as String;
                                          return Text(
                                            mes.split(
                                              '/',
                                            )[0], // Só o mês (Set, Out, etc.)
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          CurrencyFormatter.formatCompact(
                                            value,
                                          ),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _entradasVsSaidas
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final entradas =
                                          ((item['entradas'] as num?) ?? 0.0)
                                              .toDouble();
                                      final saidas =
                                          ((item['saidas'] as num?) ?? 0.0)
                                              .toDouble();

                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: entradas,
                                            color: AppColors.verdeSucesso,
                                            width: 12,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                ),
                                          ),
                                          BarChartRodData(
                                            toY: saidas,
                                            color: AppColors.vermelhoErro,
                                            width: 12,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                ),
                                          ),
                                        ],
                                        barsSpace: 4,
                                      );
                                    })
                                    .toList(),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.black87,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          if (groupIndex <
                                              _entradasVsSaidas.length) {
                                            final item =
                                                _entradasVsSaidas[groupIndex];
                                            final mes = item['mes'] as String;
                                            final isEntrada = rodIndex == 0;
                                            final valor = rod.toY;

                                            return BarTooltipItem(
                                              '$mes\n${isEntrada ? 'Entrada' : 'Saída'}: ${CurrencyFormatter.format(valor)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            );
                                          }
                                          return null;
                                        },
                                  ),
                                ),
                              ),
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

  /// 🏷️ GRÁFICO DE CATEGORIAS
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (igual ao device)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.azulHeader.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.donut_large,
                    color: AppColors.azulHeader,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Movimentações por Categoria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cinzaEscuro,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gráfico Pizza com container completo
            _gastosPorCategoria.isEmpty ||
                    _gastosPorCategoria.every((cat) => cat.valor == 0.0)
                ? Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_flat,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sem gastos\neste mês',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 300,
                      child: Row(
                        children: [
                          // Gráfico de pizza
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => _navegarParaTransacoesComFiltro(),
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null) {
                                              _touchedIndex = -1;
                                              return;
                                            }
                                            _touchedIndex = pieTouchResponse
                                                .touchedSection!
                                                .touchedSectionIndex;
                                          });
                                        },
                                  ),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                  sections: _buildPieChartSections(),
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 800,
                                ),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ..._gastosPorCategoria.take(6).map((categoria) {
                                  final cores = [
                                    Colors.blue,
                                    Colors.green,
                                    Colors.orange,
                                    Colors.red,
                                    Colors.purple,
                                    Colors.teal,
                                  ];
                                  final index = _gastosPorCategoria.indexOf(
                                    categoria,
                                  );
                                  final cor = cores[index % cores.length];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector(
                                      onTap: () =>
                                          _navegarParaTransacoesComFiltroCategoria(
                                            categoria.nome,
                                          ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: cor,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  categoria.nome,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyFormatter.format(
                                                    categoria.valor,
                                                  ),
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
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// 🧭 Navegar para TransacoesPage com filtro da conta
  Future<void> _navegarParaTransacoesComFiltro() async {
    // Define o contexto de navegação com a conta atual
    navigationContext.setContaSelecionada(widget.conta.id);

    // Navegar para a aba de transações
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransacoesPage(
            filtrosIniciais: {
              'contas': [widget.conta.id],
            },
            showNavigationBar: true,
          ),
        ),
      );
    }
  }

  /// 🧭 Navegar para TransacoesPage com filtro da conta e categoria específica
  Future<void> _navegarParaTransacoesComFiltroCategoria(
    String nomeCategoria,
  ) async {
    // Define o contexto de navegação com a conta atual
    navigationContext.setContaSelecionada(widget.conta.id);

    // Adiciona filtro por categoria
    navigationContext.adicionarFiltro('categoria', nomeCategoria);

    // Navegar para a aba de transações
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransacoesPage(
            filtrosIniciais: {
              'contas': [widget.conta.id],
              'categoria': nomeCategoria,
            },
            showNavigationBar: true,
          ),
        ),
      );
    }
  }

  /// 🏷️ ITEM DA LEGENDA
  Widget _buildLegendaItem(String texto, Color cor, {bool isSolid = true}) {
    return Row(
      children: [
        if (isSolid)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          )
        else
          // Linha pontilhada para projeção
          SizedBox(
            width: 16,
            height: 3,
            child: CustomPaint(painter: DashedLinePainter(color: cor)),
          ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, color: AppColors.cinzaTexto),
        ),
      ],
    );
  }

  /// 🎯 HELPERS

  /// Formatar mês e ano (Jan 2024)
  String _formatarMesAno(DateTime data) {
    final meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  /// Gerar insights automáticos baseados nos dados
  List<Map<String, dynamic>> _generateInsights() {
    List<Map<String, dynamic>> insights = [];

    final saldo = widget.conta.saldo;
    final percentualMedio = (_saldoMedio / saldo);

    if (percentualMedio > 0.9) {
      insights.add({
        'icone': Icons.trending_up,
        'cor': AppColors.verdeSucesso,
        'texto':
            'Seu saldo está ${percentualMedio > 1 ? 'acima' : 'próximo'} da média! Continue mantendo esse controle.',
      });
    } else if (percentualMedio < 0.7) {
      insights.add({
        'icone': Icons.warning_amber,
        'cor': Colors.orange,
        'texto':
            'Seu saldo atual está abaixo da média dos últimos meses. Considere revisar seus gastos.',
      });
    }

    if (_entradaMesAtual > _saidaMesAtual) {
      insights.add({
        'icone': Icons.thumb_up,
        'cor': AppColors.verdeSucesso,
        'texto':
            'Suas entradas estão superando as saídas este mês. Ótimo controle financeiro!',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icone': Icons.info_outline,
        'cor': AppColors.tealPrimary,
        'texto':
            'Continue acompanhando sua conta para receber insights personalizados.',
      });
    }

    return insights;
  }

  /// Parse de cor da string (copiado de contas_page)
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.tealPrimary;
    }
  }

  /// Mapper de ícone por tipo (copiado de contas_page)
  IconData _iconFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) {
      return Icons.account_balance_wallet_outlined;
    }

    switch (slug.toLowerCase()) {
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
        return Icons.account_balance_wallet_outlined;
    }
  }

  /// Navega para relatórios com filtro da conta atual
  void _navegarParaRelatoriosComFiltro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RelatoriosPage()),
    );
  }

  /// Menu da conta (igual ao contas_page)
  void _mostrarMenuConta() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.conta.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.tealPrimary),
              title: const Text('Editar Conta'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaAcao('editar_conta');
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.account_balance,
                color: AppColors.tealPrimary,
              ),
              title: const Text('Ajustar Saldo'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaAcao('ajustar_saldo');
              },
            ),

            ListTile(
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: const Text('Arquivar Conta'),
              onTap: () {
                Navigator.pop(context);
                _arquivarConta();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Obter ícone baseado no tipo da conta
  IconData _getIconeTipoConta() {
    switch (widget.conta.tipo.toLowerCase()) {
      case 'poupanca':
        return Icons.savings;
      case 'investimento':
        return Icons.trending_up;
      case 'carteira':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance;
    }
  }

  /// 🧭 Handler para navegação do bottom navigation
  void _onBottomNavigationTap(int index) {
    // Navegar para MainNavigation com o índice selecionado
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigation(initialIndex: index),
      ),
      (route) => false, // Remove todas as rotas anteriores
    );
  }
}

/// 🎨 CUSTOM PAINTER PARA LINHA PONTILHADA
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      final endX = (startX + dashWidth < size.width)
          ? startX + dashWidth
          : size.width;
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
