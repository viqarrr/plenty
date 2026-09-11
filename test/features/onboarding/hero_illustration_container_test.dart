import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:plenty/features/onboarding/presentation/widgets/hero_illustration_container.dart';

void main() {
  group('HeroIllustrationContainer Widget Tests', () {
    test('all Lottie animation assets can be loaded by rootBundle and parsed by Lottie', () async {
      for (final path in [
        'assets/animations/leaf_line.json',
        'assets/animations/curly_leaf.json',
        'assets/animations/tree_leaf.json',
        'assets/animations/monstera_leaf.json',
      ]) {
        final byteData = await rootBundle.load(path);
        expect(byteData.lengthInBytes, greaterThan(0));
        final comp = await LottieComposition.fromByteData(byteData);
        expect(comp.duration.inMilliseconds, greaterThan(0));
      }
    });

    testWidgets(
        'renders unbounded Lottie animation without blob backdrop by default',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroIllustrationContainer(
                animationPath: 'assets/animations/leaf_line.json',
                repeatAnimation: false,
                size: 280,
                iconSize: 260,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify dimensions
      expect(
        tester.getSize(find.byType(HeroIllustrationContainer)),
        const Size(280, 280),
      );

      // Verify CustomPaint backdrop is NOT present by default (unbounded)
      expect(
        find.descendant(
          of: find.byType(HeroIllustrationContainer),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      // Verify LottieBuilder is rendered with repeat: false and size 260
      expect(find.byType(LottieBuilder), findsOneWidget);
      final lottieWidget = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(lottieWidget.repeat, false);
      expect(lottieWidget.width, 260);
      expect(lottieWidget.height, 260);
    });

    testWidgets(
        'renders layered organic backdrop with CustomPaint when showBackdrop is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroIllustrationContainer(
                animationPath: 'assets/animations/leaf_line.json',
                repeatAnimation: false,
                showBackdrop: true,
                primaryColor: Color(0xFF4A6B5B),
                size: 280,
                iconSize: 180,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify CustomPaint is present when showBackdrop: true
      expect(
        find.descendant(
          of: find.byType(HeroIllustrationContainer),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      expect(find.byType(LottieBuilder), findsOneWidget);
    });

    testWidgets(
        'renders image asset when imagePath is provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroIllustrationContainer(
                imagePath: 'assets/icons/water-drop-alt.png',
                iconColor: Color(0xFF2D4A3E),
                size: 240,
                iconSize: 76,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.width, 76);
      expect(imageWidget.height, 76);
      expect(imageWidget.color, const Color(0xFF2D4A3E));
    });

    testWidgets('renders custom child within container when provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroIllustrationContainer(
                child: Text('Editorial Hero'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Editorial Hero'), findsOneWidget);
    });

    testWidgets('renders fallback Lottie animation when parameters are omitted',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroIllustrationContainer(
                size: 220,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LottieBuilder), findsOneWidget);
      final lottieWidget = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(lottieWidget.repeat, false);

      expect(
        tester.getSize(find.byType(HeroIllustrationContainer)),
        const Size(220, 220),
      );
    });

    testWidgets('supports slideIndex layer rotations across all slides when showBackdrop is true',
        (tester) async {
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: HeroIllustrationContainer(
                  slideIndex: i,
                  showBackdrop: true,
                  animationPath: 'assets/animations/tree_leaf.json',
                  repeatAnimation: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(HeroIllustrationContainer),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      }
    });
  });
}
