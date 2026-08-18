/// Configuration for plant care gamification XP and Level metrics.
abstract final class XpConfig {
  XpConfig._();

  /// XP awarded for completing specific daily care tasks.
  static const Map<String, int> xpPerTask = {
    'siram': 10,
    'bersih_bersih': 10,
    'monitor_tinggi': 15, // Higher reward as it requires numerical height measurement
  };

  /// Experience points threshold required per level.
  static const int xpPerLevel = 100;

  /// Calculates the level corresponding to a total XP amount.
  /// Level 1 is from 0 to 99 XP, Level 2 from 100 to 199 XP, etc.
  static int levelForXp(int xp) => (xp ~/ xpPerLevel) + 1;

  /// Calculates progress XP towards the next level (0 to 99).
  static int xpTowardsNextLevel(int xp) => xp % xpPerLevel;
}
