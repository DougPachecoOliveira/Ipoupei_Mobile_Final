// ⏳ Loading Overlay - iPoupei Mobile (Atualizado)
//
// Wrapper para compatibilidade com sistema novo de loading
// Redireciona para IPoupeiProcessingOverlay com design moderno
//
// DEPRECATED: Use IPoupeiProcessingOverlay diretamente

import 'package:flutter/material.dart';
import '../../../shared/components/loading/ipoupei_loading_system.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? color;
  final IconData? icon;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Mapeia contexto baseado na cor ou ícone
    IPoupeiLoadingContext loadingContext;

    if (color != null) {
      // Mapeia cor para contexto apropriado
      if (color == Colors.green || color == const Color(0xFF4CAF50)) {
        loadingContext = IPoupeiLoadingContext.saving;
      } else if (color == Colors.orange || color == const Color(0xFFFF9800)) {
        loadingContext = IPoupeiLoadingContext.processing;
      } else if (color == Colors.red || color == const Color(0xFFF44336)) {
        loadingContext = IPoupeiLoadingContext.error;
      } else {
        loadingContext = IPoupeiLoadingContext.defaultState;
      }
    } else if (icon != null) {
      // Mapeia ícone para contexto apropriado
      if (icon == Icons.save || icon == Icons.check_circle) {
        loadingContext = IPoupeiLoadingContext.saving;
      } else if (icon == Icons.sync || icon == Icons.cloud_sync) {
        loadingContext = IPoupeiLoadingContext.sync;
      } else if (icon == Icons.error_outline) {
        loadingContext = IPoupeiLoadingContext.error;
      } else {
        loadingContext = IPoupeiLoadingContext.processing;
      }
    } else {
      loadingContext = IPoupeiLoadingContext.defaultState;
    }

    // Usa o novo sistema de loading
    return IPoupeiProcessingOverlay(
      isProcessing: isLoading,
      message: message,
      context: loadingContext,
      child: child,
    );
  }
}