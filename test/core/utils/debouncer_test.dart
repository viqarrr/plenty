import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/utils/debouncer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Debouncer Utility Tests', () {
    test('Executes action once after the specified delay', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      int callCount = 0;

      debouncer.run(() {
        callCount++;
      });

      // Before delay expires -> 0 executions
      expect(callCount, 0);

      // Wait for delay to complete
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(callCount, 1);

      debouncer.dispose();
    });

    test('Cancels previous timers on rapid calls and fires only the last action once',
        () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 400));
      int executionCount = 0;
      String lastExecutedQuery = '';

      // Simulate rapid user keystrokes: 'm' -> 'mo' -> 'mon' -> 'monstera'
      debouncer.run(() {
        executionCount++;
        lastExecutedQuery = 'm';
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));

      debouncer.run(() {
        executionCount++;
        lastExecutedQuery = 'mo';
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));

      debouncer.run(() {
        executionCount++;
        lastExecutedQuery = 'mon';
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));

      debouncer.run(() {
        executionCount++;
        lastExecutedQuery = 'monstera';
      });

      // Still before the final 400ms delay finishes
      expect(executionCount, 0);

      // Wait for debouncer delay to lapse
      await Future<void>.delayed(const Duration(milliseconds: 450));

      // Must execute EXACTLY once with the final query
      expect(executionCount, 1);
      expect(lastExecutedQuery, 'monstera');

      debouncer.dispose();
    });

    test('Dispose cancels pending timer and prevents callback execution',
        () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      bool wasExecuted = false;

      debouncer.run(() {
        wasExecuted = true;
      });

      // Dispose immediately before timer fires
      debouncer.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(wasExecuted, isFalse);
    });
  });
}
