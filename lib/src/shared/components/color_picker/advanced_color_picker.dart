// lib/src/shared/components/color_picker/advanced_color_picker.dart
import 'package:flutter/material.dart';
import 'models/color_picker_config.dart';
import 'models/app_color_item.dart';
import 'widgets/color_gradient_picker.dart';
import 'widgets/color_search_field.dart';
import 'widgets/color_preview_card.dart';

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
    // Usar sempre as cores do config, que já carregam todas as cores da paleta
    _allColors = widget.config.availableColors;
    _filteredColors = _allColors;
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

        // Campo de busca
        if (widget.config.showSearch)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ColorSearchField(
              onSearchChanged: _onSearchChanged,
            ),
          ),

        // Seletor de cores contínuo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Gradiente principal
                Expanded(
                  flex: 3,
                  child: ColorGradientPicker(
                    selectedColor: _selectedColor,
                    onColorSelected: _onColorTap,
                    height: double.infinity,
                  ),
                ),

                const SizedBox(height: 16),

                // Lista horizontal de cores filtradas (se há busca)
                if (_searchQuery.isNotEmpty && _filteredColors.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: ColorStripPicker(
                      colors: _filteredColors,
                      selectedColor: _selectedColor,
                      onColorSelected: _onColorTap,
                    ),
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
}