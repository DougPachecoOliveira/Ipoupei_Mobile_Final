// 💡 Insights Card - iPoupei Mobile
//
// Componente reutilizável para card de insights e dicas
// Usado em gestão de contas, cartões e dashboard
//
// Features:
// - Header com logo/ícone iPoupei
// - Lista de insights com ícones
// - AutoSizeText para acessibilidade
// - Expansível/colapsável (opcional)

import 'package:flutter/material.dart';
import '../../../modules/shared/theme/app_colors.dart';
import 'app_text.dart';

/// Dados de um insight individual
class InsightData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const InsightData({
    required this.icon,
    required this.title,
    required this.description,
    this.color = AppColors.azul,
    this.onTap,
  });
}

/// Widget de card com insights e dicas
class InsightsCard extends StatefulWidget {
  final String headerTitle;
  final List<InsightData> insights;
  final bool isCollapsible;
  final bool initiallyExpanded;
  final double? cardPadding;
  final Widget? customHeader;

  const InsightsCard({
    super.key,
    this.headerTitle = '💡 Insights & Dicas',
    required this.insights,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.cardPadding = 16.0,
    this.customHeader,
  });

  @override
  State<InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<InsightsCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(widget.cardPadding!),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do card
            _buildHeader(),

            // Conteúdo (insights)
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              _buildInsightsList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói o header do card
  Widget _buildHeader() {
    if (widget.customHeader != null) {
      return widget.customHeader!;
    }

    return InkWell(
      onTap: widget.isCollapsible ? _toggleExpanded : null,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          // Logo iPoupei
          _buildIPoupeiLogo(),

          const SizedBox(width: 12),

          // Título
          Expanded(
            child: AppText.cardTitle(
              widget.headerTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              color: AppColors.cinzaEscuro,
            ),
          ),

          // Ícone de expandir/colapsar
          if (widget.isCollapsible)
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.cinzaTexto,
              size: 24,
            ),
        ],
      ),
    );
  }

  /// Logo/ícone do iPoupei
  Widget _buildIPoupeiLogo() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulHeader.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.azulHeader,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: AppText.cardSecondary(
              'iP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói a lista de insights
  Widget _buildInsightsList() {
    if (widget.insights.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < widget.insights.length; i++) ...[
          _buildInsightItem(widget.insights[i]),
          if (i < widget.insights.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Constrói um item individual de insight
  Widget _buildInsightItem(InsightData insight) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: insight.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: insight.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: insight.color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone do insight
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: insight.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  insight.icon,
                  size: 16,
                  color: insight.color,
                ),
              ),

              const SizedBox(width: 12),

              // Conteúdo textual
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título do insight
                    AppText.cardTitle(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      color: insight.color,
                    ),

                    const SizedBox(height: 4),

                    // Descrição
                    AppText.body(
                      insight.description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                      ),
                      color: AppColors.cinzaTexto,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              // Seta de ação (se tiver onTap)
              if (insight.onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.cinzaTexto,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado vazio (sem insights)
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          AppText.cardSecondary(
            'Nenhum insight disponível',
            style: const TextStyle(fontSize: 14),
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}

/// Factory methods para insights comuns
class CommonInsights {
  /// Insights para contas
  static List<InsightData> forAccount({
    required double currentBalance,
    required double averageBalance,
    required double lastMonthExpenses,
  }) {
    List<InsightData> insights = [];

    // Insight sobre saldo atual vs médio
    if (currentBalance < averageBalance * 0.8) {
      insights.add(InsightData(
        icon: Icons.warning_outlined,
        title: 'Saldo abaixo da média',
        description: 'Seu saldo atual está 20% abaixo da sua média histórica. Considere revisar seus gastos.',
        color: AppColors.vermelhoErro,
      ));
    }

    // Insight sobre economia
    if (currentBalance > averageBalance * 1.2) {
      insights.add(InsightData(
        icon: Icons.trending_up,
        title: 'Parabéns! Saldo acima da média',
        description: 'Você está conseguindo manter um saldo 20% acima da sua média. Continue assim!',
        color: AppColors.verdeSucesso,
      ));
    }

    return insights;
  }

  /// Insights para cartões
  static List<InsightData> forCard({
    required double currentStatement,
    required double totalLimit,
    required double lastMonthStatement,
  }) {
    List<InsightData> insights = [];

    final utilizationPercentage = (currentStatement / totalLimit) * 100;

    // Insight sobre utilização do cartão
    if (utilizationPercentage > 80) {
      insights.add(InsightData(
        icon: Icons.warning_outlined,
        title: 'Alto uso do limite',
        description: 'Você está usando ${utilizationPercentage.toStringAsFixed(1)}% do seu limite. Isso pode impactar seu score.',
        color: AppColors.vermelhoErro,
      ));
    }

    return insights;
  }
}