// 🤖 Auto Categorization Button - iPoupei Mobile
//
// Botão inteligente para auto-categorizar transações baseado em:
// - Palavras-chave na descrição
// - Histórico de transações similares
// - Padrões conhecidos (Uber, iFood, etc.)
//
// Visual: Botão brilhante com animação de pulso

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

class AutoCategorizationButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isProcessing;
  final int totalTransacoes;
  final int categorizadasCount;

  const AutoCategorizationButton({
    super.key,
    required this.onPressed,
    this.isProcessing = false,
    required this.totalTransacoes,
    this.categorizadasCount = 0,
  });

  @override
  State<AutoCategorizationButton> createState() => _AutoCategorizationButtonState();
}

class _AutoCategorizationButtonState extends State<AutoCategorizationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faltamCategorizar = widget.totalTransacoes - widget.categorizadasCount;
    final mostrarBotao = faltamCategorizar > 0;

    if (!mostrarBotao) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isProcessing ? 1.0 : _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withAlpha(234),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(156),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.azulHeader.withAlpha(78),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isProcessing ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isProcessing) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.azulHeader),
                          ),
                        ),
                      ] else ...[
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppColors.azulHeader,
                              AppColors.tealPrimary,
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isProcessing
                                ? 'Categorizando...'
                                : 'Categorizar Automaticamente',
                            style: TextStyle(
                              color: AppColors.azulHeader,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (!widget.isProcessing && faltamCategorizar > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$faltamCategorizar transação(ões) sem categoria',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
