// ⏳ Loading Overlay - iPoupei Mobile
//
// Componente de loading que sobrepõe o conteúdo
// Versão melhorada com cores e ícones contextuais
//
// Baseado em: Material Design + Overlay Pattern

import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? color; // ✨ Cor customizável do loading
  final IconData? icon; // ✨ Ícone contextual opcional

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
    // Cor padrão: azul do tema
    final loadingColor = color ?? Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        child,

        // Overlay de loading
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: loadingColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: loadingColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone contextual (se fornecido)
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: loadingColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: loadingColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // CircularProgressIndicator com cor customizada
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
                      ),
                    ),

                    // Mensagem
                    if (message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        message!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: loadingColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}