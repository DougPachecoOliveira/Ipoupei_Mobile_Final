// 📊 Planejamento Page - iPoupei Mobile
//
// Página principal para gestão de planejamento de orçamento
// 100% baseada na estrutura de CategoriasPage
//
// Baseado em: Material Design + Budget Management + Offline-First

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/planejamento_model.dart';
import '../services/planejamento_service.dart';
import '../../../shared/utils/format_currency.dart';
import '../../shared/theme/app_colors.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';
import '../../categorias/data/categoria_icons.dart';
import '../../transacoes/services/transacao_service.dart';

// ===============================================
// 💰 FORMATADOR DE MOEDA
// ===============================================

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

// ===============================================
// 🔧 COMPONENTES UI - COPIADOS DE CATEGORIAS
// ===============================================
class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({
    super.key,
    this.message = 'Carregando...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}

class PlanejamentoPage extends StatefulWidget {
  const PlanejamentoPage({super.key});

  @override
  State<PlanejamentoPage> createState() => _PlanejamentoPageState();
}

// ===============================================
// 📊 PÁGINA PRINCIPAL - ESTRUTURA IDÊNTICA AO CATEGORIAS
// ===============================================

class _PlanejamentoPageState extends State<PlanejamentoPage> with TickerProviderStateMixin {
  // VERSÃO ATUALIZADA COM SUBCATEGORIAS FAKE - V2
  final PlanejamentoService _planejamentoService = PlanejamentoService.instance;
  final CategoriaService _categoriaService = CategoriaService.instance;
  final TransacaoService _transacaoService = TransacaoService.instance;
  final _supabase = Supabase.instance.client;

  late TabController _tabController;
  final _searchController = TextEditingController();

  // Estados principais - copiado de categorias
  late StreamSubscription<List<PlanejamentoModel>> _planejamentosSubscription;
  List<PlanejamentoModel> _receitas = [];
  List<PlanejamentoModel> _despesas = [];
  List<CategoriaModel> _todasCategorias = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';

  // Estados para dados financeiros
  double _totalReceitasPlanejado = 0.0;
  double _totalDespesasPlanejado = 0.0;
  double _totalReceitasRealizado = 0.0;
  double _totalDespesasRealizado = 0.0;
  double _saldoPlanejado = 0.0;
  double _saldoRealizado = 0.0;
  bool _carregandoValores = false;

  // Toggle para tipo de valor (efetivado ou efetivado + pendente)
  bool _incluirPendentes = false;
  bool _mostrarPesquisa = false;
  final Set<String> _categoriasExpandidas = {};

  // Estados visuais - baseados no CategoriasPage
  DateTime _dataAtual = DateTime.now();
  String _periodoAtual = '';
  bool _modoAnual = false; // false = mensal, true = anual
  Color _headerColor = AppColors.vermelhoHeader;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _atualizarPeriodoTexto();
    _carregarDados();

    // ✅ ESCUTAR STREAM DE PLANEJAMENTOS
    _planejamentosSubscription = _planejamentoService.planejamentosStream.listen((planejamentos) {
      if (mounted) {
        _processarPlanejamentos(planejamentos).then((_) {
          _calcularTotais();
        });
      }
    });

    // Listener para mudança de cores e card principal baseado na tab
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _headerColor = _getHeaderColor();
          // Card principal será atualizado automaticamente via _buildResumoFinanceiro()
        });
      }
    });

    _headerColor = _getHeaderColor();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _planejamentosSubscription.cancel(); // ✅ CANCELAR SUBSCRIPTION
    super.dispose();
  }

  // ===============================================
  // 🎨 MÉTODOS DE UI - BASEADOS NO PROJETO ANTIGO
  // ===============================================

  Color _getHeaderColor() {
    switch (_tabController.index) {
      case 0: // Despesas
        return AppColors.vermelhoHeader;
      case 1: // Receitas
        return AppColors.tealPrimary;
      default:
        return AppColors.vermelhoHeader;
    }
  }

  Color _getBackgroundColor() {
    switch (_tabController.index) {
      case 0: // Despesas
        return AppColors.vermelhoHeader.withValues(alpha: 0.1);
      case 1: // Receitas
        return AppColors.tealPrimary.withValues(alpha: 0.1);
      default:
        return AppColors.vermelhoHeader.withValues(alpha: 0.1);
    }
  }


  // ===========================
  // MÉTODOS DE CARREGAMENTO
  // ===========================

  void _atualizarPeriodoTexto() {
    if (_modoAnual) {
      _periodoAtual = '${_dataAtual.year}';
    } else {
      _periodoAtual = _formatarPeriodo(_dataAtual);
    }
  }

  String _formatarPeriodo(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];

    return '${meses[data.month - 1]}/${data.year.toString().substring(2)}';
  }

  String _formatarPeriodoCompleto(DateTime data) {
    final meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    return meses[data.month - 1];
  }

  void _alternarModo() {
    setState(() {
      _modoAnual = !_modoAnual;
      _atualizarPeriodoTexto();
    });
    // Recarregar dados com novo período
    _carregarDados();
  }

  /// 🏠 IR PARA O MÊS/ANO ATUAL
  void _irParaHoje() {
    setState(() {
      _dataAtual = DateTime.now();
      _periodoAtual = _formatarPeriodo(_dataAtual);
    });
    _carregarDados();
  }

  void _periodoAnterior() {
    setState(() {
      if (_modoAnual) {
        _dataAtual = DateTime(_dataAtual.year - 1, _dataAtual.month);
      } else {
        _dataAtual = DateTime(_dataAtual.year, _dataAtual.month - 1);
      }
      _atualizarPeriodoTexto();
    });
    _carregarDados();
  }

  void _proximoPeriodo() {
    setState(() {
      if (_modoAnual) {
        _dataAtual = DateTime(_dataAtual.year + 1, _dataAtual.month);
      } else {
        _dataAtual = DateTime(_dataAtual.year, _dataAtual.month + 1);
      }
      _atualizarPeriodoTexto();
    });
    _carregarDados();
  }

  // Método para nova meta/planejamento
  void _novoPlanejamento() {
    // TODO: Implementar modal ou navegação para criar novo planejamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  Future<void> _carregarDados() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Definir período no service baseado no modo
      _planejamentoService.definirPeriodo(_dataAtual);

      // Carregar planejamentos e categorias
      await _planejamentoService.carregarPlanejamentos(modoAnual: _modoAnual);

      // Buscar todas as categorias (receitas e despesas)
      final receitas = await _categoriaService.fetchCategorias(tipo: 'receita');
      final despesas = await _categoriaService.fetchCategorias(tipo: 'despesa');

      _todasCategorias = [
        ...receitas,
        ...despesas,
      ];

      await _processarPlanejamentos();
      await _calcularTotais();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      debugPrint('Erro ao carregar planejamentos: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _processarPlanejamentos([List<PlanejamentoModel>? planejamentosParam]) async {
    final planejamentos = planejamentosParam ?? _planejamentoService.planejamentos;
    final Map<String, PlanejamentoModel> planejamentosMap = {};

    debugPrint('📋 PLANEJAMENTOS DO SUPABASE:');
    debugPrint('  Total planejamentos carregados: ${planejamentos.length}');

    for (final p in planejamentos) {
      debugPrint('    - ${p.categoriaNome ?? p.categoriaId}: R\$ ${p.valorPlanejado} (${p.tipo}, ano: ${p.ano}, mês: ${p.mes})');
    }

    // Criar mapa dos planejamentos existentes
    if (_modoAnual) {
      // No modo anual, agrupa planejamentos da mesma categoria somando os valores
      final Map<String, List<PlanejamentoModel>> planejamentosPorCategoria = {};
      for (final planejamento in planejamentos) {
        final categoriaId = planejamento.categoriaId ?? '';
        planejamentosPorCategoria.putIfAbsent(categoriaId, () => []);
        planejamentosPorCategoria[categoriaId]!.add(planejamento);
      }

      // Consolidar planejamentos por categoria
      for (final entry in planejamentosPorCategoria.entries) {
        final categoriaId = entry.key;
        final planejamentosCategoria = entry.value;

        if (planejamentosCategoria.isNotEmpty) {
          final primeiro = planejamentosCategoria.first;
          final valorTotal = planejamentosCategoria.fold(0.0, (sum, p) => sum + p.valorPlanejado);

          planejamentosMap[categoriaId] = primeiro.copyWith(
            valorPlanejado: valorTotal,
          );
        }
      }
    } else {
      // No modo mensal, TAMBÉM agrupar subcategorias da mesma categoria
      final Map<String, List<PlanejamentoModel>> planejamentosPorCategoria = {};
      for (final planejamento in planejamentos) {
        final categoriaId = planejamento.categoriaId ?? '';
        planejamentosPorCategoria.putIfAbsent(categoriaId, () => []);
        planejamentosPorCategoria[categoriaId]!.add(planejamento);
      }

      // Consolidar planejamentos por categoria (somar todas as subcategorias)
      for (final entry in planejamentosPorCategoria.entries) {
        final categoriaId = entry.key;
        final planejamentosCategoria = entry.value;

        if (planejamentosCategoria.isNotEmpty) {
          final primeiro = planejamentosCategoria.first;
          final valorTotal = planejamentosCategoria.fold(0.0, (sum, p) => sum + p.valorPlanejado);

          planejamentosMap[categoriaId] = primeiro.copyWith(
            valorPlanejado: valorTotal,
            subcategoriaId: null, // Sempre categoria principal no card
            subcategoriaNome: null,
          );
        }
      }
    }

    // Listas para receitas e despesas
    final List<PlanejamentoModel> todasReceitas = [];
    final List<PlanejamentoModel> todasDespesas = [];

    // Processar TODAS as categorias (igual ao CategoriasPage)
    for (final categoria in _todasCategorias) {
      final planejamentoExistente = planejamentosMap[categoria.id];

      if (planejamentoExistente != null) {
        // Já tem planejamento - usar dados existentes
        if (categoria.tipo == 'receita') {
          todasReceitas.add(planejamentoExistente);
        } else {
          todasDespesas.add(planejamentoExistente);
        }
      } else {
        // Não tem planejamento - criar placeholder com R$ 0,00
        final planejamentoZerado = _criarPlanejamentoZerado(categoria);
        if (categoria.tipo == 'receita') {
          todasReceitas.add(planejamentoZerado);
        } else {
          todasDespesas.add(planejamentoZerado);
        }
      }
    }

    setState(() {
      _receitas = todasReceitas;
      _despesas = todasDespesas;
    });

    // Ordenar por nome da categoria
    _receitas.sort((a, b) => (a.categoriaNome ?? '').compareTo(b.categoriaNome ?? ''));
    _despesas.sort((a, b) => (a.categoriaNome ?? '').compareTo(b.categoriaNome ?? ''));
  }

  PlanejamentoModel _criarPlanejamentoZerado(CategoriaModel categoria) {
    return PlanejamentoModel(
      id: 'temp_${categoria.id}',
      usuarioId: categoria.usuarioId,
      categoriaId: categoria.id,
      categoriaNome: categoria.nome,
      categoriaIcone: categoria.icone,
      categoriaCor: categoria.cor,
      valorPlanejado: 0.0,
      ano: _dataAtual.year,
      mes: _dataAtual.month,
      tipo: categoria.tipo,
    );
  }

  Future<void> _calcularTotais() async {
    if (_carregandoValores) return;

    setState(() {
      _carregandoValores = true;
    });

    try {
      // 🚀 MÉTODO SUPER SIMPLES: somar direto todos os planejamentos
      final todosPlanejamentos = _planejamentoService.planejamentos
          .where((p) => p.temPlanejamentoReal)
          .toList();

      _totalReceitasPlanejado = 0.0;
      _totalDespesasPlanejado = 0.0;
      _totalReceitasRealizado = 0.0;
      _totalDespesasRealizado = 0.0;

      for (final p in todosPlanejamentos) {
        // 🚀 RESPEITAR FILTRO: se incluir pendentes, usa totalMes; senão, só valorRealizado
        final valorConsiderado = _incluirPendentes ? p.totalMes : p.valorRealizado;

        if (p.isReceita) {
          _totalReceitasPlanejado += p.valorPlanejado;
          _totalReceitasRealizado += valorConsiderado;
        } else {
          _totalDespesasPlanejado += p.valorPlanejado;
          _totalDespesasRealizado += valorConsiderado;
        }
      }

      _saldoPlanejado = _totalReceitasPlanejado - _totalDespesasPlanejado;
      _saldoRealizado = _totalReceitasRealizado - _totalDespesasRealizado;

      debugPrint('  Receitas planejadas: R\$ ${_totalReceitasPlanejado.toStringAsFixed(2)}');
      debugPrint('  Despesas planejadas: R\$ ${_totalDespesasPlanejado.toStringAsFixed(2)}');
      debugPrint('  Saldo planejado: R\$ ${_saldoPlanejado.toStringAsFixed(2)}');
      debugPrint('  Receitas realizadas: R\$ ${_totalReceitasRealizado.toStringAsFixed(2)}');
      debugPrint('  Despesas realizadas: R\$ ${_totalDespesasRealizado.toStringAsFixed(2)}');
      debugPrint('  Saldo realizado: R\$ ${_saldoRealizado.toStringAsFixed(2)}');

      // 📈 ATUALIZAR VALORES INDIVIDUAIS DOS PLANEJAMENTOS
      await _atualizarValoresPlanejamentos();

    } finally {
      setState(() {
        _carregandoValores = false;
      });
    }
  }

  /// 📊 CALCULAR VALORES REALIZADOS DAS TRANSAÇÕES
  Future<void> _calcularValoresRealizados() async {
    // Período baseado no modo (mensal ou anual)
    final DateTime inicioPeriodo;
    final DateTime fimPeriodo;

    if (_modoAnual) {
      // Período do ano inteiro
      inicioPeriodo = DateTime(_dataAtual.year, 1, 1);
      fimPeriodo = DateTime(_dataAtual.year + 1, 1, 0);
    } else {
      // Período do mês atual
      inicioPeriodo = DateTime(_dataAtual.year, _dataAtual.month, 1);
      fimPeriodo = DateTime(_dataAtual.year, _dataAtual.month + 1, 0);
    }

    try {
      // 📊 Buscar TODAS as transações do período (sem limite)
      final todasTransacoes = await _transacaoService.fetchTransacoes(
        dataInicio: inicioPeriodo,
        dataFim: fimPeriodo,
        limit: 10000, // ← Aumentar limite para pegar todas as transações
      );


      // 🔄 FILTRAR POR TOGGLE, TIPO E CATEGORIA VÁLIDA
      final receitasFiltradas = todasTransacoes.where((t) {
        final isReceita = t.tipo == 'receita';
        final temCategoria = t.categoriaId != null;
        final incluir = _incluirPendentes ? true : t.efetivado;
        return isReceita && temCategoria && incluir;
      }).toList();

      final despesasFiltradas = todasTransacoes.where((t) {
        final isDespesa = t.tipo == 'despesa';
        final temCategoria = t.categoriaId != null;
        final incluir = _incluirPendentes ? true : t.efetivado;
        return isDespesa && temCategoria && incluir;
      }).toList();

      // 💱 SOMAR VALORES (igual CategoriaPage - sem .abs())
      _totalReceitasRealizado = receitasFiltradas
          .fold(0.0, (sum, t) => sum + t.valor);

      _totalDespesasRealizado = despesasFiltradas
          .fold(0.0, (sum, t) => sum + t.valor);

      _saldoRealizado = _totalReceitasRealizado - _totalDespesasRealizado;

    } catch (e) {
      debugPrint('❌ Erro ao calcular valores realizados: $e');
      // Manter valores zerados em caso de erro
      _totalReceitasRealizado = 0.0;
      _totalDespesasRealizado = 0.0;
      _saldoRealizado = 0.0;
    }
  }

  /// 📈 ATUALIZAR VALORES INDIVIDUAIS DOS PLANEJAMENTOS
  Future<void> _atualizarValoresPlanejamentos() async {
    // Período baseado no modo (mensal ou anual)
    final DateTime inicioPeriodo;
    final DateTime fimPeriodo;

    if (_modoAnual) {
      // Período do ano inteiro
      inicioPeriodo = DateTime(_dataAtual.year, 1, 1);
      fimPeriodo = DateTime(_dataAtual.year + 1, 1, 0);
    } else {
      // Período do mês atual
      inicioPeriodo = DateTime(_dataAtual.year, _dataAtual.month, 1);
      fimPeriodo = DateTime(_dataAtual.year, _dataAtual.month + 1, 0);
    }

    try {
      // 📊 Buscar TODAS as transações do período uma só vez (sem limite)
      final todasTransacoes = await _transacaoService.fetchTransacoes(
        dataInicio: inicioPeriodo,
        dataFim: fimPeriodo,
        limit: 10000, // ← Aumentar limite para pegar todas as transações
      );

      // Atualizar receitas
      for (int i = 0; i < _receitas.length; i++) {
        final planejamento = _receitas[i];
        if (planejamento.categoriaId != null) {
          final transacoesCategoria = todasTransacoes.where((t) {
            final mesmaCategoria = t.categoriaId == planejamento.categoriaId;
            final isReceita = t.tipo == 'receita';
            final temCategoria = t.categoriaId != null; // ← Garantir categoria válida
            final incluir = _incluirPendentes ? true : t.efetivado;
            return mesmaCategoria && isReceita && temCategoria && incluir;
          }).toList();

          final totalCategoria = transacoesCategoria.fold(0.0, (sum, t) => sum + t.valor);
          _receitas[i] = planejamento.copyWith(valorRealizado: totalCategoria);
        }
      }

      // Atualizar despesas
      for (int i = 0; i < _despesas.length; i++) {
        final planejamento = _despesas[i];
        if (planejamento.categoriaId != null) {
          final transacoesCategoria = todasTransacoes.where((t) {
            final mesmaCategoria = t.categoriaId == planejamento.categoriaId;
            final isDespesa = t.tipo == 'despesa';
            final temCategoria = t.categoriaId != null; // ← Garantir categoria válida
            final incluir = _incluirPendentes ? true : t.efetivado;
            return mesmaCategoria && isDespesa && temCategoria && incluir;
          }).toList();

          // Usando mesma lógica da CategoriaPage (sem .abs())
          final totalCategoria = transacoesCategoria.fold(0.0, (sum, t) => sum + t.valor);
          _despesas[i] = planejamento.copyWith(valorRealizado: totalCategoria);
        }
      }

    } catch (e) {
      debugPrint('❌ Erro ao atualizar valores dos planejamentos: $e');
    }
  }

  // ===========================
  // NAVEGAÇÃO DE PERÍODO
  // ===========================
  // MÉTODOS DE FILTRO
  // ===========================

  List<PlanejamentoModel> get _receitasFiltradas {
    // Aplicar lógica inteligente: só exibir categorias que devem ser mostradas
    var filtrados = _receitas.where((r) => _deveExibirCategoria(r)).toList();

    if (_searchQuery.isEmpty) return filtrados;
    return filtrados.where((r) =>
      (r.categoriaNome?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (r.subcategoriaNome?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  List<PlanejamentoModel> get _despesasFiltradas {
    // Aplicar lógica inteligente: só exibir categorias que devem ser mostradas
    var filtrados = _despesas.where((d) => _deveExibirCategoria(d)).toList();

    if (_searchQuery.isEmpty) return filtrados;
    return filtrados.where((d) =>
      (d.categoriaNome?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (d.subcategoriaNome?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }


  // ===========================
  // WIDGETS DE UI - COPIADOS DO CATEGORIAS
  // ===========================


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Tema claro
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Planejamento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Seletor de período compacto no lado direito
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  onPressed: _periodoAnterior,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                GestureDetector(
                  onTap: _alternarModo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _modoAnual ? '${_dataAtual.year}' : _formatarPeriodo(_dataAtual),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                  onPressed: _proximoPeriodo,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                  onPressed: _mostrarMenuOpcoes,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            color: _getBackgroundColor(),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_down, size: 18),
                      SizedBox(width: 8),
                      Text('Despesas'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 18),
                      SizedBox(width: 8),
                      Text('Receitas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _getFabColor(),
        onPressed: _mostrarAcoesRapidas,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildBody() {
    if (_loading) {
      return const LoadingWidget(message: 'Carregando planejamento...');
    }

    if (_error != null) {
      return AppErrorWidget(
        title: 'Erro ao carregar',
        message: _error!,
        onRetry: _carregarDados,
      );
    }

    return Column(
      children: [
        _buildResumoFinanceiro(),
        if (_mostrarPesquisa) _buildSearchBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListaDespesas(),
              _buildListaReceitas(),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildResumoFinanceiro() {
    // Obter dados baseado na aba ativa
    final bool isDespesas = _tabController.index == 0;
    final String titulo = isDespesas ? 'Total Despesas' : 'Total Receitas';
    final double valorPlanejado = isDespesas ? _totalDespesasPlanejado : _totalReceitasPlanejado;
    final double valorRealizado = isDespesas ? _totalDespesasRealizado : _totalReceitasRealizado;

    // Calcular percentual baseado na aba ativa
    final double percentual = valorPlanejado != 0 ? (valorRealizado / valorPlanejado) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle para incluir pendentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _incluirPendentes = !_incluirPendentes;
                  });
                  _carregarDados(); // Recarregar com novo filtro
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _incluirPendentes ? AppColors.azul : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _incluirPendentes ? 'Efetivado + Pendente' : 'Apenas Efetivado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _incluirPendentes ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Linha principal: Total vs Planejado (igual aos cards individuais)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título da aba ativa
              Expanded(
                child: Text(
                  isDespesas ? 'Despesas do Mês' : 'Receitas do Mês',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Valores: Realizado vs Planejado da aba ativa
              Text(
                '${formatCurrency(valorRealizado)} vs ${formatCurrency(valorPlanejado)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Barra de progresso (baseada na aba ativa)
          LinearProgressIndicator(
            value: valorPlanejado != 0 ? (percentual / 100).clamp(0.0, 1.0) : 0.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentual, isReceita: !isDespesas)),
            minHeight: 4,
          ),

          const SizedBox(height: 4),

          // Percentual (baseado na aba ativa)
          Text(
            '${percentual.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar categorias...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildListaReceitas() {
    if (_receitasFiltradas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma receita encontrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receitasFiltradas.length,
        itemBuilder: (context, index) {
          final planejamento = _receitasFiltradas[index];
          return _buildPlanejamentoCard(planejamento);
        },
      ),
    );
  }

  Widget _buildListaDespesas() {
    if (_despesasFiltradas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_down, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma despesa encontrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _despesasFiltradas.length,
        itemBuilder: (context, index) {
          final planejamento = _despesasFiltradas[index];
          return _buildPlanejamentoCard(planejamento);
        },
      ),
    );
  }

  // ===========================
  // CARD DE PLANEJAMENTO - BASEADO NA IMAGEM
  // ===========================

  Widget _buildPlanejamentoCard(PlanejamentoModel planejamento) {
    final subcategorias = _getSubcategoriasPorCategoria(planejamento.categoriaId);


    // 🚀 SIMPLES: Se JÁ é uma categoria com subcategoria_id, usar só esse valor
    // Se é categoria principal, somar APENAS as subcategorias (não duplicar)
    double valorGastoTotal;
    double valorPlanejadoTotal;

    if (planejamento.subcategoriaId != null) {
      // É uma subcategoria específica, usar apenas seu valor (respeitando filtro)
      valorGastoTotal = _incluirPendentes ? planejamento.totalMes : planejamento.valorRealizado;
      valorPlanejadoTotal = planejamento.valorPlanejado;
    } else {
      // É categoria principal, somar APENAS as subcategorias (não a categoria principal)
      valorGastoTotal = 0.0;
      valorPlanejadoTotal = 0.0;

      if (subcategorias.isNotEmpty) {
        for (final sub in subcategorias) {
          // 🚀 RESPEITAR FILTRO: se incluir pendentes, usa totalMes; senão, só valorRealizado
          final valorSubcategoria = _incluirPendentes ? sub.totalMes : sub.valorRealizado;
          valorGastoTotal += valorSubcategoria;
          valorPlanejadoTotal += sub.valorPlanejado;
        }
      } else {
        // Se não tem subcategorias, usar o valor da categoria mesmo (também respeitando filtro)
        final valorCategoria = _incluirPendentes ? planejamento.totalMes : planejamento.valorRealizado;
        valorGastoTotal = valorCategoria;
        valorPlanejadoTotal = planejamento.valorPlanejado;
      }
    }


    final percentual = valorPlanejadoTotal > 0 ? (valorGastoTotal / valorPlanejadoTotal) * 100 : 0.0;

    // Determinar se tem subcategorias reais
    final temSubcategorias = subcategorias.isNotEmpty;
    final expandido = _categoriasExpandidas.contains(planejamento.categoriaId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card principal
          GestureDetector(
            onTap: () => _editarPlanejamento(planejamento),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone quadrado colorido com seta integrada
                  GestureDetector(
                    onTap: temSubcategorias ? () => _toggleExpansaoCategoria(planejamento.categoriaId) : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(int.parse(planejamento.categoriaCor?.replaceAll('#', '0xFF') ?? '0xFF6B7280')),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Stack(
                        children: [
                          // Ícone principal
                          Center(
                            child: _buildCategoriaIcon(planejamento.categoriaIcone ?? 'category', 20),
                          ),
                          // Seta de expansão no canto inferior direito (se tem subcategorias)
                          if (temSubcategorias)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(234),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  expandido ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                  color: Colors.black87,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Conteúdo do card
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome da categoria + Valor (mesma linha)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Nome da categoria
                            Expanded(
                              child: Text(
                                planejamento.categoriaNome ?? 'Sem nome',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Valor atual vs planejado + indicador de subcategorias
                            Row(
                              children: [
                                Text(
                                  '${formatCurrency(valorGastoTotal)} vs ${formatCurrency(valorPlanejadoTotal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (temSubcategorias) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${subcategorias.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Barra de progresso
                        LinearProgressIndicator(
                          value: valorPlanejadoTotal > 0 ? (percentual / 100).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentual, isReceita: planejamento.tipo == 'RECEITA')),
                          minHeight: 4,
                        ),

                        const SizedBox(height: 4),

                        // Percentual
                        Text(
                          '${percentual.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MUDANÇA: SEMPRE mostra subcategorias, sem depender de expandido
          if (subcategorias.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(left: 16), // Máximo à esquerda com padding mínimo
              child: Column(
                children: [
                  // Linha divisória
                  Container(
                    height: 0.5,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  // Lista de subcategorias
                  ...subcategorias.map((sub) => _buildSubcategoriaItem(sub)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(double percentual, {bool isReceita = false}) {
    if (isReceita) {
      // RECEITAS: Bom quando atinge/supera a meta
      if (percentual >= 100) {
        return Colors.green; // Verde para meta atingida/superada
      } else if (percentual >= 80) {
        return Colors.orange; // Laranja próximo da meta
      } else if (percentual >= 50) {
        return Colors.orange; // Laranja médio
      } else {
        return Colors.red; // Vermelho para baixa receita
      }
    } else {
      // DESPESAS: Bom quando fica abaixo da meta
      if (percentual <= 50) {
        return Colors.green; // Verde para baixo gasto
      } else if (percentual <= 80) {
        return Colors.orange; // Laranja médio
      } else if (percentual <= 100) {
        return Colors.orange; // Laranja próximo do limite
      } else {
        return Colors.red; // Vermelho para estourar meta
      }
    }
  }

  void _mostrarMenuAcoes(PlanejamentoModel planejamento) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Meta'),
              onTap: () {
                Navigator.pop(context);
                _editarMeta(planejamento);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ver Histórico'),
              onTap: () {
                Navigator.pop(context);
                _mostrarHistoricoGeral();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editarMeta(PlanejamentoModel planejamento) {
    final controller = TextEditingController(
      text: planejamento.valorPlanejado.toStringAsFixed(2)
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Meta - ${planejamento.categoriaNome}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Valor Planejado',
            prefixText: 'R\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final novoValor = double.tryParse(controller.text) ?? 0.0;
              final novoPlano = planejamento.copyWith(valorPlanejado: novoValor);

              try {
                await _planejamentoService.salvarPlanejamento(novoPlano);
                Navigator.pop(context);
                _carregarDados();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meta atualizada com sucesso!'),
                    backgroundColor: AppColors.verdeSucesso,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro: $e'),
                    backgroundColor: AppColors.vermelhoErro,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }



  // ===========================
  // HISTÓRICO GERAL
  // ===========================

  void _mostrarHistoricoGeral() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 24,
                    color: AppColors.roxoHeader,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histórico de Planejamentos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cinzaEscuro,
                          ),
                        ),
                        Text(
                          _planejamentoService.formatarPeriodo(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Resumo estatístico
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.roxoHeader, Color(0xFF9C88FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Categorias',
                          '${(_receitas + _despesas).length}',
                          Icons.category,
                        ),
                        _buildStatCard(
                          'Metas Definidas',
                          '${(_receitas + _despesas).where((p) => p.valorPlanejado > 0).length}',
                          Icons.flag,
                        ),
                        _buildStatCard(
                          'Em Andamento',
                          '${(_receitas + _despesas).where((p) => p.statusMeta == StatusMeta.emAndamento).length}',
                          Icons.trending_up,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Atingidas',
                          '${(_receitas + _despesas).where((p) => p.percentualCumprimento >= 80).length}',
                          Icons.check_circle,
                        ),
                        _buildStatCard(
                          'Ultrapassadas',
                          '${(_receitas + _despesas).where((p) => p.statusMeta == StatusMeta.ultrapassou).length}',
                          Icons.warning,
                        ),
                        _buildStatCard(
                          'Baixo',
                          '${(_receitas + _despesas).where((p) => p.statusMeta == StatusMeta.baixo).length}',
                          Icons.trending_down,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Lista de categorias com maior desvio
              const Text(
                'Categorias com Maiores Desvios',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cinzaEscuro,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: (_receitas + _despesas).length > 5 ? 5 : (_receitas + _despesas).length,
                  itemBuilder: (context, index) {
                    // Ordena por maior desvio da meta
                    final planejamentosOrdenados = List<PlanejamentoModel>.from(_receitas + _despesas)
                      ..sort((a, b) {
                        final desvioA = (a.percentualCumprimento - 100).abs();
                        final desvioB = (b.percentualCumprimento - 100).abs();
                        return desvioB.compareTo(desvioA);
                      });

                    final planejamento = planejamentosOrdenados[index];
                    final desvio = planejamento.percentualCumprimento - 100;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cinzaClaro,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            width: 4,
                            color: planejamento.percentualCumprimento >= 100
                                ? AppColors.vermelhoErro
                                : AppColors.laranjaAlerta,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getCorCategoria(planejamento),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: _buildCategoriaIcon(planejamento.categoriaIcone ?? 'category', 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getNomeExibicao(planejamento),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cinzaEscuro,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatCurrency(planejamento.totalMes)} de ${formatCurrency(planejamento.valorPlanejado)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.cinzaMedio,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${desvio >= 0 ? '+' : ''}${desvio.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: desvio >= 0 ? AppColors.vermelhoErro : AppColors.laranjaAlerta,
                                ),
                              ),
                              Text(
                                desvio >= 0 ? 'Acima' : 'Abaixo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.cinzaMedio,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Botão de ação
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roxoHeader,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Color _getCorCategoria(PlanejamentoModel planejamento) {
    try {
      final cor = planejamento.categoriaCor;
      if (cor != null && cor.isNotEmpty) {
        return Color(int.parse(cor.replaceAll('#', '0xFF')));
      }
    } catch (e) {
      // Cor padrão
    }
    return planejamento.isReceita ? AppColors.verdeSucesso : AppColors.cinzaEscuro;
  }

  String _getNomeExibicao(PlanejamentoModel planejamento) {
    if (planejamento.subcategoriaNome != null) {
      return '${planejamento.categoriaNome} • ${planejamento.subcategoriaNome}';
    }
    return planejamento.categoriaNome ?? 'Sem nome';
  }

  void _mostrarAcoesRapidas() {
    // ✨ DETECÇÃO INTELIGENTE: Verificar se usuário tem planejamentos reais
    final temPlanejamentosReais = _planejamentoService.planejamentos.any((p) => p.temPlanejamentoReal);

    if (!temPlanejamentosReais) {
      // ✨ MODO CONFIGURAÇÃO INICIAL: Mostrar apenas dica para começar
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Como Começar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toque em qualquer categoria abaixo para definir sua meta de gastos.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi!'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // ✨ MODO NORMAL: Mostrar apenas histórico
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opções',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
              title: const Text('Histórico Geral'),
              subtitle: const Text('Ver estatísticas e histórico'),
              onTap: () {
                Navigator.pop(context);
                _mostrarHistoricoGeral();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 MOSTRAR MENU DE OPÇÕES (3 PONTINHOS)
  void _mostrarMenuOpcoes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador visual do modal
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Opções do menu
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: AppColors.azul),
              title: const Text('Histórico Geral'),
              onTap: () {
                Navigator.pop(context);
                _mostrarHistoricoGeral();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.verdeSucesso),
              title: const Text('Ir para Hoje'),
              onTap: () {
                Navigator.pop(context);
                _irParaHoje();
              },
            ),
            ListTile(
              leading: Icon(
                _mostrarPesquisa ? Icons.search_off : Icons.search,
                color: AppColors.cinzaMedio
              ),
              title: Text(_mostrarPesquisa ? 'Ocultar Pesquisa' : 'Mostrar Pesquisa'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _mostrarPesquisa = !_mostrarPesquisa;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.cinzaMedio),
              title: const Text('Atualizar Dados'),
              onTap: () {
                Navigator.pop(context);
                _carregarDados();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 OBTER COR DO FAB BASEADA NA ABA ATIVA
  Color _getFabColor() {
    final currentIndex = _tabController.index;

    if (currentIndex == 0) {
      // Aba Despesas - Vermelho
      return AppColors.vermelhoErro;
    } else {
      // Aba Receitas - Teal
      return AppColors.tealPrimary;
    }
  }

  /// 🎨 CONSTRUIR ÍCONE DA CATEGORIA (IGUAL CATEGORIAS PAGE)
  Widget _buildCategoriaIcon(String icone, double size) {
    final bool isEmoji = CategoriaIcons.isEmoji(icone);

    if (isEmoji) {
      return Text(
        icone,
        style: TextStyle(fontSize: size),
      );
    } else {
      return Icon(
        CategoriaIcons.getIconFromName(icone),
        color: Colors.white,
        size: size,
      );
    }
  }

  // ==========================================
  // 🎯 MÉTODOS DE CRIAÇÃO DE PLANEJAMENTO
  // ==========================================

  /// 📋 Copiar valores do mês anterior
  Future<void> _copiarMesAnterior() async {
    try {
      final mesAnterior = DateTime(_dataAtual.year, _dataAtual.month - 1);

      // Buscar transações do mês anterior
      final transacoesMesAnterior = await _transacaoService.fetchTransacoes(
        dataInicio: DateTime(mesAnterior.year, mesAnterior.month, 1),
        dataFim: DateTime(mesAnterior.year, mesAnterior.month + 1, 0),
        limit: 10000,
      );

      await _criarPlanejamentosBasadoEmTransacoes(transacoesMesAnterior, 'Mês Anterior');

    } catch (e) {
      _mostrarErro('Erro ao copiar mês anterior: $e');
    }
  }

  /// 📊 Aplicar média histórica (Service)
  Future<void> _aplicarMedia3Meses() async {
    try {
      _mostrarSucesso('📊 Aplicando média histórica...');

      // Usar a função do service que já tem a sincronização corrigida
      await _planejamentoService.aplicarMediaHistorica();
      // ✅ Stream vai atualizar automaticamente

      _mostrarSucesso('✅ Média histórica aplicada com sucesso!');
    } catch (e) {
      _mostrarErro('Erro ao aplicar média histórica: $e');
    }
  }

  /// 📉 Modal para reduzir gastos por percentual
  void _mostrarModalReducaoGastos() {
    final TextEditingController percentualController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reduzir Gastos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Qual percentual deseja reduzir dos gastos do mês anterior?'),
            const SizedBox(height: 16),
            TextField(
              controller: percentualController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Percentual (%)',
                hintText: 'Ex: 10 para reduzir 10%',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final percentual = double.tryParse(percentualController.text);
              if (percentual != null && percentual > 0 && percentual <= 100) {
                Navigator.pop(context);
                _aplicarReducaoGastos(percentual);
              }
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  /// 📉 Aplicar redução de gastos por percentual
  Future<void> _aplicarReducaoGastos(double percentual) async {
    try {
      final mesAnterior = DateTime(_dataAtual.year, _dataAtual.month - 1);

      // Buscar transações do mês anterior (apenas despesas)
      final transacoesMesAnterior = await _transacaoService.fetchTransacoes(
        dataInicio: DateTime(mesAnterior.year, mesAnterior.month, 1),
        dataFim: DateTime(mesAnterior.year, mesAnterior.month + 1, 0),
        tipo: 'despesa',
        limit: 10000,
      );

      final Map<String, double> gastosPorCategoria = {};

      // Agrupar gastos por categoria
      for (final t in transacoesMesAnterior.where((t) => t.categoriaId != null && t.efetivado)) {
        gastosPorCategoria[t.categoriaId!] = (gastosPorCategoria[t.categoriaId!] ?? 0) + t.valor;
      }

      // Aplicar redução e criar planejamentos
      for (final categoriaId in gastosPorCategoria.keys) {
        final valorOriginal = gastosPorCategoria[categoriaId]!;
        final valorReduzido = valorOriginal * (1 - percentual / 100);

        final categoria = _todasCategorias.firstWhere((c) => c.id == categoriaId);
        await _criarPlanejamento(categoria, valorReduzido);
      }

      _carregarDados();
      _mostrarSucesso('Redução de ${percentual.toStringAsFixed(1)}% aplicada com sucesso!');

    } catch (e) {
      _mostrarErro('Erro ao aplicar redução de gastos: $e');
    }
  }

  /// 🔄 Repetir planejamento atual para o ano inteiro
  Future<void> _repetirParaAno() async {
    try {
      final planejamentosAtuais = _planejamentoService.planejamentos
          .where((p) => p.ano == _dataAtual.year && p.mes == _dataAtual.month)
          .toList();

      if (planejamentosAtuais.isEmpty) {
        _mostrarErro('Não há planejamentos no mês atual para repetir');
        return;
      }

      // Repetir para todos os meses do ano
      for (int mes = 1; mes <= 12; mes++) {
        if (mes == _dataAtual.month) continue; // Pular o mês atual

        for (final planejamento in planejamentosAtuais) {
          final novoPlano = planejamento.copyWith(
            mes: mes,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _planejamentoService.salvarPlanejamento(novoPlano);
        }
      }

      _carregarDados();
      _mostrarSucesso('Planejamentos repetidos para todo o ano!');

    } catch (e) {
      _mostrarErro('Erro ao repetir para o ano: $e');
    }
  }

  /// ✏️ Editar planejamento existente - Modal scrollável
  Future<void> _editarPlanejamento(PlanejamentoModel planejamento) async {
    // Se for uma subcategoria, buscar a categoria principal e todas as subcategorias
    final String categoriaId = planejamento.categoriaId;

    // Buscar todas as subcategorias desta categoria
    final subcategorias = _getSubcategoriasPorCategoria(categoriaId);

    // Se for subcategoria, buscar o planejamento principal da categoria
    PlanejamentoModel? planejamentoPrincipal;
    if (planejamento.subcategoriaId != null) {
      planejamentoPrincipal = _planejamentoService.planejamentos
          .where((p) => p.categoriaId == categoriaId && p.subcategoriaId == null)
          .isNotEmpty
          ? _planejamentoService.planejamentos.firstWhere((p) => p.categoriaId == categoriaId && p.subcategoriaId == null)
          : null;

      // 🚀 CORREÇÃO: Se não existe planejamento principal, criar um automaticamente
      if (planejamentoPrincipal == null) {

        // Buscar dados da categoria para criar o planejamento principal
        final categoriaInfo = subcategorias.isNotEmpty ? subcategorias.first : planejamento;

        planejamentoPrincipal = PlanejamentoModel(
          id: 'temp_principal_$categoriaId', // ID temporário
          usuarioId: planejamento.usuarioId,
          ano: planejamento.ano,
          mes: planejamento.mes,
          categoriaId: categoriaId,
          subcategoriaId: null, // Categoria principal
          tipo: planejamento.tipo,
          valorPlanejado: 0.0, // Valor inicial zero
          createdAt: DateTime.now(), // 🚀 CORREÇÃO: adicionar created_at
          updatedAt: DateTime.now(), // 🚀 CORREÇÃO: adicionar updated_at
          categoriaNome: categoriaInfo.categoriaNome,
          categoriaIcone: categoriaInfo.categoriaIcone,
          categoriaCor: categoriaInfo.categoriaCor,
          valorRealizado: 0.0,
          valorPrevisto: 0.0,
        );

      }
    } else {
      planejamentoPrincipal = planejamento;
    }

    // Criar controladores e FocusNodes
    Map<String, TextEditingController> controladores = {};
    Map<String, FocusNode> focusNodes = {};
    List<String> orderedIds = [];

    // Ordem: categoria principal primeiro, depois subcategorias
    if (planejamentoPrincipal != null) {
      orderedIds.add(planejamentoPrincipal.id);
      controladores[planejamentoPrincipal.id] = TextEditingController();
      focusNodes[planejamentoPrincipal.id] = FocusNode();
    }

    for (final sub in subcategorias) {
      orderedIds.add(sub.id);
      controladores[sub.id] = TextEditingController();
      focusNodes[sub.id] = FocusNode();
    }

    // Manter valores originais para fallback
    Map<String, double> valoresOriginais = {};
    if (planejamentoPrincipal != null) {
      valoresOriginais[planejamentoPrincipal.id] = planejamentoPrincipal.valorPlanejado;
    }
    for (final sub in subcategorias) {
      valoresOriginais[sub.id] = sub.valorPlanejado;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador visual do modal
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Card da categoria principal (não editável visualmente)
                if (planejamentoPrincipal != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        // Ícone quadrado colorido
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(int.parse(planejamentoPrincipal.categoriaCor?.replaceAll('#', '0xFF') ?? '0xFF6B7280')),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: _buildCategoriaIcon(planejamentoPrincipal.categoriaIcone ?? 'category', 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Conteúdo do card
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome da categoria
                              Text(
                                planejamentoPrincipal.categoriaNome ?? 'Sem nome',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Valores
                              Text(
                                '${formatCurrency(planejamentoPrincipal.totalMes)} vs ${formatCurrency(planejamentoPrincipal.valorPlanejado)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Meta da categoria principal (não editável - calculada automaticamente)
                if (planejamentoPrincipal != null && subcategorias.isNotEmpty) ...[
                  StatefulBuilder(
                    builder: (context, setPreviewState) {
                      // 🔄 Adicionar listeners para atualização em tempo real
                      for (final sub in subcategorias) {
                        controladores[sub.id]?.removeListener(() => setPreviewState(() {}));
                        controladores[sub.id]?.addListener(() => setPreviewState(() {}));
                      }

                      // 📊 Cálculo em tempo real da meta total
                      double metaAtual = subcategorias.fold(0.0, (total, sub) => total + sub.valorPlanejado);
                      double metaNova = subcategorias.fold(0.0, (total, sub) {
                        final valorDigitado = controladores[sub.id]?.text.trim() ?? '';
                        if (valorDigitado.isNotEmpty) {
                          try {
                            return total + _parseMoneyValue(valorDigitado);
                          } catch (e) {
                            return total + sub.valorPlanejado; // Se erro no parse, manter valor original
                          }
                        }
                        return total + sub.valorPlanejado;
                      });

                      bool temAlteracoes = (metaAtual - metaNova).abs() > 0.01; // Evitar problemas de ponto flutuante

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: temAlteracoes ? Colors.orange[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: temAlteracoes ? Colors.orange[200]! : Colors.blue[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  temAlteracoes ? Icons.trending_up : Icons.info_outline,
                                  size: 16,
                                  color: temAlteracoes ? Colors.orange[600] : Colors.blue[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Meta Total: ${planejamentoPrincipal?.categoriaNome ?? 'Categoria'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: temAlteracoes ? Colors.orange[800] : Colors.blue[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 📊 Preview do valor
                            if (temAlteracoes) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Valor anterior
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Atual:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(metaAtual),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Seta
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.orange[600],
                                    size: 20,
                                  ),

                                  // Valor novo
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Nova:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(metaNova),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Diferença: ${formatCurrency(metaNova - metaAtual)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: metaNova > metaAtual ? Colors.red[600] : Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else ...[
                              Text(
                                formatCurrency(metaAtual),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],

                            const SizedBox(height: 4),
                            Text(
                              'Calculada automaticamente pela soma das subcategorias',
                              style: TextStyle(
                                fontSize: 11,
                                color: temAlteracoes ? Colors.orange[600] : Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Subcategorias editáveis
                if (subcategorias.isNotEmpty) ...[
                  // Título das subcategorias
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Subcategorias:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de subcategorias editáveis
                  ...subcategorias.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sub = entry.value;
                    final isUltima = index == subcategorias.length - 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                        ),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setFieldState) {
                          // 🔄 Adicionar listener para atualizar o helper text
                          controladores[sub.id]?.removeListener(() => setFieldState(() {}));
                          controladores[sub.id]?.addListener(() => setFieldState(() {}));

                          // 📊 Verificar se há valor digitado
                          final valorDigitado = controladores[sub.id]?.text.trim() ?? '';
                          final temValorNovo = valorDigitado.isNotEmpty;

                          // 💰 Calcular nova meta se digitada
                          String helperText = 'Atual: ${formatCurrency(sub.totalMes)} | Meta atual: ${formatCurrency(sub.valorPlanejado)}';
                          if (temValorNovo) {
                            try {
                              final novaMeta = _parseMoneyValue(valorDigitado);
                              helperText += ' | Nova meta: ${formatCurrency(novaMeta)}';
                            } catch (e) {
                              // Se erro no parse, não mostrar nova meta
                            }
                          }

                          return TextField(
                            controller: controladores[sub.id],
                            focusNode: focusNodes[sub.id],
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoneyInputFormatter()],
                            textInputAction: isUltima ? TextInputAction.done : TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: sub.subcategoriaNome ?? 'Subcategoria',
                              hintText: 'Digite a nova meta ou deixe vazio para manter: ${formatCurrency(sub.valorPlanejado)}',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              labelStyle: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              helperText: helperText,
                              helperStyle: TextStyle(
                                fontSize: 11,
                                color: temValorNovo ? Colors.orange[600] : (sub.valorPlanejado > 0 ? Colors.blue[600] : Colors.grey),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixText: 'R\$ ',
                              prefixStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              suffixIcon: temValorNovo
                                ? Icon(Icons.check_circle, color: Colors.green[600], size: 20)
                                : Icon(Icons.edit, color: Colors.grey[400], size: 18),
                            ),
                            onSubmitted: (value) {
                              if (!isUltima) {
                                // Navegar para próxima subcategoria
                                final proximaSubId = subcategorias[index + 1].id;
                                focusNodes[proximaSubId]?.requestFocus();
                              }
                            },
                          );
                        },
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 32),

                // Botões
                Row(
                  children: [
                    // Botão Voltar
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Voltar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botão Salvar
                    Expanded(
                      flex: 2,
                      child: StatefulBuilder(
                        builder: (context, setModalState) {
                          bool salvando = false;

                          // 🎨 Cor dinâmica baseada no tipo
                          final corBotao = planejamentoPrincipal?.tipo == 'receita'
                            ? AppColors.tealPrimary
                            : AppColors.vermelhoHeader;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: corBotao,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: salvando ? null : () async {
                              setModalState(() => salvando = true);

                              try {

                                // 📋 Coletar apenas subcategorias que foram editadas
                                final subcategoriasParaSalvar = <PlanejamentoModel>[];

                                for (final sub in subcategorias) {
                                  final valorDigitado = controladores[sub.id]!.text.trim();

                                  // ✅ SÓ SALVA SE O USUÁRIO DIGITOU ALGO
                                  if (valorDigitado.isNotEmpty) {
                                    final novoValor = _parseMoneyValue(valorDigitado);
                                    final subcategoriaAtualizada = sub.copyWith(
                                      valorPlanejado: novoValor,
                                      updatedAt: DateTime.now(),
                                    );
                                    subcategoriasParaSalvar.add(subcategoriaAtualizada);
                                  } else {
                                  }
                                }

                                if (subcategoriasParaSalvar.isEmpty) {
                                  Navigator.pop(context);
                                  _mostrarSucesso('Nenhuma alteração foi feita!');
                                  return;
                                }

                                // 🚀 UPDATE OTIMISTA - Atualizar tela IMEDIATAMENTE
                                _atualizarMultiplosPlanejamentosOtimista(subcategoriasParaSalvar);

                                // 🔄 Fechar modal IMEDIATAMENTE
                                Navigator.pop(context);

                                // ✅ Feedback de sucesso IMEDIATO
                                _mostrarSucesso('${subcategoriasParaSalvar.length} meta(s) atualizada(s) com sucesso!');

                                // 💾 Salvar em background (sem await para não travar UI)

                                if (planejamentoPrincipal == null) {
                                  _mostrarErro('Erro interno: categoria principal não encontrada');
                                  return;
                                }


                                try {
                                  _salvarSubcategoriasBackground(subcategoriasParaSalvar, planejamentoPrincipal!, subcategorias);
                                } catch (callError) {
                                }

                              } catch (e) {
                                setModalState(() => salvando = false);
                                _mostrarErro('Erro ao salvar: $e');
                              }
                            },
                            child: salvando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Salvar'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // Dispose dos controladores e focusNodes ao fechar o modal
      for (final controller in controladores.values) {
        controller.dispose();
      }
      for (final focusNode in focusNodes.values) {
        focusNode.dispose();
      }
    });
  }

  /// 🗑️ Excluir planejamento
  Future<void> _excluirPlanejamento(PlanejamentoModel planejamento) async {
    try {
      // Implementar lógica de exclusão no service se não existir
      await _planejamentoService.excluirPlanejamento(planejamento.id);
      _carregarDados();
      _mostrarSucesso('Meta excluída com sucesso!');
    } catch (e) {
      _mostrarErro('Erro ao excluir meta: $e');
    }
  }

  /// 🔄 Toggle expansão categoria
  void _toggleExpansaoCategoria(String categoriaId) {

    setState(() {
      if (_categoriasExpandidas.contains(categoriaId)) {
        _categoriasExpandidas.remove(categoriaId);
      } else {
        _categoriasExpandidas.add(categoriaId);

        // Verificar subcategorias disponíveis
        final subcategorias = _getSubcategoriasPorCategoria(categoriaId);
        for (final sub in subcategorias) {
        }
      }
    });
  }

  /// 🚀 SIMPLES: Buscar subcategorias com lógica inteligente
  List<PlanejamentoModel> _getSubcategoriasPorCategoria(String categoriaId) {

    // ✨ MODO CONFIGURAÇÃO INICIAL: Se usuário não tem planejamentos reais, mostrar todas
    final temPlanejamentosReais = _planejamentoService.planejamentos.any((p) => p.temPlanejamentoReal);

    if (!temPlanejamentosReais) {
      // Modo configuração inicial: mostrar todas as subcategorias
      final todasSubcategorias = _planejamentoService.planejamentos
          .where((p) => p.categoriaId == categoriaId && p.subcategoriaId != null)
          .toList();
      return todasSubcategorias;
    }

    // ✨ MODO NORMAL: APENAS subcategorias com planejamento real
    final todasSubcategorias = _planejamentoService.planejamentos
        .where((p) => p.categoriaId == categoriaId &&
                      p.subcategoriaId != null &&
                      p.temPlanejamentoReal) // ← FILTRO PARA USUÁRIOS EXPERIENTES
        .toList();


    // Debug simples
    for (final sub in todasSubcategorias) {
    }

    return todasSubcategorias;
  }

  /// 🎯 LÓGICA INTELIGENTE: Verificar se categoria deve ser exibida
  bool _deveExibirCategoria(PlanejamentoModel categoria) {
    // 🔢 Contar quantas categorias têm planejamento preenchido
    final categoriasPreenchidas = _planejamentoService.planejamentos
        .where((p) => p.temPlanejamentoReal && p.subcategoriaId == null)
        .map((p) => p.categoriaId)
        .toSet()
        .length;

    // Se tem poucas categorias preenchidas (≤ 3), mostrar todas (modo configuração)
    if (categoriasPreenchidas <= 3) {
      return true;
    }

    // Modo normal: mostrar apenas categorias preenchidas ou com subcategorias preenchidas
    if (categoria.temPlanejamentoReal && categoria.subcategoriaId == null) {
      return true;
    }

    // Verificar se tem subcategorias preenchidas
    final subcategorias = _getSubcategoriasPorCategoria(categoria.categoriaId);
    final temSubcategorias = subcategorias.isNotEmpty;

    // 🚨 Fallback: Sempre mostrar pelo menos algumas categorias essenciais
    if (!temSubcategorias && categoriasPreenchidas == 0) {
      final categoriasEssenciais = ['Transporte', 'Alimentação', 'Casa'];
      if (categoriasEssenciais.contains(categoria.categoriaNome)) {
        return true;
      }
    }

    return temSubcategorias;
  }

  /// 📝 Widget para item de subcategoria
  Widget _buildSubcategoriaItem(PlanejamentoModel subcategoria) {
    return GestureDetector(
      onTap: () => _editarPlanejamento(subcategoria),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 0, right: 16, bottom: 6), // Máximo à esquerda
        child: Row(
          children: [
            // Nome da subcategoria - máximo à esquerda
            Expanded(
              child: Text(
                subcategoria.subcategoriaNome ?? 'Subcategoria',
                style: const TextStyle(
                  fontSize: 11, // Reduzido de 13 para 11
                  color: Colors.black54,
                ),
              ),
            ),
            // Valores lado a lado: Atual vs Meta (respeitando filtro)
            Text(
              '${formatCurrency(_incluirPendentes ? subcategoria.totalMes : subcategoria.valorRealizado)} vs ${formatCurrency(subcategoria.valorPlanejado)}',
              style: const TextStyle(
                fontSize: 10, // Reduzido de 12 para 10
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            // Ícone de edição
            GestureDetector(
              onTap: () => _editarPlanejamento(subcategoria),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 Método auxiliar para criar planejamentos baseados em transações
  Future<void> _criarPlanejamentosBasadoEmTransacoes(List<dynamic> transacoes, String fonte) async {
    final Map<String, double> valoresPorCategoria = {};

    // Agrupar valores por categoria
    for (final t in transacoes.where((t) => t.categoriaId != null && t.efetivado)) {
      valoresPorCategoria[t.categoriaId!] = (valoresPorCategoria[t.categoriaId!] ?? 0) + t.valor;
    }

    // Criar planejamentos
    for (final categoria in _todasCategorias) {
      final valor = valoresPorCategoria[categoria.id];
      if (valor != null && valor > 0) {
        await _criarPlanejamento(categoria, valor);
      }
    }

    _carregarDados();
    _mostrarSucesso('Planejamentos criados baseados em: $fonte');
  }

  /// 🔧 Método auxiliar para criar um planejamento individual
  Future<void> _criarPlanejamento(CategoriaModel categoria, double valor) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _mostrarErro('Usuário não autenticado');
      return;
    }

    final planejamento = PlanejamentoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      usuarioId: userId,
      ano: _dataAtual.year,
      mes: _dataAtual.month,
      categoriaId: categoria.id,
      tipo: categoria.tipo,
      valorPlanejado: valor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _planejamentoService.salvarPlanejamento(planejamento);
  }

  /// 📝 Mostrar mensagem de sucesso
  void _mostrarSucesso(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: AppColors.verdeSucesso,
        ),
      );
    }
  }

  /// ❌ Mostrar mensagem de erro
  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: AppColors.vermelhoErro,
        ),
      );
    }
  }

  /// 💰 Parse de valor monetário - idêntico ao despesa cartão page
  double _parseMoneyValue(String value) {
    // Remove R$ e converte vírgula para ponto
    final cleanValue = value.replaceAll('R\$', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  // ===========================
  // ATUALIZAR CATEGORIA PRINCIPAL
  // ===========================

  /// Atualiza a categoria principal com a soma das subcategorias
  Future<void> _atualizarCategoriaPrincipal(
    PlanejamentoModel categoriaPrincipal,
    List<PlanejamentoModel> todasSubcategorias,
    List<PlanejamentoModel> subcategoriasEditadas,
  ) async {
    try {
      // Calcular nova soma total das subcategorias
      double somaSubcategorias = 0.0;

      for (final sub in todasSubcategorias) {
        // Se foi editada, usar o novo valor, senão usar o valor atual
        final subcategoriaEditada = subcategoriasEditadas.firstWhere(
          (editada) => editada.id == sub.id,
          orElse: () => sub,
        );
        somaSubcategorias += subcategoriaEditada.valorPlanejado;
      }


      // Só atualizar se a soma mudou
      if ((somaSubcategorias - categoriaPrincipal.valorPlanejado).abs() > 0.01) {

        // 🔥 GARANTIR que a categoria principal tenha subcategoria_id = NULL
        final categoriaPrincipalAtualizada = categoriaPrincipal.copyWith(
          valorPlanejado: somaSubcategorias,
          subcategoriaId: null, // ⚠️ FORÇAR NULL para categoria principal
          updatedAt: DateTime.now(),
        );


        await _planejamentoService.salvarPlanejamento(categoriaPrincipalAtualizada);
      } else {
      }
    } catch (e) {
      // Não propagar o erro para não quebrar o fluxo
    }
  }

  // ===========================
  // FUNÇÕES AUTOMÁTICAS ADICIONAIS
  // ===========================

  /// 🔄 Repetir pelo ano
  Future<void> _repetirPeloAno() async {
    try {
      _mostrarSucesso('🔄 Aplicando metas para todos os meses...');

      await _planejamentoService.repetirPeloAno();
      // ✅ Stream vai atualizar automaticamente

      _mostrarSucesso('✅ Metas aplicadas para todo o ano!');
    } catch (e) {
      _mostrarErro('Erro ao repetir pelo ano: $e');
    }
  }

  /// 💰 Aplicar desafio de economia (10%)
  Future<void> _aplicarDesafioEconomia() async {
    try {
      _mostrarSucesso('💰 Aplicando desafio de economia (-10%)...');

      await _planejamentoService.aplicarDesafioEconomia(10.0); // 10%
      // ✅ Stream vai atualizar automaticamente

      _mostrarSucesso('✅ Desafio aplicado! Despesas reduzidas em 10%');
    } catch (e) {
      _mostrarErro('Erro ao aplicar desafio: $e');
    }
  }

  /// 🧹 Limpar dados inconsistentes
  Future<void> _limparDados() async {
    try {
      _mostrarSucesso('🧹 Iniciando limpeza de dados...');

      await _planejamentoService.limparDadosInconsistentes();
      // ✅ Stream vai atualizar automaticamente

      _mostrarSucesso('✅ Limpeza concluída! Dados organizados');
    } catch (e) {
      _mostrarErro('Erro ao limpar dados: $e');
    }
  }

  /// 🚨 Reset de emergência
  Future<void> _resetEmergencia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Reset de Emergência'),
        content: const Text(
          'Esta ação irá REMOVER TODOS os planejamentos do mês atual!\n\n'
          'Esta operação NÃO pode ser desfeita.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET TOTAL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _mostrarSucesso('🚨 Executando reset de emergência...');

        await _planejamentoService.resetEmergenciaPeriodoAtual();
        // ✅ Stream vai atualizar automaticamente

        _mostrarSucesso('✅ Reset concluído! Página limpa');
      } catch (e) {
        _mostrarErro('Erro durante reset: $e');
      }
    }
  }

  // ===========================
  // 🚀 UPDATES OTIMISTAS
  // ===========================

  /// 🚀 UPDATE OTIMISTA - Atualiza tela IMEDIATAMENTE
  void _atualizarPlanejamentoOtimista(PlanejamentoModel planejamentoAtualizado) {
    setState(() {
      if (planejamentoAtualizado.isReceita) {
        final index = _receitas.indexWhere((p) => p.id == planejamentoAtualizado.id);
        if (index != -1) {
          _receitas[index] = planejamentoAtualizado;
        }
      } else {
        final index = _despesas.indexWhere((p) => p.id == planejamentoAtualizado.id);
        if (index != -1) {
          _despesas[index] = planejamentoAtualizado;
        }
      }
      _calcularTotais();
    });
  }

  /// 🚀 UPDATE OTIMISTA MÚLTIPLO - Para várias subcategorias
  void _atualizarMultiplosPlanejamentosOtimista(List<PlanejamentoModel> planejamentosAtualizados) {
    setState(() {
      for (final planejamento in planejamentosAtualizados) {
        if (planejamento.isReceita) {
          final index = _receitas.indexWhere((p) => p.id == planejamento.id);
          if (index != -1) {
            _receitas[index] = planejamento;
          }
        } else {
          final index = _despesas.indexWhere((p) => p.id == planejamento.id);
          if (index != -1) {
            _despesas[index] = planejamento;
          }
        }
      }
      _calcularTotais();
    });
  }

  /// 💾 SALVAR EM BACKGROUND - Não trava a UI
  Future<void> _salvarSubcategoriasBackground(
    List<PlanejamentoModel> subcategoriasParaSalvar,
    PlanejamentoModel planejamentoPrincipal,
    List<PlanejamentoModel> todasSubcategorias,
  ) async {
    try {



      // 🔥 PRIMEIRO: Garantir que a categoria principal EXISTE no banco
      await _garantirCategoriaPrincipalExiste(planejamentoPrincipal);

      // Salvar subcategorias
      for (int i = 0; i < subcategoriasParaSalvar.length; i++) {
        final subcategoria = subcategoriasParaSalvar[i];

        try {
          await _planejamentoService.salvarPlanejamento(subcategoria);
        } catch (subError) {
          rethrow;
        }
      }

      // Atualizar categoria principal
      await _atualizarCategoriaPrincipal(planejamentoPrincipal, todasSubcategorias, subcategoriasParaSalvar);


      // 🔄 REFRESH AUTOMÁTICO: Recarregar dados após salvamento
      await Future.delayed(const Duration(milliseconds: 500));
      await _planejamentoService.carregarPlanejamentos();
    } catch (e, stackTrace) {
      // TODO: Implementar reversão otimista se necessário
      _mostrarErro('Erro ao sincronizar: $e');
    }
  }

  /// 🔥 Garantir que a categoria principal tenha um registro
  Future<void> _garantirCategoriaPrincipalExiste(PlanejamentoModel categoriaPrincipal) async {
    try {
      // PULAR salvamento se for temporário
      if (categoriaPrincipal.id.startsWith('temp_')) {
        return;
      }

      // Criar registro da categoria principal com subcategoria_id = NULL
      final categoriaPrincipalBase = categoriaPrincipal.copyWith(
        subcategoriaId: null, // ⚠️ SEMPRE NULL para categoria principal
        valorPlanejado: 0.0,  // Valor inicial, será atualizado depois
        createdAt: categoriaPrincipal.createdAt ?? DateTime.now(),
        updatedAt: categoriaPrincipal.updatedAt ?? DateTime.now(),
      );


      // Salvar/atualizar categoria principal (vai fazer UPSERT)
      await _planejamentoService.salvarPlanejamento(categoriaPrincipalBase);

    } catch (e) {
    }
  }
}
