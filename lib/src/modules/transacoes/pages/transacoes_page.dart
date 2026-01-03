// 💳 Transações Page - iPoupei Mobile
//
// Página principal para listagem e gestão de transações
// Implementa padrões UX do iPoupei Device com offline-first
// Features: Tabs, Cards Adaptativos, Agrupamento, Timeline
//
// Baseado em: Device UX Patterns + Material Design

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/app_colors.dart';
import '../../../database/local_database.dart';
import '../../../shared/components/ui/app_button.dart';
import '../models/transacao_model.dart';
import '../services/transacao_service.dart';
import '../services/transacao_edit_service.dart';
import 'editar_transacao_page.dart';
import '../../contas/models/conta_model.dart';
import '../../contas/services/conta_service.dart';
import '../../cartoes/models/cartao_model.dart';
import '../../cartoes/models/fatura_model.dart';
import '../../cartoes/services/cartao_service.dart';
import '../../cartoes/services/cartao_data_service.dart';
import '../../cartoes/widgets/cartao_card.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';
import 'transacao_form_page.dart';
import 'transferencia_form_page.dart';
import '../../cartoes/pages/despesa_cartao_page.dart';
import '../components/filtros_transacoes_modal.dart';
import '../components/timeline_transacoes.dart';
import '../../../services/grupos_metadados_service.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../routes/main_navigation.dart';
import '../components/transaction_detail_card.dart';
import '../../importacao/pages/importacao_modal.dart';
import '../../../shared/components/modals/transacao_opcoes_modal.dart';
import '../../../shared/components/navigation/app_bottom_navigation.dart';

/// Enum para modos de visualização - Padrão Device
enum TransacoesPageMode {
  todas(
    titulo: 'Todas',
    corHeader: Colors.teal, // teal igual ao contas
    icone: Icons.receipt_long,
  ),
  receitas(
    titulo: 'Receitas',
    corHeader: Colors.teal, // teal igual ao contas
    icone: Icons.trending_up,
    filtroTipo: 'receita',
  ),
  despesas(
    titulo: 'Despesas',
    corHeader: Color(0xFFDC2626), // red-600
    icone: Icons.trending_down,
    filtroTipo: 'despesa',
  ),
  cartoes(
    titulo: 'Cartões',
    corHeader: Color(0xFF7C3AED), // purple-600
    icone: Icons.credit_card,
    filtroTipo: 'despesa',
    apenasCartao: true,
  ),
  transferencias(
    titulo: 'Transf.',
    corHeader: Color(0xFF0EA5E9), // sky-500
    icone: Icons.swap_horiz,
    filtroTipo: 'transferencia',
  );

  const TransacoesPageMode({
    required this.titulo,
    required this.corHeader,
    required this.icone,
    this.filtroTipo,
    this.apenasCartao = false,
  });

  final String titulo;
  final Color corHeader;
  final IconData icone;
  final String? filtroTipo;
  final bool apenasCartao;
}

/// Filtros de período para navegação temporal
enum FiltroPeriodo {
  mesAtual(titulo: 'Mês Atual', icone: Icons.calendar_today),
  anoAtual(titulo: 'Ano Atual', icone: Icons.date_range),
  ultimos3Meses(titulo: 'Últimos 3 Meses', icone: Icons.calendar_month),
  ultimos6Meses(titulo: 'Últimos 6 Meses', icone: Icons.date_range),
  anoCompleto(titulo: 'Ano Completo', icone: Icons.date_range_outlined),
  personalizado(
    titulo: 'Período Personalizado',
    icone: Icons.calendar_view_week,
  );

  const FiltroPeriodo({required this.titulo, required this.icone});

  final String titulo;
  final IconData icone;
}

/// Visões rápidas pragmáticas
enum VisaoRapida {
  // Status
  pendentes(
    titulo: 'Pendentes (sem cartão)',
    icone: Icons.pending_actions,
    categoria: 'Status',
  ),
  faturasPendentes(
    titulo: 'Faturas Pendentes',
    icone: Icons.credit_card_outlined,
    categoria: 'Status',
  ),
  efetivadas(
    titulo: 'Efetivadas',
    icone: Icons.check_circle_outline,
    categoria: 'Status',
  ),
  vencidas(
    titulo: 'Vencidas',
    icone: Icons.warning_outlined,
    categoria: 'Status',
  ),

  // Origem
  porCartao(
    titulo: 'Por Cartão',
    icone: Icons.credit_card,
    categoria: 'Origem',
  ),
  porConta(
    titulo: 'Por Conta',
    icone: Icons.account_balance_wallet,
    categoria: 'Origem',
  ),
  transferencias(
    titulo: 'Transf.',
    icone: Icons.swap_horiz,
    categoria: 'Origem',
  ),

  // Combinadas
  despesasMes(
    titulo: 'Despesas do Mês',
    icone: Icons.trending_down,
    categoria: 'Inteligentes',
  ),
  receitasAno(
    titulo: 'Receitas do Ano',
    icone: Icons.trending_up,
    categoria: 'Inteligentes',
  );

  const VisaoRapida({
    required this.titulo,
    required this.icone,
    required this.categoria,
  });

  final String titulo;
  final IconData icone;
  final String categoria;
}

/// Enum para filtros inteligentes pré-definidos (DEPRECATED - mantido por compatibilidade)
enum FiltroInteligente {
  // Por período
  mesAtual(
    titulo: 'Mês Atual',
    icone: Icons.calendar_today,
    categoria: 'Período',
  ),
  anoAtual(titulo: 'Ano Atual', icone: Icons.date_range, categoria: 'Período'),
  ultimos3Meses(
    titulo: 'Últimos 3 Meses',
    icone: Icons.calendar_month,
    categoria: 'Período',
  ),
  ultimos6Meses(
    titulo: 'Últimos 6 Meses',
    icone: Icons.date_range,
    categoria: 'Período',
  ),

  // Por status
  transacoesPendentes(
    titulo: 'Pendentes (sem cartão)',
    icone: Icons.pending_actions,
    categoria: 'Status',
  ),
  faturasPendentes(
    titulo: 'Faturas Pendentes',
    icone: Icons.credit_card_outlined,
    categoria: 'Status',
  ),
  transacoesEfetivadas(
    titulo: 'Efetivadas',
    icone: Icons.check_circle_outline,
    categoria: 'Status',
  ),
  transacoesVencidas(
    titulo: 'Vencidas',
    icone: Icons.warning_outlined,
    categoria: 'Status',
  ),

  // Por origem
  porCartao(
    titulo: 'Por Cartão',
    icone: Icons.credit_card,
    categoria: 'Origem',
  ),
  porConta(
    titulo: 'Por Conta',
    icone: Icons.account_balance_wallet,
    categoria: 'Origem',
  ),
  transferencias(
    titulo: 'Transf.',
    icone: Icons.swap_horiz,
    categoria: 'Origem',
  ),

  // Combinados inteligentes
  despesasMes(
    titulo: 'Despesas do Mês',
    icone: Icons.trending_down,
    categoria: 'Inteligentes',
  ),
  receitasAno(
    titulo: 'Receitas do Ano',
    icone: Icons.trending_up,
    categoria: 'Inteligentes',
  );

  const FiltroInteligente({
    required this.titulo,
    required this.icone,
    required this.categoria,
  });

  final String titulo;
  final IconData icone;
  final String categoria;
}

class TransacoesPage extends StatefulWidget {
  final TransacoesPageMode modoInicial;
  final Map<String, dynamic>? filtrosIniciais;
  final bool showNavigationBar;

  const TransacoesPage({
    super.key,
    this.modoInicial = TransacoesPageMode.todas,
    this.filtrosIniciais,
    this.showNavigationBar = false,
  });

  @override
  State<TransacoesPage> createState() => _TransacoesPageState();
}

class _TransacoesPageState extends State<TransacoesPage>
    with SingleTickerProviderStateMixin {
  // Services (mantendo offline-first)
  final _transacaoService = TransacaoService.instance;
  final _contaService = ContaService.instance;
  final _cartaoService = CartaoService.instance;
  final _categoriaService = CategoriaService.instance;

  // Dados
  List<TransacaoModel> _transacoes = [];
  List<ContaModel> _contas = [];
  List<CartaoModel> _cartoes = [];
  List<CategoriaModel> _categorias = [];
  List<SubcategoriaModel> _subcategorias = [];
  bool _loading = false;

  // Controles de navegação - Padrão Device
  late TabController _tabController;
  TransacoesPageMode _modoAtual = TransacoesPageMode.todas;

  // Filtros e período
  DateTime _mesAtual = DateTime.now();
  String? _contaFiltro;
  bool _agruparPorDia = true;
  bool _mostrarPendentes = true;

  // Filtros por categoria
  FiltroPeriodo? _periodoAtivo;

  // FASE 2: Migração gradual das visões rápidas para busca inteligente
  @Deprecated('Use busca inteligente + filtros. Será removido na Fase 3')
  VisaoRapida? _visaoAtiva; // TODO: Migrar para _filtroBusca

  @Deprecated('Use busca inteligente + filtros. Será removido na Fase 3')
  VisaoRapida? _visaoTempSelecionada; // TODO: Migrar para _filtroBusca

  FiltroInteligente? _filtroAtivo; // DEPRECATED - mantido por compatibilidade
  Map<String, dynamic> _parametrosFiltro = {};

  // Toggle específico para cartões - Padrão Device
  bool _porFatura = true; // true = "Por Fatura", false = "Detalhado"

  // Modos de visualização disponíveis
  int _modoVisualizacao = 0; // 0 = Lista, 1 = Lista Compacta, 2 = Timeline

  // Variável para o FAB
  bool _fabExpanded = false;

  // Filtros avançados
  Map<String, dynamic> _filtrosPersonalizados = {
    'categorias': <String>[],
    'contas': <String>[],
    'cartoes': <String>[],
    'status': <String>[],
    'valorMinimo': 0.0,
    'valorMaximo': 999999.0,
    'dataInicio': null,
    'dataFim': null,
  };

  // Filtro de busca por texto
  String _filtroBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  // Search overlay state
  bool _showSearchOverlay = false;
  OverlayEntry? _overlayEntry;

  // Resumo adaptativo
  Map<String, double> _estatisticas = {};

  @override
  void initState() {
    super.initState();

    // Inicializar TabController - Padrão Device
    _tabController = TabController(
      length: TransacoesPageMode.values.length,
      vsync: this,
      initialIndex: widget.modoInicial.index,
    );
    _modoAtual = widget.modoInicial;

    // Aplicar filtros iniciais se fornecidos
    if (widget.filtrosIniciais != null) {
      debugPrint(
        '🎯 TransacoesPage: Recebendo filtros iniciais: ${widget.filtrosIniciais}',
      );
      _aplicarFiltrosIniciais(widget.filtrosIniciais!);
    } else {
      debugPrint('🎯 TransacoesPage: Nenhum filtro inicial fornecido');
    }

    // Listener para mudanças de tab
    _tabController.addListener(_onTabChanged);

    // Carregar dados
    _carregarDados();
  }

  void _aplicarFiltrosIniciais(Map<String, dynamic> filtros) {
    setState(() {
      // Aplicar filtros de status
      if (filtros.containsKey('status')) {
        _filtrosPersonalizados['status'] = List<String>.from(filtros['status']);

        // Se incluir 'pendente', mostrar pendentes
        if (filtros['status'].contains('pendente')) {
          _mostrarPendentes = true;
        }
      }

      // Aplicar filtros de data
      if (filtros.containsKey('dataInicio')) {
        _filtrosPersonalizados['dataInicio'] = filtros['dataInicio'];
      }

      if (filtros.containsKey('dataFim')) {
        _filtrosPersonalizados['dataFim'] = filtros['dataFim'];
      }

      // Aplicar filtro de mês/ano específico
      if (filtros.containsKey('mes') && filtros.containsKey('ano')) {
        final mes = filtros['mes'] as int;
        final ano = filtros['ano'] as int;
        _filtrosPersonalizados['dataInicio'] = DateTime(ano, mes, 1);
        _filtrosPersonalizados['dataFim'] = DateTime(ano, mes + 1, 0);
        debugPrint('🎯 Aplicando filtro de período: $mes/$ano');
      }

      // Aplicar filtros de conta individual (contexto de navegação)
      if (filtros.containsKey('conta_id')) {
        _filtrosPersonalizados['contas'] = [filtros['conta_id']];
        debugPrint('🎯 Aplicando filtro de conta: ${filtros['conta_id']}');
      }

      // Aplicar filtros de cartão individual (contexto de navegação)
      if (filtros.containsKey('cartao_id')) {
        _filtrosPersonalizados['cartoes'] = [filtros['cartao_id']];
        debugPrint('🎯 Aplicando filtro de cartão: ${filtros['cartao_id']}');
      }

      // Aplicar filtros de categoria individual (contexto de navegação)
      if (filtros.containsKey('categoria_id')) {
        _filtrosPersonalizados['categorias'] = [filtros['categoria_id']];
        debugPrint(
          '🎯 Aplicando filtro de categoria: ${filtros['categoria_id']}',
        );
      }

      // Aplicar filtros de subcategoria individual (contexto de navegação)
      if (filtros.containsKey('subcategoria_id')) {
        _filtrosPersonalizados['subcategorias'] = [filtros['subcategoria_id']];
        debugPrint(
          '🎯 Aplicando filtro de subcategoria: ${filtros['subcategoria_id']}',
        );
      }

      // Aplicar outros filtros se necessário
      if (filtros.containsKey('categorias')) {
        _filtrosPersonalizados['categorias'] = List<String>.from(
          filtros['categorias'],
        );
      }

      if (filtros.containsKey('subcategorias')) {
        _filtrosPersonalizados['subcategorias'] = List<String>.from(
          filtros['subcategorias'],
        );
      }

      if (filtros.containsKey('contas')) {
        _filtrosPersonalizados['contas'] = List<String>.from(filtros['contas']);
      }

      if (filtros.containsKey('cartoes')) {
        _filtrosPersonalizados['cartoes'] = List<String>.from(
          filtros['cartoes'],
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    // Limpar overlay se ainda estiver ativo
    _overlayEntry?.remove();
    super.dispose();
  }

  /// 🎯 MUDANÇA DE TAB - Padrão Device
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _modoAtual = TransacoesPageMode.values[_tabController.index];
      });
      _carregarDados();
    }
  }

  /// 🔄 CARREGAR DADOS - Adaptativo por modo
  Future<void> _carregarDados() async {
    setState(() => _loading = true);

    try {
      // Determinar período baseado no filtro ativo, período ativo ou mês atual
      DateTime inicioMes, fimMes;

      if ((_filtroAtivo != null || _periodoAtivo != null) &&
          _parametrosFiltro.containsKey('inicio')) {
        inicioMes = _parametrosFiltro['inicio'] as DateTime;
        fimMes = _parametrosFiltro['fim'] as DateTime;
      } else {
        inicioMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
        fimMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      }

      print('🔍 DEBUG: Chamando fetchTransacoes com:');
      print('   dataInicio: $inicioMes');
      print('   dataFim: $fimMes');
      print('   tipo: ${_modoAtual.filtroTipo}');
      print('   contaId: $_contaFiltro');

      // Calcular limit baseado no período (para períodos maiores, buscar mais transações)
      final diffDias = fimMes.difference(inicioMes).inDays;
      final diffMeses = diffDias ~/ 30;

      // Limite dinâmico: 100 por mês + extra para períodos longos
      int limit;
      if (diffMeses <= 1) {
        limit = 200; // 1 mês ou menos
      } else if (diffMeses <= 3) {
        limit = 500; // 2-3 meses
      } else if (diffMeses <= 6) {
        limit = 1000; // 4-6 meses
      } else {
        limit = 2000; // Mais de 6 meses
      }

      print('   limit: $limit (período de $diffMeses meses, $diffDias dias)');

      // Carregar dados base em paralelo (offline-first)
      final futures = await Future.wait([
        _transacaoService.fetchTransacoes(
          dataInicio: inicioMes,
          dataFim: fimMes,
          tipo: _modoAtual.filtroTipo,
          contaId: _contaFiltro,
          limit: limit,
        ),
        _contaService.fetchContas(),
        _cartaoService.listarCartoesAtivos(),
        _categoriaService.fetchCategorias(),
        _categoriaService.fetchSubcategorias(),
      ]);

      final transacoes = futures[0] as List<TransacaoModel>;
      final contas = futures[1] as List<ContaModel>;
      final cartoes = futures[2] as List<CartaoModel>;
      final categorias = futures[3] as List<CategoriaModel>;
      final subcategorias = futures[4] as List<SubcategoriaModel>;

      print('🔍 DEBUG _carregarDados:');
      print('   Total de transações buscadas: ${transacoes.length}');
      if (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) {
        final cartaoFiltrado = _filtrosPersonalizados['cartoes'][0];
        final transacoesDoCartao = transacoes
            .where((t) => t.cartaoId == cartaoFiltrado)
            .length;
        print(
          '   Transações do cartão filtrado ($cartaoFiltrado): $transacoesDoCartao',
        );
      }

      // 🔥 MODO CARTÕES: USAR LÓGICA DE FATURAS
      Map<String, double> estatisticas;
      List<TransacaoModel> transacoesFiltradas;

      if (_modoAtual.apenasCartao) {
        print('💳 🔥 MODO CARTÕES: Usando lógica de faturas...');

        // Usar método que busca por faturas em vez de transações por período
        transacoesFiltradas = await _obterTransacoesComPeriodosReais();
        print(
          '   Transações obtidas por faturas: ${transacoesFiltradas.length}',
        );

        // Calcular estatísticas usando método específico de faturas
        estatisticas = await _calcularEstatisticasCartoesPorFaturas(
          inicioMes,
          fimMes,
          transacoesFiltradas,
        );
      } else {
        // OUTROS MODOS: USAR LÓGICA NORMAL + FATURAS SINTÉTICAS
        print(
          '💳 🔥 MODO NORMAL: Filtrando transações de cartão e adicionando faturas sintéticas...',
        );

        // 🎯 1. FILTRAR TRANSAÇÕES DE CARTÃO (cartao_id IS NULL)
        List<TransacaoModel> transacoesSemCartao = transacoes
            .where((t) => t.cartaoId == null || t.cartaoId!.isEmpty)
            .toList();

        print('   Transações SEM cartão: ${transacoesSemCartao.length}');

        // 🎯 2. BUSCAR TRANSAÇÕES DE CARTÃO REAIS AGRUPADAS (apenas para "Todas" e "Despesas")
        List<TransacaoModel> transacoesCartaoAgrupadas = [];
        if (_modoAtual.filtroTipo == null || _modoAtual.filtroTipo == 'despesa') {
          if (_temFiltrosCategoriaAtivos()) {
            // 🔍 NOVO: Mostrar transações individuais de cartão filtradas
            transacoesCartaoAgrupadas =
                await _buscarTransacoesCartaoIndividuais(inicioMes, fimMes);
            print('   Transações de cartão individuais filtradas: ${transacoesCartaoAgrupadas.length}');
          } else {
            // ✅ ATUAL: Mostrar agrupamentos (comportamento padrão)
            transacoesCartaoAgrupadas =
                await _gerarAgrupamentosCartaoReais(inicioMes, fimMes);
            print('   Transações de cartão agrupadas: ${transacoesCartaoAgrupadas.length}');
          }
        } else {
          print('   Agrupamentos de cartão ignorados para modo: ${_modoAtual.filtroTipo}');
        }

        // 🎯 3. IMPLEMENTAR DEDUPLICAÇÃO E CACHE
        final Set<String> idsExistentes = {};
        final List<TransacaoModel> transacoesDeduplicated = [];

        // Adicionar transações sem cartão primeiro
        for (final transacao in transacoesSemCartao) {
          if (!idsExistentes.contains(transacao.id)) {
            idsExistentes.add(transacao.id);
            transacoesDeduplicated.add(transacao);
          }
        }

        // Adicionar transações de cartão agrupadas, evitando duplicação
        for (final transacaoCartao in transacoesCartaoAgrupadas) {
          if (!idsExistentes.contains(transacaoCartao.id)) {
            idsExistentes.add(transacaoCartao.id);
            transacoesDeduplicated.add(transacaoCartao);
          } else {
            debugPrint(
              '⚠️  Transação de cartão agrupada duplicada ignorada: ${transacaoCartao.id}',
            );
          }
        }

        transacoesFiltradas = transacoesDeduplicated;

        if (_modoAtual.filtroTipo != null) {
          if (_modoAtual.filtroTipo == 'transferencia') {
            // Filtrar APENAS transferências (usa campo transferencia = true)
            transacoesFiltradas = transacoesFiltradas
                .where((t) => (t.transferencia ?? false) == true)
                .toList();
            print(
              '   Após filtro de transferências: ${transacoesFiltradas.length}',
            );
          } else {
            // Filtrar por tipo específico (receita/despesa) E EXCLUIR transferências
            transacoesFiltradas = transacoesFiltradas
                .where(
                  (t) =>
                      t.tipo == _modoAtual.filtroTipo &&
                      !(t.transferencia ?? false),
                )
                .toList();
            print(
              '   Após filtro de tipo (sem transferências): ${transacoesFiltradas.length}',
            );
          }
        } else {
          // Modo "Todas": EXCLUIR transferências (seguindo padrão React)
          transacoesFiltradas = transacoesFiltradas
              .where((t) => !(t.transferencia ?? false))
              .toList();
          print(
            '   Após excluir transferências de "Todas": ${transacoesFiltradas.length}',
          );
        }

        // Aplicar filtros personalizados para outros modos
        transacoesFiltradas = _aplicarFiltrosPersonalizados(
          transacoesFiltradas,
        );

        // Calcular estatísticas normal para outros modos
        estatisticas = _calcularEstatisticas(transacoesFiltradas);
      }

      setState(() {
        _transacoes = transacoesFiltradas;
        _contas = contas.where((c) => c.ativo).toList();
        _cartoes = cartoes.where((c) => c.ativo).toList();
        _categorias = categorias.where((c) => c.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
        _subcategorias = subcategorias.where((s) => s.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
        _estatisticas = estatisticas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 💳 CALCULAR ESTATÍSTICAS DE CARTÕES POR FATURAS
  /// 🔥 VERSÃO SIMPLIFICADA: Busca transações diretamente pelo campo fatura_vencimento
  Future<Map<String, double>> _calcularEstatisticasCartoesPorFaturas(
    DateTime inicioMes,
    DateTime fimMes,
    List<TransacaoModel> transacoesFiltradas,
  ) async {
    try {
      debugPrint(
        '💳 🔥 Calculando estatísticas DIRETO pelas transações com fatura_vencimento...',
      );

      final mesVencimento = inicioMes.month;
      final anoVencimento = inicioMes.year;

      debugPrint(
        '💳 📅 Buscando transações com fatura_vencimento em: ${mesVencimento}/${anoVencimento}',
      );

      final db = LocalDatabase.instance;

      // 🎯 BUSCAR DIRETAMENTE transações que têm fatura_vencimento no período
      final transacoesResult = await db.select(
        'transacoes',
        where: '''
          usuario_id = ?
          AND cartao_id IS NOT NULL
          AND fatura_vencimento IS NOT NULL
          AND strftime('%Y', fatura_vencimento) = ?
          AND strftime('%m', fatura_vencimento) = ?
        ''',
        whereArgs: [
          db.currentUserId,
          anoVencimento.toString(),
          mesVencimento.toString().padLeft(2, '0'),
        ],
      );

      debugPrint('💳 📊 Transações encontradas: ${transacoesResult.length}');

      double totalCartoes = 0.0;
      double totalPendentes = 0.0;
      double totalPagas = 0.0;
      int quantidadeTransacoes = 0;

      for (final transacaoData in transacoesResult) {
        try {
          final valor = (transacaoData['valor'] as num?)?.toDouble() ?? 0.0;
          final cartaoId = transacaoData['cartao_id'] as String;
          final faturaVencimento = transacaoData['fatura_vencimento'] as String;
          final efetivado = (transacaoData['efetivado'] as num?)?.toInt() == 1;

          // Buscar nome do cartão para debug
          final cartaoResult = await db.select(
            'cartoes',
            where: 'id = ?',
            whereArgs: [cartaoId],
          );
          final nomeCartao = cartaoResult.isNotEmpty
              ? cartaoResult.first['nome'] as String
              : 'Cartão';

          if (valor > 0.01) {
            totalCartoes += valor;
            quantidadeTransacoes++;

            // 🔥 SEPARAR PAGAS DE PENDENTES
            if (efetivado) {
              totalPagas += valor;
              debugPrint(
                '💳 ✅ PAGA: $nomeCartao - R\$ ${valor.toStringAsFixed(2)} - Fatura: $faturaVencimento',
              );
            } else {
              totalPendentes += valor;
              debugPrint(
                '💳 ⏳ PENDENTE: $nomeCartao - R\$ ${valor.toStringAsFixed(2)} - Fatura: $faturaVencimento',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Erro ao processar transação: $e');
        }
      }

      debugPrint(
        '💳 📈 TOTAL CARTÕES PERÍODO ${mesVencimento}/${anoVencimento}: R\$ ${totalCartoes.toStringAsFixed(2)} (${quantidadeTransacoes} transações)',
      );
      debugPrint(
        '💳 📊 SEPARAÇÃO: Pendentes: R\$ ${totalPendentes.toStringAsFixed(2)}, Pagas: R\$ ${totalPagas.toStringAsFixed(2)}',
      );

      return {
        'totalReceitas': 0.0, // Cartões não têm receitas
        'totalDespesas': 0.0, // Cartões são tratados separadamente
        'totalCartoes':
            totalCartoes, // 🔥 VALOR TOTAL DAS TRANSAÇÕES NO PERÍODO
        'totalCartoesPendentes':
            totalPendentes, // 🔥 APENAS FATURAS PENDENTES (não efetivadas)
        'totalCartoesPagas': totalPagas, // 🔥 APENAS FATURAS PAGAS (efetivadas)
        'totalTransferencias': 0.0,
        'saldo': -totalPendentes, // 🔥 SALDO DEVE SER APENAS DAS PENDENTES
        'quantidadeReceitas': 0.0,
        'quantidadeDespesas': 0.0,
        'quantidadeCartoes': quantidadeTransacoes
            .toDouble(), // Quantidade de transações
        'quantidadeTransferencias': 0.0,
        'receitasPendentes': 0.0,
        'despesasPendentes': 0.0,
        'mediaReceitas': 0.0,
        'mediaDespesas': 0.0,
        'mediaCartoes': quantidadeTransacoes > 0
            ? totalCartoes / quantidadeTransacoes
            : 0.0,
      };
    } catch (e) {
      debugPrint('❌ Erro ao calcular estatísticas de cartões por faturas: $e');
      return {};
    }
  }

  /// 📊 CALCULAR ESTATÍSTICAS - Padrão Device
  /// Agora calcula com base nas transações filtradas
  Map<String, double> _calcularEstatisticas(
    List<TransacaoModel> transacoesFiltradas,
  ) {
    try {
      double totalReceitas = 0.0;
      double totalDespesas = 0.0;
      double totalCartoes = 0.0;
      int quantidadeReceitas = 0;
      int quantidadeDespesas = 0;
      int quantidadeCartoes = 0;
      int quantidadeTransferencias = 0;
      double totalTransferencias = 0.0;
      double receitasPendentes = 0.0;
      double despesasPendentes = 0.0;

      for (final transacao in transacoesFiltradas) {
        // Primeiro, verificar se é transferência
        if (transacao.transferencia == true) {
          totalTransferencias += transacao.valor;
          quantidadeTransferencias++;
        } else {
          // Se não for transferência, processar normalmente
          switch (transacao.tipo) {
            case 'receita':
              totalReceitas += transacao.valor;
              quantidadeReceitas++;
              if (!transacao.efetivado) {
                receitasPendentes += transacao.valor;
              }
              break;
            case 'despesa':
              // ✅ Para faturas sintéticas, extrair cartaoId real e direcionar para totalCartoes
              final String? cartaoIdReal = _extrairCartaoIdDeFaturaSintetica(
                transacao.id,
              );
              final bool temCartao =
                  transacao.cartaoId != null || cartaoIdReal != null;

              if (temCartao) {
                totalCartoes += transacao.valor;
                quantidadeCartoes++;
              } else {
                totalDespesas += transacao.valor;
                quantidadeDespesas++;
              }
              if (!transacao.efetivado) {
                despesasPendentes += transacao.valor;
              }
              break;
          }
        }
      }

      return {
        'totalReceitas': totalReceitas,
        'totalDespesas': totalDespesas,
        'totalCartoes': totalCartoes,
        'totalTransferencias': totalTransferencias,
        'saldo': totalReceitas - totalDespesas - totalCartoes,
        'quantidadeReceitas': quantidadeReceitas.toDouble(),
        'quantidadeDespesas': quantidadeDespesas.toDouble(),
        'quantidadeCartoes': quantidadeCartoes.toDouble(),
        'quantidadeTransferencias': quantidadeTransferencias.toDouble(),
        'receitasPendentes': receitasPendentes,
        'despesasPendentes': despesasPendentes,
        'mediaReceitas': quantidadeReceitas > 0
            ? totalReceitas / quantidadeReceitas
            : 0.0,
        'mediaDespesas': quantidadeDespesas > 0
            ? totalDespesas / quantidadeDespesas
            : 0.0,
        'mediaCartoes': quantidadeCartoes > 0
            ? totalCartoes / quantidadeCartoes
            : 0.0,
      };
    } catch (e) {
      return {};
    }
  }

  /// 📅 NAVEGAÇÃO DE MÊS - Padrão Device
  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1);
      // Limpar filtros de período ao navegar manualmente
      _periodoAtivo = null;
      _parametrosFiltro.clear();
      _filtrosPersonalizados['dataInicio'] = null;
      _filtrosPersonalizados['dataFim'] = null;
    });
    _carregarDados();
  }

  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1);
      // Limpar filtros de período ao navegar manualmente
      _periodoAtivo = null;
      _parametrosFiltro.clear();
      _filtrosPersonalizados['dataInicio'] = null;
      _filtrosPersonalizados['dataFim'] = null;
    });
    _carregarDados();
  }

  Future<void> _selecionarMes() async {
    final resultado = await _mostrarModalPeriodo();

    if (resultado != null) {
      if (resultado['tipo'] == 'filtro_periodo') {
        _aplicarFiltroPeriodo(resultado['periodo'] as FiltroPeriodo);
      } else if (resultado['tipo'] == 'data_picker') {
        _abrirSeletorData();
      }
    }
  }

  /// Abre o DatePicker tradicional
  Future<void> _abrirSeletorData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _mesAtual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (data != null) {
      setState(() {
        _mesAtual = DateTime(data.year, data.month);
        _filtroAtivo = null; // Limpar filtro ativo
        _parametrosFiltro.clear();
      });
      _carregarDados();
    }
  }

  /// 📅 ABRE SELETOR DE PERÍODO PERSONALIZADO (data início e fim independentes)
  Future<void> _abrirSeletorPeriodoPersonalizado() async {
    DateTime? dataInicio;
    DateTime? dataFim;

    // Valores iniciais baseados no filtro atual (se houver)
    if (_filtrosPersonalizados['dataInicio'] != null) {
      dataInicio = _filtrosPersonalizados['dataInicio'] as DateTime;
    }
    if (_filtrosPersonalizados['dataFim'] != null) {
      dataFim = _filtrosPersonalizados['dataFim'] as DateTime;
    }

    // Primeiro: selecionar data de início
    final dataInicioSelecionada = await showDatePicker(
      context: context,
      initialDate:
          dataInicio ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar Data de Início',
      confirmText: 'Continuar',
      cancelText: 'Cancelar',
    );

    if (dataInicioSelecionada == null) return; // Usuário cancelou

    // Segundo: selecionar data de fim
    final dataFimSelecionada = await showDatePicker(
      context: context,
      initialDate:
          dataFim ?? dataInicioSelecionada.add(const Duration(days: 30)),
      firstDate: DateTime(2020), // Permitir seleção livre
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar Data de Fim',
      confirmText: 'Aplicar',
      cancelText: 'Voltar',
    );

    if (dataFimSelecionada == null) return; // Usuário cancelou

    // Aplicar o período personalizado selecionado
    setState(() {
      _periodoAtivo = FiltroPeriodo.personalizado;
      _visaoAtiva = null;
      _filtroAtivo = null;

      // Configurar filtros personalizados com horário completo no último dia
      final dataFimComHorario = DateTime(dataFimSelecionada.year, dataFimSelecionada.month, dataFimSelecionada.day, 23, 59, 59);

      _filtrosPersonalizados['dataInicio'] = dataInicioSelecionada;
      _filtrosPersonalizados['dataFim'] = dataFimComHorario;

      // Configurar parâmetros (para compatibilidade)
      _parametrosFiltro = {
        'inicio': dataInicioSelecionada,
        'fim': dataFimComHorario,
      };
    });

    debugPrint(
      '📅 Período personalizado aplicado: ${dataInicioSelecionada.toIso8601String().split('T')[0]} até ${dataFimSelecionada.toIso8601String().split('T')[0]}',
    );
    _carregarDados();
  }

  /// Aplica filtro de período selecionado
  void _aplicarFiltroPeriodo(FiltroPeriodo periodo) {
    final agora = DateTime.now();

    // Se for período personalizado, abrir seletor de datas
    if (periodo == FiltroPeriodo.personalizado) {
      _abrirSeletorPeriodoPersonalizado();
      return;
    }

    setState(() {
      _periodoAtivo = periodo;
      _visaoAtiva = null; // Limpar visão ativa
      _filtroAtivo = null; // Limpar filtro antigo
      _parametrosFiltro = _gerarParametrosFiltroPeriodo(periodo);

      print('🔍 DEBUG _aplicarFiltroPeriodo:');
      print('   Período: ${periodo.titulo}');
      print(
        '   Filtros de cartões antes: ${_filtrosPersonalizados['cartoes']}',
      );

      // Para "Mês Atual" e "Ano Atual", também atualiza a navegação
      if (periodo == FiltroPeriodo.mesAtual) {
        _mesAtual = DateTime(agora.year, agora.month);
        _periodoAtivo = null; // Não manter como filtro, apenas navegar
        _parametrosFiltro.clear();
        _filtrosPersonalizados['dataInicio'] = null;
        _filtrosPersonalizados['dataFim'] = null;
      } else if (periodo == FiltroPeriodo.anoAtual) {
        _mesAtual = DateTime(agora.year, agora.month);
        _periodoAtivo = null; // Não manter como filtro, apenas navegar
        _parametrosFiltro.clear();
        _filtrosPersonalizados['dataInicio'] = null;
        _filtrosPersonalizados['dataFim'] = null;
      } else if (periodo == FiltroPeriodo.anoCompleto) {
        _mesAtual = DateTime(agora.year, agora.month);
        _periodoAtivo = periodo; // Manter como filtro ativo
        _filtrosPersonalizados['dataInicio'] = _parametrosFiltro['inicio'];
        _filtrosPersonalizados['dataFim'] = _parametrosFiltro['fim'];
      } else {
        // Para períodos que precisam de filtro (últimos 3/6 meses), copiar para _filtrosPersonalizados
        _filtrosPersonalizados['dataInicio'] = _parametrosFiltro['inicio'];
        _filtrosPersonalizados['dataFim'] = _parametrosFiltro['fim'];
      }

      print(
        '   Filtros de cartões depois: ${_filtrosPersonalizados['cartoes']}',
      );
    });
    _carregarDados();
  }

  /// Aplica visão rápida selecionada
  void _aplicarVisaoRapida(VisaoRapida visao) {
    setState(() {
      _visaoAtiva = visao;
      _periodoAtivo = null; // Limpar período ativo
      _filtroAtivo = null; // Limpar filtro antigo
      _parametrosFiltro = _gerarParametrosVisaoRapida(visao);
    });
    _carregarDados();
  }

  /// Gera parâmetros para filtro de período
  Map<String, dynamic> _gerarParametrosFiltroPeriodo(FiltroPeriodo periodo) {
    final agora = DateTime.now();

    switch (periodo) {
      case FiltroPeriodo.mesAtual:
        final ultimoDiaDoMes = DateTime(agora.year, agora.month + 1, 0);
        return {
          'inicio': DateTime(agora.year, agora.month, 1),
          'fim': DateTime(ultimoDiaDoMes.year, ultimoDiaDoMes.month, ultimoDiaDoMes.day, 23, 59, 59),
        };

      case FiltroPeriodo.anoAtual:
        return {
          'inicio': DateTime(agora.year, 1, 1),
          'fim': DateTime(agora.year, 12, 31, 23, 59, 59),
        };

      case FiltroPeriodo.ultimos3Meses:
        final ultimoDiaDoMes = DateTime(agora.year, agora.month + 1, 0);
        return {
          'inicio': DateTime(agora.year, agora.month - 2, 1),
          'fim': DateTime(ultimoDiaDoMes.year, ultimoDiaDoMes.month, ultimoDiaDoMes.day, 23, 59, 59),
        };

      case FiltroPeriodo.ultimos6Meses:
        final ultimoDiaDoMes = DateTime(agora.year, agora.month + 1, 0);
        return {
          'inicio': DateTime(agora.year, agora.month - 5, 1),
          'fim': DateTime(ultimoDiaDoMes.year, ultimoDiaDoMes.month, ultimoDiaDoMes.day, 23, 59, 59),
        };

      case FiltroPeriodo.anoCompleto:
        return {
          'inicio': DateTime(agora.year, 1, 1),
          'fim': DateTime(agora.year, 12, 31, 23, 59, 59),
        };

      case FiltroPeriodo.personalizado:
        // Retorna período padrão, será substituído pelo seletor
        final ultimoDiaDoMes = DateTime(agora.year, agora.month + 1, 0);
        return {
          'inicio': DateTime(agora.year, agora.month, 1),
          'fim': DateTime(ultimoDiaDoMes.year, ultimoDiaDoMes.month, ultimoDiaDoMes.day, 23, 59, 59),
        };
    }
  }

  /// Gera parâmetros para visão rápida
  Map<String, dynamic> _gerarParametrosVisaoRapida(VisaoRapida visao) {
    final agora = DateTime.now();

    switch (visao) {
      case VisaoRapida.pendentes:
        return {'efetivado': false, 'cartao': false};

      case VisaoRapida.faturasPendentes:
        return {'cartao': true, 'efetivado': false};

      case VisaoRapida.efetivadas:
        return {'efetivado': true};

      case VisaoRapida.vencidas:
        return {'vencidas': true, 'efetivado': false};

      case VisaoRapida.porCartao:
        return {'cartao': true};

      case VisaoRapida.porConta:
        return {'cartao': false};

      case VisaoRapida.transferencias:
        return {'tipo': 'transferencia'};

      case VisaoRapida.despesasMes:
        return {
          'tipo': 'despesa',
          'cartao': false,
          'inicio': DateTime(agora.year, agora.month, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case VisaoRapida.receitasAno:
        return {
          'tipo': 'receita',
          'inicio': DateTime(agora.year, 1, 1),
          'fim': DateTime(agora.year, 12, 31),
        };
    }
  }

  /// Modal com filtros de período
  Future<Map<String, dynamic>?> _mostrarModalPeriodo() async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalPeriodo(),
    );
  }

  /// Modal com visões rápidas
  Future<VisaoRapida?> _mostrarModalVisoesRapidas() async {
    // Inicializar seleção temporária com a visão atualmente ativa (se houver)
    setState(() {
      _visaoTempSelecionada = _visaoAtiva;
    });

    final resultado = await showModalBottomSheet<VisaoRapida>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalVisoesRapidas(),
    );

    // Limpar seleção temporária ao fechar o modal
    setState(() {
      _visaoTempSelecionada = null;
    });

    return resultado;
  }

  /// Modal com filtros inteligentes pré-definidos (DEPRECATED)
  Future<Map<String, dynamic>?> _mostrarModalFiltros() async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalFiltros(),
    );
  }

  /// Aplica filtro inteligente selecionado
  void _aplicarFiltroInteligente(FiltroInteligente filtro) {
    setState(() {
      _filtroAtivo = filtro;
      _parametrosFiltro = _gerarParametrosFiltro(filtro);
    });
    _carregarDados();
  }

  /// Gera parâmetros específicos para cada filtro
  Map<String, dynamic> _gerarParametrosFiltro(FiltroInteligente filtro) {
    final agora = DateTime.now();

    switch (filtro) {
      case FiltroInteligente.mesAtual:
        return {
          'inicio': DateTime(agora.year, agora.month, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case FiltroInteligente.anoAtual:
        return {
          'inicio': DateTime(agora.year, 1, 1),
          'fim': DateTime(agora.year, 12, 31),
        };

      case FiltroInteligente.ultimos3Meses:
        return {
          'inicio': DateTime(agora.year, agora.month - 2, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case FiltroInteligente.ultimos6Meses:
        return {
          'inicio': DateTime(agora.year, agora.month - 5, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case FiltroInteligente.transacoesPendentes:
        return {'efetivado': false, 'cartao': false};

      case FiltroInteligente.faturasPendentes:
        return {'cartao': true, 'efetivado': false};

      case FiltroInteligente.transacoesEfetivadas:
        return {'efetivado': true};

      case FiltroInteligente.transacoesVencidas:
        return {'vencidas': true, 'efetivado': false};

      case FiltroInteligente.porCartao:
        return {'cartao': true};

      case FiltroInteligente.porConta:
        return {'cartao': false};

      case FiltroInteligente.transferencias:
        return {'tipo': 'transferencia'};

      case FiltroInteligente.despesasMes:
        return {
          'tipo': 'despesa',
          'cartao': false,
          'inicio': DateTime(agora.year, agora.month, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case FiltroInteligente.receitasAno:
        return {
          'tipo': 'receita',
          'inicio': DateTime(agora.year, 1, 1),
          'fim': DateTime(agora.year, 12, 31),
        };

      default:
        return {};
    }
  }

  /// Constrói o modal de seleção de período
  Widget _buildModalPeriodo() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecionar Período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de períodos
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: _buildFiltrosPeriodo()),
            ),
          ),

          // Opção do seletor de data tradicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, {'tipo': 'data_picker'}),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Escolher Data Específica'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o modal de visões rápidas
  Widget _buildModalVisoesRapidas() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle visual do modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Visões Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de visões agrupadas por categoria (agora scrollável)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: _buildVisoesAgrupadas()),
            ),
          ),

          // Seção de botões
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Botão Cancelar
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFF6B7280)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _visaoTempSelecionada != null
                        ? () => Navigator.pop(context, _visaoTempSelecionada)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _modoAtual.corHeader,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _visaoTempSelecionada != null
                              ? 'Aplicar Visão'
                              : 'Selecione uma visão',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o modal de seleção de filtros (DEPRECATED)
  Widget _buildModalFiltros() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecionar Filtro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de filtros agrupados por categoria
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: _buildFiltrosAgrupados()),
            ),
          ),

          // Opção do seletor de data tradicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, {'tipo': 'data_picker'}),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Escolher Data Específica'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói lista de filtros de período
  List<Widget> _buildFiltrosPeriodo() {
    final widgets = <Widget>[];

    for (final periodo in FiltroPeriodo.values) {
      widgets.add(_buildItemPeriodo(periodo));
    }

    return widgets;
  }

  /// Constrói visões agrupadas por categoria
  List<Widget> _buildVisoesAgrupadas() {
    final grupos = <String, List<VisaoRapida>>{};

    // Agrupa visões por categoria
    for (final visao in VisaoRapida.values) {
      grupos.putIfAbsent(visao.categoria, () => []).add(visao);
    }

    final widgets = <Widget>[];

    for (final categoria in grupos.keys) {
      // Título da categoria
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                categoria,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );

      // Visões da categoria
      for (final visao in grupos[categoria]!) {
        widgets.add(_buildItemVisao(visao));
      }
    }

    return widgets;
  }

  /// Constrói item individual de período
  Widget _buildItemPeriodo(FiltroPeriodo periodo) {
    final isAtivo = _periodoAtivo == periodo;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isAtivo
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isAtivo
            ? Border.all(color: Theme.of(context).primaryColor, width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          periodo.icone,
          color: isAtivo ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        title: Text(
          periodo.titulo,
          style: TextStyle(
            fontWeight: isAtivo ? FontWeight.w600 : FontWeight.normal,
            color: isAtivo ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
        trailing: isAtivo
            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
            : null,
        onTap: () {
          Navigator.pop(context, {
            'tipo': 'filtro_periodo',
            'periodo': periodo,
          });
        },
      ),
    );
  }

  /// Constrói item individual de visão
  Widget _buildItemVisao(VisaoRapida visao) {
    final isAtiva = _visaoAtiva == visao;
    final isSelecionadaTemp = _visaoTempSelecionada == visao;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelecionadaTemp
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : isAtiva
            ? Colors.grey[100]
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelecionadaTemp
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : isAtiva
            ? Border.all(color: Colors.grey[400]!, width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          visao.icone,
          color: isSelecionadaTemp
              ? Theme.of(context).primaryColor
              : isAtiva
              ? Colors.grey[600]
              : Colors.grey[600],
        ),
        title: Text(
          visao.titulo,
          style: TextStyle(
            fontWeight: isSelecionadaTemp ? FontWeight.w600 : FontWeight.normal,
            color: isSelecionadaTemp
                ? Theme.of(context).primaryColor
                : isAtiva
                ? Colors.grey[700]
                : Colors.black87,
          ),
        ),
        subtitle: isAtiva && !isSelecionadaTemp
            ? const Text(
                'Atualmente ativa',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        trailing: isSelecionadaTemp
            ? Icon(
                Icons.radio_button_checked,
                color: Theme.of(context).primaryColor,
              )
            : isAtiva
            ? const Icon(Icons.check_circle_outline, color: Colors.grey)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
        onTap: () {
          setState(() {
            _visaoTempSelecionada = visao;
          });
        },
      ),
    );
  }

  /// Constrói filtros agrupados por categoria (DEPRECATED)
  List<Widget> _buildFiltrosAgrupados() {
    final grupos = <String, List<FiltroInteligente>>{};

    // Agrupa filtros por categoria
    for (final filtro in FiltroInteligente.values) {
      grupos.putIfAbsent(filtro.categoria, () => []).add(filtro);
    }

    final widgets = <Widget>[];

    for (final categoria in grupos.keys) {
      // Título da categoria
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                categoria,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );

      // Filtros da categoria
      for (final filtro in grupos[categoria]!) {
        widgets.add(_buildItemFiltro(filtro));
      }
    }

    return widgets;
  }

  /// Constrói item individual de filtro
  Widget _buildItemFiltro(FiltroInteligente filtro) {
    final isAtivo = _filtroAtivo == filtro;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isAtivo
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isAtivo
            ? Border.all(color: Theme.of(context).primaryColor, width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          filtro.icone,
          color: isAtivo ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        title: Text(
          filtro.titulo,
          style: TextStyle(
            fontWeight: isAtivo ? FontWeight.w600 : FontWeight.normal,
            color: isAtivo ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
        trailing: isAtivo
            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
            : null,
        onTap: () {
          Navigator.pop(context, {
            'tipo': 'filtro_inteligente',
            'filtro': filtro,
          });
        },
      ),
    );
  }

  /// ➕ NAVEGAR PARA NOVA TRANSAÇÃO
  void _navegarParaNovaTransacao(String tipo) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransacaoFormPage(modo: 'criar', tipo: tipo),
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  /// ↔️ NAVEGAR PARA TRANSFERÊNCIA
  void _navegarParaTransferencia() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const TransferenciaFormPage()),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  /// ✏️ NAVEGAR PARA EDITAR TRANSAÇÃO
  void _navegarParaEditarTransacao(TransacaoModel transacao) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            TransacaoFormPage(modo: 'editar', transacao: transacao),
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  /// 🗑️ EXCLUIR TRANSAÇÃO
  void _excluirTransacao(TransacaoModel transacao) async {
    final confirmacao = await _mostrarModalConfirmacaoExclusao(transacao);

    if (confirmacao == true) {
      try {
        await _transacaoService.deleteTransacao(transacao.id);
        _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transação "${transacao.descricao}" excluída'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir transação: $e')),
          );
        }
      }
    }
  }

  /// 🔧 NAVEGAR PARA EDIÇÃO AVANÇADA
  void _navegarParaEditarAvancado(TransacaoModel transacao) async {
    // ✅ TODAS AS TRANSAÇÕES (incluindo cartão) usam EditarTransacaoPage
    // que contém as melhorias visuais e controles adequados
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditarTransacaoPage(
          transacao: transacao,
          modo: ModoEdicao.completa,
        ),
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  /// ✅ EFETIVAR TRANSAÇÃO
  void _efetivarTransacao(TransacaoModel transacao) async {
    try {
      final resultado = await TransacaoEditService.instance.efetivar(transacao);

      if (resultado.sucesso) {
        _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.mensagem ?? 'Transação efetivada'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao efetivar transação: $e')),
        );
      }
    }
  }

  /// ❌ DESEFETIVAR TRANSAÇÃO
  void _desefetivarTransacao(TransacaoModel transacao) async {
    try {
      final resultado = await TransacaoEditService.instance.desefetivar(
        transacao,
      );

      if (resultado.sucesso) {
        _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resultado.mensagem ?? 'Transação marcada como pendente',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.erro ?? 'Erro desconhecido'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desefetivar transação: $e'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    }
  }

  /// 📋 DUPLICAR TRANSAÇÃO
  void _duplicarTransacao(TransacaoModel transacao) async {
    try {
      final resultado = await TransacaoEditService.instance.duplicar(transacao);

      if (resultado.sucesso) {
        _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.mensagem ?? 'Transação duplicada'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.erro ?? 'Erro desconhecido')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao duplicar transação: $e')),
        );
      }
    }
  }

  /// 🎨 OBTER COR DA TRANSAÇÃO
  Color _getCorTransacao(TransacaoModel transacao) {
    if (transacao.tipo == 'receita') {
      return AppColors.tealPrimary;
    } else if (transacao.tipo == 'despesa') {
      return transacao.cartaoId != null
          ? AppColors.roxoHeader
          : AppColors.vermelhoErro;
    } else {
      return AppColors.azul;
    }
  }

  /// 🎨 OBTER ÍCONE DA TRANSAÇÃO
  IconData _getIconeTransacao(TransacaoModel transacao) {
    if (transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (transacao.tipo == 'despesa') {
      return transacao.cartaoId != null
          ? Icons.credit_card
          : Icons.trending_down;
    } else {
      return Icons.swap_horiz;
    }
  }

  /// 🎨 RESUMO ADAPTATIVO - Padrão Device
  Widget _buildResumoAdaptativo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _modoAtual.corHeader.withAlpha(26),
            _modoAtual.corHeader.withAlpha(12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _modoAtual.corHeader.withAlpha(52)),
      ),
      child: Column(
        children: [
          // Header com título e valor principal
          _buildHeaderResumo(),
          const SizedBox(height: 10),
          // Métricas em linha - Padrão Device
          _buildMetricasLinha(),
        ],
      ),
    );
  }

  /// 📊 HEADER DO RESUMO
  Widget _buildHeaderResumo() {
    String titulo;
    double valorPrincipal;

    switch (_modoAtual) {
      case TransacoesPageMode.receitas:
        titulo = 'Resumo de Receitas';
        valorPrincipal = _estatisticas['totalReceitas'] ?? 0.0;
        break;
      case TransacoesPageMode.despesas:
        titulo = 'Resumo de Despesas';
        valorPrincipal = _estatisticas['totalDespesas'] ?? 0.0;
        break;
      case TransacoesPageMode.cartoes:
        titulo = 'Resumo dos Cartões';
        valorPrincipal = _estatisticas['totalCartoes'] ?? 0.0;
        break;
      case TransacoesPageMode.transferencias:
        titulo = 'Resumo das Transferências';
        valorPrincipal = _estatisticas['totalTransferencias'] ?? 0.0;
        break;
      default:
        titulo = 'Resumo Geral';
        valorPrincipal = _estatisticas['saldo'] ?? 0.0;
    }

    return Row(
      children: [
        Icon(_modoAtual.icone, color: _modoAtual.corHeader, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          _formatarMoeda(valorPrincipal),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _modoAtual.corHeader,
          ),
        ),
      ],
    );
  }

  /// 📈 MÉTRICAS EM LINHA - Padrão Device
  Widget _buildMetricasLinha() {
    switch (_modoAtual) {
      case TransacoesPageMode.todas:
        return _buildMetricasGeral();
      case TransacoesPageMode.receitas:
        return _buildMetricasReceitas();
      case TransacoesPageMode.despesas:
        return _buildMetricasDespesas();
      case TransacoesPageMode.cartoes:
        return _buildMetricasCartoes();
      case TransacoesPageMode.transferencias:
        return _buildMetricasTransferencias();
    }
  }

  Widget _buildMetricasGeral() {
    final receitas = _estatisticas['totalReceitas'] ?? 0.0;
    final despesas = _estatisticas['totalDespesas'] ?? 0.0;
    final cartoes = _estatisticas['totalCartoes'] ?? 0.0;
    final transferencias = _estatisticas['totalTransferencias'] ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica(
          'Receitas',
          receitas,
          Icons.trending_up,
          Colors.green[600]!,
        ),
        _buildMetrica(
          'Despesas',
          despesas,
          Icons.trending_down,
          Colors.red[600]!,
        ),
        _buildMetrica(
          'Cartões',
          cartoes,
          Icons.credit_card,
          Colors.purple[600]!,
        ),
        _buildMetrica(
          'Transf.',
          transferencias,
          Icons.swap_horiz,
          Colors.blue[600]!,
        ),
      ],
    );
  }

  Widget _buildMetricasReceitas() {
    final quantidade = _estatisticas['quantidadeReceitas']?.toInt() ?? 0;
    final pendente = _estatisticas['receitasPendentes'] ?? 0.0;
    final media = _estatisticas['mediaReceitas'] ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica(
          'Transações',
          quantidade.toDouble(),
          Icons.receipt,
          _modoAtual.corHeader,
          isQuantidade: true,
        ),
        _buildMetrica(
          'Pendente',
          pendente,
          Icons.schedule,
          Colors.orange[600]!,
        ),
        _buildMetrica('Média', media, Icons.trending_flat, Colors.grey[600]!),
      ],
    );
  }

  Widget _buildMetricasDespesas() {
    final quantidade = _estatisticas['quantidadeDespesas']?.toInt() ?? 0;
    final pendente = _estatisticas['despesasPendentes'] ?? 0.0;
    final media = _estatisticas['mediaDespesas'] ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica(
          'Transações',
          quantidade.toDouble(),
          Icons.receipt,
          _modoAtual.corHeader,
          isQuantidade: true,
        ),
        _buildMetrica(
          'Pendente',
          pendente,
          Icons.schedule,
          Colors.orange[600]!,
        ),
        _buildMetrica('Média', media, Icons.trending_flat, Colors.grey[600]!),
      ],
    );
  }

  Widget _buildMetricasCartoes() {
    final quantidade = _estatisticas['quantidadeCartoes']?.toInt() ?? 0;
    final pendente = _estatisticas['totalCartoesPendentes'] ?? 0.0;
    final media = _estatisticas['mediaCartoes'] ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica(
          'Transações',
          quantidade.toDouble(),
          Icons.receipt,
          _modoAtual.corHeader,
          isQuantidade: true,
        ),
        _buildMetrica(
          'Pendente',
          pendente,
          Icons.schedule,
          Colors.orange[600]!,
        ),
        _buildMetrica('Média', media, Icons.trending_flat, Colors.grey[600]!),
      ],
    );
  }

  Widget _buildMetricasTransferencias() {
    final quantidade = _estatisticas['quantidadeTransferencias']?.toInt() ?? 0;
    final total = _estatisticas['totalTransferencias'] ?? 0.0;
    final media = quantidade > 0 ? total / quantidade : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica(
          'Transações',
          quantidade.toDouble(),
          Icons.receipt,
          _modoAtual.corHeader,
          isQuantidade: true,
        ),
        _buildMetrica('Total', total, Icons.swap_horiz, _modoAtual.corHeader),
        _buildMetrica('Média', media, Icons.trending_flat, Colors.grey[600]!),
      ],
    );
  }

  Widget _buildMetrica(
    String label,
    double valor,
    IconData icone,
    Color cor, {
    bool isQuantidade = false,
  }) {
    return Column(
      children: [
        Icon(icone, color: cor),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isQuantidade ? valor.toInt().toString() : _formatarMoeda(valor),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
      ],
    );
  }

  // Filtros removidos - agora controlados pelas tabs

  /// 🎨 WIDGET ITEM TRANSAÇÃO - Padrão Device
  Widget _buildTransacaoItem(TransacaoModel transacao) {
    final conta = transacao.contaId != null
        ? _contas.firstWhere(
            (c) => c.id == transacao.contaId,
            orElse: () => ContaModel(
              id: '',
              usuarioId: '',
              nome: 'Conta não encontrada',
              tipo: 'corrente',
              saldoInicial: 0,
              saldo: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
        : null;

    final cartao = transacao.cartaoId != null
        ? _cartoes.firstWhere(
            (c) => c.id == transacao.cartaoId,
            orElse: () => CartaoModel(
              id: '',
              usuarioId: '',
              nome: 'Cartão não encontrado',
              limite: 0,
              diaFechamento: 1,
              diaVencimento: 10,
              ativo: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: InkWell(
        onTap: () => _mostrarOpcoesTransacao(transacao),
        child: Column(
          children: [
            // LINHA 1: Status + Conta/Cartão + Data
            Row(
              children: [
                _buildIconeStatus(transacao),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getTextoConta(transacao, conta, cartao),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(transacao.data),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // LINHA 2: Tipo + Descrição + Valor
            Row(
              children: [
                _buildIndicadorTipo(transacao),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transacao.descricao,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildValor(transacao),
              ],
            ),
            const SizedBox(height: 8),

            // LINHA 3: Chips de informações - Alinhados à esquerda
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 8,
                    runSpacing: 6,
                    children: _buildChipsInformacoes(transacao),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ÍCONE DE STATUS CIRCULAR - Padrão Device
  Widget _buildIconeStatus(TransacaoModel transacao) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: transacao.efetivado
            ? const Color(0xFF10B981).withAlpha(26) // Verde success
            : const Color(0xFFF59E0B).withAlpha(26), // Amarelo warning
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        transacao.efetivado ? Icons.check_circle : Icons.schedule,
        color: transacao.efetivado
            ? const Color(0xFF10B981) // Verde success
            : const Color(0xFFF59E0B), // Amarelo warning
        size: 24,
      ),
    );
  }

  // INDICADOR DE TIPO - Padrão Device
  Widget _buildIndicadorTipo(TransacaoModel transacao) {
    IconData icone;
    Color cor;

    switch (transacao.tipo) {
      case 'receita':
        icone = Icons.north_east;
        cor = const Color(0xFF10B981); // Verde success
        break;
      case 'despesa':
        if (transacao.cartaoId != null) {
          icone = Icons.credit_card;
          cor = const Color(0xFF7C3AED); // Roxo
        } else {
          icone = Icons.south_east;
          cor = const Color(0xFFEF4444); // Vermelho error
        }
        break;
      case 'transferencia':
        icone = Icons.swap_horiz;
        cor = const Color(0xFF3B82F6); // Azul
        break;
      default:
        icone = Icons.help_outline;
        cor = const Color(0xFF6B7280); // Cinza
    }

    return Icon(icone, size: 16, color: cor);
  }

  // VALOR COM PREFIXO - Padrão Device
  Widget _buildValor(TransacaoModel transacao) {
    String prefixo;
    Color cor;

    switch (transacao.tipo) {
      case 'receita':
        prefixo = '+';
        cor = const Color(0xFF111827); // Cinza escuro
        break;
      case 'despesa':
        prefixo = '-';
        cor = const Color(0xFF111827); // Cinza escuro
        break;
      case 'transferencia':
        prefixo = '';
        cor = const Color(0xFF111827); // Cinza escuro
        break;
      default:
        prefixo = '';
        cor = const Color(0xFF111827); // Cinza escuro
    }

    return Text(
      '$prefixo${_formatarMoeda(transacao.valor)}',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cor),
    );
  }

  // TEXTO DA CONTA - Padrão Device
  String _getTextoConta(
    TransacaoModel transacao,
    ContaModel? conta,
    CartaoModel? cartao,
  ) {
    if (transacao.tipo == 'transferencia') {
      // Para transferências, mostrar conta origem → destino
      final contaOrigem = conta?.nome ?? 'Conta';
      final contaDestino =
          'Conta Destino'; // ✅ TODO: Implementar busca da conta destino quando necessário
      return '$contaOrigem → $contaDestino';
    } else if (transacao.cartaoId != null) {
      return cartao?.nome ?? 'Cartão não encontrado';
    } else {
      return conta?.nome ?? 'Conta não encontrada';
    }
  }

  // CHIPS DE INFORMAÇÕES - Padrão Device
  List<Widget> _buildChipsInformacoes(TransacaoModel transacao) {
    final List<Widget> chips = [];

    // 1. RECORRENTE - Azul sólido
    if (transacao.ehRecorrente || transacao.recorrente) {
      chips.add(_buildChipRecorrente(transacao.tipoRecorrencia));
    }

    // 2. PARCELADO - Laranja sólido
    if ((transacao.totalParcelas ?? 0) > 1) {
      chips.add(
        _buildChipParcelado(
          transacao.parcelaAtual ?? 1,
          transacao.totalParcelas ?? 1,
        ),
      );
    }

    // 3. PREVISÍVEL - Roxo sólido
    if (transacao.tipoDespesa == 'previsivel' ||
        transacao.tipoReceita == 'previsivel') {
      chips.add(_buildChipPrevisivel());
    }

    // 4. CATEGORIA - Cor da categoria
    if (transacao.categoriaId != null) {
      chips.add(_buildChipCategoria(transacao));
    }

    // 5. SUBCATEGORIA - Mesma cor da categoria pai
    if (transacao.subcategoriaId != null) {
      chips.add(_buildChipSubcategoria(transacao));
    }

    // 6. BANCO DE PAGAMENTO (apenas para agrupamentos de cartão pagos)
    if (transacao.id.startsWith('agrupamento_cartao_') &&
        transacao.efetivado &&
        transacao.contaId != null) {
      final conta = _contas.firstWhere(
        (c) => c.id == transacao.contaId,
        orElse: () => ContaModel(
          id: '',
          usuarioId: '',
          nome: 'Conta não encontrada',
          tipo: 'corrente',
          saldoInicial: 0.0,
          saldo: 0.0,
          ativo: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (conta.id.isNotEmpty) {
        chips.add(_buildChipBancoPagamento(conta));
      }
    }

    // 7. TAGS (máximo 2)
    if (transacao.tags != null && transacao.tags!.isNotEmpty) {
      for (final tag in transacao.tags!.take(2)) {
        chips.add(_buildChipTag(tag));
      }
    }

    return chips;
  }

  // CHIP RECORRENTE - Azul sólido
  Widget _buildChipRecorrente(String? tipoRecorrencia) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Azul sólido
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, color: Colors.white, size: 9),
          const SizedBox(width: 3),
          Text(
            _formatarRecorrencia(tipoRecorrencia),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // CHIP PARCELADO - Laranja sólido
  Widget _buildChipParcelado(int parcelaAtual, int totalParcelas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange, // Laranja sólido
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 9),
          const SizedBox(width: 3),
          Text(
            '$parcelaAtual/$totalParcelas',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // CHIP PREVISÍVEL - Roxo sólido
  Widget _buildChipPrevisivel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple, // Roxo sólido
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: Colors.white, size: 9),
          SizedBox(width: 3),
          Text(
            'Previsível',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // CHIP CATEGORIA - Cor da categoria
  Widget _buildChipCategoria(TransacaoModel transacao) {
    final categoria = _encontrarCategoria(transacao.categoriaId!);

    if (categoria == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280), // Cinza como padrão
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Categoria',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );
    }

    // Converter cor hex para Color
    Color corCategoria;
    try {
      corCategoria = Color(int.parse(categoria.cor.replaceAll('#', '0xFF')));
    } catch (e) {
      corCategoria = const Color(0xFF6B7280); // Fallback para cinza
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: corCategoria,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoria.nome,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  // Helper para encontrar categoria
  CategoriaModel? _encontrarCategoria(String categoriaId) {
    try {
      return _categorias.firstWhere((c) => c.id == categoriaId);
    } catch (e) {
      return null;
    }
  }

  SubcategoriaModel? _encontrarSubcategoria(String subcategoriaId) {
    try {
      return _subcategorias.firstWhere((s) => s.id == subcategoriaId);
    } catch (e) {
      return null;
    }
  }

  // CHIP SUBCATEGORIA - Mesma cor da categoria pai
  Widget _buildChipSubcategoria(TransacaoModel transacao) {
    final subcategoria = _encontrarSubcategoria(transacao.subcategoriaId!);
    if (subcategoria == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280), // Cinza como padrão
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Subcategoria',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );
    }

    // Buscar categoria pai para obter a cor
    final categoria = _encontrarCategoria(subcategoria.categoriaId);
    Color corSubcategoria;
    try {
      // Se subcategoria tem cor própria, usar ela, senão usar a da categoria pai
      final corFinal = subcategoria.cor ?? categoria?.cor ?? '#6B7280';
      corSubcategoria = Color(int.parse(corFinal.replaceAll('#', '0xFF')));
    } catch (e) {
      corSubcategoria = const Color(0xFF6B7280); // Fallback para cinza
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: corSubcategoria,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        subcategoria.nome,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  // CHIP TAG - Teal sólido
  Widget _buildChipTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6), // Teal sólido
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, color: Colors.white, size: 9),
          const SizedBox(width: 3),
          Text(
            tag,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarRecorrencia(String? tipo) {
    switch (tipo) {
      case 'semanal':
        return 'Semanal';
      case 'quinzenal':
        return 'Quinzenal';
      case 'mensal':
        return 'Mensal';
      case 'anual':
        return 'Anual';
      default:
        return 'Recorrente';
    }
  }

  /// Widget para exibir chips dos filtros ativos
  Widget _buildFiltrosAtivosChips() {
    final List<Widget> chips = [];

    // 1. PERÍODO ATIVO
    if (_periodoAtivo != null) {
      chips.add(_buildChipPeriodoAtivo(_periodoAtivo!));
    }

    // 2. VISÃO ATIVA
    if (_visaoAtiva != null) {
      chips.add(_buildChipVisaoAtiva(_visaoAtiva!));
    }

    // 3. FILTRO INTELIGENTE ATIVO (DEPRECATED - manter por compatibilidade)
    if (_filtroAtivo != null) {
      chips.add(_buildChipFiltroInteligente(_filtroAtivo!));
    }

    // 4. PERÍODO/DATA (se não há filtros ativos)
    if (_periodoAtivo == null && _visaoAtiva == null && _filtroAtivo == null) {
      chips.add(_buildChipPeriodo());
    }

    // 3. FILTROS PERSONALIZADOS
    if (_temFiltrosAtivos()) {
      // Categorias
      if (_filtrosPersonalizados['categorias']?.isNotEmpty ?? false) {
        for (final categoriaId in _filtrosPersonalizados['categorias']) {
          final categoria = _encontrarCategoria(categoriaId);
          if (categoria != null) {
            chips.add(_buildChipCategoriaFiltro(categoria));
          }
        }
      }

      // Subcategorias
      if (_filtrosPersonalizados['subcategorias']?.isNotEmpty ?? false) {
        for (final subcategoriaId in _filtrosPersonalizados['subcategorias']) {
          final subcategoria = _encontrarSubcategoria(subcategoriaId);
          if (subcategoria != null) {
            chips.add(
              _buildChipSubcategoriaFiltro(subcategoriaId, subcategoria.nome),
            );
          }
        }
      }

      // Cartões
      if (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) {
        for (final cartaoId in _filtrosPersonalizados['cartoes']) {
          final cartao = _cartoes.firstWhere(
            (c) => c.id == cartaoId,
            orElse: () => CartaoModel(
              id: '',
              usuarioId: '',
              nome: 'Cartão',
              limite: 0,
              diaFechamento: 1,
              diaVencimento: 10,
              ativo: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          chips.add(_buildChipCartaoFiltro(cartao));
        }
      }

      // Contas
      if (_filtrosPersonalizados['contas']?.isNotEmpty ?? false) {
        for (final contaId in _filtrosPersonalizados['contas']) {
          final conta = _contas.firstWhere(
            (c) => c.id == contaId,
            orElse: () => ContaModel(
              id: '',
              usuarioId: '',
              nome: 'Conta',
              tipo: 'corrente',
              saldoInicial: 0,
              saldo: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          chips.add(_buildChipContaFiltro(conta));
        }
      }

      // Status
      if (_filtrosPersonalizados['status']?.isNotEmpty ?? false) {
        for (final status in _filtrosPersonalizados['status']) {
          chips.add(_buildChipStatusFiltro(status));
        }
      }

      // Valor mínimo
      if (_filtrosPersonalizados['valorMinimo'] != null &&
          _filtrosPersonalizados['valorMinimo'] > 0) {
        chips.add(_buildChipValorMinimo(_filtrosPersonalizados['valorMinimo']));
      }

      // Valor máximo
      if (_filtrosPersonalizados['valorMaximo'] != null &&
          _filtrosPersonalizados['valorMaximo'] > 0) {
        chips.add(_buildChipValorMaximo(_filtrosPersonalizados['valorMaximo']));
      }
    }

    // Se não há chips, não mostrar nada
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    // Adicionar botão "Limpar filtros" se há filtros ativos
    if (_periodoAtivo != null ||
        _visaoAtiva != null ||
        _filtroAtivo != null ||
        _temFiltrosAtivos()) {
      chips.add(_buildChipLimparFiltros());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  /// Chip para filtro inteligente ativo
  Widget _buildChipFiltroInteligente(FiltroInteligente filtro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(filtro.icone, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            filtro.titulo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para período atual
  Widget _buildChipPeriodo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _formatarMesCompacto(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para categoria filtrada
  Widget _buildChipCategoriaFiltro(CategoriaModel categoria) {
    Color corCategoria;
    try {
      corCategoria = Color(int.parse(categoria.cor.replaceAll('#', '0xFF')));
    } catch (e) {
      corCategoria = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: corCategoria,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        categoria.nome,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Chip para subcategoria filtrada
  Widget _buildChipSubcategoriaFiltro(
    String subcategoriaId,
    String subcategoriaNome,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tealPrimary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        subcategoriaNome,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Chip para cartão filtrado
  Widget _buildChipCartaoFiltro(CartaoModel cartao) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316), // Laranja
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            cartao.nome,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para conta filtrada
  Widget _buildChipContaFiltro(ContaModel conta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Azul
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            conta.nome,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para banco de pagamento (faturas de cartão pagas)
  Widget _buildChipBancoPagamento(ContaModel conta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Verde esmeralda - indica pagamento
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.paid,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Pago via ${conta.nome}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para status filtrado
  Widget _buildChipStatusFiltro(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status == 'efetivado'
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status == 'efetivado' ? 'Efetivado' : 'Pendente',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Chip para valor mínimo
  Widget _buildChipValorMinimo(double valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6), // Roxo
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Min: R\$ ${valor.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Chip para valor máximo
  Widget _buildChipValorMaximo(double valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6), // Roxo
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Max: R\$ ${valor.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Chip para limpar filtros
  Widget _buildChipLimparFiltros() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _periodoAtivo = null;
          _visaoAtiva = null;
          _filtroAtivo = null;
          _parametrosFiltro.clear();
          _filtrosPersonalizados.clear();
        });
        _carregarDados();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.clear, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            const Text(
              'Limpar',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip para período ativo
  Widget _buildChipPeriodoAtivo(FiltroPeriodo periodo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(periodo.icone, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            periodo.titulo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para visão ativa
  Widget _buildChipVisaoAtiva(VisaoRapida visao) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visao.icone, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            visao.titulo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarTipoEspecifico(String tipo) {
    switch (tipo) {
      case 'extra':
        return 'Extra';
      case 'previsivel':
        return 'Previsível';
      case 'parcelada':
        return 'Parcelada';
      default:
        return tipo;
    }
  }

  /// 🎛️ MOSTRAR OPÇÕES DA TRANSAÇÃO
  void _mostrarOpcoesTransacao(TransacaoModel transacao) {
    // Verificar se é um agrupamento de cartão
    // Na aba CARTÕES (index 3), apenas faturas reais/virtuais são não-editáveis
    // Nas outras abas (TODAS=0, DESPESAS=2), agrupamentos de cartão também são não-editáveis
    final bool isAgrupamentoCartao = transacao.id.startsWith('fatura_real_') ||
                                     transacao.id.startsWith('fatura_virtual_') ||
                                     (_tabController.index != 3 && transacao.id.startsWith('agrupamento_cartao_'));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle visual do modal
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cinzaMedio,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Card completo da transação com todos os detalhes
              TransactionDetailCard(
                transacao: transacao,
                showMetadata: true,
                loadDataAutomatically: true,
              ),

              const SizedBox(height: 24),

              // Título diferente para agrupamento de cartão
              Text(
                isAgrupamentoCartao
                  ? 'Agrupamento de Fatura'
                  : 'O que você deseja fazer?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),

              // Informação adicional para agrupamentos
              if (isAgrupamentoCartao) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transacao.efetivado
                        ? 'Fatura paga'
                        : 'Fatura pendente de pagamento',
                      style: TextStyle(
                        fontSize: 14,
                        color: transacao.efetivado
                          ? AppColors.verdeSucesso
                          : AppColors.laranjaAlerta,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Chip da conta pagadora (apenas se paga)
                    if (transacao.efetivado && transacao.contaId != null)
                      FutureBuilder<String>(
                        future: _obterNomeConta(transacao.contaId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.verdeSucesso10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.verdeSucesso30,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    size: 14,
                                    color: AppColors.verdeSucesso,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    snapshot.data!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.verdeSucesso,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Opções específicas para agrupamentos de cartão
              if (isAgrupamentoCartao) ...[
                EditOptionCardModal(
                  titulo: 'Ver Transações do Cartão',
                  subtitulo: 'Visualizar transações individuais',
                  icone: Icons.credit_card,
                  cor: AppColors.azul,
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implementar navegação para transações do cartão
                    _mostrarTransacoesDoCartao(transacao);
                  },
                ),
                EditOptionCardModal(
                  titulo: 'Agrupamento Não Editável',
                  subtitulo: 'Este é um resumo das transações do cartão',
                  icone: Icons.info_outline,
                  cor: AppColors.cinzaMedio,
                  onTap: () {},
                  habilitado: false,
                  mensagemDesabilitado:
                      'Agrupamentos de cartão não podem ser editados diretamente',
                ),
              ] else ...[
                // Opções normais para transações individuais

                // Editar
                EditOptionCardModal(
                  titulo: 'Editar',
                  subtitulo: 'Alterar dados da transação',
                  icone: Icons.edit,
                  cor: AppColors.azul,
                  onTap: () {
                    Navigator.of(context).pop();
                    _navegarParaEditarAvancado(transacao);
                  },
                ),

                // Efetivar (apenas se não efetivada E não for despesa de cartão)
                if (!transacao.efetivado && transacao.cartaoId == null)
                  EditOptionCardModal(
                    titulo: 'Efetivar',
                    subtitulo: 'Marcar como confirmada',
                    icone: Icons.check_circle,
                    cor: AppColors.verdeSucesso,
                    onTap: () {
                      Navigator.of(context).pop();
                      _efetivarTransacao(transacao);
                    },
                  ),

                // Desefetivar (apenas se efetivada E não for despesa de cartão)
                if (transacao.efetivado && transacao.cartaoId == null)
                  EditOptionCardModal(
                    titulo: 'Desefetivar',
                    subtitulo: 'Marcar como pendente',
                    icone: Icons.remove_circle,
                    cor: AppColors.amareloAlerta,
                    onTap: () {
                      Navigator.of(context).pop();
                      _desefetivarTransacao(transacao);
                    },
                  ),

                // Duplicar
                EditOptionCardModal(
                  titulo: 'Duplicar',
                  subtitulo: 'Criar uma cópia desta transação',
                  icone: Icons.copy,
                  cor: AppColors.cinzaMedio,
                  onTap: () {
                    Navigator.of(context).pop();
                    _duplicarTransacao(transacao);
                  },
                ),

                // Excluir (apenas se não efetivada)
                if (!transacao.efetivado)
                  EditOptionCardModal(
                    titulo: 'Excluir',
                    subtitulo: 'Remover permanentemente',
                    icone: Icons.delete,
                    cor: AppColors.vermelhoErro,
                    onTap: () {
                      Navigator.of(context).pop();
                      _excluirTransacao(transacao);
                    },
                  )
                else
                  EditOptionCardModal(
                    titulo: 'Não é possível excluir',
                    subtitulo: 'Transações efetivadas não podem ser excluídas',
                    icone: Icons.block,
                    cor: AppColors.cinzaMedio,
                    onTap: () {},
                    habilitado: false,
                    mensagemDesabilitado:
                        'Transações efetivadas não podem ser excluídas',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 HELPER FUNCTIONS
  String _formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  String _formatarTipoTransacao(String tipo) {
    switch (tipo) {
      case 'receita':
        return 'Receita';
      case 'despesa':
        return 'Despesa';
      case 'transferencia':
        return 'Transferência';
      default:
        return tipo;
    }
  }

  /// Obter ícone do tipo de transação (para o modal)
  IconData _getIconeTipoTransacaoModal(TransacaoModel transacao) {
    if (transacao.tipo == 'receita') {
      return Icons.trending_up;
    } else if (transacao.tipo == 'despesa') {
      return transacao.cartaoId != null
          ? Icons.credit_card
          : Icons.trending_down;
    } else {
      return Icons.swap_horiz; // transferência
    }
  }

  /// Obter cor do tipo de transação (para o modal)
  Color _getCorTipoTransacaoModal(TransacaoModel transacao) {
    if (transacao.tipo == 'receita') {
      return AppColors.verdeSucesso;
    } else if (transacao.tipo == 'despesa') {
      return transacao.cartaoId != null
          ? AppColors.roxoPrimario
          : AppColors.vermelhoErro;
    } else {
      return AppColors.azul; // transferência
    }
  }

  /// Obter texto do tipo de transação (para o modal)
  String _getTextoTipoTransacaoModal(TransacaoModel transacao) {
    if (transacao.tipo == 'receita') {
      return 'RECEITA';
    } else if (transacao.tipo == 'despesa') {
      return transacao.cartaoId != null ? 'CARTÃO' : 'DESPESA';
    } else {
      return 'TRANSFERÊNCIA';
    }
  }

  /// EditOptionCard widget (copiado de editar_transacao_page.dart)
  Widget EditOptionCardModal({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
    bool habilitado = true,
    String? mensagemDesabilitado,
  }) {
    return Opacity(
      opacity: habilitado ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withAlpha(52), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: habilitado ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cor, cor.withAlpha(208)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withAlpha(78),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icone, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habilitado
                              ? subtitulo
                              : mensagemDesabilitado ?? subtitulo,
                          style: TextStyle(
                            fontSize: 14,
                            color: habilitado
                                ? AppColors.cinzaTexto
                                : AppColors.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (habilitado)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: cor,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 SELETOR DE MÊS COMPACTO - Padrão Device
  Widget _buildSeletorMes() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: _loading ? null : _mesAnterior,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        InkWell(
          onTap: _selecionarMes,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatarMesCompacto(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: _loading ? null : _proximoMes,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 📅 FORMATO COMPACTO DO MÊS
  String _formatarMesCompacto() {
    final agora = DateTime.now();
    const meses = [
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

    // Prioridade: Visão > Período > Filtro Antigo > Data Atual
    if (_visaoAtiva != null) {
      return _visaoAtiva!.titulo;
    }

    if (_periodoAtivo != null) {
      switch (_periodoAtivo) {
        case FiltroPeriodo.mesAtual:
          final mes = meses[agora.month - 1];
          final ano = agora.year.toString().substring(2);
          return '$mes/$ano';

        case FiltroPeriodo.anoAtual:
          return agora.year.toString();

        case FiltroPeriodo.anoCompleto:
          return agora.year.toString();

        default:
          return _periodoAtivo!.titulo;
      }
    }

    // Compatibilidade com filtros antigos
    if (_filtroAtivo != null) {
      switch (_filtroAtivo) {
        case FiltroInteligente.mesAtual:
          final mes = meses[agora.month - 1];
          final ano = agora.year.toString().substring(2);
          return '$mes/$ano';

        case FiltroInteligente.anoAtual:
          return agora.year.toString();

        default:
          return _filtroAtivo!.titulo;
      }
    }

    // Caso padrão: mostra mês/ano atual da navegação
    final mes = meses[_mesAtual.month - 1];
    final ano = _mesAtual.year.toString().substring(2);
    return '$mes/$ano';
  }

  /// 🎨 TABS HORIZONTAIS - Padrão Device
  Widget _buildTabsHorizontais() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      indicatorColor: Colors.white,
      indicatorWeight: 2,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withAlpha(182),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: TransacoesPageMode.values
          .map((modo) => Tab(text: modo.titulo.toUpperCase()))
          .toList(),
    );
  }

  /// 💳 TOGGLE CARTÕES - "Por Fatura" vs "Detalhado"
  Widget _buildToggleCartoes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Visualizar: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Por Fatura'),
                icon: Icon(Icons.receipt_long),
              ),
              ButtonSegment(
                value: false,
                label: Text('Detalhado'),
                icon: Icon(Icons.list),
              ),
            ],
            selected: {_porFatura},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _porFatura = newSelection.first;
              });
              // Recarregar dados com nova visualização
              _carregarDados();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _modoAtual.corHeader;
                }
                return Colors.grey[100];
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: _modoAtual.corHeader, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 LISTA DE TRANSAÇÕES - Padrão Device
  Widget _buildListaTransacoes() {
    if (_transacoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(_modoAtual.icone, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione transações para vê-las aqui',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Modo Timeline
    if (_modoVisualizacao == 2) {
      return TimelineTransacoes(
        transacoes: _transacoes,
        contas: _contas,
        cartoes: _cartoes,
        categorias: _categorias,
        onTransacaoTap: _mostrarOpcoesTransacao,
        mostrarSaldoCorrente: _modoAtual == TransacoesPageMode.todas,
        corTema: _modoAtual.corHeader,
      );
    }

    // Modo cartões com toggle "Por Fatura"
    if (_modoAtual == TransacoesPageMode.cartoes && _porFatura) {
      return _buildListaFaturas();
    }

    // Modo cartões "Detalhado" - filtrar por períodos reais de fatura
    if (_modoAtual == TransacoesPageMode.cartoes && !_porFatura) {
      return _buildTransacoesDetalhadas();
    }

    // Modo Lista Compacta (sem headers nem saldos)
    if (_modoVisualizacao == 1) {
      print('🎯 DEBUG: Modo visualização 1 - Lista Compacta');
      return _buildListaCompacta();
    }

    // Modo Lista Normal (com agrupamento por data)
    if (_agruparPorDia) {
      return _buildTransacoesAgrupadasPorData();
    } else {
      return _buildTransacoesSemAgrupamento();
    }
  }

  /// 📱 LISTA COMPACTA - Sem headers nem saldos (máximo espaço)
  Widget _buildListaCompacta() {
    print(
      '🎯 DEBUG: _buildListaCompacta chamada - ${_transacoes.length} transações',
    );

    if (_transacoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(_modoAtual.icone, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione transações para visualizar',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Ordenar transações por data (mais recente primeiro)
    final transacoesOrdenadas = List<TransacaoModel>.from(_transacoes)
      ..sort((a, b) => b.data.compareTo(a.data));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      child: Column(
        children: transacoesOrdenadas.map((transacao) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildTransacaoItem(transacao),
          );
        }).toList(),
      ),
    );
  }

  /// 📅 TRANSAÇÕES AGRUPADAS POR DATA - Padrão Device
  Widget _buildTransacoesAgrupadasPorData() {
    final Map<String, List<TransacaoModel>> grupos = {};

    for (final transacao in _transacoes) {
      final chave = DateFormat('yyyy-MM-dd').format(transacao.data);
      grupos[chave] ??= [];
      grupos[chave]!.add(transacao);
    }

    final datasOrdenadas = grupos.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Mais recente primeiro

    // Calcular saldo corrente se modo "todas"
    double saldoAcumulado = 0.0;
    final mostrarSaldo = _modoAtual == TransacoesPageMode.todas;

    if (mostrarSaldo) {
      // Calcular saldo total das transações (do mais antigo para mais recente)
      final todasTransacoes = List<TransacaoModel>.from(_transacoes)
        ..sort((a, b) => a.data.compareTo(b.data));

      for (final transacao in todasTransacoes) {
        if (transacao.tipo == 'receita') {
          saldoAcumulado += transacao.valor;
        } else {
          saldoAcumulado -= transacao.valor;
        }
      }
    }

    return Column(
      children: datasOrdenadas.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final transacoesDia = grupos[data]!;
        final dataFormatada = DateTime.parse(data);

        // Verificar se é primeiro ou último dia do mês
        final isPrimeiroDia = dataFormatada.day == 1;
        final isUltimoDia =
            dataFormatada.day ==
            DateTime(dataFormatada.year, dataFormatada.month + 1, 0).day;

        // Atualizar saldo para o dia (voltando no tempo)
        if (mostrarSaldo) {
          for (final transacao in transacoesDia) {
            if (transacao.tipo == 'receita') {
              saldoAcumulado -= transacao.valor;
            } else {
              saldoAcumulado += transacao.valor;
            }
          }
        }

        // Mostrar saldo apenas no primeiro e último dia do mês
        final mostrarSaldoNesteDia =
            mostrarSaldo && (isPrimeiroDia || isUltimoDia);

        return _buildGrupoDia(
          dataFormatada,
          transacoesDia,
          mostrarSaldoNesteDia ? saldoAcumulado : null,
          isPrimeiroDia
              ? 'Saldo inicial do mês'
              : (isUltimoDia ? 'Saldo final do mês' : null),
        );
      }).toList(),
    );
  }

  /// 📋 TRANSAÇÕES SEM AGRUPAMENTO
  Widget _buildTransacoesSemAgrupamento() {
    return Column(
      children: _transacoes
          .map((transacao) => _buildTransacaoItem(transacao))
          .toList(),
    );
  }

  /// 📅 GRUPO DE TRANSAÇÕES DE UM DIA - Padrão Device
  Widget _buildGrupoDia(
    DateTime data,
    List<TransacaoModel> transacoes, [
    double? saldoNoPonto,
    String? labelSaldo,
  ]) {
    // Calcular total do dia
    double totalDia = 0.0;
    for (final transacao in transacoes) {
      if (transacao.tipo == 'receita') {
        totalDia += transacao.valor;
      } else {
        totalDia -= transacao.valor;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header do dia - Só mostra se houver mais de uma transação OU se houver saldo a mostrar
        if (transacoes.length > 1 ||
            (saldoNoPonto != null && labelSaldo != null))
          _buildHeaderDia(
            data,
            totalDia,
            saldoNoPonto,
            labelSaldo,
            transacoes.length,
          ),
        // Lista de transações do dia
        ...transacoes.map((transacao) => _buildTransacaoItem(transacao)),
      ],
    );
  }

  /// 📅 HEADER DO DIA - Padrão Device
  Widget _buildHeaderDia(
    DateTime data,
    double totalDia, [
    double? saldoNoPonto,
    String? labelSaldo,
    int quantidadeTransacoes = 0,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      margin: const EdgeInsets.only(top: 4),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB), // Cinza claro
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Linha principal - data e total do dia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatarDataGrupoDevice(data),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151), // Cinza escuro mas legível
                  letterSpacing: 0.1,
                ),
              ),
              // Só mostra total se há movimentação E mais de uma transação no dia
              if (totalDia != 0 && quantidadeTransacoes > 1)
                Text(
                  '${totalDia >= 0 ? '+' : ''}${_formatarMoeda(totalDia)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: totalDia >= 0
                        ? const Color(0xFF059669) // Verde mais suave
                        : const Color(0xFFDC2626), // Vermelho mais suave
                  ),
                ),
            ],
          ),

          // Saldo (se disponível e há label)
          if (saldoNoPonto != null && labelSaldo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _modoAtual.corHeader.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _modoAtual.corHeader.withAlpha(78),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    labelSaldo,
                    style: TextStyle(
                      fontSize: 12,
                      color: _modoAtual.corHeader,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatarMoeda(saldoNoPonto),
                    style: TextStyle(
                      fontSize: 14,
                      color: _modoAtual.corHeader,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📅 FORMATAR DATA DO GRUPO - Padrão Device
  String _formatarDataGrupoDevice(DateTime data) {
    final hoje = DateTime.now();
    final ontem = DateTime.now().subtract(const Duration(days: 1));

    if (data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day) {
      return 'Hoje';
    } else if (data.year == ontem.year &&
        data.month == ontem.month &&
        data.day == ontem.day) {
      return 'Ontem';
    } else {
      // Formato Device: "29 de setembro" ou "29 de set" se mesmo ano
      final meses = [
        '',
        'janeiro',
        'fevereiro',
        'março',
        'abril',
        'maio',
        'junho',
        'julho',
        'agosto',
        'setembro',
        'outubro',
        'novembro',
        'dezembro',
      ];

      final mesesAbrev = [
        '',
        'jan',
        'fev',
        'mar',
        'abr',
        'mai',
        'jun',
        'jul',
        'ago',
        'set',
        'out',
        'nov',
        'dez',
      ];

      if (data.year == hoje.year) {
        // Mesmo ano: "29 de setembro"
        return '${data.day} de ${meses[data.month]}';
      } else {
        // Ano diferente: "29 de set de 2024"
        return '${data.day} de ${mesesAbrev[data.month]} de ${data.year}';
      }
    }
  }

  /// 💳 LISTA DE FATURAS AGRUPADAS - Padrão Device
  Widget _buildListaFaturas() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _criarFaturasAgrupadasReal(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando faturas...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar faturas',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tente novamente em alguns instantes',
                  style: TextStyle(color: Colors.red[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final faturas = snapshot.data ?? [];

        if (faturas.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.credit_card_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma fatura encontrada',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione despesas no cartão para ver faturas aqui',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: faturas.map((fatura) => _buildFaturaCard(fatura)).toList(),
        );
      },
    );
  }

  /// 📊 CRIAR FATURAS AGRUPADAS - USANDO CARTAO DATA SERVICE
  /// 🔥 NOVA VERSÃO: Usa CartaoDataService.buscarFaturaReal() para garantir consistência
  Future<List<Map<String, dynamic>>> _criarFaturasAgrupadasReal() async {
    try {
      final Map<String, Map<String, dynamic>> faturas = {};
      final CartaoDataService cartaoDataService = CartaoDataService.instance;

      // Filtrar apenas transações de cartão
      final transacoesCartao = _transacoes
          .where((t) => t.cartaoId != null)
          .where((t) => _passaNosFiltros(t))
          .toList();

      // 🔥 AGRUPAR POR CARTÃO E FATURA_VENCIMENTO (NÃO POR DATA DA TRANSAÇÃO)
      final Map<String, List<TransacaoModel>> transacoesPorCartaoMes = {};

      for (final transacao in transacoesCartao) {
        final cartaoId = transacao.cartaoId!;

        // 🔥 USAR FATURA_VENCIMENTO EM VEZ DE DATA DA TRANSAÇÃO
        final faturaVencimento = transacao.faturaVencimento;
        if (faturaVencimento == null) {
          continue; // Pular transações sem data de vencimento
        }

        final mesAno =
            '${faturaVencimento.year}-${faturaVencimento.month.toString().padLeft(2, '0')}';
        final chave = '${cartaoId}_$mesAno';

        if (!transacoesPorCartaoMes.containsKey(chave)) {
          transacoesPorCartaoMes[chave] = [];
        }
        transacoesPorCartaoMes[chave]!.add(transacao);
      }

      // Para cada grupo de transações, usar CartaoDataService.buscarFaturaReal()
      for (final entry in transacoesPorCartaoMes.entries) {
        final chave = entry.key;
        final transacoesGrupo = entry.value;
        final cartaoId = chave.split('_')[0];
        final mesAnoStr = chave.split('_')[1];
        final ano = int.parse(mesAnoStr.split('-')[0]);
        final mes = int.parse(mesAnoStr.split('-')[1]);
        final mesReferencia = DateTime(ano, mes);

        final cartao = _cartoes.firstWhere(
          (c) => c.id == cartaoId,
          orElse: () => CartaoModel(
            id: cartaoId,
            usuarioId: '',
            nome: 'Cartão não encontrado',
            limite: 0.0,
            diaFechamento: 5,
            diaVencimento: 10,
            ativo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // 🔥 USAR CartaoDataService.buscarFaturaReal() - MESMA LÓGICA DOS CARTÕES
        // Para faturas pagas, usar a data de vencimento da primeira transação como referência
        DateTime mesReferenciaFinal = mesReferencia;
        if (transacoesGrupo.isNotEmpty &&
            transacoesGrupo.first.faturaVencimento != null) {
          final primeiraFaturaVencimento =
              transacoesGrupo.first.faturaVencimento!;
          mesReferenciaFinal = DateTime(
            primeiraFaturaVencimento.year,
            primeiraFaturaVencimento.month,
          );
        }

        final faturaReal = await cartaoDataService.buscarFaturaReal(
          cartaoId,
          mesReferencia: mesReferenciaFinal,
        );

        if (faturaReal != null) {
          // Calcular valor das transações neste período da fatura
          double valorTransacoes = 0.0;
          for (final transacao in transacoesGrupo) {
            valorTransacoes += transacao.valor;
          }

          // Verificar se está paga (todas transações efetivadas)
          final todasEfetivadas = transacoesGrupo.every((t) => t.efetivado);

          // 📅 ORDENAR TRANSAÇÕES POR DATA (MAIS RECENTES PRIMEIRO)
          transacoesGrupo.sort((a, b) => b.data.compareTo(a.data));

          faturas[chave] = {
            'id': chave,
            'cartaoId': cartaoId,
            'cartao': cartao,
            'mesAno': mesAnoStr,
            'dataVencimento': faturaReal.dataVencimento,
            'valor': faturaReal.valorTotal, // Usar valor real da fatura
            'valorTransacoes':
                valorTransacoes, // Valor específico das transações filtradas
            'faturaReal': faturaReal,
            'transacoes': transacoesGrupo,
            'paga': faturaReal.paga || todasEfetivadas,
          };
        } else {
          // 🔥 FALLBACK: Se faturaReal é null, criar fatura sintética para transações pagas
          // Calcular valor das transações neste grupo
          double valorTransacoes = 0.0;
          DateTime? dataVencimento;
          for (final transacao in transacoesGrupo) {
            valorTransacoes += transacao.valor;
            dataVencimento ??= transacao.faturaVencimento;
          }

          // Verificar se todas as transações estão efetivadas (pagas)
          final todasEfetivadas = transacoesGrupo.every((t) => t.efetivado);

          if (valorTransacoes > 0.01 && dataVencimento != null) {
            // 📅 ORDENAR TRANSAÇÕES POR DATA (MAIS RECENTES PRIMEIRO)
            transacoesGrupo.sort((a, b) => b.data.compareTo(a.data));

            faturas[chave] = {
              'id': chave,
              'cartaoId': cartaoId,
              'cartao': cartao,
              'mesAno': mesAnoStr,
              'dataVencimento': dataVencimento,
              'valor': valorTransacoes, // Usar valor das transações
              'valorTransacoes': valorTransacoes,
              'faturaReal': null, // Indicar que é sintética
              'transacoes': transacoesGrupo,
              'paga': todasEfetivadas, // Basear no status das transações
            };
          }
        }
      }

      final listaFaturas = faturas.values.toList();

      // Ordenar por data de vencimento
      listaFaturas.sort(
        (a, b) => (a['dataVencimento'] as DateTime).compareTo(
          b['dataVencimento'] as DateTime,
        ),
      );

      return listaFaturas;
    } catch (e) {
      debugPrint('❌ Erro ao criar faturas agrupadas: $e');
      return [];
    }
  }

  /// 📊 CRIAR FATURAS AGRUPADAS - WRAPPER SÍNCRONO
  List<Map<String, dynamic>> _criarFaturasAgrupadas() {
    // Este método será substituído pelo _buildListaFaturasAsync
    return [];
  }

  /// 💳 TRANSAÇÕES DETALHADAS - Com períodos reais de fatura
  /// 🔥 Mostra as transações específicas dentro dos períodos corretos de fatura
  Widget _buildTransacoesDetalhadas() {
    return FutureBuilder<List<TransacaoModel>>(
      future: _obterTransacoesComPeriodosReais(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando transações detalhadas...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar transações',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final transacoesFiltradas = snapshot.data ?? [];

        if (transacoesFiltradas.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma transação encontrada',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Filtre por período de fatura para ver transações detalhadas',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Usar lógica de exibição existente mas com transações filtradas
        final transacoesBackup = _transacoes;
        _transacoes = transacoesFiltradas;

        Widget resultado;
        if (_modoVisualizacao == 1) {
          resultado = _buildListaCompacta();
        } else if (_agruparPorDia) {
          resultado = _buildTransacoesAgrupadasPorData();
        } else {
          resultado = _buildTransacoesSemAgrupamento();
        }

        // Restaurar lista original
        _transacoes = transacoesBackup;

        return resultado;
      },
    );
  }

  /// 🔍 OBTER TRANSAÇÕES DETALHADAS (SIMPLIFICADO)
  /// 🔥 VERSÃO DIRETA: Busca transações pelo campo fatura_vencimento no período
  Future<List<TransacaoModel>> _obterTransacoesComPeriodosReais() async {
    try {
      debugPrint('💳 🔥 Obtendo transações DIRETO pelo fatura_vencimento...');

      // Obter período atual (igual lógica _carregarDados)
      DateTime inicioMes, fimMes;

      if ((_filtroAtivo != null || _periodoAtivo != null) &&
          _parametrosFiltro.containsKey('inicio')) {
        inicioMes = _parametrosFiltro['inicio'] as DateTime;
        fimMes = _parametrosFiltro['fim'] as DateTime;
      } else {
        inicioMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
        fimMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      }

      final mesVencimento = inicioMes.month;
      final anoVencimento = inicioMes.year;

      debugPrint(
        '💳 📅 Buscando transações com fatura_vencimento em: ${mesVencimento}/${anoVencimento}',
      );

      final db = LocalDatabase.instance;

      // 🎯 BUSCAR DIRETAMENTE todas as transações que têm fatura_vencimento no período
      final transacoesResult = await db.select(
        'transacoes',
        where: '''
          usuario_id = ?
          AND cartao_id IS NOT NULL
          AND fatura_vencimento IS NOT NULL
          AND strftime('%Y', fatura_vencimento) = ?
          AND strftime('%m', fatura_vencimento) = ?
        ''',
        whereArgs: [
          db.currentUserId,
          anoVencimento.toString(),
          mesVencimento.toString().padLeft(2, '0'),
        ],
      );

      debugPrint('💳 📊 Transações encontradas: ${transacoesResult.length}');

      final List<TransacaoModel> transacoesDetalhadas = [];

      // Converter para TransacaoModel
      for (final transacaoData in transacoesResult) {
        try {
          final transacao = TransacaoModel.fromJson(transacaoData);
          transacoesDetalhadas.add(transacao);
        } catch (e) {
          debugPrint('❌ Erro ao converter transação: $e');
        }
      }

      debugPrint(
        '💳 ✅ Total de transações convertidas: ${transacoesDetalhadas.length}',
      );

      if (transacoesDetalhadas.isNotEmpty) {
        for (final transacao in transacoesDetalhadas.take(5)) {
          debugPrint(
            '💳 📝 ${transacao.descricao} - R\$ ${transacao.valor.toStringAsFixed(2)} - Fatura: ${transacao.faturaVencimento}',
          );
        }
        if (transacoesDetalhadas.length > 5) {
          debugPrint(
            '💳 📝 ... e mais ${transacoesDetalhadas.length - 5} transações',
          );
        }
      }

      // Aplicar filtros personalizados (cartões, categorias, valores, etc.)
      return _aplicarFiltrosPersonalizados(transacoesDetalhadas);
    } catch (e) {
      debugPrint('❌ Erro ao obter transações detalhadas: $e');
      return [];
    }
  }

  /// 💳 CARD DE FATURA - Usando CartaoCard (unificado com CartoesConsolidadoPage)
  /// 🔥 NOVA VERSÃO: Usa dados reais da fatura do CartaoDataService
  Widget _buildFaturaCard(Map<String, dynamic> fatura) {
    final cartao = fatura['cartao'] as CartaoModel;
    final valor = fatura['valor'] as double; // Valor real da fatura
    final faturaReal =
        fatura['faturaReal']
            as FaturaModel?; // Fatura real do CartaoDataService (pode ser null para faturas sintéticas)
    final transacoes = fatura['transacoes'] as List<TransacaoModel>;
    final dataVencimento = fatura['dataVencimento'] as DateTime;
    final paga = fatura['paga'] as bool;

    // 🔥 Para faturas sintéticas, criar um FaturaModel sintético
    final faturaParaCard =
        faturaReal ??
        FaturaModel(
          id: 'synthetic_${cartao.id}',
          cartaoId: cartao.id,
          usuarioId: cartao.usuarioId,
          ano: dataVencimento.year,
          mes: dataVencimento.month,
          dataFechamento: DateTime(
            dataVencimento.year,
            dataVencimento.month,
            cartao.diaFechamento,
          ),
          dataVencimento: dataVencimento,
          valorTotal: valor,
          valorMinimo: valor * 0.15, // 15% como valor mínimo padrão
          status: paga ? 'paga' : 'aberta',
          paga: paga,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    return CartaoCard(
      cartao: cartao,
      valorUtilizado: valor, // Usar valor real da fatura
      faturaAtual: faturaParaCard, // Usar FaturaModel real ou sintético
      showUtilizacao: true,
      showFaturaInfo: true,
      isCompact: false,
      onTap: () => _mostrarDetalhesFatura(fatura),
    );
  }

  /// 🔍 MOSTRAR DETALHES DA FATURA
  void _mostrarDetalhesFatura(Map<String, dynamic> fatura) {
    final cartao = fatura['cartao'] as CartaoModel;
    final transacoesOriginais = fatura['transacoes'] as List<TransacaoModel>;
    final valor = fatura['valor'] as double;

    // 📅 ORDENAR TRANSAÇÕES POR DATA (MAIS RECENTES PRIMEIRO)
    final transacoes = List<TransacaoModel>.from(transacoesOriginais);
    transacoes.sort((a, b) => b.data.compareTo(a.data));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Fatura ${cartao.nome}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${_formatarMoeda(valor)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _modoAtual.corHeader,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Lista de transações
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: transacoes.length,
                  itemBuilder: (context, index) {
                    final transacao = transacoes[index];
                    return _buildTransacaoItem(transacao);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ➕ MENU ADICIONAR TRANSAÇÃO - Padrão Device
  void _mostrarMenuAdicionar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Nova Transação',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOpcaoMenu(
              'Receita',
              Icons.trending_up,
              Colors.green[600]!,
              () {
                Navigator.pop(context);
                _navegarParaNovaTransacao('receita');
              },
            ),
            const SizedBox(height: 12),
            _buildOpcaoMenu(
              'Despesa',
              Icons.trending_down,
              Colors.red[600]!,
              () {
                Navigator.pop(context);
                _navegarParaNovaTransacao('despesa');
              },
            ),
            const SizedBox(height: 12),
            _buildOpcaoMenu(
              'Transferência',
              Icons.swap_horiz,
              Colors.blue[600]!,
              () {
                Navigator.pop(context);
                _navegarParaTransferencia();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoMenu(
    String titulo,
    IconData icone,
    Color cor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withAlpha(78)),
        ),
        child: Row(
          children: [
            Icon(icone, color: cor),
            const SizedBox(width: 16),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cor,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: cor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _modoAtual.corHeader,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Botão voltar customizado
            Transform.translate(
              offset: const Offset(-8, 0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => _voltarComInteligencia(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
            Text(
              _modoAtual.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle Visualização (Lista → Compacta → Timeline) - Ícone compacto
          if (_modoAtual != TransacoesPageMode.cartoes || !_porFatura)
            IconButton(
              icon: Icon(
                _modoVisualizacao == 0
                    ? Icons.view_compact
                    : _modoVisualizacao == 1
                    ? Icons.timeline
                    : Icons.list,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _modoVisualizacao = (_modoVisualizacao + 1) % 3;
                  print(
                    '🎯 DEBUG: Modo visualização alterado para: $_modoVisualizacao',
                  );
                });
              },
              tooltip: _modoVisualizacao == 0
                  ? 'Lista Compacta'
                  : _modoVisualizacao == 1
                  ? 'Timeline'
                  : 'Lista Normal',
            ),

          // Botão de Busca Inteligente (migração gradual das visões rápidas)
          IconButton(
            onPressed: () {
              // Prioridade 1: Abrir search overlay
              _mostrarSearchOverlay();

              // TODO: Fase 3 - Remover visões rápidas após validação
              // Manter temporariamente para compatibilidade
            },
            icon: Stack(
              children: [
                Icon(
                  Icons.search,
                  color: (_visaoAtiva != null || _filtroBusca.isNotEmpty)
                      ? Colors.yellow[300]
                      : Colors.white,
                ),
                // Indicador combinado (busca ativa ou visão ativa)
                if (_filtroBusca.isNotEmpty || _visaoAtiva != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.yellow[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: _filtroBusca.isNotEmpty
                ? 'Busca: "$_filtroBusca" (clique para editar)'
                : 'Busca Inteligente + Filtros Rápidos',
          ),

          // Botão de filtros com indicador
          Stack(
            children: [
              IconButton(
                onPressed: _mostrarFiltros,
                icon: const Icon(Icons.tune),
              ),
              if (_temFiltrosAtivos())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Sublinha com navegação - Padrão Device
              Container(
                decoration: BoxDecoration(
                  color: _modoAtual.corHeader,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seletor de mês à esquerda
                    _buildSeletorMes(),
                    // Tabs à direita
                    Expanded(child: _buildTabsHorizontais()),
                  ],
                ),
              ),

              // Chips de busca ativa
              if (_filtroBusca.isNotEmpty) _buildSearchChips(),

              // Toggle "Por Fatura" vs "Detalhado" para cartões - Padrão Device
              if (_modoAtual == TransacoesPageMode.cartoes)
                _buildToggleCartoes(),

              // Conteúdo principal
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _carregarDados,
                        color: _modoAtual.corHeader,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Chips de filtros ativos
                              _buildFiltrosAtivosChips(),

                              // Resumo adaptativo - Padrão Device
                              _buildResumoAdaptativo(),

                              // Lista de transações
                              _buildListaTransacoes(),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          _buildFABOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _modoAtual.corHeader,
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
      bottomNavigationBar: widget.showNavigationBar
          ? AppBottomNavigation(currentIndex: 4, onTap: _onBottomNavigationTap)
          : null,
    );
  }

  /// 🔧 FILTROS AVANÇADOS
  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltrosTransacoesModal(
        modo: _modoAtual,
        filtrosAtuais: _filtrosPersonalizados,
        onClose: () => Navigator.of(context).pop(),
        onFiltrosAplicados: (filtros) {
          setState(() {
            _filtrosPersonalizados = filtros;
          });
          _carregarDados();
        },
      ),
    );
  }

  /// 📥 MOSTRAR MODAL DE IMPORTAÇÃO
  Future<void> _mostrarImportacao() async {
    try {
      final resultado = await ImportacaoModal.show(context);

      if (resultado != null && resultado['sucesso'] == true) {
        final transacoesSalvas = resultado['transacoesSalvas'] ?? 0;
        final transacoesPuladas = resultado['transacoesPuladas'] ?? 0;

        // Mostrar feedback de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ $transacoesSalvas transação(ões) importada(s) com sucesso!' +
                    (transacoesPuladas > 0
                        ? '\n$transacoesPuladas foram puladas.'
                        : ''),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );

          // Recarregar dados
          _carregarDados();
        }
      }
    } catch (e) {
      debugPrint('❌ Erro na importação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na importação: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _temFiltrosAtivos() {
    return (_filtrosPersonalizados['categorias']?.isNotEmpty ?? false) ||
        (_filtrosPersonalizados['subcategorias']?.isNotEmpty ?? false) ||
        (_filtrosPersonalizados['contas']?.isNotEmpty ?? false) ||
        (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) ||
        (_filtrosPersonalizados['status']?.isNotEmpty ?? false) ||
        (_filtrosPersonalizados['valorMinimo'] ?? 0.0) > 0 ||
        (_filtrosPersonalizados['valorMaximo'] ?? 999999.0) < 999999 ||
        _filtroBusca.isNotEmpty;
    // Removido dataInicio/dataFim pois são aplicados na busca do banco, não aqui
  }

  bool _passaNosFiltros(TransacaoModel transacao) {
    return _aplicarFiltrosPersonalizados([transacao]).isNotEmpty;
  }

  /// Verifica se há filtros de categoria ou subcategoria ativos
  bool _temFiltrosCategoriaAtivos() {
    return (_filtrosPersonalizados['categorias']?.isNotEmpty ?? false) ||
        (_filtrosPersonalizados['subcategorias']?.isNotEmpty ?? false);
  }

  /// Aplica filtro de busca por texto
  void _aplicarFiltroBusca() {
    if (_filtroBusca.isEmpty) {
      // Se busca está vazia, recarregar dados normalmente
      _carregarDados();
      return;
    }

    // Filtrar transações existentes em memória
    setState(() {
      // A filtragem será aplicada no método _aplicarFiltrosPersonalizados
      // que já é chamado no carregamento de dados
    });
    _carregarDados();
  }

  /// Controle do Search Overlay
  void _mostrarSearchOverlay() {
    if (_showSearchOverlay) return;

    setState(() => _showSearchOverlay = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => SearchOverlay(
        initialSearch: _filtroBusca,
        onSearchChanged: (value) {
          setState(() {
            _filtroBusca = value;
            _buscaController.text = value;
          });
          _aplicarFiltroBusca();
        },
        onClose: _fecharSearchOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _fecharSearchOverlay() {
    if (!_showSearchOverlay) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showSearchOverlay = false);
  }

  /// Build da área de chips de busca
  Widget _buildSearchChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Busca ativa:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              SearchChip(
                text: _filtroBusca,
                onRemove: () {
                  setState(() {
                    _filtroBusca = '';
                    _buscaController.clear();
                  });
                  _carregarDados();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TransacaoModel> _aplicarFiltrosPersonalizados(
    List<TransacaoModel> transacoes,
  ) {
    if (!_temFiltrosAtivos() && _filtroAtivo == null) return transacoes;

    return transacoes.where((transacao) {
      // Aplicar filtros inteligentes primeiro
      if (_filtroAtivo != null && _parametrosFiltro.isNotEmpty) {
        // Filtro por efetivado - 🔥 FIX COMPLETO: Nas abas normais, não filtrar receitas por efetivado
        if (_parametrosFiltro.containsKey('efetivado')) {
          final efetivadoRequerido = _parametrosFiltro['efetivado'] as bool;

          // 🚨 EXCEÇÃO IMPORTANTE: Para abas normais (Todas/Receitas), receitas sempre passam
          final modoAtual = _modoAtual;
          final isAbaNormal =
              (modoAtual == TransacoesPageMode.todas ||
              modoAtual == TransacoesPageMode.receitas);
          final isReceita = transacao.tipo == 'receita';

          if (isAbaNormal && isReceita) {
            // ✅ Receitas sempre passam nas abas normais (independente de efetivado)
          } else {
            // Para outras situações, aplicar filtro normal
            if (transacao.efetivado != efetivadoRequerido) {
              return false;
            }
          }
        }

        // Filtro por cartão (booleano)
        if (_parametrosFiltro.containsKey('cartao')) {
          final cartaoRequerido = _parametrosFiltro['cartao'] as bool;

          // ✅ EXCEÇÃO: Faturas sintéticas são consideradas como "tem cartão"
          final String? cartaoIdReal = _extrairCartaoIdDeFaturaSintetica(
            transacao.id,
          );
          final bool temCartao =
              transacao.cartaoId != null || cartaoIdReal != null;

          if (cartaoRequerido != temCartao) {
            return false;
          }
        }

        // Filtro por tipo
        if (_parametrosFiltro.containsKey('tipo')) {
          final tipoRequerido = _parametrosFiltro['tipo'] as String;
          if (transacao.tipo != tipoRequerido) {
            return false;
          }
        }

        // Filtro por vencidas
        if (_parametrosFiltro.containsKey('vencidas')) {
          final agora = DateTime.now();
          final isVencida =
              !transacao.efetivado && transacao.data.isBefore(agora);
          if (!isVencida) {
            return false;
          }
        }
      }
      // ✅ FILTRO POR CATEGORIA (NULL-SAFE para faturas sintéticas reais/virtuais)
      if (_filtrosPersonalizados['categorias']?.isNotEmpty ?? false) {
        final bool isFaturaSintetica =
            transacao.id.startsWith('fatura_virtual_') ||
            transacao.id.startsWith('fatura_real_');
        // Se é fatura sintética (categoriaId = null), permitir sempre
        if (isFaturaSintetica && transacao.categoriaId == null) {
          // sempre permitido
        } else if (transacao.categoriaId == null ||
            !_filtrosPersonalizados['categorias'].contains(
              transacao.categoriaId,
            )) {
          return false;
        }
      }

      // ✅ FILTRO POR SUBCATEGORIA (NULL-SAFE para faturas sintéticas reais/virtuais)
      if (_filtrosPersonalizados['subcategorias']?.isNotEmpty ?? false) {
        final bool isFaturaSintetica =
            transacao.id.startsWith('fatura_virtual_') ||
            transacao.id.startsWith('fatura_real_');
        // Se é fatura sintética (subcategoriaId = null), permitir sempre
        if (isFaturaSintetica && transacao.subcategoriaId == null) {
          // sempre permitido
        } else if (transacao.subcategoriaId == null ||
            !_filtrosPersonalizados['subcategorias'].contains(
              transacao.subcategoriaId,
            )) {
          return false;
        }
      }

      // Filtro por conta
      if (_filtrosPersonalizados['contas']?.isNotEmpty ?? false) {
        if (!_filtrosPersonalizados['contas'].contains(transacao.contaId)) {
          return false;
        }
      }

      // Filtro por cartão (lista)
      if (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) {
        // ✅ Para faturas sintéticas, extrair cartaoId real
        final String? cartaoIdReal = _extrairCartaoIdDeFaturaSintetica(
          transacao.id,
        );
        final String? cartaoEfetivo = transacao.cartaoId ?? cartaoIdReal;

        if (cartaoEfetivo == null ||
            !_filtrosPersonalizados['cartoes'].contains(cartaoEfetivo)) {
          print(
            '🔍 DEBUG: Transação ${transacao.id} eliminada por filtro de cartão',
          );
          print('   CartaoId da transação: ${transacao.cartaoId}');
          print('   CartaoId extraído (sintético): $cartaoIdReal');
          print('   CartaoId efetivo usado: $cartaoEfetivo');
          print('   Cartões filtrados: ${_filtrosPersonalizados['cartoes']}');
          return false;
        }
      }

      // Filtro por status
      if (_filtrosPersonalizados['status']?.isNotEmpty ?? false) {
        final status = transacao.efetivado ? 'efetivado' : 'pendente';
        if (!_filtrosPersonalizados['status'].contains(status)) {
          return false;
        }
      }

      // Filtro por valor mínimo
      final valorMin = _filtrosPersonalizados['valorMinimo'] ?? 0.0;
      if (valorMin > 0 && transacao.valor < valorMin) {
        return false;
      }

      // Filtro por valor máximo
      final valorMax = _filtrosPersonalizados['valorMaximo'] ?? 999999.0;
      if (valorMax < 999999 && transacao.valor > valorMax) {
        return false;
      }

      // NOTA: Não aplicamos filtro de data aqui porque já é aplicado na busca do banco
      // (_carregarDados já busca com dataInicio e dataFim corretos)
      // Aplicar novamente causaria problemas com transações de cartão que têm data da compra
      // diferente do período de faturamento

      // Filtro por busca de texto
      if (_filtroBusca.isNotEmpty) {
        final buscaLower = _filtroBusca.toLowerCase();

        // Buscar na descrição da transação
        if (transacao.descricao.toLowerCase().contains(buscaLower)) {
          return true;
        }

        // Buscar no nome da categoria (se disponível)
        if (transacao.categoriaId != null) {
          final categoria = _categorias.firstWhere(
            (c) => c.id == transacao.categoriaId,
            orElse: () => CategoriaModel(
              id: '',
              usuarioId: '',
              nome: '',
              tipo: 'despesa',
              cor: '#008080',
              icone: 'folder',
              ativo: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (categoria.nome.toLowerCase().contains(buscaLower)) {
            return true;
          }
        }

        // Buscar no nome da subcategoria (se disponível)
        if (transacao.subcategoriaId != null) {
          final subcategoria = _subcategorias.firstWhere(
            (s) => s.id == transacao.subcategoriaId,
            orElse: () => SubcategoriaModel(
              id: '',
              usuarioId: '',
              categoriaId: '',
              nome: '',
              cor: '#008080',
              icone: 'folder',
              ativo: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (subcategoria.nome.toLowerCase().contains(buscaLower)) {
            return true;
          }
        }

        // Buscar no nome do cartão (se disponível)
        if (transacao.cartaoId != null) {
          final cartao = _cartoes.firstWhere(
            (c) => c.id == transacao.cartaoId,
            orElse: () => CartaoModel(
              id: '',
              usuarioId: '',
              nome: '',
              limite: 0,
              diaFechamento: 1,
              diaVencimento: 10,
              ativo: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (cartao.nome.toLowerCase().contains(buscaLower)) {
            return true;
          }
        }

        // Buscar no nome da conta (se disponível)
        if (transacao.contaId != null) {
          final conta = _contas.firstWhere(
            (c) => c.id == transacao.contaId,
            orElse: () => ContaModel(
              id: '',
              usuarioId: '',
              nome: '',
              tipo: 'corrente',
              saldoInicial: 0.0,
              saldo: 0.0,
              ativo: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (conta.nome.toLowerCase().contains(buscaLower)) {
            return true;
          }
        }

        // Se chegou até aqui e tem filtro de busca, não passou na busca
        return false;
      }

      return true;
    }).toList();
  }

  /// 🎨 MODAL DE CONFIRMAÇÃO DE EXCLUSÃO COM IDENTIDADE VISUAL
  Future<bool?> _mostrarModalConfirmacaoExclusao(
    TransacaoModel transacao,
  ) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildExclusaoHeader(), _buildExclusaoBody(transacao)],
          ),
        );
      },
    );
  }

  Widget _buildExclusaoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.vermelhoErro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delete_forever, color: AppColors.branco, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Excluir Transação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.branco,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.branco),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildExclusaoBody(TransacaoModel transacao) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExclusaoResumo(transacao),
          const SizedBox(height: 24),
          const Text(
            'Esta ação não pode ser desfeita. Tem certeza que deseja continuar?',
            style: TextStyle(fontSize: 14, color: AppColors.cinzaTexto),
          ),
          const SizedBox(height: 32),
          _buildExclusaoBotoes(),
        ],
      ),
    );
  }

  Widget _buildExclusaoResumo(TransacaoModel transacao) {
    final categoria = _categorias.firstWhere(
      (c) => c.id == transacao.categoriaId,
      orElse: () => CategoriaModel(
        id: '',
        usuarioId: '',
        nome: 'Sem categoria',
        tipo: transacao.tipo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.vermelhoTransparente10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vermelhoTransparente20, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconeTransacao(transacao),
                color: AppColors.vermelhoErro,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  transacao.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
            ).format(transacao.valor),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.vermelhoErro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoria.nome,
            style: const TextStyle(fontSize: 14, color: AppColors.cinzaTexto),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy').format(transacao.data),
            style: const TextStyle(fontSize: 12, color: AppColors.cinzaLegenda),
          ),
        ],
      ),
    );
  }

  Widget _buildExclusaoBotoes() {
    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: AppButton.outline(
            text: 'CANCELAR',
            onPressed: () => Navigator.of(context).pop(false),
            customColor: AppColors.cinzaTexto,
          ),
        ),

        const SizedBox(width: 16),

        // Botão Excluir
        Expanded(
          child: AppButton(
            text: 'EXCLUIR',
            icon: Icons.delete_forever,
            onPressed: () => Navigator.of(context).pop(true),
            customColor: AppColors.vermelhoErro,
          ),
        ),
      ],
    );
  }

  /// 🚀 FAB com menu de 4 opções (padrão do app)
  Widget _buildFAB() {
    return Stack(
      children: [
        // Overlay transparente quando menu está expandido
        if (_fabExpanded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => setState(() => _fabExpanded = false),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black.withAlpha(78),
              ),
            ),
          ),

        // Menu de opções expandido
        if (_fabExpanded)
          Positioned(
            right: 16,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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

        // FAB principal
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton(
            backgroundColor: _modoAtual.corHeader,
            foregroundColor: Colors.white,
            elevation: _fabExpanded ? 8 : 6,
            onPressed: () {
              setState(() => _fabExpanded = !_fabExpanded);
            },
            heroTag: 'transacoes_fab',
            child: AnimatedRotation(
              turns: _fabExpanded ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(_fabExpanded ? Icons.close : Icons.add),
            ),
          ),
        ),
      ],
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
              child: Icon(icon, color: Colors.white, size: 24),
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
      MaterialPageRoute(builder: (context) => const TransferenciaFormPage()),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  void _navegarParaNovaReceita() async {
    setState(() => _fabExpanded = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            const TransacaoFormPage(modo: 'criar', tipo: 'receita'),
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  void _navegarParaNovaDespesa() async {
    setState(() => _fabExpanded = false);

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            const TransacaoFormPage(modo: 'criar', tipo: 'despesa'),
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  void _navegarParaNovaDespesaCartao() async {
    setState(() => _fabExpanded = false);

    // ✅ Usar página específica para despesas de cartão
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const DespesaCartaoPage()),
    );

    if (resultado == true) {
      _carregarDados();
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
            child: Container(color: Colors.black.withAlpha(78)),
          ),
        ),

        // Menu de opções expandido
        Positioned(
          right: 16,
          bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mostrar apenas transferência se estiver na aba de transferências
              if (_modoAtual == TransacoesPageMode.transferencias)
                _buildFABOption(
                  icon: Icons.swap_horiz,
                  label: "Nova Transferência",
                  color: _modoAtual.corHeader,
                  onTap: _navegarParaNovaTransferencia,
                )
              else ...[
                // Menu completo para outras abas
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
            ],
          ),
        ),
      ],
    );
  }

  /// 🧭 NAVEGAÇÃO INTELIGENTE - Voltar para origem ou relatórios
  void _voltarComInteligencia() {
    // Verificar se pode voltar (tem página anterior na pilha)
    if (Navigator.canPop(context)) {
      debugPrint('🧭 TransacoesPage: Voltando para página anterior');
      Navigator.pop(context);
    } else {
      // Não tem página anterior, ir para relatórios (índice 2 no MainNavigation)
      debugPrint(
        '🧭 TransacoesPage: Sem página anterior, navegando para relatórios',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigation(initialIndex: 2),
        ),
        (route) => false, // Remove todas as rotas anteriores
      );
    }
  }

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigation(initialIndex: index),
      ),
      (route) => false,
    );
  }

  /// 🔧 MÉTODO AUXILIAR: Extrair cartaoId real de faturas sintéticas
  String? _extrairCartaoIdDeFaturaSintetica(String id) {
    if (!id.startsWith('fatura_')) return null;

    // Formato: fatura_real_{cartaoId}_{hash} ou fatura_virtual_{cartaoId}_{hash} (hash = cartao+anoMes)
    final partes = id.split('_');
    if (partes.length >= 3) {
      if (partes[1] == 'virtual' && partes.length >= 4) {
        return partes[2]; // fatura_virtual_{cartaoId}_{hash}
      }
      if (partes[1] == 'real' && partes.length >= 4) {
        return partes[2]; // fatura_real_{cartaoId}_{hash}
      }
    }
    return null;
  }

  /// 💳 BUSCAR TRANSAÇÕES INDIVIDUAIS DE CARTÃO FILTRADAS
  /// Busca transações individuais de cartão que passam nos filtros de categoria/subcategoria
  Future<List<TransacaoModel>> _buscarTransacoesCartaoIndividuais(
    DateTime inicioMes,
    DateTime fimMes,
  ) async {
    try {
      debugPrint('💳 🔍 Buscando transações individuais de cartão com filtros...');

      final db = LocalDatabase.instance;
      final userId = db.currentUserId;
      if (userId == null) {
        debugPrint('❌ Usuário não autenticado');
        return [];
      }

      // Buscar transações de cartão reais no período
      final transacoesResult = await db.select(
        'transacoes',
        where: '''
          usuario_id = ?
          AND cartao_id IS NOT NULL
          AND DATE(fatura_vencimento) BETWEEN DATE(?) AND DATE(?)
        ''',
        whereArgs: [
          userId,
          inicioMes.toIso8601String().split('T')[0],
          fimMes.toIso8601String().split('T')[0],
        ],
      );

      debugPrint('💳 📋 Transações de cartão encontradas: ${transacoesResult.length}');

      final List<TransacaoModel> transacoesIndividuais = [];

      // Converter para TransacaoModel e aplicar filtros
      for (final transacaoData in transacoesResult) {
        try {
          final transacao = TransacaoModel.fromJson(transacaoData);
          // Aplicar filtros de categoria/subcategoria
          if (_passaNosFiltros(transacao)) {
            transacoesIndividuais.add(transacao);
          }
        } catch (e) {
          debugPrint('❌ Erro ao converter transação: $e');
        }
      }

      debugPrint('💳 ✅ Transações individuais filtradas: ${transacoesIndividuais.length}');
      return transacoesIndividuais;

    } catch (e) {
      debugPrint('❌ Erro ao buscar transações individuais de cartão: $e');
      return [];
    }
  }

  /// 💳 GERAR AGRUPAMENTOS DE CARTÃO REAIS - NOVO MÉTODO
  /// Busca transações reais de cartão e cria agrupamentos para exibição nas abas "Todas" e "Despesas"
  Future<List<TransacaoModel>> _gerarAgrupamentosCartaoReais(
    DateTime inicioMes,
    DateTime fimMes,
  ) async {
    try {
      debugPrint(
        '💳 ✨ Gerando agrupamentos reais de cartão para o período: ${inicioMes.toIso8601String().split('T')[0]} - ${fimMes.toIso8601String().split('T')[0]}',
      );

      final db = LocalDatabase.instance;
      final userId = db.currentUserId;
      if (userId == null) {
        debugPrint('❌ Usuário não autenticado');
        return [];
      }

      // Buscar transações de cartão reais no período (tanto efetivadas quanto pendentes)
      final transacoesCartao = await db.select(
        'transacoes',
        where: '''
          usuario_id = ?
          AND cartao_id IS NOT NULL
          AND DATE(fatura_vencimento) BETWEEN DATE(?) AND DATE(?)
        ''',
        whereArgs: [
          userId,
          inicioMes.toIso8601String().split('T')[0],
          fimMes.toIso8601String().split('T')[0],
        ],
      );

      debugPrint('💳 📋 Transações de cartão encontradas: ${transacoesCartao.length}');

      if (transacoesCartao.isEmpty) {
        return [];
      }

      // Agrupar por cartão
      final Map<String, List<Map<String, dynamic>>> transacoesPorCartao = {};
      for (final transacao in transacoesCartao) {
        final cartaoId = transacao['cartao_id'] as String;
        transacoesPorCartao[cartaoId] ??= [];
        transacoesPorCartao[cartaoId]!.add(transacao);
      }

      final List<TransacaoModel> agrupamentos = [];

      // Para cada cartão, criar um agrupamento
      for (final entry in transacoesPorCartao.entries) {
        final cartaoId = entry.key;
        final transacoesDoCartao = entry.value;

        // Buscar dados do cartão
        final cartaoResult = await db.select(
          'cartoes',
          where: 'id = ?',
          whereArgs: [cartaoId],
        );

        if (cartaoResult.isEmpty) continue;

        final cartaoData = cartaoResult.first;
        final nomeCartao = cartaoData['nome'] as String;

        // Calcular valores do agrupamento e detectar conta de pagamento
        double valorTotal = 0.0;
        int quantidadePagas = 0;
        int quantidadePendentes = 0;
        final Map<String, int> contasPagamento = {}; // Para rastrear qual conta foi mais usada

        for (final transacao in transacoesDoCartao) {
          final valor = (transacao['valor'] as num?)?.toDouble() ?? 0.0;
          final efetivado = (transacao['efetivado'] as num?)?.toInt() == 1;

          if (transacao['tipo'] == 'despesa') {
            valorTotal += valor;
            if (efetivado) {
              quantidadePagas++;
              // Rastrear conta usada no pagamento
              final contaIdPagamento = transacao['conta_id'] as String?;
              if (contaIdPagamento != null) {
                contasPagamento[contaIdPagamento] = (contasPagamento[contaIdPagamento] ?? 0) + 1;
              }
            } else {
              quantidadePendentes++;
            }
          }
        }

        // Determinar conta mais usada no pagamento
        String? contaIdPagamento;
        if (contasPagamento.isNotEmpty) {
          contaIdPagamento = contasPagamento.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

        if (valorTotal > 0.01) {
          // Determinar data mais apropriada: data de vencimento da fatura ou data de pagamento
          DateTime dataAgrupamento = fimMes; // Fallback

          // Buscar a data de vencimento mais comum ou mais recente das transações deste cartão
          DateTime? dataVencimentoFatura;
          DateTime? dataPagamento;

          for (final transacao in transacoesDoCartao) {
            final faturaVencimento = transacao['fatura_vencimento'] as String?;
            final efetivado = (transacao['efetivado'] as num?)?.toInt() == 1;

            if (faturaVencimento != null) {
              final vencimento = DateTime.tryParse(faturaVencimento);
              if (vencimento != null) {
                dataVencimentoFatura = vencimento;
              }
            }

            // Se efetivada, usar data_efetivacao ou data da transação
            if (efetivado) {
              final dataEfetivacao = transacao['data_efetivacao'] as String?;
              if (dataEfetivacao != null) {
                final efetivacao = DateTime.tryParse(dataEfetivacao);
                if (efetivacao != null) {
                  dataPagamento = efetivacao;
                }
              }
            }
          }

          // Prioridade: data de pagamento (se paga) > data de vencimento > fim do período
          if (quantidadePendentes == 0 && dataPagamento != null) {
            dataAgrupamento = dataPagamento;
          } else if (dataVencimentoFatura != null) {
            dataAgrupamento = dataVencimentoFatura;
          }

          // Criar transação agrupada representando o cartão
          final agora = DateTime.now();
          final agrupamento = TransacaoModel(
            id: 'agrupamento_cartao_${cartaoId}_${inicioMes.month}_${inicioMes.year}',
            usuarioId: userId,
            descricao: 'Fatura $nomeCartao - ${_formatarMesAno(inicioMes)}',
            valor: valorTotal,
            tipo: 'despesa',
            data: dataAgrupamento, // Data baseada em vencimento ou pagamento
            cartaoId: cartaoId,
            contaId: contaIdPagamento, // ✅ Conta usada no pagamento (se paga)
            categoriaId: 'categoria_cartao_agrupamento',
            efetivado: quantidadePendentes == 0, // Efetivado se não há pendentes
            observacoes: 'Agrupamento: ${quantidadePagas + quantidadePendentes} transações (${quantidadePagas} pagas, ${quantidadePendentes} pendentes)',
            createdAt: agora,
            updatedAt: agora,
          );

          agrupamentos.add(agrupamento);

          debugPrint(
            '💳 📊 Agrupamento criado: $nomeCartao - R\$${valorTotal.toStringAsFixed(2)} (${quantidadePagas + quantidadePendentes} transações)',
          );
        }
      }

      debugPrint('💳 ✅ Total de agrupamentos criados: ${agrupamentos.length}');
      return agrupamentos;

    } catch (e) {
      debugPrint('❌ Erro ao gerar agrupamentos de cartão reais: $e');
      return [];
    }
  }

  /// 📅 Formatar mês/ano para exibição
  String _formatarMesAno(DateTime data) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${meses[data.month - 1]}/${data.year}';
  }

  /// 💳 GERAR FATURAS SINTÉTICAS PARA CONSOLIDAR NAS ABAS PRINCIPAIS
  /// Cria transações virtuais representando as faturas como um todo
  Future<List<TransacaoModel>> _gerarFaturasSinteticas(
    DateTime inicioMes,
    DateTime fimMes,
  ) async {
    try {
      debugPrint(
        '💳 🔥 Gerando faturas sintéticas para o período: ${inicioMes.toIso8601String().split('T')[0]} - ${fimMes.toIso8601String().split('T')[0]}',
      );

      final db = LocalDatabase.instance;
      final userId = db.currentUserId;

      if (userId == null) {
        debugPrint('❌ Usuário não autenticado');
        return [];
      }

      List<TransacaoModel> faturasSinteticas = [];

      // 🎯 1. CONTROLAR DUPLICAÇÃO: faturas reais vs virtuais por chave (cartao+vencimento)
      final Set<String> chavesFaturasReais = {};

      // 🎯 2. TENTAR BUSCAR FATURAS NO PERÍODO (fallback por transações se falhar)
      List<Map<String, dynamic>> faturasResult = [];

      try {
        faturasResult = await db.select(
          'faturas',
          where: '''
            usuario_id = ?
            AND DATE(data_vencimento) BETWEEN DATE(?) AND DATE(?)
          ''',
          whereArgs: [
            userId,
            inicioMes.toIso8601String().split('T')[0],
            fimMes.toIso8601String().split('T')[0],
          ],
        );

        debugPrint(
          '💳 📊 Faturas encontradas no período: ${faturasResult.length}',
        );
      } catch (e) {
        debugPrint('⚠️  Erro ao buscar faturas ou tabela não existe: $e');
        debugPrint('🔄 Implementando fallback via transações...');
      }

      // 🎯 3. IMPLEMENTAR FALLBACK VIA TRANSAÇÕES (sempre executar para cobrir gaps)
      // Executa independente de faturasResult para cobrir cartões sem fatura na tabela
      Map<String, List<Map<String, dynamic>>> faturasPorCartaoFallback = {};

      try {
        final transacoesCartao = await db.select(
          'transacoes',
          where: '''
            usuario_id = ?
            AND cartao_id IS NOT NULL
            AND fatura_vencimento IS NOT NULL
            AND tipo = ?
            AND (transferencia IS NULL OR transferencia = 0 OR transferencia = ?)
            AND DATE(fatura_vencimento) BETWEEN DATE(?) AND DATE(?)
          ''',
          whereArgs: [
            userId,
            'despesa', // Só despesas de cartão
            0, // Excluir transferências
            inicioMes.toIso8601String().split('T')[0],
            fimMes.toIso8601String().split('T')[0],
          ],
        );

        debugPrint(
          '💳 🔄 Transações de cartão encontradas para fallback: ${transacoesCartao.length}',
        );

        // Agrupar por cartão + fatura_vencimento NORMALIZADA
        for (final transacaoData in transacoesCartao) {
          final cartaoId = transacaoData['cartao_id'] as String;
          final faturaVencimento = transacaoData['fatura_vencimento'] as String;

          // ✅ NORMALIZAR data de vencimento para compatibilidade com chaves reais
          final dataVencimentoNormalizada = DateTime.parse(
            faturaVencimento,
          ).toIso8601String().split('T')[0];
          final chaveAgrupamento = '${cartaoId}_$dataVencimentoNormalizada';

          if (!faturasPorCartaoFallback.containsKey(chaveAgrupamento)) {
            faturasPorCartaoFallback[chaveAgrupamento] = [];
          }
          faturasPorCartaoFallback[chaveAgrupamento]!.add(transacaoData);
        }

        debugPrint(
          '💳 🔄 Faturas virtuais identificadas: ${faturasPorCartaoFallback.length}',
        );
      } catch (fallbackError) {
        debugPrint('❌ Erro no fallback via transações: $fallbackError');
      }

      // 🎯 4. PROCESSAR FATURAS REAIS E REGISTRAR CHAVES PARA DEDUPLICAÇÃO
      for (final faturaData in faturasResult) {
        try {
          final fatura = FaturaModel.fromJson(faturaData);

          // ✅ Registrar chave real NORMALIZADA para evitar duplicação com virtual
          final dataVencimentoNormalizada = fatura.dataVencimento
              .toIso8601String()
              .split('T')[0];
          final chaveReal = '${fatura.cartaoId}_$dataVencimentoNormalizada';
          chavesFaturasReais.add(chaveReal);

          debugPrint('🔑 Chave fatura real registrada: $chaveReal');

          // Buscar dados do cartão
          final cartaoResult = await db.select(
            'cartoes',
            where: 'id = ?',
            whereArgs: [fatura.cartaoId],
          );

          if (cartaoResult.isEmpty) {
            debugPrint(
              '⚠️  Cartão ${fatura.cartaoId} não encontrado para fatura ${fatura.id}',
            );
            continue;
          }

          final nomeCartao = cartaoResult.first['nome'] as String;

          // ✅ USAR ID ESTÁVEL INCLUINDO fatura.id para evitar colisões múltiplas faturas mesmo vencimento
          final hashInput =
              '${fatura.cartaoId}|${fatura.dataVencimento.toIso8601String().substring(0, 7)}|${fatura.id}';
          final hashBytes = utf8.encode(hashInput);
          final digest = md5.convert(hashBytes);
          final hashEstavel = digest.toString().substring(0, 8);

          // 🎯 2. CRIAR TRANSAÇÃO SINTÉTICA BASEADA NA FATURA
          final transacaoSintetica = TransacaoModel(
            id: 'fatura_real_${fatura.cartaoId}_$hashEstavel',
            usuarioId: userId,
            descricao: 'Fatura $nomeCartao',
            valor: fatura.valorTotal, // Valor total da fatura
            tipo: 'despesa', // Faturas são sempre despesas
            data: fatura.paga
                ? (fatura.dataPagamento ?? fatura.dataVencimento)
                : fatura.dataVencimento,
            efetivado:
                fatura.paga, // Se a fatura foi paga, a transação é efetivada
            contaId: null, // Faturas não têm conta associada diretamente
            cartaoId:
                null, // NÃO COLOCAR cartaoId para não ser filtrada nas abas principais
            categoriaId:
                null, // ✅ Usar null em vez de criar categoria on-the-fly
            subcategoriaId: null,
            observacoes: fatura.paga
                ? 'Fatura paga em ${fatura.dataPagamento?.toIso8601String().split('T')[0] ?? fatura.dataVencimento.toIso8601String().split('T')[0]}'
                : 'Fatura a vencer',
            anexos: null,
            transferencia: false,
            createdAt: fatura.createdAt,
            updatedAt: fatura.updatedAt,
            sincronizado: fatura.sincronizado,
          );

          faturasSinteticas.add(transacaoSintetica);

          debugPrint(
            '💳 ✅ Fatura sintética real criada: $nomeCartao - R\$ ${fatura.valorTotal.toStringAsFixed(2)} - ${fatura.paga ? 'PAGA' : 'PENDENTE'}',
          );
        } catch (e) {
          debugPrint('❌ Erro ao processar fatura real: $e');
        }
      }

      // 🎯 5. PROCESSAR FATURAS VIRTUAIS (fallback) APENAS SE NÃO HÁ FATURA REAL
      for (final entry in faturasPorCartaoFallback.entries) {
        final chaveAgrupamento = entry.key;
        final transacoesDaFatura = entry.value;

        if (transacoesDaFatura.isEmpty) continue;

        // Normalizar chave para comparar com faturas reais (cartaoId + anoMes)
        final partesChave = chaveAgrupamento.split('_');
        final cartaoDaChave = partesChave.isNotEmpty ? partesChave.first : '';
        final dataVencBruta = partesChave.length > 1
            ? partesChave.sublist(1).join('_')
            : '';
        String chaveNormalizadaVirtual;
        try {
          final dataNorm = DateTime.parse(
            dataVencBruta,
          ).toIso8601String().substring(0, 7);
          chaveNormalizadaVirtual = '${cartaoDaChave}_$dataNorm';
        } catch (_) {
          chaveNormalizadaVirtual = chaveAgrupamento;
        }

        // ✅ VERIFICAR SE JÁ EXISTE FATURA REAL PARA ESTA CHAVE NORMALIZADA
        if (chavesFaturasReais.contains(chaveNormalizadaVirtual)) {
          debugPrint(
            '⚠️  Pulando fatura virtual $chaveAgrupamento - fatura real já existe',
          );
          continue;
        }

        debugPrint(
          '🔑 Processando fatura virtual com chave: $chaveAgrupamento',
        );

        final primeiraTransacao = transacoesDaFatura.first;
        final cartaoId = primeiraTransacao['cartao_id'] as String;
        final faturaVencimento =
            primeiraTransacao['fatura_vencimento'] as String;

        // ✅ MELHORAR LÓGICA: calcular valor e status mais preciso
        double valorTotal = 0.0;
        int transacoesPagas = 0;
        int totalTransacoes = 0;
        DateTime? dataEfetivacaoMaisRecente;

        // ✅ CALCULAR VALORES COM CONTROLES DE PARCELAS E RECORRÊNCIA
        double valorTotalPago = 0.0;
        double valorTotalPendente = 0.0;

        for (final transacao in transacoesDaFatura) {
          // ✅ VERIFICAR se é transação recorrente/previsível que deve ser filtrada
          final tipoRecorrencia = transacao['tipo_recorrencia'] as String?;
          if (tipoRecorrencia != null &&
              tipoRecorrencia.isNotEmpty &&
              tipoRecorrencia != 'nao_recorrente') {
            debugPrint('⚠️  Pulando transação recorrente: $tipoRecorrencia');
            continue;
          }

          // ✅ LÓGICA INTELIGENTE DE VALOR: parcela para parceladas, valor para avulsas
          final valorParcela = transacao['valor_parcela'] as num?;
          final valorNormal = transacao['valor'] as num?;
          final parcelaAtual = transacao['parcela_atual'] as num?;
          final totalParcelas = transacao['total_parcelas'] as num?;

          double valorFinal = 0.0;

          // Se tem parcela definida E é parcelada (parcela_atual/total_parcelas)
          if (valorParcela != null &&
              parcelaAtual != null &&
              totalParcelas != null &&
              totalParcelas > 1) {
            valorFinal = valorParcela.toDouble();
            debugPrint(
              '📦 Transação parcelada: parcela ${parcelaAtual}/${totalParcelas}, valor: R\$ ${valorFinal.toStringAsFixed(2)}',
            );
          }
          // Senão, usar valor normal
          else {
            valorFinal = valorNormal?.toDouble() ?? 0.0;
            debugPrint(
              '💰 Transação avulsa/integral: R\$ ${valorFinal.toStringAsFixed(2)}',
            );
          }

          valorTotal += valorFinal;
          totalTransacoes++;

          final efetivado = (transacao['efetivado'] as num?)?.toInt() == 1;
          if (efetivado) {
            transacoesPagas++;
            valorTotalPago += valorFinal;

            // ✅ CORRIGIR: usar data_efetivacao se disponível, senão data para pagamento real
            final dataEfetivacao = transacao['data_efetivacao'] as String?;
            final dataTransacao = transacao['data'] as String?;

            DateTime? dataRealPagamento;
            if (dataEfetivacao != null && dataEfetivacao.isNotEmpty) {
              dataRealPagamento = DateTime.tryParse(dataEfetivacao);
            } else if (dataTransacao != null && dataTransacao.isNotEmpty) {
              dataRealPagamento = DateTime.tryParse(dataTransacao);
            }

            if (dataRealPagamento != null) {
              if (dataEfetivacaoMaisRecente == null ||
                  dataRealPagamento.isAfter(dataEfetivacaoMaisRecente)) {
                dataEfetivacaoMaisRecente = dataRealPagamento;
              }
            }
          } else {
            valorTotalPendente += valorFinal;
          }
        }

        // ✅ Status mais inteligente: todas pagas = paga, alguma paga = parcial, nenhuma = pendente
        final bool todasPagas = transacoesPagas == totalTransacoes;
        final bool algumaPaga = transacoesPagas > 0;

        // Buscar nome do cartão
        final cartaoResult = await db.select(
          'cartoes',
          where: 'id = ?',
          whereArgs: [cartaoId],
        );

        final nomeCartao = cartaoResult.isNotEmpty
            ? cartaoResult.first['nome'] as String
            : 'Cartão';

        // ✅ HASH ESTÁVEL SEM VALOR: usar apenas cartaoId + ano/mês para estabilidade
        final dataVencimento = DateTime.parse(faturaVencimento);
        final anoMes =
            '${dataVencimento.year}-${dataVencimento.month.toString().padLeft(2, '0')}';
        final hashInput = '$cartaoId|$anoMes';
        final hashBytes = utf8.encode(hashInput);
        final digest = md5.convert(hashBytes);
        final hashEstavel = digest.toString().substring(0, 8);

        debugPrint('🔑 Hash estável gerado: $hashInput -> $hashEstavel');

        // ✅ Decidir data da fatura: se todas pagas, usar data efetivação; senão vencimento
        final dataFatura = todasPagas && dataEfetivacaoMaisRecente != null
            ? dataEfetivacaoMaisRecente!
            : DateTime.parse(faturaVencimento);

        final transacaoSintetica = TransacaoModel(
          id: 'fatura_virtual_${cartaoId}_$hashEstavel',
          usuarioId: userId,
          descricao: 'Fatura $nomeCartao (Virtual)',
          valor: valorTotal,
          tipo: 'despesa',
          data: dataFatura,
          efetivado:
              todasPagas, // ✅ Só marca como efetivado se TODAS estão pagas
          contaId: null,
          cartaoId: cartaoId, // ✅ PREENCHER cartaoId para simplificar filtros
          categoriaId: null, // ✅ Usar null em vez de criar categoria
          subcategoriaId: null,
          observacoes: todasPagas
              ? 'Fatura paga - R\$${valorTotalPago.toStringAsFixed(2)} ($transacoesPagas/$totalTransacoes transações)'
              : algumaPaga
              ? 'Fatura parcial - R\$${valorTotalPago.toStringAsFixed(2)} pago, R\$${valorTotalPendente.toStringAsFixed(2)} pendente ($transacoesPagas/$totalTransacoes pagas)'
              : 'Fatura pendente - R\$${valorTotalPendente.toStringAsFixed(2)} ($totalTransacoes transações)',
          anexos: null,
          transferencia: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sincronizado: false,
        );

        faturasSinteticas.add(transacaoSintetica);

        final statusDescricao = todasPagas
            ? 'PAGA'
            : algumaPaga
            ? 'PARCIAL ($transacoesPagas/$totalTransacoes)'
            : 'PENDENTE';

        debugPrint(
          '💳 🔄 Fatura virtual criada: $nomeCartao - R\$ ${valorTotal.toStringAsFixed(2)} - $statusDescricao',
        );
      }

      // ✅ REMOVER BLOCO DUPLICADO - já foi processado acima

      debugPrint(
        '💳 📈 Total de faturas sintéticas geradas: ${faturasSinteticas.length}',
      );
      return faturasSinteticas;
    } catch (e) {
      debugPrint('❌ Erro ao gerar faturas sintéticas: $e');
      return [];
    }
  }

  /// ✅ REMOVIDO: método de criação de categoria on-the-fly para evitar problemas

  /// Obter nome da conta/banco para exibir no modal
  Future<String> _obterNomeConta(String? contaId) async {
    if (contaId == null) return 'Conta não informada';

    try {
      final result = await LocalDatabase.instance.select(
        'contas',
        where: 'id = ?',
        whereArgs: [contaId],
      );

      if (result.isNotEmpty) {
        final banco = result.first['banco'] as String? ?? '';
        final nome = result.first['nome'] as String? ?? '';
        return '$banco - $nome'.trim().replaceAll(RegExp(r'^-\s*|-\s*$'), '');
      }

      return 'Conta não encontrada';
    } catch (e) {
      debugPrint('❌ Erro ao obter nome da conta: $e');
      return 'Erro ao carregar conta';
    }
  }

  /// Navegar para tela de transações do cartão
  void _mostrarTransacoesDoCartao(TransacaoModel transacao) {
    String? cartaoId;

    // Extrair cartaoId do agrupamento ou usar cartaoId direto
    if (transacao.id.startsWith('agrupamento_cartao_')) {
      // Formato: agrupamento_cartao_{cartaoId}_{month}_{year}
      final parts = transacao.id.split('_');
      if (parts.length >= 4) {
        cartaoId = parts[2]; // O cartaoId está na posição 2
      }
    } else {
      cartaoId = transacao.cartaoId;
    }

    if (cartaoId == null) return;

    debugPrint('🔍 Exibir transações do cartão: $cartaoId');

    // Navegar para aba CARTÕES (index 3) com filtro de cartão aplicado
    setState(() {
      _tabController.animateTo(3); // Ir para aba CARTÕES
      _filtrosPersonalizados['cartoes'] = [cartaoId]; // Aplicar filtro do cartão
    });
  }
}

// ===== BUSCAS SALVAS SERVICE =====

/// Serviço simples para gerenciar buscas salvas do usuário
class BuscasSalvasService {
  static const String _key = 'buscas_salvas_usuario';
  static const int _maxBuscas = 15;

  /// Busca todas as buscas salvas
  static Future<List<Map<String, dynamic>>> getBuscas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buscasJson = prefs.getString(_key);
    if (buscasJson == null) return [];

    try {
      final List<dynamic> lista = json.decode(buscasJson);
      return lista.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Salva uma nova busca ou incrementa contador se já existe
  static Future<void> salvarBusca(String termo) async {
    if (termo.trim().isEmpty) return;

    final buscas = await getBuscas();
    final termoLimpo = termo.trim().toLowerCase();

    // Verifica se já existe
    final index = buscas.indexWhere((b) => b['termo'] == termoLimpo);

    if (index >= 0) {
      // Já existe - incrementa contador e move para frente
      buscas[index]['count'] = (buscas[index]['count'] ?? 0) + 1;
      buscas[index]['lastUsed'] = DateTime.now().toIso8601String();
      final busca = buscas.removeAt(index);
      buscas.insert(0, busca);
    } else {
      // Nova busca - adiciona no início
      buscas.insert(0, {
        'termo': termoLimpo,
        'count': 1,
        'created': DateTime.now().toIso8601String(),
        'lastUsed': DateTime.now().toIso8601String(),
      });
    }

    // Limita o número de buscas
    while (buscas.length > _maxBuscas) {
      buscas.removeLast();
    }

    await _saveBuscas(buscas);
  }

  /// Incrementa contador de uso de uma busca
  static Future<void> incrementarUso(String termo) async {
    await salvarBusca(termo); // Reutiliza a lógica de salvamento
  }

  /// Remove uma busca específica
  static Future<void> removerBusca(String termo) async {
    final buscas = await getBuscas();
    final termoLimpo = termo.trim().toLowerCase();

    buscas.removeWhere((b) => b['termo'] == termoLimpo);
    await _saveBuscas(buscas);
  }

  /// Obtém buscas ordenadas por uso (mais usadas primeiro)
  static Future<List<String>> getBuscasOrdenadas() async {
    final buscas = await getBuscas();

    // Ordena por count (desc) e depois por lastUsed (desc)
    buscas.sort((a, b) {
      final countCompare = (b['count'] ?? 0).compareTo(a['count'] ?? 0);
      if (countCompare != 0) return countCompare;

      final aLastUsed = DateTime.tryParse(a['lastUsed'] ?? '') ?? DateTime(1970);
      final bLastUsed = DateTime.tryParse(b['lastUsed'] ?? '') ?? DateTime(1970);
      return bLastUsed.compareTo(aLastUsed);
    });

    return buscas.map<String>((b) => b['termo'] as String).toList();
  }

  /// Salva lista de buscas no SharedPreferences
  static Future<void> _saveBuscas(List<Map<String, dynamic>> buscas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(buscas));
  }
}

// ===== SEARCH OVERLAY COMPONENTS =====

/// Widget overlay para busca expansível e elegante
class SearchOverlay extends StatefulWidget {
  final String initialSearch;
  final Function(String) onSearchChanged;
  final VoidCallback onClose;

  const SearchOverlay({
    super.key,
    required this.initialSearch,
    required this.onSearchChanged,
    required this.onClose,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late FocusNode _focusNode;
  List<String> _buscasSalvas = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSearch);
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Carregar buscas salvas
    _carregarBuscasSalvas();

    // Iniciar animação e focar no campo
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _carregarBuscasSalvas() async {
    final buscas = await BuscasSalvasService.getBuscasOrdenadas();
    if (mounted) {
      setState(() {
        _buscasSalvas = buscas;
      });
    }
  }

  Future<void> _salvarBuscaAtual() async {
    final termo = _controller.text.trim();
    if (termo.isEmpty) return;

    await BuscasSalvasService.salvarBusca(termo);
    await _carregarBuscasSalvas(); // Recarrega para atualizar UI

    // Feedback visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Busca "$termo" salva!'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF008080),
        ),
      );
    }
  }

  Widget _buildDynamicSearchChipsArea() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_buscasSalvas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma busca salva ainda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use o botão + para salvar suas buscas favoritas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _buscasSalvas.map((termo) =>
                  _buildSavedSearchChip(termo)
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedSearchChip(String termo) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          _controller.text = termo;
          widget.onSearchChanged(termo);
          await BuscasSalvasService.incrementarUso(termo);
          _handleClose();
        },
        onLongPress: () => _mostrarMenuRemoverBusca(termo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF008080).withOpacity(0.3),
              width: 1,
            ),
            color: const Color(0xFF008080).withOpacity(0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 14,
                color: const Color(0xFF008080),
              ),
              const SizedBox(width: 6),
              Text(
                termo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF008080),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMenuRemoverBusca(String termo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Busca: "$termo"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remover busca salva'),
              onTap: () async {
                Navigator.pop(context);
                await BuscasSalvasService.removerBusca(termo);
                await _carregarBuscasSalvas();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            GestureDetector(
              onTap: _handleClose,
              child: Container(
                color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
              ),
            ),

            // Search container
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top - 8,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    elevation: 8,
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with close button
                          Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Buscar transações',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _handleClose,
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.grey[400],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Search field
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onChanged: widget.onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Digite para buscar por descrição, categoria, cartão...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Botão + para salvar busca
                                        IconButton(
                                          onPressed: _salvarBuscaAtual,
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFF008080),
                                            size: 20,
                                          ),
                                          tooltip: 'Salvar esta busca',
                                        ),
                                        // Botão clear
                                        IconButton(
                                          onPressed: () {
                                            _controller.clear();
                                            widget.onSearchChanged('');
                                          },
                                          icon: Icon(
                                            Icons.clear,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Helpful text
                          Text(
                            'Busque por descrição, categoria, subcategoria, cartão ou conta',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sugestões inteligentes (substitui visões rápidas)
                          Text(
                            'Busca rápida:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Área dinâmica para chips salvos pelo usuário
                          _buildDynamicSearchChipsArea(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Chip para mostrar termos de busca ativos
class SearchChip extends StatelessWidget {
  final String text;
  final VoidCallback? onRemove;

  const SearchChip({
    super.key,
    required this.text,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF008080).withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF008080).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search,
                  size: 14,
                  color: const Color(0xFF008080),
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.close,
                    size: 14,
                    color: const Color(0xFF008080).withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
