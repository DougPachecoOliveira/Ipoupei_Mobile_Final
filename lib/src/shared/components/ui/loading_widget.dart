import 'package:flutter/material.dart';
import '../../../modules/shared/theme/app_colors.dart';

/// Widget de carregamento padrão do iPoupei
/// Arquivo: lib/shared/components/ui/loading_widget.dart
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool showBackground;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? AppColors.tealPrimary;

    final loadingContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
            strokeWidth: 3.0,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: loadingContent,
      );
    }

    return loadingContent;
  }
}

/// Widget de carregamento para cards
class CardLoadingWidget extends StatelessWidget {
  const CardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingWidget(size: 24),
          SizedBox(height: 8),
          Text(
            'Carregando...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cinzaLegenda,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carregamento para tela inteira
class FullScreenLoadingWidget extends StatelessWidget {
  final String? message;

  const FullScreenLoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      body: Center(
        child: LoadingWidget(
          message: message ?? 'Carregando dados...',
          showBackground: true,
        ),
      ),
    );
  }
}