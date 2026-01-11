// lib/src/shared/components/color_picker/widgets/color_category_tab.dart
import 'package:flutter/material.dart';

/// Widget de tabs para categorias de cores
class ColorCategoryTab extends StatelessWidget {
  final TabController tabController;
  final List<String> categories;

  const ColorCategoryTab({
    Key? key,
    required this.tabController,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: Colors.blue[600],
        indicatorWeight: 3,
        labelColor: Colors.blue[600],
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: categories.map((category) {
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getCategoryIcon(category),
                  const SizedBox(width: 6),
                  Text(category),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData iconData;
    Color iconColor;

    switch (category.toLowerCase()) {
      case 'vermelhos':
        iconData = Icons.circle;
        iconColor = Colors.red;
        break;
      case 'rosas':
        iconData = Icons.circle;
        iconColor = Colors.pink;
        break;
      case 'laranjas':
        iconData = Icons.circle;
        iconColor = Colors.orange;
        break;
      case 'amarelos':
        iconData = Icons.circle;
        iconColor = Colors.yellow[700]!;
        break;
      case 'verdes':
        iconData = Icons.circle;
        iconColor = Colors.green;
        break;
      case 'azuis':
        iconData = Icons.circle;
        iconColor = Colors.blue;
        break;
      case 'roxos':
        iconData = Icons.circle;
        iconColor = Colors.purple;
        break;
      case 'neutros':
        iconData = Icons.circle;
        iconColor = Colors.grey;
        break;
      case 'especiais':
        iconData = Icons.auto_awesome;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.palette;
        iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      size: 12,
      color: iconColor,
    );
  }
}