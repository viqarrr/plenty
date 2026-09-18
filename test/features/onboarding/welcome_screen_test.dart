import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:plenty/features/onboarding/presentation/widgets/hero_illustration_container.dart';

void main() {
  group('WelcomeScreen Onboarding Slider Widget Tests', () {
    testWidgets('renders initial slide and pagination dots correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Lottie animation is present
      expect(find.byType(HeroIllustrationContainer), findsOneWidget);

      // Verify Slide 1 contents (title & description, no eyebrow)
      expect(find.text('JADWAL & PENGINGAT'), findsNothing);
      expect(find.text('Jangan Pernah Lupa Menyiram'), findsOneWidget);
      expect(
        find.text(
            'Pengingat cerdas otomatis yang menyesuaikan kebutuhan air dan paparan sinar matahari tiap tanaman.'),
        findsOneWidget,
      );

      // Verify action buttons (Mulai present, Lewati removed)
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
    });

    testWidgets('swiping page view advances through slides',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Fling left to advance to Slide 2
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify Slide 2 contents (Title present, eyebrow removed)
      expect(find.text('PRESTASI & LENCANA'), findsNothing);
      expect(find.text('Raih Lencana & Koleksi Prestasi'), findsOneWidget);

      // Fling left to advance to Slide 3
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify Slide 3 contents (Title present, eyebrow removed)
      expect(find.text('MONITOR PERTUMBUHAN'), findsNothing);
      expect(find.text('Pantau Tumbuh Kembang Tanamanmu'), findsOneWidget);
    });
  });
}
