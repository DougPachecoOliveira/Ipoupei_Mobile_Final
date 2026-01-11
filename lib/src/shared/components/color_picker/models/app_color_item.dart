// lib/src/shared/components/color_picker/models/app_color_item.dart
import 'package:flutter/material.dart';

/// Modelo de cor com metadata para uso no seletor universal
class AppColorItem {
  final String name;
  final String hexValue;
  final String category;
  final bool isLightColor;
  final double contrastRatio;
  final List<String> tags; // Para busca

  const AppColorItem({
    required this.name,
    required this.hexValue,
    required this.category,
    required this.isLightColor,
    required this.contrastRatio,
    this.tags = const [],
  });

  /// Verifica se a cor tem contraste adequado para texto branco
  bool get hasGoodContrastForWhiteText => contrastRatio >= 4.5; // WCAG AA

  /// Verifica se a cor é adequada para uso na aplicação
  bool get isUsableColor => hasGoodContrastForWhiteText && !isLightColor;

  /// Busca por nome ou tags
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
           category.toLowerCase().contains(lowerQuery);
  }

  /// Converte hex para Color do Flutter
  Color get color {
    final buffer = StringBuffer();
    if (hexValue.length == 6 || hexValue.length == 7) buffer.write('ff');
    buffer.write(hexValue.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppColorItem &&
          runtimeType == other.runtimeType &&
          hexValue == other.hexValue;

  @override
  int get hashCode => hexValue.hashCode;

  @override
  String toString() => 'AppColorItem(name: $name, hex: $hexValue, category: $category)';
}