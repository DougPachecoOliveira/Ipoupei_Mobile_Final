// lib/src/shared/components/color_picker/widgets/color_grid_widget.dart
import 'package:flutter/material.dart';
import '../models/app_color_item.dart';

/// Widget de grid para exibir as cores
class ColorGridWidget extends StatelessWidget {
  final List<AppColorItem> colors;
  final AppColorItem? selectedColor;
  final Function(AppColorItem) onColorTap;

  const ColorGridWidget({
    Key? key,
    required this.colors,
    required this.onColorTap,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma cor encontrada',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar sua busca',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 colunas para melhor visualização
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = selectedColor?.hexValue == color.hexValue;

        return _ColorGridItem(
          color: color,
          isSelected: isSelected,
          onTap: () => onColorTap(color),
        );
      },
    );
  }
}

/// Item individual do grid de cores
class _ColorGridItem extends StatefulWidget {
  final AppColorItem color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorGridItem({
    Key? key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ColorGridItem> createState() => _ColorGridItemState();
}

class _ColorGridItemState extends State<_ColorGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color.color,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: widget.color.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  else if (_isPressed)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Ícone de seleção
                  if (widget.isSelected)
                    const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                  // Informações da cor (aparecem no hover ou long press)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: widget.color.name,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}