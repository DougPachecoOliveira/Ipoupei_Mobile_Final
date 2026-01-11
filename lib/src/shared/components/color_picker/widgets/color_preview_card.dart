// lib/src/shared/components/color_picker/widgets/color_preview_card.dart
import 'package:flutter/material.dart';
import '../models/app_color_item.dart';
import '../models/color_picker_config.dart';

/// Widget de preview da cor selecionada
class ColorPreviewCard extends StatelessWidget {
  final AppColorItem color;
  final ColorPickerType type;

  const ColorPreviewCard({
    Key? key,
    required this.color,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview visual da cor
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _getPreviewContent(),
            ),
          ),

          const SizedBox(width: 16),

          // Informações da cor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  color.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  color.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildContrastInfo(),
              ],
            ),
          ),

          // Código hex
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              color.hexValue.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPreviewContent() {
    switch (type) {
      case ColorPickerType.card:
        return const Icon(
          Icons.credit_card,
          color: Colors.white,
          size: 24,
        );
      case ColorPickerType.account:
        return const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 24,
        );
      case ColorPickerType.category:
        return const Icon(
          Icons.category,
          color: Colors.white,
          size: 24,
        );
      case ColorPickerType.theme:
        return const Icon(
          Icons.palette,
          color: Colors.white,
          size: 24,
        );
    }
  }

  Widget _buildContrastInfo() {
    return Row(
      children: [
        Icon(
          Icons.visibility,
          size: 14,
          color: color.hasGoodContrastForWhiteText ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          color.hasGoodContrastForWhiteText
              ? 'Ótimo contraste'
              : 'Contraste moderado',
          style: TextStyle(
            fontSize: 11,
            color: color.hasGoodContrastForWhiteText ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${color.contrastRatio.toStringAsFixed(1)}:1',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}