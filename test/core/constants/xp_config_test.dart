import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/constants/xp_config.dart';

void main() {
  group('XpConfig Unit Tests', () {
    test('levelForXp boundary calculations', () {
      expect(XpConfig.levelForXp(0), 1);
      expect(XpConfig.levelForXp(50), 1);
      expect(XpConfig.levelForXp(99), 1);
      expect(XpConfig.levelForXp(100), 2);
      expect(XpConfig.levelForXp(199), 2);
      expect(XpConfig.levelForXp(200), 3);
      expect(XpConfig.levelForXp(1050), 11);
    });

    test('xpPerTask values verify task metrics', () {
      expect(XpConfig.xpPerTask['siram'], 10);
      expect(XpConfig.xpPerTask['bersih_bersih'], 10);
      expect(XpConfig.xpPerTask['monitor_tinggi'], 15);
      expect(XpConfig.xpPerTask.containsKey('cek_hama'), isFalse);
    });
  });
}
