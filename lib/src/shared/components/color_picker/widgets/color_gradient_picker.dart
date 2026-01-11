// lib/src/shared/components/color_picker/widgets/color_gradient_picker.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/app_color_item.dart';
import '../services/color_contrast_service.dart';

/// Widget de seletor de cores contínuo com gradiente
class ColorGradientPicker extends StatefulWidget {
  final AppColorItem? selectedColor;
  final Function(AppColorItem) onColorSelected;
  final double height;

  const ColorGradientPicker({
    Key? key,
    required this.onColorSelected,
    this.selectedColor,
    this.height = 200,
  }) : super(key: key);

  @override
  State<ColorGradientPicker> createState() => _ColorGradientPickerState();
}

class _ColorGradientPickerState extends State<ColorGradientPicker> {
  late List<AppColorItem> _availableColors;
  Offset? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadColors();
  }

  void _loadColors() {
    // Carregar todas as cores e filtrar apenas as escuras
    final allColors = ColorContrastService.convertPaletteToColorItems();

    // Filtrar tons muito claros e organizar por matiz
    _availableColors = allColors.where((color) {
      // Calcular luminosidade para filtrar cores muito claras
      final c = color.color;
      final luminance = (0.299 * c.red + 0.587 * c.green + 0.114 * c.blue) / 255;
      return luminance < 0.7 && color.hasGoodContrastForWhiteText; // Apenas cores escuras/médias
    }).toList();

    // Ordenar por matiz para criar transição suave
    _availableColors.sort((a, b) => _getHue(a.color).compareTo(_getHue(b.color)));
  }

  /// Calcula o matiz (hue) de uma cor para ordenação
  double _getHue(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final diff = max - min;

    if (diff == 0) return 0;

    double hue;
    if (max == r) {
      hue = (60 * ((g - b) / diff) + 360) % 360;
    } else if (max == g) {
      hue = (60 * ((b - r) / diff) + 120) % 360;
    } else {
      hue = (60 * ((r - g) / diff) + 240) % 360;
    }

    return hue;
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final localPosition = details.localPosition;
    final normalizedX = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);

    // Calcular índice da cor baseado na posição X
    final colorIndex = (normalizedX * (_availableColors.length - 1)).round();
    final selectedColor = _availableColors[colorIndex];

    setState(() {
      _selectedPosition = localPosition;
    });

    widget.onColorSelected(selectedColor);
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    _onPanUpdate(
      DragUpdateDetails(
        localPosition: details.localPosition,
        globalPosition: details.globalPosition,
        delta: Offset.zero,
      ),
      constraints,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (details) => _onTapDown(details, constraints),
              onPanUpdate: (details) => _onPanUpdate(details, constraints),
              child: Stack(
                children: [
                  // Gradiente principal com todas as cores
                  _buildColorGradient(),

                  // Gradiente vertical para criar variações de saturação/brilho
                  _buildSaturationOverlay(),

                  // Indicador de seleção
                  if (_selectedPosition != null)
                    _buildSelectionIndicator(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildColorGradient() {
    final colors = _generateGradientColors();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          stops: _generateGradientStops(colors.length),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildSaturationOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black26,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Positioned(
      left: _selectedPosition!.dx - 12,
      top: _selectedPosition!.dy - 12,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _generateGradientColors() {
    // Gerar um espectro suave de cores baseado nas cores disponíveis
    if (_availableColors.isEmpty) return [Colors.grey];

    final List<Color> gradientColors = [];

    // Adicionar cores em intervalos regulares para criar transição suave
    final step = _availableColors.length / 12; // ~12 cores principais no gradiente

    for (int i = 0; i < 12; i++) {
      final index = (i * step).round().clamp(0, _availableColors.length - 1);
      gradientColors.add(_availableColors[index].color);
    }

    return gradientColors;
  }

  List<double> _generateGradientStops(int colorCount) {
    return List.generate(colorCount, (index) => index / (colorCount - 1));
  }
}

/// Widget simplificado para mostrar cores em linha horizontal
class ColorStripPicker extends StatelessWidget {
  final List<AppColorItem> colors;
  final AppColorItem? selectedColor;
  final Function(AppColorItem) onColorSelected;

  const ColorStripPicker({
    Key? key,
    required this.colors,
    required this.onColorSelected,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = selectedColor?.hexValue == color.hexValue;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color.color,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: Colors.black.withValues(alpha: 0.1)),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}