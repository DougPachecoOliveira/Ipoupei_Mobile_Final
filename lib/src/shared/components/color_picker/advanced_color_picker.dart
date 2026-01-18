// lib/src/shared/components/color_picker/advanced_color_picker.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models/color_picker_config.dart';
import 'models/app_color_item.dart';
import 'widgets/color_2d_matrix.dart';
import 'widgets/color_search_field.dart';
import 'widgets/color_preview_card.dart';
import 'models/color_matrix_data.dart';

/// Seletor de cores universal e reutilizável
class AdvancedColorPicker extends StatefulWidget {
  final ColorPickerConfig config;
  final String? currentColor;
  final Function(String hexColor) onColorSelected;

  const AdvancedColorPicker({
    Key? key,
    required this.config,
    required this.onColorSelected,
    this.currentColor,
  }) : super(key: key);

  /// Método estático para mostrar o modal
  static Future<String?> show({
    required BuildContext context,
    required ColorPickerType type,
    String? currentColor,
    String? bankName,
    String? categoryType,
  }) {
    late ColorPickerConfig config;

    switch (type) {
      case ColorPickerType.card:
        config = ColorPickerConfig.forCard(bankName: bankName);
        break;
      case ColorPickerType.account:
        config = ColorPickerConfig.forAccount(bankName: bankName);
        break;
      case ColorPickerType.category:
        config = ColorPickerConfig.forCategory(categoryType: categoryType ?? 'despesa');
        break;
      case ColorPickerType.theme:
        // Implementar futuramente
        config = ColorPickerConfig.forCard();
        break;
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AdvancedColorPicker(
            config: config,
            currentColor: currentColor,
            onColorSelected: (color) {
              Navigator.of(context).pop(color);
            },
          ),
        ),
      ),
    );
  }

  @override
  State<AdvancedColorPicker> createState() => _AdvancedColorPickerState();
}

class _AdvancedColorPickerState extends State<AdvancedColorPicker> {
  late List<AppColorItem> _allColors;
  late List<AppColorItem> _filteredColors;
  String _searchQuery = '';
  AppColorItem? _selectedColor;

  @override
  void initState() {
    super.initState();
    _initializeColors();
    _selectInitialColor();
  }

  void _initializeColors() {
    // Converter cores da matriz para AppColorItem
    _allColors = _convertMatrixToAppColorItems();
    _filteredColors = _allColors;
  }

  List<AppColorItem> _convertMatrixToAppColorItems() {
    final List<AppColorItem> colors = [];

    for (int row = 0; row < ColorMatrixData.rowCount; row++) {
      for (int column = 0; column < ColorMatrixData.columnCount; column++) {
        final colorData = ColorMatrixData.getColor(row, column);
        if (colorData != null) {
          colors.add(AppColorItem(
            name: colorData['nome']!,
            hexValue: colorData['hex']!,
            category: ColorMatrixData.hueLabels[column],
            isLightColor: _isLightColor(colorData['hex']!),
            contrastRatio: _calculateContrastRatio(colorData['hex']!),
          ));
        }
      }
    }

    return colors;
  }

  bool _isLightColor(String hexColor) {
    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    final brightness = ((color.r * 255.0).round() * 299 +
                       (color.g * 255.0).round() * 587 +
                       (color.b * 255.0).round() * 114) / 1000;
    return brightness > 186;
  }

  double _calculateContrastRatio(String hexColor) {
    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    final colorLum = _calculateRelativeLuminance(color);
    const whiteLum = 1.0;

    final lighterLum = colorLum > whiteLum ? colorLum : whiteLum;
    final darkerLum = colorLum > whiteLum ? whiteLum : colorLum;

    return (lighterLum + 0.05) / (darkerLum + 0.05);
  }

  double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorChannel(color.r);
    final g = _linearizeColorChannel(color.g);
    final b = _linearizeColorChannel(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _linearizeColorChannel(double channel) {
    if (channel <= 0.04045) {
      return channel / 12.92;
    } else {
      return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  void _selectInitialColor() {
    if (widget.currentColor != null) {
      _selectedColor = _allColors.firstWhere(
        (color) => color.hexValue.toLowerCase() == widget.currentColor!.toLowerCase(),
        orElse: () => _allColors.first,
      );
    }
  }


  void _filterColors() {
    setState(() {
      _filteredColors = _allColors.where((color) {
        final matchesSearch = _searchQuery.isEmpty ||
                             color.matchesSearch(_searchQuery);
        return matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterColors();
    });
  }

  void _onMatrixColorSelected(int row, int column, Map<String, String> colorData) {
    // Encontrar o AppColorItem correspondente
    final selectedAppColor = _allColors.firstWhere(
      (color) => color.hexValue.toLowerCase() == colorData['hex']!.toLowerCase(),
    );

    setState(() {
      _selectedColor = selectedAppColor;
    });
  }

  void _onColorTap(AppColorItem color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _onConfirmSelection() {
    if (_selectedColor != null) {
      widget.onColorSelected(_selectedColor!.hexValue);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle do modal
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.config.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (widget.config.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.config.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
        ),

        // Preview da cor selecionada
        if (_selectedColor != null && widget.config.showPreview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ColorPreviewCard(
              color: _selectedColor!,
              type: widget.config.type,
            ),
          ),



        // Seletor de cores contínuo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Matriz 2D principal
                Expanded(
                  child: _buildColorMatrix(),
                ),
              ],
            ),
          ),
        ),

        // Botão de confirmação
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedColor != null ? _onConfirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor?.color ?? Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _selectedColor != null ? 4 : 0,
              ),
              child: Text(
                _selectedColor != null
                    ? 'Confirmar ${_selectedColor!.name}'
                    : 'Selecione uma cor',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorMatrix() {
    // Converter a cor selecionada de volta para coordenadas da matriz para a seleção visual
    int? selectedRow;
    int? selectedColumn;

    if (_selectedColor != null) {
      // Procurar as coordenadas da cor selecionada na matriz
      for (int row = 0; row < ColorMatrixData.rowCount; row++) {
        for (int column = 0; column < ColorMatrixData.columnCount; column++) {
          final colorData = ColorMatrixData.getColor(row, column);
          if (colorData != null &&
              colorData['hex']!.toLowerCase() == _selectedColor!.hexValue.toLowerCase()) {
            selectedRow = row;
            selectedColumn = column;
            break;
          }
        }
        if (selectedRow != null) break;
      }
    }

    return Color2DMatrix(
      onColorSelected: _onMatrixColorSelected,
      selectedRow: selectedRow,
      selectedColumn: selectedColumn,
      cellSize: 35,
      spacing: 4,
    );
  }

  Widget _buildSearchResults() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredColors.length,
        itemBuilder: (context, index) {
          final color = _filteredColors[index];
          final isSelected = _selectedColor?.hexValue == color.hexValue;

          return GestureDetector(
            onTap: () => _onColorTap(color),
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