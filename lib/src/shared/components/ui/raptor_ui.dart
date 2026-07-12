import 'package:flutter/material.dart';

/// Blocos visuais pequenos e previsíveis usados nas telas financeiras.
/// Eles evitam que cada módulo invente card, vazio e cabeçalho próprios.
class RaptorSurface extends StatelessWidget {
  const RaptorSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: accent == null
          ? null
          : BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: accent!.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
      ),
    );
  }
}

class RaptorSectionTitle extends StatelessWidget {
  const RaptorSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class RaptorEmptyState extends StatelessWidget {
  const RaptorEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RaptorSurface(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 24 : 34,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 48 : 58,
                height: compact ? 48 : 58,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RaptorProgressBar extends StatelessWidget {
  const RaptorProgressBar({
    super.key,
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
    );
  }
}
