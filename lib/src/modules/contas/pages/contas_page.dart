// 🏦 Contas Page - iPoupei Mobile
// 
// Página principal para listagem de contas
// Design atualizado com faixa lateral colorida
// Funcionalidades completas de CRUD
// 
// Baseado em: Material Design + Navigation Pattern

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/conta_model.dart';
import '../services/conta_service.dart';
import 'conta_form_page.dart';
import 'correcao_saldo_page.dart';
import 'gestao_conta_page.dart';
import 'contas_arquivadas_page.dart';
import 'contas_sugeridas_page.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../../shared/components/ui/loading_widget.dart';
import '../../../shared/components/ui/app_error_widget.dart';
import '../../../shared/components/ui/app_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/contas_sugeridas.dart';
import '../../../sync/sync_manager.dart';
import '../../relatorios/pages/relatorios_page.dart';
import '../../../routes/main_navigation.dart';
import '../../transacoes/pages/transacao_form_page.dart';
import '../../transacoes/pages/transferencia_form_page.dart';
import '../../cartoes/pages/despesa_cartao_page.dart';
import '../../relatorios/services/transacoes_pendentes_service.dart';
import '../../relatorios/models/transacao_pendente_model.dart';
import '../../../database/local_database.dart';
import '../../../shared/services/contas_refresh_notifier.dart';

class ContasPage extends StatefulWidget {
  const ContasPage({super.key});

  @override
  State<ContasPage> createState() => _ContasPageState();
}

class _ContasPageState extends State<ContasPage> {
  // === FUNCIONALIDADE 100% DO ORIGINAL ===
  final _contaService = ContaService.instance;
  final _transacoesPendentesService = TransacoesPendentesService.instance;

  List<ContaModel> _contas = [];
  bool _loading = false;
  double _saldoTotal = 0.0;

  // === VISUAL DO TESTE 1 ===
  String _viewMode = 'consolidado'; // consolidado, mini
  String? _erro;

  // === CONTROLE DO FAB ===
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _carregarContas();

    // 🔔 Escutar notificações de mudança em contas
    ContasRefreshNotifier.instance.refreshTrigger.addListener(_onContasMudaram);
    debugPrint('🔔 [ContasPage] Listener registrado no ContasRefreshNotifier');
  }

  @override
  void dispose() {
    // 🧹 Remover listener
    ContasRefreshNotifier.instance.refreshTrigger.removeListener(_onContasMudaram);
    super.dispose();
  }

  /// 🔔 Callback quando contas mudaram (transação efetivada/desefetivada)
  void _onContasMudaram() {
    if (!mounted) return; // Evita erro se página foi fechada
    debugPrint('🔔 ContasPage: recebeu notificação de mudança, recarregando...');
    _carregarContas();
  }

  /// 🔄 CARREGAR CONTAS (limpa cache para garantir dados frescos após sync)
  Future<void> _carregarContas() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      // 🧹 FORÇA INVALIDAÇÃO DO CACHE ANTES DE RECARREGAR
      // Isso garante que dados vêm diretamente do SQLite (que foi atualizado pelo sync)
      // em vez de retornar cache desatualizado
      _contaService.limparCache();
      debugPrint('🧹 [ContasPage] Cache invalidado antes do carregamento');

      // Buscar contas ativas (método original funcionando)
      final contas = await _contaService.fetchContas();
      final contasAtivas = contas.where((c) => c.ativo).toList();

      // Buscar saldo total (método original funcionando)
      final saldoTotal = await _contaService.getSaldoTotal();

      setState(() {
        _contas = contasAtivas;
        _saldoTotal = saldoTotal;
        _loading = false;
      });

    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar contas: $e';
        _loading = false;
      });
    }
  }

  /// 🔄 REFRESH PULL-TO-REFRESH (força atualização completa)
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 Pull-to-refresh: Iniciando atualização...');

      // 1. Forçar sync com Supabase (se online)
      try {
        await SyncManager.instance.syncAll();
        debugPrint('✅ Sync forçado com Supabase concluído');
      } catch (syncError) {
        debugPrint('⚠️ Sync falhou, continuando com dados locais: $syncError');
      }

      // 2. Buscar contas ativas (forçar refresh do cache local)
      final contas = await _contaService.fetchContas(forceRefresh: true);
      final contasAtivas = contas.where((c) => c.ativo).toList();

      // 3. Buscar saldo total atualizado
      final saldoTotal = await _contaService.getSaldoTotal();

      debugPrint('🔄 Pull-to-refresh: ${contasAtivas.length} contas carregadas, saldo: R\$ ${saldoTotal.toStringAsFixed(2)}');

      setState(() {
        _contas = contasAtivas;
        _saldoTotal = saldoTotal;
        _erro = null;
      });

      // 4. Feedback visual de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contas atualizadas com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erro no pull-to-refresh: $e');
      setState(() {
        _erro = 'Erro ao atualizar contas: $e';
      });

      // Feedback visual de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao atualizar: ${e.toString()}'),
            backgroundColor: AppColors.vermelhoErro,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 🔮 BUSCAR TRANSAÇÕES PENDENTES FUTURAS ATÉ O FIM DO MÊS
  Future<List<Map<String, dynamic>>> _buscarTransacoesPendentesAteFimDoMes() async {
    try {
      final hoje = DateTime.now();
      final ultimoDiaMes = DateTime(hoje.year, hoje.month + 1, 0);

      final db = LocalDatabase.instance;
      final userId = db.currentUserId;
      if (userId == null) return [];

      // Buscar transações pendentes futuras (depois de hoje até fim do mês)
      final result = await db.rawQuery('''
        SELECT
          t.id,
          t.descricao,
          t.valor,
          t.data,
          t.tipo,
          t.categoria_id,
          c.nome as categoria_nome,
          c.cor as categoria_cor,
          c.icone as categoria_icone
        FROM transacoes t
        LEFT JOIN categorias c ON t.categoria_id = c.id
        WHERE t.usuario_id = ?
          AND t.efetivado = 0
          AND t.cartao_id IS NULL
          AND (t.transferencia IS NULL OR t.transferencia = 0 OR t.transferencia = ?)
          AND DATE(t.data) > DATE(?)
          AND DATE(t.data) <= DATE(?)
      ''', [
        userId,
        false,
        hoje.toIso8601String().split('T')[0], // Depois de hoje
        ultimoDiaMes.toIso8601String().split('T')[0], // Até fim do mês
      ]);

      return result;
    } catch (e) {
      debugPrint('❌ Erro ao buscar transações futuras: $e');
      return [];
    }
  }

  /// 📊 CALCULAR PROJEÇÃO BASEADA EM TRANSAÇÕES PENDENTES ATÉ O FIM DO MÊS
  Future<Map<String, double>> _calcularProjecao() async {
    try {
      // Buscar transações pendentes vencidas (método original)
      final transacoesVencidas = await _transacoesPendentesService.buscarTransacoesPendentes();

      // Buscar transações pendentes futuras até o fim do mês
      final transacoesFuturasRaw = await _buscarTransacoesPendentesAteFimDoMes();
      final transacoesFuturas = transacoesFuturasRaw
          .map((data) => TransacaoPendente.fromMap(data))
          .toList();

      // Combinar todas as transações pendentes
      final transacoesPendentes = [...transacoesVencidas, ...transacoesFuturas];

      // Separar por tipo
      double receitasPendentes = 0.0;
      double despesasPendentes = 0.0;

      for (final transacao in transacoesPendentes) {
        if (transacao.tipo == 'receita') {
          receitasPendentes += transacao.valor;
        } else if (transacao.tipo == 'despesa') {
          despesasPendentes += transacao.valor;
        }
      }

      // Calcular projeção: Saldo Atual + Receitas Pendentes - Despesas Pendentes
      final projecao = _saldoTotal + receitasPendentes - despesasPendentes;

      return {
        'receitas_pendentes': receitasPendentes,
        'despesas_pendentes': despesasPendentes,
        'projecao': projecao,
        'total_pendente': receitasPendentes - despesasPendentes, // Líquido
      };
    } catch (e) {
      debugPrint('Erro ao calcular projeção: $e');
      return {
        'receitas_pendentes': 0.0,
        'despesas_pendentes': 0.0,
        'projecao': _saldoTotal,
        'total_pendente': 0.0,
      };
    }
  }

  /// 🧹 LIMPAR QUEUE DE SYNC (funcionalidade original)
  Future<void> _limparQueueSync() async {
    try {
      setState(() => _loading = true);
      
      await SyncManager.instance.clearSyncQueue();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Queue de sync limpa com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar queue: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ➕ NAVEGAR PARA CRIAR CONTA (funcionalidade original)
  void _navegarParaCriarConta() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ContaFormPage(modo: 'criar'),
      ),
    );

    if (resultado == true) {
      _carregarContas();
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
      _carregarContas(); // Atualizar saldos
    }
  }

  /// 💸 NAVEGAR PARA NOVA DESPESA
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
      _carregarContas(); // Atualizar saldos
    }
  }

  /// 💳 NAVEGAR PARA NOVA DESPESA CARTÃO
  void _navegarParaNovaDespesaCartao() async {
    setState(() => _fabExpanded = false);

    // ✅ Usar página específica para despesas de cartão
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const DespesaCartaoPage(),
      ),
    );

    if (resultado == true) {
      _carregarContas(); // Atualizar saldos
    }
  }

  /// 🏦 NAVEGAR PARA CRIAR CONTA DO FAB
  void _navegarParaCriarContaFab() async {
    setState(() => _fabExpanded = false);
    _navegarParaCriarConta();
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
      _carregarContas(); // Atualizar saldos
    }
  }

  /// ✏️ NAVEGAR PARA EDITAR CONTA (funcionalidade original)
  void _navegarParaGestaoCompleta(ContaModel conta) async {
    final bool? precisaAtualizar = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => GestaoContaPage(conta: conta),
      ),
    );
    
    // 🔄 RECARREGAR DADOS QUANDO VOLTAR DA GESTÃO
    // (sempre recarrega para garantir sincronização com gráficos)
    if (precisaAtualizar == true || precisaAtualizar == null) {
      _carregarContas();
    }
  }

  void _navegarParaEditarConta(ContaModel conta) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ContaFormPage(modo: 'editar', conta: conta),
      ),
    );
    
    if (resultado == true) {
      _carregarContas();
    }
  }

  /// 🔧 NAVEGAR PARA CORREÇÃO DE SALDO (funcionalidade original)
  void _navegarParaCorrecaoSaldo(ContaModel conta) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CorrecaoSaldoPage(conta: conta),
      ),
    );
    
    if (resultado == true) {
      _carregarContas();
    }
  }

  /// 📂 NAVEGAR PARA CONTAS ARQUIVADAS
  void _navegarParaContasArquivadas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContasArquivadasPage(),
      ),
    );
    // Recarregar contas caso alguma tenha sido restaurada
    _carregarContas();
  }

  /// 🎯 CRIAR DADOS DEMO (funcionalidade original)
  Future<void> _criarDadosDemo() async {
    try {
      setState(() => _loading = true);

      // Criar múltiplas contas demo para demonstração
      final contasDemo = [
        {
          'nome': 'Conta Corrente Itaú',
          'tipo': 'corrente',
          'banco': 'Itaú',
          'saldoInicial': 2500.0,
          'cor': '#FF6B00',
        },
        {
          'nome': 'Poupança Caixa',
          'tipo': 'poupanca',
          'banco': 'Caixa Econômica',
          'saldoInicial': 1800.0,
          'cor': '#0066CC',
        },
        {
          'nome': 'Carteira Digital',
          'tipo': 'carteira',
          'banco': 'PicPay',
          'saldoInicial': 150.0,
          'cor': '#21C25E',
        },
      ];

      for (final conta in contasDemo) {
        await _contaService.addConta(
          nome: conta['nome'] as String,
          tipo: conta['tipo'] as String,
          banco: conta['banco'] as String,
          saldoInicial: conta['saldoInicial'] as double,
          cor: conta['cor'] as String,
        );
      }

      await _carregarContas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contas demo criadas com sucesso!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar dados demo: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🏦 NAVEGAR PARA CONTAS POPULARES (abre página de contas sugeridas)
  Future<void> _navegarParaContasPopulares() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContasSugeridasPage(),
      ),
    );

    // Se contas foram importadas, recarregar dados
    if (result == true || mounted) {
      await _carregarContas();
    }
  }

  /// MÉTODO ANTIGO PRESERVADO COMO BACKUP
  /// 🏦 CRIAR CONTAS BÁSICAS (versão simples - 3 contas básicas)
  Future<void> _criarContasBasicas() async {
    try {
      setState(() => _loading = true);

      // Criar os 3 tipos básicos de conta que todo mundo precisa
      final contasBasicas = [
        {
          'nome': 'Conta Corrente',
          'tipo': 'corrente',
          'banco': 'Banco Principal',
          'saldoInicial': 0.0,
          'cor': '#2196F3', // Azul para corrente
        },
        {
          'nome': 'Carteira',
          'tipo': 'carteira',
          'banco': 'Dinheiro Físico',
          'saldoInicial': 0.0,
          'cor': '#4CAF50', // Verde para carteira
        },
        {
          'nome': 'Poupança',
          'tipo': 'poupanca',
          'banco': 'Reserva de Emergência',
          'saldoInicial': 0.0,
          'cor': '#FF9800', // Laranja para poupança
        },
      ];

      for (final conta in contasBasicas) {
        await _contaService.addConta(
          nome: conta['nome'] as String,
          tipo: conta['tipo'] as String,
          banco: conta['banco'] as String,
          saldoInicial: conta['saldoInicial'] as double,
          cor: conta['cor'] as String,
        );
      }

      await _carregarContas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contas básicas criadas: Corrente, Carteira e Poupança!'),
            backgroundColor: AppColors.verdeSucesso,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar contas básicas: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }


  /// Parse de cor da string (visual do teste1)
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.tealPrimary;
    }
  }

  /// Buscar logo do banco nas contas sugeridas
  String? _getLogoBanco(ContaModel conta) {
    if (conta.banco == null || conta.banco!.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == conta.banco,
        orElse: () => <String, dynamic>{},
      );

      return bancoEncontrado['logo'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Buscar cor oficial do banco dos dados sugeridos
  Color? _getCorFromBankData(String? banco) {
    if (banco == null || banco.isEmpty) return null;

    try {
      final bancoEncontrado = ContasSugeridas.todas.firstWhere(
        (contaSugerida) => contaSugerida['banco'] == banco,
        orElse: () => <String, dynamic>{},
      );

      final corString = bancoEncontrado['cor'] as String?;
      if (corString != null && corString.isNotEmpty) {
        return _parseColor(corString);
      }
    } catch (e) {
      // Falha silenciosa
    }
    return null;
  }

  /// Widget de logo do banco em formato circular
  Widget _buildIconeComLogo(ContaModel conta, {required double size, bool isCompact = false}) {
    final logo = _getLogoBanco(conta);
    final corConta = _parseColor(conta.cor ?? '#008080');
    final corOficialBanco = _getCorFromBankData(conta.banco);

    // Usar cor oficial do banco se disponível, senão cor da conta
    final corFinal = corOficialBanco ?? corConta;

    // Se tem logo, usar bolinha branca com logo
    if (logo != null && logo.isNotEmpty) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: _buildLogoWidget(logo, size: size, fallbackColor: corFinal),
      );
    }

    // Fallback: ícone tradicional
    return Icon(
      _iconFromSlug(conta.tipo),
      color: Colors.white,
      size: size,
    );
  }

  /// Widget de logo com fallback
  Widget _buildLogoWidget(String logo, {required double size, required Color fallbackColor}) {
    final fallbackIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(
        Icons.account_balance,
        color: Colors.white,
        size: size * 0.6,
      ),
    );

    try {
      final lowerLogo = logo.toLowerCase();

      if (lowerLogo.endsWith('.svg')) {
        return SvgPicture.asset(
          logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) => fallbackIcon,
        );
      }

      return Image.asset(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallbackIcon,
      );
    } catch (e) {
      return fallbackIcon;
    }
  }

  /// Mapper de ícone por tipo (visual do teste1)
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

  /// Formatar tipo de conta (visual do teste1)
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
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,

      // AppBar com visual simplificado
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 42,
        title: const Text(
          'Gerenciar Contas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // 1. Visualização
          IconButton(
            icon: Icon(
              _viewMode == 'consolidado' ? Icons.view_module : Icons.view_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'consolidado' ? 'mini' : 'consolidado';
              });
            },
            tooltip: _viewMode == 'consolidado' ? 'Mini cards' : 'Cards normais',
          ),

          // 2. Importar Contas (ícone de cartão)
          IconButton(
            icon: const Icon(
              Icons.credit_card,
              color: Colors.white,
            ),
            onPressed: _navegarParaContasPopulares,
            tooltip: 'Importar Contas',
          ),

          // 3. Nova Conta
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: _navegarParaCriarConta,
            tooltip: 'Nova conta',
          ),

          // 4. Arquivadas
          IconButton(
            icon: const Icon(
              Icons.archive,
              color: Colors.white,
            ),
            onPressed: _navegarParaContasArquivadas,
            tooltip: 'Ver arquivadas',
          ),
        ],
      ),

      body: Stack(
        children: [
          _buildConteudo(),
          _buildFABOverlay(),
        ],
      ),

      // FAB principal
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        elevation: _fabExpanded ? 8 : 6,
        onPressed: () {
          setState(() => _fabExpanded = !_fabExpanded);
        },
        child: AnimatedRotation(
          turns: _fabExpanded ? 0.125 : 0, // Rotação de 45 graus
          duration: const Duration(milliseconds: 200),
          child: Icon(_fabExpanded ? Icons.close : Icons.add),
        ),
      ),
    );
  }

  /// Conteúdo principal
  Widget _buildConteudo() {
    if (_loading) {
      return const Center(
        child: LoadingWidget(
          message: 'Carregando contas...',
          color: AppColors.tealPrimary,
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: AppErrorWidget(
          message: _erro!,
          onRetry: _carregarContas,
        ),
      );
    }

    // Layout para contas ativas
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card de resumo
            _buildResumoCard(),

            const SizedBox(height: 16),

            // Lista de contas
            if (_contas.isEmpty)
              _buildVazio()
            else if (_viewMode == 'consolidado')
              ..._contas.map((conta) => _buildContaItem(conta))
            else
              ..._contas.map((conta) => _buildContaSimples(conta)),

            const SizedBox(height: 32),

            // Botões inferiores
            _buildBotoesInferiores(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Widget estado vazio
  Widget _buildVazio() {
    // Estado vazio elegante para contas ativas
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone principal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.tealPrimary,
              ),
            ),

            const SizedBox(height: 24),

            // Título
            const Text(
              'Nenhuma conta cadastrada',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.cinzaEscuro,
              ),
            ),

            const SizedBox(height: 12),

            // Descrição
            const Text(
              'Comece organizando suas finanças adicionando suas contas bancárias, carteiras e investimentos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.cinzaTexto,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 32),

            // Botão principal - Contas Básicas
            AppButton(
              text: 'Criar Contas Básicas',
              onPressed: _navegarParaContasPopulares,
              variant: AppButtonVariant.primary,
              customColor: AppColors.tealPrimary,
              icon: Icons.account_balance,
              fullWidth: true,
            ),

            const SizedBox(height: 12),

            // Botão secundário - Criar personalizada
            AppButton(
              text: 'Criar Conta Personalizada',
              onPressed: _navegarParaCriarConta,
              variant: AppButtonVariant.outline,
              customColor: AppColors.tealPrimary,
              icon: Icons.add,
              fullWidth: true,
            ),

            const SizedBox(height: 12),

            // Botão terciário - Demo
            AppButton(
              text: 'Testar com Dados Demo',
              onPressed: _criarDadosDemo,
              variant: AppButtonVariant.outline,
              customColor: AppColors.cinzaTexto,
              icon: Icons.play_arrow,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Modo consolidado (visual do teste1 + funcionalidades reais)
  Widget _buildModoConsolidado(List<ContaModel> contas) {
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _buildResumoCard(),
              const SizedBox(height: 24),
              _buildListaEmbebida(contas),
              const SizedBox(height: 32),
              _botoesInferiores(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Modo empilhado (visual do teste1)
  Widget _buildModoEmpilhado(List<ContaModel> contas) {
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _buildResumoCard(),
              const SizedBox(height: 24),
              ...contas.map((conta) => _buildContaSimples(conta)),
              const SizedBox(height: 32),
              _botoesInferiores(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de resumo (visual da screenshot)
  Widget _buildResumoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.tealPrimary, AppColors.tealPrimary.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealPrimary.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primeira linha: Ícone + Saldo | Contas Ativas + Número
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone + Saldo
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(_saldoTotal), // SALDO REAL!
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Contas Ativas
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Contas Ativas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(208),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        '${_contas.length}', // QUANTIDADE REAL!
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Projeção (saldo + receitas pendentes - despesas pendentes)
          FutureBuilder<Map<String, double>>(
            future: _calcularProjecao(),
            builder: (context, snapshot) {
              final dados = snapshot.data ?? {
                'receitas_pendentes': 0.0,
                'despesas_pendentes': 0.0,
                'projecao': _saldoTotal,
                'total_pendente': 0.0,
              };

              final projecao = dados['projecao'] ?? _saldoTotal;
              final receitasPendentes = dados['receitas_pendentes'] ?? 0.0;
              final despesasPendentes = dados['despesas_pendentes'] ?? 0.0;
              final totalPendente = dados['total_pendente'] ?? 0.0;

              final temPendentes = receitasPendentes > 0 || despesasPendentes > 0;

              if (!temPendentes) {
                return const SizedBox.shrink(); // Não mostra se não tem pendentes
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Projetado (fim do mês)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        totalPendente >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: totalPendente >= 0 ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(projecao),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(+${CurrencyFormatter.format(receitasPendentes)} -${CurrencyFormatter.format(despesasPendentes)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Lista embebida (visual do teste1)
  Widget _buildListaEmbebida(List<ContaModel> contas) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 0),
      itemCount: contas.length,
      itemBuilder: (context, i) => _buildContaItem(contas[i]),
    );
  }

  /// Card de conta (visual com faixa lateral colorida como offline)
  Widget _buildContaItem(ContaModel conta) {
    final cor = _parseColor(conta.cor ?? '#008080');
    final saldoNegativo = conta.saldo < 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navegarParaGestaoCompleta(conta),
          child: Container(
            height: 85, // Aumentado de 71 para 85 (+20%)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.branco,
            ),
            child: Row(
              children: [
                // 🎨 FAIXA LATERAL COLORIDA EXPANDIDA
                Container(
                  width: 55, // Expandido para dar mais destaque
                  decoration: BoxDecoration(
                    color: cor, // Cor da conta
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: _buildIconeComLogo(conta, size: 24), // Logo maior na bolinha
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
                                  conta.nome,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cinzaEscuro,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(conta.saldo),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: saldoNegativo ? Colors.red[600] : Colors.green[600],
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
                                '${conta.banco ?? 'Sem banco'} • Conta',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.cinzaTexto,
                                ),
                              ),
                            ),
                            
                            // Menu três pontinhos
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _mostrarMenuConta(conta),
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

  /// Mini card para modo empilhado (visual do teste1 + funcionalidades reais)
  Widget _buildContaSimples(ContaModel conta) {
    final cor = _parseColor(conta.cor ?? '#008080');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _mostrarMenuConta(conta), // MENU REAL!
          child: Container(
            height: 72, // Aumentado de 60 para 72 (+20%)
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  cor,
                  cor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, // Maior para acomodar bolinha
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: _buildIconeComLogo(conta, size: 20, isCompact: true), // Tamanho da bolinha
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        conta.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conta.banco != null)
                        Text(
                          conta.banco!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha(208),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      CurrencyFormatter.format(conta.saldo),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  /// Menu da conta com FUNCIONALIDADES REAIS
  /// 🎯 MOSTRAR MENU DA CONTA (funcionalidades completas)
  void _mostrarMenuConta(ContaModel conta) {
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
              conta.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.tealPrimary),
              title: const Text('Gestão Completa'),
              subtitle: const Text('Insights, gráficos e análises'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaGestaoCompleta(conta);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.tealPrimary),
              title: const Text('Editar Conta'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaEditarConta(conta);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.account_balance, color: AppColors.tealPrimary),
              title: const Text('Ajustar Saldo'),
              onTap: () {
                Navigator.pop(context);
                _navegarParaCorrecaoSaldo(conta);
              },
            ),
            
            if (conta.ativo) ...[
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.orange),
                title: const Text('Arquivar Conta'),
                onTap: () {
                  Navigator.pop(context);
                  _arquivarConta(conta);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.unarchive, color: Colors.green),
                title: const Text('Desarquivar Conta'),
                onTap: () {
                  Navigator.pop(context);
                  _desarquivarConta(conta);
                },
              ),
            ],
            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir Conta'),
              onTap: () {
                Navigator.pop(context);
                _excluirConta(conta);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Botões inferiores (roláveis com o conteúdo)
  Widget _buildBotoesInferiores() {
    return Row(
      children: [
        // Botão VOLTAR (lado esquerdo)
        Expanded(
          child: AppButton.outline(
            text: 'VOLTAR',
            icon: Icons.arrow_back,
            size: AppButtonSize.medium,
            onPressed: () {
              // Se pode voltar (veio de outra página, como diagnóstico), volta
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // Se não pode voltar (página inicial), vai para navegação principal
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 2), // Índice 2 = Relatórios
                  ),
                  (route) => false,
                );
              }
            },
            customColor: AppColors.tealPrimary,
            fullWidth: true,
          ),
        ),

        const SizedBox(width: 12),

        // Botão NOVA CONTA (lado direito)
        Expanded(
          child: AppButton.primary(
            text: 'NOVA CONTA',
            icon: Icons.add,
            size: AppButtonSize.medium,
            onPressed: _navegarParaCriarConta,
            customColor: AppColors.tealPrimary,
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  /// Botões inferiores (visual do teste1) - MÉTODO ANTIGO
  Widget _botoesInferiores() {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AppButton(
                text: 'NOVA CONTA',
                icon: Icons.add,
                onPressed: _navegarParaCriarConta, // FUNÇÃO REAL!
                variant: AppButtonVariant.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AppButton(
                text: 'VOLTAR',
                icon: Icons.arrow_back,
                onPressed: () {
                  // Se pode voltar (veio de outra página, como diagnóstico), volta
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Se não pode voltar (página inicial), vai para navegação principal
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigation(initialIndex: 2), // Índice 2 = Relatórios
                      ),
                      (route) => false,
                    );
                  }
                },
                variant: AppButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💬 MOSTRAR DIÁLOGO DE MOTIVO
  Future<String?> _mostrarDialogMotivo(String titulo, String label) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// ❓ MOSTRAR CONFIRMAÇÃO
  Future<bool> _mostrarConfirmacao(String titulo, String mensagem) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 🗃️ ARQUIVAR CONTA
  void _arquivarConta(ContaModel conta) async {
    final motivo = await _mostrarDialogMotivo('Arquivar', 'Digite o motivo (opcional):');
    if (motivo == null) return; // Usuário cancelou
    
    try {
      // Mostra loading durante operação
      setState(() => _loading = true);
      
      await _contaService.arquivarConta(conta.id, motivo: motivo);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 Arquivando "${conta.nome}"... Sincronizando com Supabase'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 🔄 Recarrega lista de contas
        await _carregarContas();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao arquivar conta: $e'),
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

  /// 📤 DESARQUIVAR CONTA
  void _desarquivarConta(ContaModel conta) async {
    try {
      // Mostra loading durante operação
      setState(() => _loading = true);
      
      await _contaService.desarquivarConta(conta.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📤 Desarquivando "${conta.nome}"... Sincronizando com Supabase'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 🔄 Recarrega lista de contas
        await _carregarContas();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desarquivar conta: $e'),
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

  /// 🗑️ EXCLUIR CONTA
  void _excluirConta(ContaModel conta) async {
    final confirmacao = await _mostrarConfirmacao(
      'Excluir Conta',
      'Tem certeza que deseja excluir a conta "${conta.nome}"?\n\nEsta ação não pode ser desfeita.',
    );
    
    if (!confirmacao) return;

    try {
      await _contaService.excluirConta(conta.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conta "${conta.nome}" excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarContas();
      }
    } catch (e) {
      if (mounted) {
        // Se há transações vinculadas, oferece exclusão forçada
        if (e.toString().contains('transações') || e.toString().contains('possui')) {
          final forcarExclusao = await _mostrarConfirmacao(
            'Conta possui transações',
            'A conta "${conta.nome}" possui transações vinculadas.\n\nDeseja mesmo excluir? Isso também excluirá todas as transações relacionadas.',
          );
          
          if (forcarExclusao) {
            try {
              await _contaService.excluirConta(conta.id, confirmacao: true);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conta "${conta.nome}" e suas transações foram excluídas!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _carregarContas();
              }
            } catch (e2) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao forçar exclusão: $e2'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir conta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 🎯 OVERLAY E MENU DO FAB (COBRE TELA TODA)
  Widget _buildFABOverlay() {
    if (!_fabExpanded) return const SizedBox.shrink();

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
                icon: Icons.account_balance,
                label: 'Nova Conta',
                color: AppColors.tealPrimary,
                onTap: _navegarParaCriarContaFab,
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
                onTap: _navegarParaNovaDespesa,
              ),
              const SizedBox(height: 12),
              _buildFABOption(
                icon: Icons.credit_card,
                label: 'Despesa Cartão',
                color: Colors.orange,
                onTap: _navegarParaNovaDespesaCartao,
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

}
