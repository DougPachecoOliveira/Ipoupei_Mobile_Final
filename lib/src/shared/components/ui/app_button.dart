// 🎨 App Button - iPoupei Mobile
// 
// Sistema unificado de botões adaptado do projeto device
// Compatível com a arquitetura mobile existente
// 
// Features:
// - 5 variantes: Primary, Secondary, Outline, Text, Danger
// - 3 tamanhos: Small, Medium, Large
// - Estados: Loading, disabled, enabled
// - Ícones integrados com espaçamento automático
// - Cores customizáveis e contextuais

import 'package:flutter/material.dart';
import '../../../modules/shared/theme/app_colors.dart';
import '../../../modules/shared/theme/responsive_sizes.dart';
import '../../../modules/shared/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }
enum AppButtonSize { small, medium, large }

/// Botão unificado do app com design consistente
/// Substitui ElevatedButton, OutlinedButton e TextButton
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color? customColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.backgroundColor,
    this.padding,
  });

  // Factories para uso comum
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.backgroundColor,
    this.padding,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.backgroundColor,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.backgroundColor,
    this.padding,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.backgroundColor,
    this.padding,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.backgroundColor,
    this.padding,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final height = _getHeight(context);
    final child = _buildChild(context);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: variant == AppButtonVariant.text
          ? TextButton(
              onPressed: isLoading ? null : onPressed,
              onLongPress: onLongPress,
              style: buttonStyle,
              child: child,
            )
          : variant == AppButtonVariant.outline
              ? OutlinedButton(
                  onPressed: isLoading ? null : onPressed,
                  onLongPress: onLongPress,
                  style: buttonStyle,
                  child: child,
                )
              : ElevatedButton(
                  onPressed: isLoading ? null : onPressed,
                  onLongPress: onLongPress,
                  style: buttonStyle,
                  child: child,
                ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final customPadding = padding ?? ResponsiveSizes.actionButtonPadding(context);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? customColor ?? theme.primaryColor,
          foregroundColor: Colors.white,
          overlayColor: (backgroundColor ?? customColor ?? theme.primaryColor).withValues(alpha: 0.1),
          elevation: 2,
          shadowColor: (backgroundColor ?? customColor ?? theme.primaryColor).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: customPadding,
        );
      
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.grey.shade100,
          foregroundColor: Colors.grey.shade800,
          overlayColor: Colors.grey.shade200,
          elevation: 1,
          shadowColor: Colors.grey.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: customPadding,
        );
      
      case AppButtonVariant.outline:
        return OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: customColor ?? theme.primaryColor,
          side: BorderSide(color: customColor ?? theme.primaryColor, width: 1.5),
          overlayColor: (customColor ?? theme.primaryColor).withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: customPadding,
        );
      
      case AppButtonVariant.text:
        return TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: customColor ?? theme.primaryColor,
          overlayColor: (customColor ?? theme.primaryColor).withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: customPadding,
        );
      
      case AppButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.red.shade600,
          foregroundColor: Colors.white,
          overlayColor: Colors.red.withValues(alpha: 0.1),
          elevation: 2,
          shadowColor: Colors.red.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: customPadding,
        );
    }
  }

  double _getHeight(BuildContext context) {
    switch (size) {
      case AppButtonSize.small:
        return ResponsiveSizes.actionButtonHeight(context, base: 32);
      case AppButtonSize.medium:
        return ResponsiveSizes.actionButtonHeight(context, base: 38);
      case AppButtonSize.large:
        return ResponsiveSizes.actionButtonHeight(context, base: 44);
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    // Usar tipografia responsiva - mesmo padrão do AppBar
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
        return AppTypography.actionButton(context);
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return AppTypography.actionButtonSecondary(context);
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: ResponsiveSizes.actionButtonIconSize(context, base: 16),
        width: ResponsiveSizes.actionButtonIconSize(context, base: 16),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.outline || variant == AppButtonVariant.text
                ? (customColor ?? Colors.blue)
                : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveSizes.actionButtonIconSize(context, base: 17),
          ),
          const SizedBox(width: 8),
          Text(text, style: _getTextStyle(context)),
        ],
      );
    }

    return Text(text, style: _getTextStyle(context));
  }
}

// Extensões para cores contextuais específicas do app
extension AppButtonExtensions on AppButton {
  // Botões contextuais para transações
  static AppButton receita({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      customColor: AppColors.tealPrimary,
    );
  }

  static AppButton despesa({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      customColor: Colors.red.shade600,
    );
  }

  static AppButton transferencia({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      customColor: Colors.blue.shade600,
    );
  }

  static AppButton cartao({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      customColor: Colors.purple.shade600,
    );
  }
}