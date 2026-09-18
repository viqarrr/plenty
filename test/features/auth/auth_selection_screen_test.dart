import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:plenty/features/auth/presentation/screens/auth_selection_screen.dart';

void main() {
  group('AuthSelectionScreen Widget Tests', () {
    testWidgets('renders top logo, watering_plants animation, and bottom buttons correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthSelectionScreen(),
        ),
      );
      await tester.pump();

      // Verify logo is present at top
      expect(find.byType(Image), findsOneWidget);

      // Verify watering_plants Lottie animation is present in middle
      expect(find.byType(LottieBuilder), findsOneWidget);

      // Verify title & subtitle
      expect(find.text('Selamat datang di Plenty'), findsOneWidget);
      expect(find.text('Daftar atau masuk ke akun anda'), findsOneWidget);

      // Verify divider
      expect(find.text('Atau'), findsOneWidget);

      // Verify buttons
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Masuk dengan Email'), findsOneWidget);
    });
  });
}
