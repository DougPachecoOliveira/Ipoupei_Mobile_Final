import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

/// Botão com gradiente reutilizável
/// Usado em páginas de ação como salvar, confirmar, etc.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color startColor;
  final Color endColor;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.startColor = AppColors.verdeSucesso,
    this.endColor = AppColors.tealPrimary,
    this.icon,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  /// Construtor para botão de sucesso (verde)
  const GradientButton.success({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : startColor = AppColors.verdeSucesso,
       endColor = AppColors.tealPrimary;

  /// Construtor para botão de erro (vermelho)
  const GradientButton.error({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : startColor = AppColors.vermelhoErro,
       endColor = const Color(0xFFE53E3E);

  /// Construtor para botão de informação (azul)
  const GradientButton.info({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : startColor = AppColors.azul,
       endColor = AppColors.roxoPrimario;

  /// Construtor para botão de aviso (laranja/amarelo)
  const GradientButton.warning({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : startColor = AppColors.amareloAlerta,
       endColor = const Color(0xFFFF8C00);

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled
          ? LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : LinearGradient(
              colors: [
                AppColors.cinzaMedio,
                AppColors.cinzaMedio.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding,
            child: Center(
              child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão outline com gradiente na borda
class OutlineGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color startColor;
  final Color endColor;
  final IconData? icon;
  final double? width;
  final double height;

  const OutlineGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.startColor = AppColors.azul,
    this.endColor = AppColors.roxoPrimario,
    this.icon,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled
          ? LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: startColor,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: isEnabled ? startColor : AppColors.cinzaMedio,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: isEnabled ? startColor : AppColors.cinzaMedio,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}