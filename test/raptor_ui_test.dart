import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipoupei_mobile/src/modules/contas/models/conta_model.dart';
import 'package:ipoupei_mobile/src/modules/contas/widgets/conta_card.dart';
import 'package:ipoupei_mobile/src/modules/planejamento/models/planejamento_model.dart';
import 'package:ipoupei_mobile/src/modules/planejamento/widgets/planejamento_card.dart';
import 'package:ipoupei_mobile/src/shared/components/ui/raptor_ui.dart';
import 'package:ipoupei_mobile/src/shared/theme/app_theme.dart';

void main() {
  final account = ContaModel(
    id: 'account',
    usuarioId: 'user',
    nome: 'Conta do dia a dia',
    tipo: 'corrente',
    banco: 'Nubank',
    saldoInicial: 1000,
    saldo: 8234.56,
    cor: '#8A05BE',
    contaPrincipal: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  const planning = PlanejamentoModel(
    id: 'plan',
    usuarioId: 'user',
    ano: 2026,
    mes: 7,
    categoriaId: 'food',
    tipo: 'despesa',
    valorPlanejado: 1500,
    valorRealizado: 860,
    valorPrevisto: 120,
    categoriaNome: 'Alimentação',
    categoriaIcone: '🍽️',
    categoriaCor: '#E76F51',
    temPlanejamentoReal: true,
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Raptor 3 renders at 320px in ${mode.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: RepaintBoundary(
            key: const ValueKey('preview'),
            child: Scaffold(
              body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                ContaCard(
                  conta: account,
                  entradaMensal: 3500,
                  saidaMensal: 2100,
                  saldoMedio: 7400,
                  periodoAtual: 'Jul/26',
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: PlanejamentoCard(planejamento: planning),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: RaptorEmptyState(
                    icon: Icons.donut_small_outlined,
                    title: 'Seu relatório começa aqui',
                    message: 'Registre uma movimentação para ver a análise.',
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Conta do dia a dia'), findsOneWidget);
      expect(find.text('Alimentação'), findsOneWidget);

      await expectLater(
        find.byKey(const ValueKey('preview')),
        matchesGoldenFile('goldens/raptor_${mode.name}.png'),
      );

    });
  }
}
