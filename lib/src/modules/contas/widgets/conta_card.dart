import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/components/ui/raptor_ui.dart';
import '../../shared/utils/currency_formatter.dart';
import '../data/contas_sugeridas.dart';
import '../models/conta_model.dart';

/// Card bancário Raptor 3.
///
/// O banco aparece como identidade, não como um gradiente ocupando o card
/// inteiro. Assim saldo, movimentação e ações continuam legíveis nos dois
/// temas e contas de bancos diferentes permanecem parte do mesmo aplicativo.
class ContaCard extends StatelessWidget {
  const ContaCard({
    super.key,
    required this.conta,
    this.entradaMensal,
    this.saidaMensal,
    this.saldoMedio,
    this.periodoAtual,
    this.showMovimentacao = true,
    this.showMetricas = true,
    this.isCompact = false,
    this.onTap,
    this.onMenuTap,
    this.trailing,
  });

  final ContaModel conta;
  final double? entradaMensal;
  final double? saidaMensal;
  final double? saldoMedio;
  final String? periodoAtual;
  final bool showMovimentacao;
  final bool showMetricas;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final Widget? trailing;

  Color _accountColor(Color fallback) {
    final value = conta.cor?.replaceAll('#', '');
    if (value == null || value.isEmpty) return fallback;
    return Color(int.tryParse('FF$value', radix: 16) ?? fallback.toARGB32());
  }

  IconData get _accountIcon {
    switch (conta.tipo.toLowerCase()) {
      case 'corrente':
        return Icons.account_balance_rounded;
      case 'poupanca':
        return Icons.savings_outlined;
      case 'carteira':
        return Icons.account_balance_wallet_outlined;
      case 'investimento':
        return Icons.trending_up_rounded;
      default:
        return Icons.wallet_outlined;
    }
  }

  String? get _bankLogo {
    if (conta.banco == null || conta.banco!.isEmpty) return null;
    final bank = ContasSugeridas.todas.firstWhere(
      (item) => item['banco'] == conta.banco,
      orElse: () => <String, dynamic>{},
    );
    return bank['logo'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = _accountColor(colors.primary);

    return RaptorSurface(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: EdgeInsets.zero,
      onTap: onTap,
      accent: accent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: accent),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, isCompact ? 14 : 18, 16, isCompact ? 14 : 18),
              child: isCompact
                  ? _compactContent(context, accent)
                  : _fullContent(context, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactContent(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _identity(context, accent, 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conta.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                conta.banco ?? _typeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(conta.saldo),
              style: theme.textTheme.titleMedium?.copyWith(
                color: conta.saldo < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface,
              ),
            ),
            if (conta.contaPrincipal)
              Text(
                'Principal',
                style: theme.textTheme.labelSmall?.copyWith(color: accent),
              ),
          ],
        ),
        if (onMenuTap != null)
          IconButton(
            tooltip: 'Mais opções',
            onPressed: onMenuTap,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
      ],
    );
  }

  Widget _fullContent(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _identity(context, accent, 48),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conta.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (conta.contaPrincipal) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Principal',
                            style: theme.textTheme.labelSmall?.copyWith(color: accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${conta.banco ?? 'Conta'} • $_typeLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onMenuTap != null)
              IconButton(
                tooltip: 'Mais opções',
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Saldo disponível',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Text(
          CurrencyFormatter.format(conta.saldo),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 30,
            color: conta.saldo < 0 ? colors.error : colors.onSurface,
          ),
        ),
        if (showMovimentacao && (entradaMensal != null || saidaMensal != null)) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              if (entradaMensal != null)
                Expanded(
                  child: _metric(
                    context,
                    icon: Icons.south_west_rounded,
                    label: 'Entradas',
                    value: entradaMensal!,
                    color: colors.tertiary,
                  ),
                ),
              if (entradaMensal != null && saidaMensal != null) const SizedBox(width: 10),
              if (saidaMensal != null)
                Expanded(
                  child: _metric(
                    context,
                    icon: Icons.north_east_rounded,
                    label: 'Saídas',
                    value: saidaMensal!,
                    color: colors.error,
                  ),
                ),
            ],
          ),
        ],
        if (showMetricas && (saldoMedio != null || periodoAtual != null)) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (saldoMedio != null)
                Expanded(
                  child: Text(
                    'Saldo médio  ${CurrencyFormatter.format(saldoMedio!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              if (periodoAtual != null)
                Text(
                  periodoAtual!,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _metric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(
                  CurrencyFormatter.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context, Color accent, double size) {
    final logo = _bankLogo;
    final fallback = Icon(_accountIcon, color: accent, size: size * 0.46);
    Widget child = fallback;
    if (logo != null && logo.isNotEmpty) {
      child = logo.toLowerCase().endsWith('.svg')
          ? SvgPicture.asset(
              logo,
              width: size * 0.55,
              height: size * 0.55,
              placeholderBuilder: (_) => fallback,
            )
          : Image.asset(
              logo,
              width: size * 0.55,
              height: size * 0.55,
              errorBuilder: (_, __, ___) => fallback,
            );
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(child: child),
    );
  }

  String get _typeLabel {
    switch (conta.tipo.toLowerCase()) {
      case 'corrente':
        return 'Conta corrente';
      case 'poupanca':
        return 'Poupança';
      case 'carteira':
        return 'Carteira';
      case 'investimento':
        return 'Investimento';
      default:
        return conta.tipo;
    }
  }
}
