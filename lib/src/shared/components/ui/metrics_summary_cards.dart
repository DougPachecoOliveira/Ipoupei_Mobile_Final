// 📊 Metrics Summary Cards - iPoupei Mobile
//
// Componente reutilizável para 3 cards de resumo de métricas
// Usado em gestão de contas, cartões e relatórios
//
// Features:
// - Layout responsivo em linha
// - AutoSizeText para acessibilidade
// - Cores personalizáveis por métrica
// - Valores formatados automaticamente

import 'package:flutter/material.dart';
import '../../../modules/shared/theme/app_colors.dart';
import 'app_text.dart';

/// Dados de uma métrica para exibição
class MetricData {
  final String title;
  final String value;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const MetricData({
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.onTap,
  });
}

/// Widget com 3 cards de métricas em linha
class MetricsSummaryCards extends StatelessWidget {
  final List<MetricData> metrics;
  final double? spacing;
  final double? cardPadding;
  final bool showIcons;

  const MetricsSummaryCards({
    super.key,
    required this.metrics,
    this.spacing = 12.0,
    this.cardPadding = 16.0,
    this.showIcons = false,
  }) : assert(metrics.length == 3, 'MetricsSummaryCards deve ter exatamente 3 métricas');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(child: _buildMetricCard(context, metrics[i])),
            if (i < 2) SizedBox(width: spacing!),
          ],
        ],
      ),
    );
  }

  /// Constrói um card individual de métrica
  Widget _buildMetricCard(BuildContext context, MetricData metric) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(cardPadding!),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone (opcional)
              if (showIcons && metric.icon != null) ...[
                Icon(
                  metric.icon,
                  size: 20,
                  color: metric.color,
                ),
                const SizedBox(height: 8),
              ],

              // Valor principal (em destaque)
              AppText.cardValue(
                metric.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                color: metric.color,
                group: AppTextGroups.cardValues,
              ),

              const SizedBox(height: 4),

              // Título da métrica (menor e mais sutil)
              AppText.cardSecondary(
                metric.title,
                style: const TextStyle(
                  fontSize: 12,
                ),
                color: AppColors.cinzaTexto,
                group: AppTextGroups.cardSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Factory methods para métricas comuns
class CommonMetrics {

  /// Métricas para contas
  static List<MetricData> forAccount({
    required String averageBalance,
    required String maxIncome,
    required String maxExpense,
    VoidCallback? onAverageBalanceTap,
    VoidCallback? onMaxIncomeTap,
    VoidCallback? onMaxExpenseTap,
  }) {
    return [
      MetricData(
        title: 'Saldo Médio Período',
        value: averageBalance,
        color: AppColors.azul,
        icon: Icons.account_balance_wallet_outlined,
        onTap: onAverageBalanceTap,
      ),
      MetricData(
        title: 'Maior Entrada',
        value: maxIncome,
        color: AppColors.verdeSucesso,
        icon: Icons.trending_up_outlined,
        onTap: onMaxIncomeTap,
      ),
      MetricData(
        title: 'Maior Saída',
        value: maxExpense,
        color: AppColors.vermelhoErro,
        icon: Icons.trending_down_outlined,
        onTap: onMaxExpenseTap,
      ),
    ];
  }

  /// Métricas para cartões
  static List<MetricData> forCard({
    required String currentStatement,
    required String totalLimit,
    required String availableLimit,
    VoidCallback? onCurrentStatementTap,
    VoidCallback? onTotalLimitTap,
    VoidCallback? onAvailableLimitTap,
  }) {
    return [
      MetricData(
        title: 'Fatura Atual',
        value: currentStatement,
        color: AppColors.azul,
        icon: Icons.receipt_long_outlined,
        onTap: onCurrentStatementTap,
      ),
      MetricData(
        title: 'Limite Total',
        value: totalLimit,
        color: AppColors.verdeSucesso,
        icon: Icons.credit_card_outlined,
        onTap: onTotalLimitTap,
      ),
      MetricData(
        title: 'Limite Disponível',
        value: availableLimit,
        color: AppColors.verdeSucesso,
        icon: Icons.account_balance_wallet_outlined,
        onTap: onAvailableLimitTap,
      ),
    ];
  }

  /// Métricas para relatórios financeiros
  static List<MetricData> forFinancialReport({
    required String totalIncome,
    required String totalExpense,
    required String balance,
    VoidCallback? onTotalIncomeTap,
    VoidCallback? onTotalExpenseTap,
    VoidCallback? onBalanceTap,
  }) {
    return [
      MetricData(
        title: 'Total Receitas',
        value: totalIncome,
        color: AppColors.verdeSucesso,
        icon: Icons.add_circle_outline,
        onTap: onTotalIncomeTap,
      ),
      MetricData(
        title: 'Total Despesas',
        value: totalExpense,
        color: AppColors.vermelhoErro,
        icon: Icons.remove_circle_outline,
        onTap: onTotalExpenseTap,
      ),
      MetricData(
        title: 'Saldo Líquido',
        value: balance,
        color: AppColors.azul,
        icon: Icons.account_balance_outlined,
        onTap: onBalanceTap,
      ),
    ];
  }
}