// 📊 Interactive Pie Chart - iPoupei Mobile
//
// Componente reutilizável de gráfico de pizza interativo
// Com efeitos visuais, navegação por toque e customização completa
//
// Features:
// - Efeitos visuais ao tocar (crescimento, borda, transparência)
// - Navegação customizável por callback
// - Texto central personalizado
// - Cores e estilos configuráveis
// - Suporte a diferentes tipos de dados

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Modelo de dados para o gráfico de pizza
class PieChartDataItem {
  final String label;
  final double value;
  final Color color;
  final dynamic data; // Dados extras para callbacks

  PieChartDataItem({
    required this.label,
    required this.value,
    required this.color,
    this.data,
  });
}

/// Configuração de estilo do gráfico
class PieChartStyle {
  final double radius;
  final double touchedRadius;
  final double centerSpaceRadius;
  final double sectionsSpace;
  final TextStyle? titleStyle;
  final TextStyle? touchedTitleStyle;
  final bool showBorderOnTouch;
  final Color borderColor;
  final double borderWidth;

  const PieChartStyle({
    this.radius = 60,
    this.touchedRadius = 70,
    this.centerSpaceRadius = 50,
    this.sectionsSpace = 2,
    this.titleStyle,
    this.touchedTitleStyle,
    this.showBorderOnTouch = true,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });
}

/// Widget de gráfico de pizza interativo reutilizável
class InteractivePieChart extends StatefulWidget {
  final List<PieChartDataItem> data;
  final String? centerTitle;
  final String? centerSubtitle;
  final Color? centerTitleColor;
  final Color? centerSubtitleColor;
  final PieChartStyle style;
  final Function(PieChartDataItem item)? onTap;
  final double height;
  final bool showPercentages;

  const InteractivePieChart({
    super.key,
    required this.data,
    this.centerTitle,
    this.centerSubtitle,
    this.centerTitleColor,
    this.centerSubtitleColor,
    this.style = const PieChartStyle(),
    this.onTap,
    this.height = 200,
    this.showPercentages = true,
  });

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final total = widget.data.fold(0.0, (sum, item) => sum + item.value);

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: widget.style.sectionsSpace,
              centerSpaceRadius: widget.style.centerSpaceRadius,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });

                  if (event is FlTapUpEvent &&
                      pieTouchResponse?.touchedSection != null &&
                      widget.onTap != null) {
                    final sectionIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    if (sectionIndex >= 0 && sectionIndex < widget.data.length) {
                      widget.onTap!(widget.data[sectionIndex]);
                    }
                  }
                },
                enabled: true,
              ),
              sections: _buildSections(total),
            ),
          ),

          // Texto central (não clicável)
          if (widget.centerTitle != null || widget.centerSubtitle != null)
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.centerTitle != null)
                    Text(
                      widget.centerTitle!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.centerTitleColor ?? Colors.black87,
                      ),
                    ),
                  if (widget.centerSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.centerSubtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: widget.centerSubtitleColor ?? Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;
      final percentual = total > 0 ? (item.value / total) * 100 : 0;

      return PieChartSectionData(
        color: isTouched ? item.color.withAlpha(204) : item.color,
        value: item.value,
        title: widget.showPercentages ? '${percentual.toStringAsFixed(1)}%' : '',
        radius: isTouched ? widget.style.touchedRadius : widget.style.radius,
        titleStyle: _getTitleStyle(isTouched),
        borderSide: BorderSide(
          color: isTouched && widget.style.showBorderOnTouch
              ? widget.style.borderColor
              : Colors.transparent,
          width: isTouched ? widget.style.borderWidth : 0,
        ),
      );
    }).toList();
  }

  TextStyle _getTitleStyle(bool isTouched) {
    if (isTouched && widget.style.touchedTitleStyle != null) {
      return widget.style.touchedTitleStyle!;
    }

    if (widget.style.titleStyle != null) {
      return widget.style.titleStyle!;
    }

    // Estilo padrão
    return TextStyle(
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
    );
  }
}

/// Widget de gráfico com legenda lateral (combinação completa)
class InteractivePieChartWithLegend extends StatelessWidget {
  final List<PieChartDataItem> data;
  final String? centerTitle;
  final String? centerSubtitle;
  final Color? centerTitleColor;
  final Color? centerSubtitleColor;
  final PieChartStyle style;
  final Function(PieChartDataItem item)? onTap;
  final Function(PieChartDataItem item)? onLegendTap;
  final double height;
  final bool showPercentages;
  final String Function(double)? valueFormatter;

  const InteractivePieChartWithLegend({
    super.key,
    required this.data,
    this.centerTitle,
    this.centerSubtitle,
    this.centerTitleColor,
    this.centerSubtitleColor,
    this.style = const PieChartStyle(),
    this.onTap,
    this.onLegendTap,
    this.height = 200,
    this.showPercentages = true,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gráfico
        Expanded(
          flex: 2,
          child: InteractivePieChart(
            data: data,
            centerTitle: centerTitle,
            centerSubtitle: centerSubtitle,
            centerTitleColor: centerTitleColor,
            centerSubtitleColor: centerSubtitleColor,
            style: style,
            onTap: onTap,
            height: height,
            showPercentages: showPercentages,
          ),
        ),

        const SizedBox(width: 20),

        // Legenda
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.take(6).map((item) => _buildLegendItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(PieChartDataItem item) {
    return GestureDetector(
      onTap: onLegendTap != null ? () => onLegendTap!(item) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    valueFormatter?.call(item.value) ?? item.value.toStringAsFixed(2),
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
  }
}