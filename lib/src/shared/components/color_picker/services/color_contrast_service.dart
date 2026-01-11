// lib/src/shared/components/color_picker/services/color_contrast_service.dart
import 'package:flutter/material.dart';
import '../models/app_color_item.dart';
import '../../../../modules/shared/theme/cartao_color_palette.dart';

/// Serviço para validação de contraste de cores
class ColorContrastService {

  /// Calcula o contraste entre duas cores usando algoritmo WCAG
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calcula a luminância relativa de uma cor
  static double _calculateLuminance(Color color) {
    final r = _calculateComponentLuminance((color.r * 255.0).round() / 255.0);
    final g = _calculateComponentLuminance((color.g * 255.0).round() / 255.0);
    final b = _calculateComponentLuminance((color.b * 255.0).round() / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calcula a luminância de um componente RGB
  static double _calculateComponentLuminance(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return ((component + 0.055) / 1.055) * ((component + 0.055) / 1.055);
    }
  }

  /// Verifica se uma cor é considerada clara
  static bool isColorLight(String hexColor) {
    return CartaoColorPalette.isColorLight(hexColor);
  }

  /// Verifica se uma cor tem contraste adequado para texto branco
  static bool hasGoodContrastForWhiteText(String hexColor) {
    final color = CartaoColorPalette.hexToColor(hexColor);
    final whiteColor = Colors.white;
    final contrast = calculateContrastRatio(color, whiteColor);
    return contrast >= 4.5; // WCAG AA standard
  }

  /// Converte as cores do CartaoColorPalette para AppColorItem com validação
  static List<AppColorItem> convertPaletteToColorItems() {
    final List<AppColorItem> validColors = [];

    // Processar cada categoria da paleta
    final categories = {
      'Vermelhos': CartaoColorPalette.vermelhos,
      'Rosas': CartaoColorPalette.rosas,
      'Laranjas': CartaoColorPalette.laranjas,
      'Amarelos': CartaoColorPalette.amarelos,
      'Verdes': CartaoColorPalette.verdes,
      'Azuis': CartaoColorPalette.azuis,
      'Roxos': CartaoColorPalette.roxos,
      'Neutros': CartaoColorPalette.neutros,
      'Especiais': CartaoColorPalette.especiais,
    };

    for (final categoryEntry in categories.entries) {
      final categoryName = categoryEntry.key;
      final categoryColors = categoryEntry.value;

      for (final colorEntry in categoryColors.entries) {
        final colorName = colorEntry.key;
        final hexValue = colorEntry.value;

        // Verificar contraste
        final isLight = isColorLight(hexValue);
        final hasGoodContrast = hasGoodContrastForWhiteText(hexValue);

        // Só adicionar cores com bom contraste
        if (hasGoodContrast && !isLight) {
          final color = CartaoColorPalette.hexToColor(hexValue);
          final contrastRatio = calculateContrastRatio(color, Colors.white);

          // Gerar tags para busca
          final tags = _generateSearchTags(colorName, categoryName);

          validColors.add(AppColorItem(
            name: colorName,
            hexValue: hexValue,
            category: categoryName,
            isLightColor: isLight,
            contrastRatio: contrastRatio,
            tags: tags,
          ));
        }
      }
    }

    return validColors;
  }

  /// Gera tags de busca para uma cor
  static List<String> _generateSearchTags(String colorName, String category) {
    final tags = <String>[];

    // Tag da categoria
    tags.add(category.toLowerCase());

    // Tags baseadas no nome da cor
    final nameParts = colorName.toLowerCase().split(' ');
    tags.addAll(nameParts);

    // Tags específicas para bancos
    if (colorName.toLowerCase().contains('nubank')) {
      tags.addAll(['nubank', 'roxo', 'banco']);
    }
    if (colorName.toLowerCase().contains('santander')) {
      tags.addAll(['santander', 'vermelho', 'banco']);
    }
    if (colorName.toLowerCase().contains('bradesco')) {
      tags.addAll(['bradesco', 'vermelho', 'banco']);
    }
    if (colorName.toLowerCase().contains('itau') || colorName.toLowerCase().contains('itaú')) {
      tags.addAll(['itau', 'itaú', 'laranja', 'banco']);
    }

    // Tags semânticas
    if (category == 'Verdes') {
      tags.addAll(['natureza', 'dinheiro', 'sucesso']);
    }
    if (category == 'Vermelhos') {
      tags.addAll(['energia', 'atenção', 'importante']);
    }
    if (category == 'Azuis') {
      tags.addAll(['confiança', 'calma', 'profissional']);
    }
    if (category == 'Neutros') {
      tags.addAll(['elegante', 'sóbrio', 'clássico']);
    }

    return tags.toSet().toList(); // Remove duplicatas
  }

  /// Filtra cores por categoria
  static List<AppColorItem> filterByCategory(
    List<AppColorItem> colors,
    String category
  ) {
    return colors.where((color) => color.category == category).toList();
  }

  /// Filtra cores por busca
  static List<AppColorItem> filterBySearch(
    List<AppColorItem> colors,
    String query
  ) {
    if (query.isEmpty) return colors;

    return colors.where((color) => color.matchesSearch(query)).toList();
  }

  /// Sugere cores baseadas no nome do banco
  static List<AppColorItem> suggestColorsForBank(
    List<AppColorItem> colors,
    String bankName
  ) {
    final suggestions = <AppColorItem>[];
    final bankLower = bankName.toLowerCase();

    // Buscar cores que tenham o banco nas tags
    for (final color in colors) {
      if (color.tags.any((tag) => tag.contains(bankLower))) {
        suggestions.add(color);
      }
    }

    // Se não encontrou, sugerir cores baseadas em mapeamento conhecido
    if (suggestions.isEmpty) {
      final bankColorMapping = {
        'nubank': '#8A05BE',
        'santander': '#EC0000',
        'bradesco': '#CC092F',
        'itau': '#EC7000',
        'itaú': '#EC7000',
        'banco do brasil': '#FFF100', // Amarelo muito claro - será filtrado
        'caixa': '#0066B3',
        'inter': '#FF6500',
        'c6': '#FFD700', // Amarelo - será filtrado
        'picpay': '#21C25E',
      };

      final suggestedHex = bankColorMapping[bankLower];
      if (suggestedHex != null) {
        final suggestedColor = colors.firstWhere(
          (color) => color.hexValue == suggestedHex,
          orElse: () => colors.first,
        );
        suggestions.add(suggestedColor);
      }
    }

    return suggestions;
  }
}