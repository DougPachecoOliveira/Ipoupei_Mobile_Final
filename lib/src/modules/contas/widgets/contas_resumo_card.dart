import 'package:flutter/material.dart';

import '../../../shared/components/ui/raptor_ui.dart';
import '../../shared/utils/currency_formatter.dart';

class ContasResumoCard extends StatelessWidget {
  const ContasResumoCard({
    super.key,
    required this.saldoTotal,
    required this.contasAtivas,
    required this.projecao,
  });

  final double saldoTotal;
  final int contasAtivas;
  final Future<Map<String, double>> projecao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RaptorSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saldo em contas',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$contasAtivas ${contasAtivas == 1 ? 'conta' : 'contas'}',
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            CurrencyFormatter.format(saldoTotal),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 31,
              color: saldoTotal < 0 ? colors.error : colors.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, double>>(
            future: projecao,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final income = data?['receitas_pendentes'] ?? 0;
              final expenses = data?['despesas_pendentes'] ?? 0;
              final projected = data?['projecao'] ?? saldoTotal;
              if (income == 0 && expenses == 0) {
                return Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Nenhum lançamento pendente', style: theme.textTheme.bodySmall),
                  ],
                );
              }
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Projeção do mês', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 2),
                          Text(CurrencyFormatter.format(projected), style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                    Text(
                      '+${CurrencyFormatter.format(income)}\n−${CurrencyFormatter.format(expenses)}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
