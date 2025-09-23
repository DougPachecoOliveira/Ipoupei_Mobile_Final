// 📊 Gráficos de Categoria Widget - iPoupei Mobile
//
// Widget com gráficos de pizza para despesas e receitas por categoria
// Baseado no gráfico da gestão de cartões (gestao_cartoes_mobile.dart)
//
// Design: Dois gráficos lado a lado - Despesas e Receitas

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../services/graficos_categoria_service.dart';

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

  List<Map<String, dynamic>> _despesasPorCategoria = [];
  List<Map<String, dynamic>> _receitasPorCategoria = [];
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

  /// 🔄 Carregar dados dos gráficos
  Future<void> _carregarDados() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.buscarDespesasPorCategoria(widget.dataInicio, widget.dataFim),
        _service.buscarReceitasPorCategoria(widget.dataInicio, widget.dataFim),
      ]);

      setState(() {
        _despesasPorCategoria = results[0];
        _receitasPorCategoria = results[1];
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icone,
                    color: cor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gráfico + Legenda
            Row(
              children: [
                // Gráfico de pizza
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      _buildPieChartData(dados),
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
                      for (final categoria in dados.take(6))
                        Builder(
                          builder: (context) {
                            final cores = _getCoresGrafico();
                            final index = dados.indexOf(categoria);
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
                                          categoria['categoria'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          CurrencyFormatter.format(categoria['total_valor'] ?? 0.0),
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
                          },
                        ),
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

  /// 🎨 Cores para o gráfico
  List<Color> _getCoresGrafico() {
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

  /// 📊 Dados do gráfico de pizza
  PieChartData _buildPieChartData(List<Map<String, dynamic>> dados) {
    final cores = _getCoresGrafico();
    final total = dados.fold(0.0, (sum, cat) => sum + (cat['total_valor'] ?? 0.0));

    if (total == 0) {
      return PieChartData(sections: []);
    }

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: dados.take(6).map((categoria) {
        final index = dados.indexOf(categoria);
        final cor = cores[index % cores.length];
        final valor = (categoria['total_valor'] ?? 0.0).toDouble();
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
}