import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neptune_recyclers/theme/app_theme.dart';
import 'package:neptune_recyclers/theme/hexagon_clipper.dart';

/// One-shot generator: renders the app's own logo mark (hexagon + recycling
/// glyph, exactly as the SplashScreen shows it) into PNGs for the PWA.
/// Run with `flutter test --update-goldens` then copy the outputs to web/icons/.
void main() {
  Widget mark(double fill) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: fill,
        heightFactor: fill,
        child: ClipPath(
          clipper: HexagonClipper(),
          child: const DecoratedBox(
            decoration: BoxDecoration(color: AppTheme.primaryGreen),
            child: Center(
              child: Icon(
                Icons.recycling_rounded,
                size: 240,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('render 512 logo', (tester) async {
    tester.view.physicalSize = const Size(512, 512);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.pureWhite,
          body: mark(0.94),
        ),
      ),
    );
    await expectLater(
      find.byType(ClipPath),
      matchesGoldenFile('goldens/logo_512.png'),
    );
  });

  testWidgets('render maskable 512 logo', (tester) async {
    tester.view.physicalSize = const Size(512, 512);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          // Maskable: full-bleed background with the mark inside the safe
          // zone (inner ~80% circle).
          backgroundColor: AppTheme.primaryGreen,
          body: mark(0.62),
        ),
      ),
    );
    await expectLater(
      find.byType(ClipPath),
      matchesGoldenFile('goldens/logo_maskable_512.png'),
    );
  });
}
