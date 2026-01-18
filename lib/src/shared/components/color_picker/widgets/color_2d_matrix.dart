// lib/src/shared/components/color_picker/widgets/color_2d_matrix.dart
import 'package:flutter/material.dart';
import '../models/color_matrix_data.dart';

/// Widget de matriz 2D para seleção de cores
class Color2DMatrix extends StatefulWidget {
  final Function(int row, int column, Map<String, String> colorData) onColorSelected;
  final int? selectedRow;
  final int? selectedColumn;
  final double cellSize;
  final double spacing;

  const Color2DMatrix({
    Key? key,
    required this.onColorSelected,
    this.selectedRow,
    this.selectedColumn,
    this.cellSize = 40.0,
    this.spacing = 4.0,
  }) : super(key: key);

  @override
  State<Color2DMatrix> createState() => _Color2DMatrixState();
}

class _Color2DMatrixState extends State<Color2DMatrix>
    with TickerProviderStateMixin {
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionScaleAnimation;
  int? _hoveredRow;
  int? _hoveredColumn;

  @override
  void initState() {
    super.initState();
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _selectionAnimationController,
      curve: Curves.easeInOut,
    ));

    if (widget.selectedRow != null && widget.selectedColumn != null) {
      _selectionAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(Color2DMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRow != null && widget.selectedColumn != null) {
      if (oldWidget.selectedRow != widget.selectedRow ||
          oldWidget.selectedColumn != widget.selectedColumn) {
        _selectionAnimationController.reset();
        _selectionAnimationController.forward();
      }
    } else {
      _selectionAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _selectionAnimationController.dispose();
    super.dispose();
  }

  void _onCellTap(int row, int column) {
    final colorData = ColorMatrixData.getColor(row, column);
    if (colorData != null) {
      widget.onColorSelected(row, column, colorData);
    }
  }

  void _onCellHover(int? row, int? column) {
    setState(() {
      _hoveredRow = row;
      _hoveredColumn = column;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: _buildMatrix(),
    );
  }

  Widget _buildHueLabels() {
    return Row(
      children: [
        // Espaço para os labels de intensidade
        SizedBox(width: 60),

        // Labels dos matizes
        ...List.generate(ColorMatrixData.columnCount, (column) {
          return Expanded(
            child: Center(
              child: Column(
                children: [
                  Icon(
                    ColorMatrixData.hueIcons[column],
                    color: ColorMatrixData.hueIconColors[column],
                    size: 16,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ColorMatrixData.hueLabels[column],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatrix() {
    return Column(
      children: List.generate(ColorMatrixData.rowCount, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.spacing),
          child: Row(
            children: [
              // Células da linha (sem labels)
              ...List.generate(ColorMatrixData.columnCount, (column) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: column < ColorMatrixData.columnCount - 1 ? widget.spacing : 0),
                    child: _buildColorCell(row, column),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildColorCell(int row, int column) {
    final colorData = ColorMatrixData.getColor(row, column);
    if (colorData == null) return const SizedBox();

    final isSelected = widget.selectedRow == row && widget.selectedColumn == column;
    final isHovered = _hoveredRow == row && _hoveredColumn == column;

    final color = Color(int.parse(colorData['hex']!.replaceAll('#', '0xFF')));

    return MouseRegion(
      onEnter: (_) => _onCellHover(row, column),
      onExit: (_) => _onCellHover(null, null),
      child: GestureDetector(
        onTap: () => _onCellTap(row, column),
        child: AnimatedBuilder(
          animation: _selectionScaleAnimation,
          builder: (context, child) {
            final scale = isSelected ? _selectionScaleAnimation.value : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                height: widget.cellSize,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: _buildBorder(isSelected, isHovered),
                  boxShadow: _buildShadow(isSelected, isHovered, color),
                ),
                child: _buildCellContent(isSelected, isHovered),
              ),
            );
          },
        ),
      ),
    );
  }

  Border? _buildBorder(bool isSelected, bool isHovered) {
    if (isSelected) {
      return Border.all(color: Colors.white, width: 3);
    } else if (isHovered) {
      return Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2);
    }
    return Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1);
  }

  List<BoxShadow> _buildShadow(bool isSelected, bool isHovered, Color color) {
    if (isSelected) {
      return [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isHovered) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  Widget? _buildCellContent(bool isSelected, bool isHovered) {
    if (isSelected) {
      return const Center(
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      );
    } else if (isHovered) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return null;
  }
}

/// Widget de preview da cor selecionada na matriz
class ColorMatrixPreview extends StatelessWidget {
  final int? selectedRow;
  final int? selectedColumn;

  const ColorMatrixPreview({
    Key? key,
    this.selectedRow,
    this.selectedColumn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedRow == null || selectedColumn == null) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text(
            'Selecione uma cor',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final colorData = ColorMatrixData.getColor(selectedRow!, selectedColumn!);
    if (colorData == null) return const SizedBox();

    final color = Color(int.parse(colorData['hex']!.replaceAll('#', '0xFF')));
    final intensityLabel = ColorMatrixData.intensityLabels[selectedRow!];
    final hueLabel = ColorMatrixData.hueLabels[selectedColumn!];

    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview da cor
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Informações da cor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  colorData['nome']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$hueLabel - $intensityLabel',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Código hex
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              colorData['hex']!.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}