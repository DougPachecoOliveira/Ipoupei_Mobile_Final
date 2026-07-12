import 'package:flutter/material.dart';

import '../../../shared/components/ui/raptor_ui.dart';
import '../../../shared/utils/format_currency.dart';
import '../models/planejamento_model.dart';

class PlanejamentoCard extends StatelessWidget {
  const PlanejamentoCard({
    super.key,
    required this.planejamento,
    this.onTap,
    this.onEdit,
  });

  final PlanejamentoModel planejamento;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progressColor = _progressColor(colors);

    return RaptorSurface(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _categoryColor(colors.primary).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    planejamento.categoriaIcone ?? '📊',
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      planejamento.isDespesa ? 'Limite de gasto' : 'Meta de receita',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Editar planejamento',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usado no período',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatCurrency(planejamento.totalMes),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Text(
                'de ${formatCurrency(planejamento.valorPlanejado)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          RaptorProgressBar(value: _progress, color: progressColor),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(_statusIcon, size: 16, color: progressColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _statusText,
                  style: theme.textTheme.bodySmall?.copyWith(color: progressColor),
                ),
              ),
              Text(
                '${planejamento.percentualCumprimento.toStringAsFixed(0)}%',
                style: theme.textTheme.labelLarge?.copyWith(color: progressColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _progress {
    if (planejamento.valorPlanejado <= 0) return 0;
    return (planejamento.percentualCumprimento / 100).clamp(0, 1);
  }

  String get _displayName {
    final category = planejamento.categoriaNome ?? 'Sem categoria';
    final subcategory = planejamento.subcategoriaNome;
    return subcategory == null ? category : '$category • $subcategory';
  }

  String get _statusText {
    final percentage = planejamento.percentualCumprimento;
    if (percentage >= 100) {
      return planejamento.isDespesa ? 'Limite ultrapassado' : 'Meta alcançada';
    }
    if (percentage >= 80) return 'Perto do limite';
    if (percentage >= 50) return 'Em andamento';
    return 'Dentro do planejado';
  }

  IconData get _statusIcon {
    if (planejamento.percentualCumprimento >= 100 && planejamento.isDespesa) {
      return Icons.warning_amber_rounded;
    }
    if (planejamento.percentualCumprimento >= 100) return Icons.check_circle_outline;
    return Icons.insights_outlined;
  }

  Color _progressColor(ColorScheme colors) {
    final percentage = planejamento.percentualCumprimento;
    if (percentage >= 100 && planejamento.isDespesa) return colors.error;
    if (percentage >= 80) return colors.tertiary;
    return colors.primary;
  }

  Color _categoryColor(Color fallback) {
    final value = planejamento.categoriaCor?.replaceAll('#', '');
    if (value == null || value.isEmpty) return fallback;
    return Color(int.tryParse('FF$value', radix: 16) ?? fallback.toARGB32());
  }
}
