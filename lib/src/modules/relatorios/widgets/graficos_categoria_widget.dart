// 📊 Gráficos de Categoria Widget - iPoupei Mobile
//
// Widget com gráficos de pizza para despesas e receitas por categoria
// Baseado no gráfico da gestão de cartões (gestao_cartoes_mobile.dart)
//
// Design: Dois gráficos lado a lado - Despesas e Receitas

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../../shared/components/charts/interactive_pie_chart.dart';
import '../services/graficos_categoria_service.dart';
import '../../categorias/pages/categorias_page.dart';
import '../../categorias/pages/gestao_categoria_page.dart';
import '../../categorias/models/categoria_model.dart';
import '../../categorias/services/categoria_service.dart';

/// Widget com gráficos de pizza para despesas e receitas por categoria
class GraficosCategoriaWidget extends StatefulWidget {
  final DateTime dataInicio;
  final DateTime dataFim;

  const GraficosCategoriaWidget({
    super.key,
    required this.dataInicio,
    required this.dataFim,
  });

  @override
  State<GraficosCategoriaWidget> createState() => _GraficosCategoriaWidgetState();
}

class _GraficosCategoriaWidgetState extends State<GraficosCategoriaWidget> {
  final GraficosCategoriaService _service = GraficosCategoriaService.instance;
  final CategoriaService _categoriaService = CategoriaService.instance;

  List<Map<String, dynamic>> _despesasPorCategoria = [];
  List<Map<String, dynamic>> _receitasPorCategoria = [];
  List<CategoriaModel> _todasCategorias = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void didUpdateWidget(GraficosCategoriaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar se o período mudou
    if (oldWidget.dataInicio != widget.dataInicio || oldWidget.dataFim != widget.dataFim) {
      _carregarDados();
    }
  }

  /// 🔄 Carregar dados dos gráficos e categorias
  Future<void> _carregarDados() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.buscarDespesasPorCategoria(widget.dataInicio, widget.dataFim),
        _service.buscarReceitasPorCategoria(widget.dataInicio, widget.dataFim),
        _categoriaService.fetchCategorias(), // Buscar todas as categorias
      ]);

      setState(() {
        _despesasPorCategoria = results[0] as List<Map<String, dynamic>>;
        _receitasPorCategoria = results[1] as List<Map<String, dynamic>>;
        _todasCategorias = results[2] as List<CategoriaModel>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se está carregando, mostra loading
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Se deu erro, não mostra nada
    if (_error != null) {
      return const SizedBox.shrink();
    }

    // Se não tem dados, não mostra
    if (_despesasPorCategoria.isEmpty && _receitasPorCategoria.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Gráfico de Despesas
        if (_despesasPorCategoria.isNotEmpty) ...[
          _buildGraficoCategoria(
            titulo: 'Despesas por Categoria',
            icone: Icons.trending_down,
            cor: AppColors.vermelhoErro,
            dados: _despesasPorCategoria,
          ),
          const SizedBox(height: 16),
        ],

        // Gráfico de Receitas
        if (_receitasPorCategoria.isNotEmpty) ...[
          _buildGraficoCategoria(
            titulo: 'Receitas por Categoria',
            icone: Icons.trending_up,
            cor: AppColors.verdeSucesso,
            dados: _receitasPorCategoria,
          ),
        ],
      ],
    );
  }

  /// 📊 Widget do gráfico de categoria (baseado na gestão de cartões)
  Widget _buildGraficoCategoria({
    required String titulo,
    required IconData icone,
    required Color cor,
    required List<Map<String, dynamic>> dados,
  }) {
    return Container(
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
            // Gráfico + Legenda (sem header)
            Row(
              children: [
                // Gráfico interativo reutilizável
                Expanded(
                  child: InteractivePieChartWithLegend(
                    data: _convertToChartData(dados),
                    centerTitle: titulo.split(' ')[0], // "Despesas" ou "Receitas"
                    centerSubtitle: 'Categoria',
                    centerTitleColor: cor.withAlpha(204),
                    centerSubtitleColor: cor.withAlpha(153),
                    onTap: (item) => _navegarParaCategoriaEspecifica(
                      context,
                      item.label,
                      titulo,
                    ),
                    onLegendTap: (item) => _navegarParaCategoriaEspecifica(
                      context,
                      item.label,
                      titulo,
                    ),
                    valueFormatter: (value) => CurrencyFormatter.format(value),
                    height: 200,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  /// 🎨 Obter cor real da categoria
  Color _getCorCategoria(String nomeCategoria) {
    try {
      final categoria = _todasCategorias.firstWhere(
        (cat) => cat.nome.toLowerCase() == nomeCategoria.toLowerCase(),
      );

      // Converter string hex para Color
      final colorHex = categoria.cor.replaceAll('#', '');
      return Color(int.parse('FF$colorHex', radix: 16));
    } catch (e) {
      // Fallback para cores padrão se não encontrar a categoria
      final cores = _getCoresGraficoFallback();
      final index = nomeCategoria.hashCode % cores.length;
      return cores[index];
    }
  }

  /// 🎨 Cores fallback se não encontrar categoria
  List<Color> _getCoresGraficoFallback() {
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
  }

  /// 🔄 Converter dados para o formato do componente reutilizável
  List<PieChartDataItem> _convertToChartData(List<Map<String, dynamic>> dados) {
    return dados.take(6).map((categoria) {
      final valor = (categoria['total_valor'] ?? 0.0).toDouble();
      final nome = categoria['categoria'] as String;
      final cor = _getCorCategoria(nome); // Usar cor real da categoria

      return PieChartDataItem(
        label: nome,
        value: valor,
        color: cor,
        data: categoria, // Dados originais para referência
      );
    }).toList();
  }

  /// 🧭 Navegar para página de categorias (fallback)
  Future<void> _navegarParaCategorias(BuildContext context, String titulo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoriasPage(),
      ),
    );
  }

  /// 🎯 Navegar para gestão de categoria específica
  Future<void> _navegarParaCategoriaEspecifica(BuildContext context, String nomeCategoria, String titulo) async {
    try {
      // Buscar a categoria pelo nome
      final isDespesa = titulo.toLowerCase().contains('despesas');
      final tipo = isDespesa ? 'despesa' : 'receita';

      final categorias = await _categoriaService.fetchCategorias(tipo: tipo);
      final categoria = categorias
          .where((cat) => cat.ativo) // Filtrar apenas categorias ativas
          .firstWhere(
            (cat) => cat.nome.toLowerCase() == nomeCategoria.toLowerCase(),
            orElse: () => throw Exception('Categoria não encontrada'),
          );

      if (context.mounted) {
        // Aguardar retorno da navegação e recarregar dados
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GestaoCategoriaPage(categoria: categoria),
          ),
        );

        // Recarregar dados após voltar para atualizar cores
        _carregarDados();
      }
    } catch (e) {
      // Se não encontrar a categoria, vai para a página geral
      if (context.mounted) {
        await _navegarParaCategorias(context, titulo);
        // Recarregar também no fallback
        _carregarDados();
      }
    }
  }
}