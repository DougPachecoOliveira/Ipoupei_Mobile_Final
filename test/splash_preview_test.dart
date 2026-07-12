// Preview visual da splash (gera golden para inspeção durante o design).
// Temporário — não é teste de regressão.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipoupei_mobile/src/shared/components/ui/enhanced_splash_screen.dart';

void main() {
  testWidgets('splash preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: EnhancedSplashScreen(
          message: 'Carregando iPoupei...',
          subtitle: 'Sincronizando seus dados com segurança',
          showProgress: true,
        ),
      ),
    );

    await tester.runAsync(() async {
      final context = tester.element(find.byType(EnhancedSplashScreen));
      await precacheImage(
        const AssetImage('assets/images/logo_transparent.png'),
        context,
      );
    });

    // Estado no meio do ciclo: entrada completa + onda ~60% desenhada
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 2000));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/splash_preview.png'),
    );
  });
}
