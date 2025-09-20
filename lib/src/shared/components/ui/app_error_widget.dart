import 'package:flutter/material.dart';
import '../../../modules/shared/theme/app_colors.dart';

/// Widget de erro padrão do iPoupei
/// Arquivo: lib/shared/components/ui/app_error_widget.dart
class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool showBackground;

  const AppErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.icon,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ?? Icons.error_outline,
          size: 48,
          color: AppColors.vermelhoErro,
        ),
        const SizedBox(height: 16),
        
        // Título opcional
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.cinzaEscuro,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        
        // Mensagem principal (obrigatória)
        Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.cinzaEscuro,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Detalhes opcionais
        if (details != null) ...[
          const SizedBox(height: 8),
          Text(
            details!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinzaTexto,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        // Botão de retry opcional
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealPrimary,
              foregroundColor: AppColors.branco,
              elevation: 2,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(
              'Tentar Novamente',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );

    // Container com background opcional
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
        child: errorContent,
      );
    }

    return errorContent;
  }
}

/// Widget de erro para cards
class CardErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CardErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 32,
            color: AppColors.vermelhoErro,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.cinzaTexto,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tentar novamente',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de erro para tela inteira
class FullScreenErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const FullScreenErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinzaClaro,
      body: Center(
        child: AppErrorWidget(
          title: title,
          message: message,
          details: details,
          onRetry: onRetry,
          showBackground: true,
        ),
      ),
    );
  }
}