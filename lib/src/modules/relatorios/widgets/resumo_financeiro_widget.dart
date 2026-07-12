import 'package:flutter/material.dart';

import '../../../shared/components/ui/raptor_ui.dart';
import '../../shared/utils/currency_formatter.dart';
import '../models/resumo_financeiro_model.dart';
import '../services/resumo_financeiro_service.dart';

class ResumoFinanceiroWidget extends StatefulWidget {
  const ResumoFinanceiroWidget({
    super.key,
    required this.dataInicio,
    required this.dataFim,
    required this.onItemTap,
  });

  final DateTime dataInicio;
  final DateTime dataFim;
  final Function(TipoResumoFinanceiro tipo) onItemTap;

  @override
  State<ResumoFinanceiroWidget> createState() => _ResumoFinanceiroWidgetState();
}

class _ResumoFinanceiroWidgetState extends State<ResumoFinanceiroWidget> {
  final _service = ResumoFinanceiroService.instance;
  ResumoFinanceiroData? _data;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ResumoFinanceiroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataInicio != widget.dataInicio || oldWidget.dataFim != widget.dataFim) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _service.carregarResumo(
        dataInicio: widget.dataInicio,
        dataFim: widget.dataFim,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const RaptorSurface(
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_hasError) {
      return RaptorEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível atualizar o resumo',
        message: 'Seus dados locais continuam seguros. Tente novamente quando quiser.',
        actionLabel: 'Tentar novamente',
        onAction: _load,
        compact: true,
      );
    }

    final data = _data ?? ResumoFinanceiroData.empty();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return RaptorSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patrimônio estimado',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      CurrencyFormatter.format(data.patrimonioTotal),
                      style: theme.textTheme.headlineSmall?.copyWith(fontSize: 30),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.account_balance_wallet_outlined, color: colors.onPrimaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _metric(context, width, TipoResumoFinanceiro.contas, 'Em contas', data.saldoContas, Icons.account_balance_outlined, colors.primary),
                  _metric(context, width, TipoResumoFinanceiro.cartoes, 'Em cartões', -data.totalCartoes, Icons.credit_card_outlined, colors.secondary),
                  _metric(context, width, TipoResumoFinanceiro.receitas, 'Receitas', data.totalReceitas, Icons.south_west_rounded, colors.tertiary),
                  _metric(context, width, TipoResumoFinanceiro.despesas, 'Despesas', -data.totalDespesas, Icons.north_east_rounded, colors.error),
                ],
              );
            },
          ),
          if (!data.hasData) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seu resumo aparece aqui assim que você registrar a primeira movimentação.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    double width,
    TipoResumoFinanceiro type,
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => widget.onItemTap(type),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 12),
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: value < 0 ? colors.error : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
