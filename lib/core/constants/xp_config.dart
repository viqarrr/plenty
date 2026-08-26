/// Configuration for plant care gamification XP and Level metrics.
abstract final class XpConfig {
  XpConfig._();

  /// XP awarded for completing specific daily care tasks.
  static const Map<String, int> xpPerTask = {
    'siram': 10,
    'bersih': 10,
    'monitor': 15,
  };

  /// Experience points threshold required per level.
  static const int xpPerLevel = 100;

  /// Calculates the level corresponding to a total XP amount.
  static int levelForXp(int xp) => (xp ~/ xpPerLevel) + 1;

  /// Calculates progress XP towards the next level.
  static int xpTowardsNextLevel(int xp) => xp % xpPerLevel;
}
