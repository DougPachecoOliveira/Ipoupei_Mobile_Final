import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/components/ui/raptor_ui.dart';
import '../../../shared/utils/format_currency.dart';
import '../models/planejamento_model.dart';
import '../pages/planejamento_page.dart';
import '../services/planejamento_service.dart';

class ResumoOrcamentoWidget extends StatefulWidget {
  const ResumoOrcamentoWidget({
    super.key,
    required this.dataAtual,
    this.modoAnual = false,
  });

  final DateTime dataAtual;
  final bool modoAnual;

  @override
  State<ResumoOrcamentoWidget> createState() => _ResumoOrcamentoWidgetState();
}

class _ResumoOrcamentoWidgetState extends State<ResumoOrcamentoWidget> {
  final _service = PlanejamentoService.instance;
  List<PlanejamentoModel> _plans = [];
  StreamSubscription<List<PlanejamentoModel>>? _subscription;
  bool _loading = true;
  bool _includePending = false;

  @override
  void initState() {
    super.initState();
    _subscription = _service.planejamentosStream.listen((_) => _filter());
    _load();
  }

  @override
  void didUpdateWidget(covariant ResumoOrcamentoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataAtual != widget.dataAtual || oldWidget.modoAnual != widget.modoAnual) {
      _load();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      _service.definirPeriodo(widget.dataAtual);
      await _service.carregarPlanejamentos(modoAnual: widget.modoAnual);
      _filter();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final filtered = _service.planejamentos.where((plan) {
      if (widget.modoAnual) return plan.ano == widget.dataAtual.year;
      return plan.ano == widget.dataAtual.year && plan.mes == widget.dataAtual.month;
    }).toList();
    if (mounted) {
      setState(() {
        _plans = filtered;
        _loading = false;
      });
    }
  }

  double _planned(bool income) => _plans
      .where((plan) => plan.temPlanejamentoReal && (income ? plan.isReceita : plan.isDespesa))
      .fold(0, (sum, plan) => sum + plan.valorPlanejado);

  double _actual(bool income) => _plans
      .where((plan) => plan.temPlanejamentoReal && (income ? plan.isReceita : plan.isDespesa))
      .fold(0, (sum, plan) => sum + (_includePending ? plan.totalMes : plan.valorRealizado));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RaptorSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RaptorSectionTitle(
            title: 'Planejamento',
            subtitle: widget.modoAnual ? 'Visão do ano' : 'Metas do mês',
            trailing: IconButton(
              tooltip: 'Abrir planejamento',
              onPressed: _openPlanning,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
          if (_plans.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilterChip(
              selected: _includePending,
              onSelected: (value) => setState(() => _includePending = value),
              avatar: Icon(
                _includePending ? Icons.schedule_rounded : Icons.check_circle_outline,
                size: 17,
              ),
              label: Text(_includePending ? 'Incluindo pendentes' : 'Somente efetivados'),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()))
          else if (_plans.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.flag_outlined, color: colors.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dê um destino ao seu dinheiro', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 3),
                        Text(
                          'Crie seu primeiro limite ou meta.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _openPlanning, icon: const Icon(Icons.add_rounded)),
                ],
              ),
            )
          else ...[
            if (_planned(false) > 0)
              _budgetLine(
                context,
                label: 'Despesas',
                actual: _actual(false),
                planned: _planned(false),
                income: false,
              ),
            if (_planned(false) > 0 && _planned(true) > 0) const SizedBox(height: 16),
            if (_planned(true) > 0)
              _budgetLine(
                context,
                label: 'Receitas',
                actual: _actual(true),
                planned: _planned(true),
                income: true,
              ),
          ],
        ],
      ),
    );
  }

  Widget _budgetLine(
    BuildContext context, {
    required String label,
    required double actual,
    required double planned,
    required bool income,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percentage = planned == 0 ? 0.0 : actual / planned;
    final unhealthy = income ? percentage < .8 : percentage > .8;
    final color = unhealthy ? (percentage > 1 ? colors.error : colors.tertiary) : colors.primary;
    return InkWell(
      onTap: _openPlanning,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
                Text('${(percentage * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelLarge?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 9),
            RaptorProgressBar(value: percentage, color: color),
            const SizedBox(height: 7),
            Text(
              '${formatCurrency(actual)} de ${formatCurrency(planned)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlanning() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanejamentoPage()));
  }
}
