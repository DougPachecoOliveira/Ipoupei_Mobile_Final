// 💳 Transações Page - iPoupei Mobile
// 
// Página principal para listagem e gestão de transações
// Implementa padrões UX do iPoupei Device com offline-first
// Features: Tabs, Cards Adaptativos, Agrupamento, Timeline
// 
// Baseado em: Device UX Patterns + Material Design

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_colors.dart';
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
import '../../cartoes/widgets/cartao_card.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';
import 'transacao_form_page.dart';
import 'transferencia_form_page.dart';
import '../components/filtros_transacoes_modal.dart';
import '../components/timeline_transacoes.dart';
import '../../../services/grupos_metadados_service.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../components/transaction_detail_card.dart';
import '../../importacao/pages/importacao_modal.dart';
import '../../../shared/components/modals/transacao_opcoes_modal.dart';

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
  mesAtual(
    titulo: 'Mês Atual',
    icone: Icons.calendar_today,
  ),
  anoAtual(
    titulo: 'Ano Atual',
    icone: Icons.date_range,
  ),
  ultimos3Meses(
    titulo: 'Últimos 3 Meses',
    icone: Icons.calendar_month,
  ),
  ultimos6Meses(
    titulo: 'Últimos 6 Meses',
    icone: Icons.date_range,
  );

  const FiltroPeriodo({
    required this.titulo,
    required this.icone,
  });

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
    titulo: 'Transferências',
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

/// Enum para filtros inteligentes pré-definidos (DEPRECATED - será removido)
enum FiltroInteligente {
  // Por período
  mesAtual(
    titulo: 'Mês Atual',
    icone: Icons.calendar_today,
    categoria: 'Período',
  ),
  anoAtual(
    titulo: 'Ano Atual',
    icone: Icons.date_range,
    categoria: 'Período',
  ),
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
    titulo: 'Transferências',
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

  const TransacoesPage({
    super.key,
    this.modoInicial = TransacoesPageMode.todas,
    this.filtrosIniciais,
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
  VisaoRapida? _visaoAtiva;
  FiltroInteligente? _filtroAtivo; // DEPRECATED - manter por compatibilidade temporária
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
      debugPrint('🎯 TransacoesPage: Recebendo filtros iniciais: ${widget.filtrosIniciais}');
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
        debugPrint('🎯 Aplicando filtro de categoria: ${filtros['categoria_id']}');
      }

      // Aplicar outros filtros se necessário
      if (filtros.containsKey('categorias')) {
        _filtrosPersonalizados['categorias'] = List<String>.from(filtros['categorias']);
      }

      if (filtros.containsKey('contas')) {
        _filtrosPersonalizados['contas'] = List<String>.from(filtros['contas']);
      }

      if (filtros.containsKey('cartoes')) {
        _filtrosPersonalizados['cartoes'] = List<String>.from(filtros['cartoes']);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

      if ((_filtroAtivo != null || _periodoAtivo != null) && _parametrosFiltro.containsKey('inicio')) {
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
      final diffMeses = fimMes.difference(inicioMes).inDays ~/ 30;
      final limit = diffMeses > 2 ? 500 : 100; // 500 para períodos > 2 meses, 100 para o resto
      print('   limit: $limit (período de $diffMeses meses)');

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
      ]);

      final transacoes = futures[0] as List<TransacaoModel>;
      final contas = futures[1] as List<ContaModel>;
      final cartoes = futures[2] as List<CartaoModel>;
      final categorias = futures[3] as List<CategoriaModel>;

      print('🔍 DEBUG _carregarDados:');
      print('   Total de transações buscadas: ${transacoes.length}');
      if (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) {
        final cartaoFiltrado = _filtrosPersonalizados['cartoes'][0];
        final transacoesDoCartao = transacoes.where((t) => t.cartaoId == cartaoFiltrado).length;
        print('   Transações do cartão filtrado ($cartaoFiltrado): $transacoesDoCartao');
      }

      // Filtrar por modo específico
      List<TransacaoModel> transacoesFiltradas = transacoes;

      if (_modoAtual.apenasCartao) {
        // Filtrar apenas transações de cartão
        transacoesFiltradas = transacoes
            .where((t) => t.cartaoId != null)
            .toList();
        print('   Após filtro apenasCartao: ${transacoesFiltradas.length}');
      } else if (_modoAtual.filtroTipo != null) {
        // Filtrar por tipo específico (receita/despesa)
        transacoesFiltradas = transacoes
            .where((t) => t.tipo == _modoAtual.filtroTipo)
            .toList();
        print('   Após filtro de tipo: ${transacoesFiltradas.length}');
      }

      // Aplicar filtros personalizados
      transacoesFiltradas = _aplicarFiltrosPersonalizados(transacoesFiltradas);

      // Calcular estatísticas com base nas transações filtradas
      final estatisticas = _calcularEstatisticas(transacoesFiltradas);

      setState(() {
        _transacoes = transacoesFiltradas;
        _contas = contas.where((c) => c.ativo).toList();
        _cartoes = cartoes.where((c) => c.ativo).toList();
        _categorias = categorias.where((c) => c.ativo).toList();
        _estatisticas = estatisticas;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }
  
  /// 📊 CALCULAR ESTATÍSTICAS - Padrão Device
  /// Agora calcula com base nas transações filtradas
  Map<String, double> _calcularEstatisticas(List<TransacaoModel> transacoesFiltradas) {
    try {
      double totalReceitas = 0.0;
      double totalDespesas = 0.0;
      double totalCartoes = 0.0;
      int quantidadeReceitas = 0;
      int quantidadeDespesas = 0;
      int quantidadeCartoes = 0;
      double receitasPendentes = 0.0;
      double despesasPendentes = 0.0;

      for (final transacao in transacoesFiltradas) {
        switch (transacao.tipo) {
          case 'receita':
            totalReceitas += transacao.valor;
            quantidadeReceitas++;
            if (!transacao.efetivado) {
              receitasPendentes += transacao.valor;
            }
            break;
          case 'despesa':
            if (transacao.cartaoId != null) {
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

      return {
        'totalReceitas': totalReceitas,
        'totalDespesas': totalDespesas,
        'totalCartoes': totalCartoes,
        'saldo': totalReceitas - totalDespesas - totalCartoes,
        'quantidadeReceitas': quantidadeReceitas.toDouble(),
        'quantidadeDespesas': quantidadeDespesas.toDouble(),
        'quantidadeCartoes': quantidadeCartoes.toDouble(),
        'receitasPendentes': receitasPendentes,
        'despesasPendentes': despesasPendentes,
        'mediaReceitas': quantidadeReceitas > 0 ? totalReceitas / quantidadeReceitas : 0.0,
        'mediaDespesas': quantidadeDespesas > 0 ? totalDespesas / quantidadeDespesas : 0.0,
        'mediaCartoes': quantidadeCartoes > 0 ? totalCartoes / quantidadeCartoes : 0.0,
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

  /// Aplica filtro de período selecionado
  void _aplicarFiltroPeriodo(FiltroPeriodo periodo) {
    final agora = DateTime.now();

    setState(() {
      _periodoAtivo = periodo;
      _visaoAtiva = null; // Limpar visão ativa
      _filtroAtivo = null; // Limpar filtro antigo
      _parametrosFiltro = _gerarParametrosFiltroPeriodo(periodo);

      print('🔍 DEBUG _aplicarFiltroPeriodo:');
      print('   Período: ${periodo.titulo}');
      print('   Filtros de cartões antes: ${_filtrosPersonalizados['cartoes']}');

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
      } else {
        // Para períodos que precisam de filtro (últimos 3/6 meses), copiar para _filtrosPersonalizados
        _filtrosPersonalizados['dataInicio'] = _parametrosFiltro['inicio'];
        _filtrosPersonalizados['dataFim'] = _parametrosFiltro['fim'];
      }

      print('   Filtros de cartões depois: ${_filtrosPersonalizados['cartoes']}');
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
        return {
          'inicio': DateTime(agora.year, agora.month, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case FiltroPeriodo.anoAtual:
        return {
          'inicio': DateTime(agora.year, 1, 1),
          'fim': DateTime(agora.year, 12, 31),
        };

      case FiltroPeriodo.ultimos3Meses:
        return {
          'inicio': DateTime(agora.year, agora.month - 2, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };

      case FiltroPeriodo.ultimos6Meses:
        return {
          'inicio': DateTime(agora.year, agora.month - 5, 1),
          'fim': DateTime(agora.year, agora.month + 1, 0),
        };
    }
  }

  /// Gera parâmetros para visão rápida
  Map<String, dynamic> _gerarParametrosVisaoRapida(VisaoRapida visao) {
    final agora = DateTime.now();

    switch (visao) {
      case VisaoRapida.pendentes:
        return {
          'efetivado': false,
          'cartao': false,
        };

      case VisaoRapida.faturasPendentes:
        return {
          'cartao': true,
          'efetivado': false,
        };

      case VisaoRapida.efetivadas:
        return {
          'efetivado': true,
        };

      case VisaoRapida.vencidas:
        return {
          'vencidas': true,
          'efetivado': false,
        };

      case VisaoRapida.porCartao:
        return {
          'cartao': true,
        };

      case VisaoRapida.porConta:
        return {
          'cartao': false,
        };

      case VisaoRapida.transferencias:
        return {
          'tipo': 'transferencia',
        };

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
    return await showModalBottomSheet<VisaoRapida>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalVisoesRapidas(),
    );
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
        return {
          'efetivado': false,
          'cartao': false,
        };

      case FiltroInteligente.faturasPendentes:
        return {
          'cartao': true,
          'efetivado': false,
        };

      case FiltroInteligente.transacoesEfetivadas:
        return {
          'efetivado': true,
        };

      case FiltroInteligente.transacoesVencidas:
        return {
          'vencidas': true,
          'efetivado': false,
        };

      case FiltroInteligente.porCartao:
        return {
          'cartao': true,
        };

      case FiltroInteligente.porConta:
        return {
          'cartao': false,
        };

      case FiltroInteligente.transferencias:
        return {
          'tipo': 'transferencia',
        };

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Column(
                children: _buildFiltrosPeriodo(),
              ),
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
                onPressed: () => Navigator.pop(context, {'tipo': 'data_picker'}),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).primaryColor,
                ),
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

          // Lista de visões agrupadas por categoria
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: _buildVisoesAgrupadas(),
              ),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).primaryColor,
                ),
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
              child: Column(
                children: _buildFiltrosAgrupados(),
              ),
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
                onPressed: () => Navigator.pop(context, {'tipo': 'data_picker'}),
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
        color: isAtivo ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isAtivo ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null,
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
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isAtiva ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isAtiva ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null,
      ),
      child: ListTile(
        leading: Icon(
          visao.icone,
          color: isAtiva ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        title: Text(
          visao.titulo,
          style: TextStyle(
            fontWeight: isAtiva ? FontWeight.w600 : FontWeight.normal,
            color: isAtiva ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
        trailing: isAtiva
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
        onTap: () {
          Navigator.pop(context, visao);
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
        color: isAtivo ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isAtivo ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null,
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
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
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
        builder: (context) => TransacaoFormPage(
          modo: 'criar',
          tipo: tipo,
        ),
      ),
    );
    
    if (resultado == true) {
      _carregarDados();
    }
  }

  /// ↔️ NAVEGAR PARA TRANSFERÊNCIA
  void _navegarParaTransferencia() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TransferenciaFormPage(),
      ),
    );
    
    if (resultado == true) {
      _carregarDados();
    }
  }

  /// ✏️ NAVEGAR PARA EDITAR TRANSAÇÃO
  void _navegarParaEditarTransacao(TransacaoModel transacao) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransacaoFormPage(
          modo: 'editar',
          transacao: transacao,
        ),
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
            SnackBar(content: Text('Transação "${transacao.descricao}" excluída')),
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
            SnackBar(content: Text(resultado.mensagem ?? 'Transação efetivada')),
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
      final resultado = await TransacaoEditService.instance.desefetivar(transacao);
      
      if (resultado.sucesso) {
        _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado.mensagem ?? 'Transação marcada como pendente')),
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
            SnackBar(content: Text(resultado.mensagem ?? 'Transação duplicada')),
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
        border: Border.all(
          color: _modoAtual.corHeader.withAlpha(52),
        ),
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
      default:
        titulo = 'Resumo Geral';
        valorPrincipal = _estatisticas['saldo'] ?? 0.0;
    }
    
    return Row(
      children: [
        Icon(
          _modoAtual.icone,
          color: _modoAtual.corHeader,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
    }
  }
  
  Widget _buildMetricasGeral() {
    final receitas = _estatisticas['totalReceitas'] ?? 0.0;
    final despesas = _estatisticas['totalDespesas'] ?? 0.0;
    final cartoes = _estatisticas['totalCartoes'] ?? 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica('Receitas', receitas, Icons.trending_up, Colors.green[600]!),
        _buildMetrica('Despesas', despesas, Icons.trending_down, Colors.red[600]!),
        _buildMetrica('Cartões', cartoes, Icons.credit_card, Colors.purple[600]!),
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
        _buildMetrica('Transações', quantidade.toDouble(), Icons.receipt, _modoAtual.corHeader, isQuantidade: true),
        _buildMetrica('Pendente', pendente, Icons.schedule, Colors.orange[600]!),
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
        _buildMetrica('Transações', quantidade.toDouble(), Icons.receipt, _modoAtual.corHeader, isQuantidade: true),
        _buildMetrica('Pendente', pendente, Icons.schedule, Colors.orange[600]!),
        _buildMetrica('Média', media, Icons.trending_flat, Colors.grey[600]!),
      ],
    );
  }
  
  Widget _buildMetricasCartoes() {
    final quantidade = _estatisticas['quantidadeCartoes']?.toInt() ?? 0;
    final pendente = _estatisticas['despesasPendentes'] ?? 0.0;
    final media = _estatisticas['mediaCartoes'] ?? 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetrica('Transações', quantidade.toDouble(), Icons.receipt, _modoAtual.corHeader, isQuantidade: true),
        _buildMetrica('Pendente', pendente, Icons.schedule, Colors.orange[600]!),
        _buildMetrica('Média', media, Icons.trending_flat, Colors.grey[600]!),
      ],
    );
  }
  
  Widget _buildMetrica(String label, double valor, IconData icone, Color cor, {bool isQuantidade = false}) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
            const SizedBox(height: 2),

            // LINHA 3: Chips de informações
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: _buildChipsInformacoes(transacao),
                  ),
                ),
              ],
            ),
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
    
    return Icon(
      icone,
      size: 16,
      color: cor,
    );
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
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cor,
      ),
    );
  }

  // TEXTO DA CONTA - Padrão Device
  String _getTextoConta(TransacaoModel transacao, ContaModel? conta, CartaoModel? cartao) {
    if (transacao.tipo == 'transferencia') {
      // Para transferências, mostrar conta origem → destino
      final contaOrigem = conta?.nome ?? 'Conta';
      final contaDestino = 'Conta Destino'; // TODO: Buscar conta destino real
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
      chips.add(_buildChipParcelado(transacao.parcelaAtual ?? 1, transacao.totalParcelas ?? 1));
    }
    
    // 3. PREVISÍVEL - Roxo sólido
    if (transacao.tipoDespesa == 'previsivel' || transacao.tipoReceita == 'previsivel') {
      chips.add(_buildChipPrevisivel());
    }
    
    // 4. CATEGORIA - Cor da categoria
    if (transacao.categoriaId != null) {
      chips.add(_buildChipCategoria(transacao));
    }
    
    // 5. TAGS (máximo 2)
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280), // Cinza como padrão
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Categoria',
          style: TextStyle(
            fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: corCategoria,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        categoria.nome,
        style: const TextStyle(
          fontSize: 11,
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

  // CHIP TAG - Teal sólido
  Widget _buildChipTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
      if (_filtrosPersonalizados['valorMinimo'] != null && _filtrosPersonalizados['valorMinimo'] > 0) {
        chips.add(_buildChipValorMinimo(_filtrosPersonalizados['valorMinimo']));
      }

      // Valor máximo
      if (_filtrosPersonalizados['valorMaximo'] != null && _filtrosPersonalizados['valorMaximo'] > 0) {
        chips.add(_buildChipValorMaximo(_filtrosPersonalizados['valorMaximo']));
      }
    }

    // Se não há chips, não mostrar nada
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    // Adicionar botão "Limpar filtros" se há filtros ativos
    if (_periodoAtivo != null || _visaoAtiva != null || _filtroAtivo != null || _temFiltrosAtivos()) {
      chips.add(_buildChipLimparFiltros());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips,
      ),
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
          Icon(
            filtro.icone,
            size: 12,
            color: Colors.white,
          ),
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
          const Icon(
            Icons.calendar_today,
            size: 12,
            color: Colors.white,
          ),
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
          const Icon(
            Icons.credit_card,
            size: 12,
            color: Colors.white,
          ),
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

  /// Chip para status filtrado
  Widget _buildChipStatusFiltro(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status == 'efetivado' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
            const Icon(
              Icons.clear,
              size: 12,
              color: Colors.white,
            ),
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
          Icon(
            periodo.icone,
            size: 12,
            color: Colors.white,
          ),
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
          Icon(
            visao.icone,
            size: 12,
            color: Colors.white,
          ),
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

              const Text(
                'O que você deseja fazer?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinzaEscuro,
                ),
              ),

              const SizedBox(height: 16),

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
                  mensagemDesabilitado: 'Transações efetivadas não podem ser excluídas',
                ),
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
          border: Border.all(
            color: cor.withAlpha(52),
            width: 1,
          ),
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
                        colors: [
                          cor,
                          cor.withAlpha(208),
                        ],
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
                    child: Icon(
                      icone,
                      color: Colors.white,
                      size: 24,
                    ),
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
                          habilitado ? subtitulo : mensagemDesabilitado ?? subtitulo,
                          style: TextStyle(
                            fontSize: 14,
                            color: habilitado ? AppColors.cinzaTexto : AppColors.cinzaMedio,
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
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
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
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: TransacoesPageMode.values.map((modo) => Tab(text: modo.titulo.toUpperCase())).toList(),
    );
  }
  
  /// 💳 TOGGLE CARTÕES - "Por Fatura" vs "Detalhado"
  Widget _buildToggleCartoes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
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
            Icon(
              _modoAtual.icone,
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
              'Adicione transações para vê-las aqui',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
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
    print('🎯 DEBUG: _buildListaCompacta chamada - ${_transacoes.length} transações');
    
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
            Icon(
              _modoAtual.icone,
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
              'Adicione transações para visualizar',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
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
        final isUltimoDia = dataFormatada.day == DateTime(dataFormatada.year, dataFormatada.month + 1, 0).day;

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
        final mostrarSaldoNesteDia = mostrarSaldo && (isPrimeiroDia || isUltimoDia);

        return _buildGrupoDia(
          dataFormatada,
          transacoesDia,
          mostrarSaldoNesteDia ? saldoAcumulado : null,
          isPrimeiroDia ? 'Saldo inicial do mês' : (isUltimoDia ? 'Saldo final do mês' : null),
        );
      }).toList(),
    );
  }
  
  /// 📋 TRANSAÇÕES SEM AGRUPAMENTO
  Widget _buildTransacoesSemAgrupamento() {
    return Column(
      children: _transacoes.map((transacao) => _buildTransacaoItem(transacao)).toList(),
    );
  }
  
  /// 📅 GRUPO DE TRANSAÇÕES DE UM DIA - Padrão Device
  Widget _buildGrupoDia(DateTime data, List<TransacaoModel> transacoes, [double? saldoNoPonto, String? labelSaldo]) {
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
        if (transacoes.length > 1 || (saldoNoPonto != null && labelSaldo != null))
          _buildHeaderDia(data, totalDia, saldoNoPonto, labelSaldo, transacoes.length),
        // Lista de transações do dia
        ...transacoes.map((transacao) => _buildTransacaoItem(transacao)),
      ],
    );
  }

  /// 📅 HEADER DO DIA - Padrão Device
  Widget _buildHeaderDia(DateTime data, double totalDia, [double? saldoNoPonto, String? labelSaldo, int quantidadeTransacoes = 0]) {
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
    
    if (data.year == hoje.year && data.month == hoje.month && data.day == hoje.day) {
      return 'Hoje';
    } else if (data.year == ontem.year && data.month == ontem.month && data.day == ontem.day) {
      return 'Ontem';
    } else {
      // Formato Device: "29 de setembro" ou "29 de set" se mesmo ano
      final meses = [
        '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      
      final mesesAbrev = [
        '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
        'jul', 'ago', 'set', 'out', 'nov', 'dez'
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
    final faturas = _criarFaturasAgrupadas();
    
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
            Icon(
              Icons.credit_card_off,
              size: 64,
              color: Colors.grey[400],
            ),
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
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: faturas.map((fatura) => _buildFaturaCard(fatura)).toList(),
    );
  }
  
  /// 📊 CRIAR FATURAS AGRUPADAS
  List<Map<String, dynamic>> _criarFaturasAgrupadas() {
    final Map<String, Map<String, dynamic>> faturas = {};
    
    // Filtrar apenas transações de cartão
    final transacoesCartao = _transacoes
        .where((t) => t.cartaoId != null)
        .toList();
    
    for (final transacao in transacoesCartao) {
      final cartaoId = transacao.cartaoId!;
      final data = transacao.data;
      final mesAno = '${data.year}-${data.month.toString().padLeft(2, '0')}';
      final chave = '${cartaoId}_$mesAno';
      
      if (!faturas.containsKey(chave)) {
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
        
        final dataVencimento = DateTime(data.year, data.month + 1, cartao.diaVencimento);
        
        faturas[chave] = {
          'id': chave,
          'cartaoId': cartaoId,
          'cartao': cartao,
          'mesAno': mesAno,
          'dataVencimento': dataVencimento,
          'valor': 0.0,
          'transacoes': <TransacaoModel>[],
          'paga': false,
        };
      }
      
      faturas[chave]!['valor'] += transacao.valor;
      (faturas[chave]!['transacoes'] as List<TransacaoModel>).add(transacao);
      
      // Verificar se está paga (todas transações efetivadas)
      final todasEfetivadas = (faturas[chave]!['transacoes'] as List<TransacaoModel>)
          .every((t) => t.efetivado);
      faturas[chave]!['paga'] = todasEfetivadas;
    }
    
    final listaFaturas = faturas.values.toList();
    
    // Ordenar por data de vencimento
    listaFaturas.sort((a, b) => 
        (a['dataVencimento'] as DateTime).compareTo(b['dataVencimento'] as DateTime));
    
    return listaFaturas;
  }
  
  /// 💳 CARD DE FATURA - Usando CartaoCard (unificado com CartoesConsolidadoPage)
  Widget _buildFaturaCard(Map<String, dynamic> fatura) {
    final cartao = fatura['cartao'] as CartaoModel;
    final valor = fatura['valor'] as double;
    final dataVencimento = fatura['dataVencimento'] as DateTime;
    final transacoes = fatura['transacoes'] as List<TransacaoModel>;
    final paga = fatura['paga'] as bool;
    final agora = DateTime.now();

    // Criar FaturaModel a partir dos dados
    final faturaModel = FaturaModel(
      id: '${cartao.id}_${DateFormat('yyyyMM').format(dataVencimento)}',
      cartaoId: cartao.id,
      usuarioId: cartao.usuarioId,
      ano: dataVencimento.year,
      mes: dataVencimento.month,
      dataFechamento: DateTime(dataVencimento.year, dataVencimento.month, 1),
      dataVencimento: dataVencimento,
      valorTotal: valor,
      valorPago: paga ? valor : 0.0,
      valorMinimo: valor * 0.15, // 15% do valor como mínimo padrão
      status: paga ? 'paga' : (dataVencimento.isBefore(agora) ? 'vencida' : 'aberta'),
      paga: paga,
      dataPagamento: paga ? agora : null,
      createdAt: agora,
      updatedAt: agora,
      sincronizado: true,
    );

    return CartaoCard(
      cartao: cartao,
      valorUtilizado: valor,
      faturaAtual: faturaModel,
      showUtilizacao: true,
      showFaturaInfo: true,
      isCompact: false,
      onTap: () => _mostrarDetalhesFatura(fatura),
    );
  }
  
  /// 🔍 MOSTRAR DETALHES DA FATURA
  void _mostrarDetalhesFatura(Map<String, dynamic> fatura) {
    final cartao = fatura['cartao'] as CartaoModel;
    final transacoes = fatura['transacoes'] as List<TransacaoModel>;
    final valor = fatura['valor'] as double;
    
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
  
  Widget _buildOpcaoMenu(String titulo, IconData icone, Color cor, VoidCallback onTap) {
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
        title: Text(
          _modoAtual.titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Toggle Visualização (Lista → Compacta → Timeline) - Ícone compacto
          if (_modoAtual != TransacoesPageMode.cartoes || !_porFatura)
            IconButton(
              icon: Icon(
                _modoVisualizacao == 0 ? Icons.view_compact : 
                _modoVisualizacao == 1 ? Icons.timeline : Icons.list,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _modoVisualizacao = (_modoVisualizacao + 1) % 3;
                  print('🎯 DEBUG: Modo visualização alterado para: $_modoVisualizacao');
                });
              },
              tooltip: _modoVisualizacao == 0 ? 'Lista Compacta' : 
                      _modoVisualizacao == 1 ? 'Timeline' : 'Lista Normal',
            ),

          // Botão de Importação
          IconButton(
            onPressed: _mostrarImportacao,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: 'Importar Transações',
          ),
          // Botão de Visões Rápidas
          IconButton(
            onPressed: () async {
              final visao = await _mostrarModalVisoesRapidas();
              if (visao != null) {
                _aplicarVisaoRapida(visao);
              }
            },
            icon: Icon(
              Icons.visibility,
              color: _visaoAtiva != null ? Colors.yellow[300] : Colors.white,
            ),
            tooltip: 'Visões Rápidas',
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
      body: Column(
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
      floatingActionButton: _buildFAB(),
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
                (transacoesPuladas > 0 ? '\n$transacoesPuladas foram puladas.' : ''),
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
           (_filtrosPersonalizados['contas']?.isNotEmpty ?? false) ||
           (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) ||
           (_filtrosPersonalizados['status']?.isNotEmpty ?? false) ||
           (_filtrosPersonalizados['valorMinimo'] ?? 0.0) > 0 ||
           (_filtrosPersonalizados['valorMaximo'] ?? 999999.0) < 999999;
           // Removido dataInicio/dataFim pois são aplicados na busca do banco, não aqui
  }

  List<TransacaoModel> _aplicarFiltrosPersonalizados(List<TransacaoModel> transacoes) {
    if (!_temFiltrosAtivos() && _filtroAtivo == null) return transacoes;

    return transacoes.where((transacao) {
      // Aplicar filtros inteligentes primeiro
      if (_filtroAtivo != null && _parametrosFiltro.isNotEmpty) {
        // Filtro por efetivado
        if (_parametrosFiltro.containsKey('efetivado')) {
          final efetivadoRequerido = _parametrosFiltro['efetivado'] as bool;
          if (transacao.efetivado != efetivadoRequerido) {
            return false;
          }
        }

        // Filtro por cartão
        if (_parametrosFiltro.containsKey('cartao')) {
          final cartaoRequerido = _parametrosFiltro['cartao'] as bool;
          final temCartao = transacao.cartaoId != null;
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
          final isVencida = !transacao.efetivado && transacao.data.isBefore(agora);
          if (!isVencida) {
            return false;
          }
        }
      }
      // Filtro por categoria
      if (_filtrosPersonalizados['categorias']?.isNotEmpty ?? false) {
        if (!_filtrosPersonalizados['categorias'].contains(transacao.categoriaId)) {
          return false;
        }
      }

      // Filtro por conta
      if (_filtrosPersonalizados['contas']?.isNotEmpty ?? false) {
        if (!_filtrosPersonalizados['contas'].contains(transacao.contaId)) {
          return false;
        }
      }

      // Filtro por cartão
      if (_filtrosPersonalizados['cartoes']?.isNotEmpty ?? false) {
        if (transacao.cartaoId == null ||
            !_filtrosPersonalizados['cartoes'].contains(transacao.cartaoId)) {
          print('🔍 DEBUG: Transação ${transacao.id} eliminada por filtro de cartão');
          print('   CartaoId da transação: ${transacao.cartaoId}');
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

      return true;
    }).toList();
  }

  /// 🎨 MODAL DE CONFIRMAÇÃO DE EXCLUSÃO COM IDENTIDADE VISUAL
  Future<bool?> _mostrarModalConfirmacaoExclusao(TransacaoModel transacao) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 
                    MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExclusaoHeader(),
              _buildExclusaoBody(transacao),
            ],
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
          const Icon(
            Icons.delete_forever,
            color: AppColors.branco,
            size: 24,
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
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
        border: Border.all(
          color: AppColors.vermelhoTransparente20,
          width: 1,
        ),
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
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(transacao.valor),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.vermelhoErro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoria.nome,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy').format(transacao.data),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.cinzaLegenda,
            ),
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
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _fabExpanded = false),
              child: Container(
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
      _carregarDados();
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
      _carregarDados();
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
      _carregarDados();
    }
  }

  void _navegarParaNovaDespesaCartao() async {
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
      _carregarDados();
    }
  }
}