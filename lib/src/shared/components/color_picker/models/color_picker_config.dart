// lib/src/shared/components/color_picker/models/color_picker_config.dart
import 'app_color_item.dart';
import '../services/color_contrast_service.dart';

/// Tipos de contexto para o seletor de cores
enum ColorPickerType {
  card,      // Cartões de crédito
  account,   // Contas bancárias
  category,  // Categorias de transação
  theme,     // Temas da aplicação
}

/// Configuração do seletor de cores por contexto
class ColorPickerConfig {
  final ColorPickerType type;
  final String title;
  final String subtitle;
  final List<AppColorItem> availableColors;
  final List<String> featuredCategories;
  final bool showSearch;
  final bool showFavorites;
  final bool showPreview;
  final String? bankSuggestion; // Para sugerir cores baseadas no banco

  const ColorPickerConfig({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.availableColors,
    this.featuredCategories = const [],
    this.showSearch = true,
    this.showFavorites = true,
    this.showPreview = true,
    this.bankSuggestion,
  });

  /// Configuração para cartões de crédito
  static ColorPickerConfig forCard({String? bankName}) {
    return ColorPickerConfig(
      type: ColorPickerType.card,
      title: 'Cor do Cartão',
      subtitle: 'Escolha uma cor para identificar seu cartão',
      availableColors: _getCardColors(),
      featuredCategories: ['Neutros', 'Azuis', 'Vermelhos', 'Especiais'],
      bankSuggestion: bankName,
    );
  }

  /// Configuração para contas bancárias
  static ColorPickerConfig forAccount({String? bankName}) {
    return ColorPickerConfig(
      type: ColorPickerType.account,
      title: 'Cor da Conta',
      subtitle: 'Personalize a cor da sua conta',
      availableColors: _getAccountColors(),
      featuredCategories: ['Azuis', 'Verdes', 'Neutros'],
      bankSuggestion: bankName,
    );
  }

  /// Configuração para categorias
  static ColorPickerConfig forCategory({required String categoryType}) {
    return ColorPickerConfig(
      type: ColorPickerType.category,
      title: 'Cor da Categoria',
      subtitle: 'Facilite a identificação visual',
      availableColors: _getCategoryColors(categoryType),
      featuredCategories: categoryType == 'receita'
          ? ['Verdes', 'Azuis']
          : ['Vermelhos', 'Laranjas'],
      showFavorites: false,
    );
  }

  /// Cores para cartões (todas as cores com bom contraste)
  static List<AppColorItem> _getCardColors() {
    return ColorContrastService.convertPaletteToColorItems();
  }

  /// Cores para contas (todas as cores, priorizando tons corporativos)
  static List<AppColorItem> _getAccountColors() {
    final allColors = ColorContrastService.convertPaletteToColorItems();

    // Reordenar para priorizar cores mais corporativas
    final corporateCategories = ['Azuis', 'Verdes', 'Neutros', 'Roxos'];
    final corporateColors = <AppColorItem>[];
    final otherColors = <AppColorItem>[];

    for (final color in allColors) {
      if (corporateCategories.contains(color.category)) {
        corporateColors.add(color);
      } else {
        otherColors.add(color);
      }
    }

    return [...corporateColors, ...otherColors];
  }

  /// Cores para categorias (filtradas por contexto semântico)
  static List<AppColorItem> _getCategoryColors(String type) {
    final allColors = ColorContrastService.convertPaletteToColorItems();

    if (type == 'receita') {
      // Priorizar verdes para receitas, mas oferecer todas as cores
      final greenColors = allColors.where((c) => c.category == 'Verdes').toList();
      final blueColors = allColors.where((c) => c.category == 'Azuis').toList();
      final otherColors = allColors.where((c) =>
          c.category != 'Verdes' && c.category != 'Azuis').toList();

      return [...greenColors, ...blueColors, ...otherColors];
    } else {
      // Priorizar vermelhos e laranjas para despesas, mas oferecer todas as cores
      final redColors = allColors.where((c) => c.category == 'Vermelhos').toList();
      final orangeColors = allColors.where((c) => c.category == 'Laranjas').toList();
      final otherColors = allColors.where((c) =>
          c.category != 'Vermelhos' && c.category != 'Laranjas').toList();

      return [...redColors, ...orangeColors, ...otherColors];
    }
  }
}