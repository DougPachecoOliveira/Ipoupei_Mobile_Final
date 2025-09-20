// lib/modules/categorias/components/categoria_icon_widget.dart
import 'package:flutter/material.dart';
import '../data/categoria_icons.dart';

/// Widget reutilizável para exibir ícone de categoria
/// Segue o padrão visual do CategoriaCard com quadradinho arredondado
class CategoriaIconWidget extends StatelessWidget {
  final Map<String, dynamic> categoria;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool showShadow;

  const CategoriaIconWidget({
    super.key,
    required this.categoria,
    this.size = 32,
    this.iconSize = 18,
    this.borderRadius = 8,
    this.showShadow = true,
  });

  Color _getCorCategoria() {
    try {
      final cor = categoria['cor'] as String;
      return Color(int.parse(cor.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF008080); // Fallback teal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getCorCategoria(),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow ? const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: CategoriaIcons.renderIcon(
          categoria['icone'],
          iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}