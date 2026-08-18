import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();
  });

  testWidgets('PlentyApp initial render smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PlentyApp()));
    expect(find.byType(PlentyApp), findsOneWidget);

    // Fast-forward past splash screen delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
