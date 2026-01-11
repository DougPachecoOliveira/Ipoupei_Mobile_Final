
import 'lib/src/shared/components/color_picker/services/color_contrast_service.dart';

void main() {
  final colors = ColorContrastService.convertPaletteToColorItems();
  final categories = <String, int>{};
  
  for (final color in colors) {
    categories[color.category] = (categories[color.category] ?? 0) + 1;
  }
  
  print('Total de cores: ${colors.length}');
  print('Cores por categoria:');
  for (final entry in categories.entries) {
    print('${entry.key}: ${entry.value} cores');
  }
}

