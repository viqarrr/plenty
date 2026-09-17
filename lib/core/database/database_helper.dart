import 'package:path/path.dart';
import 'package:plenty/core/constants/site_icons.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database Helper for local offline caching, queues, and static master data.
class DatabaseHelper {
  static const String _databaseName = 'plenty.db';
  static const int _databaseVersion = 1;

  // Active SQLite table names for offline caching & sync
  static const String tableUsers = 'users';
  static const String tableUserPreferences = 'user_preferences';
  static const String tableSites = 'sites';
  static const String tableUserPlants = 'user_plants';
  static const String tableCareSchedules = 'care_schedules';
  static const String tableCareActionLogs = 'care_action_logs';
  static const String tableGrowthLogs = 'growth_logs';
  static const String tableTimeCapsules = 'time_capsules';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableCommunityPosts = 'community_posts';

  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal() : _dbName = _databaseName;

  DatabaseHelper.forTesting([String? dbName])
      : _dbName = dbName ?? 'test_${DateTime.now().microsecondsSinceEpoch}.db';

  final String _dbName;
  Database? _customDb;
  static Database? _database;

  Future<Database> get database async {
    if (_customDb != null && _customDb!.isOpen) return _customDb!;
    if (_dbName != _databaseName) return _customDb = await _openDatabase(_dbName);
    if (_database != null && _database!.isOpen) return _database!;
    return _database = await _openDatabase(_databaseName);
  }

  Future<Database> _openDatabase(String name) async {
    final path = join(await getDatabasesPath(), name);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: _onCreate,
      onOpen: (db) async {
        try {
          await db.delete(tableBadges, where: "id IN ('doctor_green', 'sun_master')");
          await db.delete(tableUserBadges, where: "badge_id IN ('doctor_green', 'sun_master')");
        } catch (_) {}
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Table schema declarations
    const tableSchemas = [
      '''CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE NOT NULL, username TEXT UNIQUE,
        password TEXT DEFAULT '', display_name TEXT NOT NULL, bio TEXT, avatar_url TEXT,
        streak_count INTEGER NOT NULL DEFAULT 0, longest_streak INTEGER NOT NULL DEFAULT 0,
        total_xp INTEGER NOT NULL DEFAULT 0, level INTEGER NOT NULL DEFAULT 1,
        unlocked_badges_count INTEGER NOT NULL DEFAULT 0, last_streak_date TEXT, created_at TEXT NOT NULL
      )''',
      '''CREATE TABLE $tableUserPreferences (
        id TEXT PRIMARY KEY, user_id INTEGER NOT NULL, experience_level TEXT NOT NULL,
        daily_time_minutes REAL DEFAULT 15.0, has_pets INTEGER DEFAULT 0, has_kids INTEGER DEFAULT 0,
        available_time TEXT, safety_restriction TEXT, has_completed_onboarding INTEGER NOT NULL DEFAULT 0
      )''',
      '''CREATE TABLE $tableSites (
        id TEXT PRIMARY KEY, user_id INTEGER NOT NULL DEFAULT 1, name TEXT NOT NULL,
        icon_code INTEGER NOT NULL, is_indoor INTEGER NOT NULL DEFAULT 1,
        is_custom INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL
      )''',
      '''CREATE TABLE $tableUserPlants (
        id TEXT PRIMARY KEY, user_id TEXT NOT NULL, species_id INTEGER, catalog_id TEXT,
        species_name TEXT NOT NULL DEFAULT '', scientific_name TEXT, nickname TEXT NOT NULL DEFAULT 'Tanaman Hias',
        placement_type TEXT NOT NULL DEFAULT 'Indoor', site_id TEXT NOT NULL DEFAULT 'site_default_ruang_tamu',
        pot_size TEXT, initial_height REAL NOT NULL DEFAULT 30.0, current_height REAL NOT NULL DEFAULT 30.0,
        image_path TEXT, watering_interval_days INTEGER NOT NULL DEFAULT 7, sunlight_preference TEXT,
        is_pet_friendly INTEGER DEFAULT 0, adopted_at TEXT NOT NULL DEFAULT '', is_indoor INTEGER NOT NULL DEFAULT 1,
        sunlight_condition TEXT, initial_height_cm REAL DEFAULT 30.0, growth_stage TEXT NOT NULL DEFAULT 'mature',
        level INTEGER NOT NULL DEFAULT 1, xp INTEGER NOT NULL DEFAULT 0, health_status TEXT NOT NULL DEFAULT 'healthy',
        cover_photo_path TEXT, default_watering_interval INTEGER NOT NULL DEFAULT 7, care_level TEXT, toxicity TEXT,
        description TEXT, growth_rate TEXT, growth_cycle TEXT, pruning_season TEXT, flower_status TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (site_id) REFERENCES $tableSites (id) ON DELETE SET NULL
      )''',
      '''CREATE TABLE $tableCareSchedules (
        id TEXT PRIMARY KEY, user_plant_id TEXT NOT NULL, task_type TEXT NOT NULL,
        interval_days INTEGER NOT NULL, last_performed_at TEXT, next_due_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      )''',
      '''CREATE TABLE $tableCareActionLogs (
        id TEXT PRIMARY KEY, user_plant_id TEXT NOT NULL, task_type TEXT NOT NULL,
        action_type TEXT, performed_at TEXT, completed_at TEXT NOT NULL, log_date TEXT,
        xp_awarded INTEGER DEFAULT 0, notes TEXT,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      )''',
      '''CREATE TABLE $tableGrowthLogs (
        id TEXT PRIMARY KEY, user_plant_id TEXT NOT NULL, logged_at TEXT NOT NULL,
        height_cm REAL NOT NULL, leaf_count INTEGER, photo_path TEXT, source TEXT NOT NULL DEFAULT 'manual', note TEXT,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      )''',
      '''CREATE TABLE $tableTimeCapsules (
        id TEXT PRIMARY KEY, user_plant_id TEXT NOT NULL, photo_path TEXT, note TEXT,
        created_at TEXT NOT NULL, unlock_at TEXT NOT NULL, is_unlocked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      )''',
      '''CREATE TABLE $tableBadges (
        id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL, icon_name TEXT NOT NULL,
        tier_name TEXT NOT NULL DEFAULT 'Normal', level INTEGER NOT NULL DEFAULT 1,
        target_total INTEGER NOT NULL DEFAULT 1, bg_color_hex TEXT NOT NULL DEFAULT '#EBF7F1',
        accent_color_hex TEXT NOT NULL DEFAULT '#2D6A4F'
      )''',
      '''CREATE TABLE $tableUserBadges (
        id TEXT PRIMARY KEY, user_id INTEGER NOT NULL, badge_id TEXT NOT NULL,
        is_unlocked INTEGER NOT NULL DEFAULT 0, current_progress INTEGER NOT NULL DEFAULT 0, unlocked_at TEXT,
        FOREIGN KEY (badge_id) REFERENCES $tableBadges (id) ON DELETE CASCADE
      )''',
      '''CREATE TABLE $tableCommunityPosts (
        id TEXT PRIMARY KEY, user_id INTEGER NOT NULL, category TEXT NOT NULL, caption TEXT,
        image_url TEXT, badge_id TEXT, kudos_count INTEGER DEFAULT 0, is_liked INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0, created_at TEXT NOT NULL
      )''',
    ];

    for (final sql in tableSchemas) {
      batch.execute(sql);
    }

    // 2. Seed static master data only (preset room locations & badge catalog)
    final now = DateTime.now().toIso8601String();
    batch.execute('''
      INSERT OR IGNORE INTO $tableSites (id, user_id, name, icon_code, is_indoor, is_custom, created_at) VALUES
      ('${SiteIcons.defaultLivingRoomId}', 1, 'Ruang Tamu', ${SiteIcons.livingRoomIconCode}, 1, 0, '$now'),
      ('${SiteIcons.defaultBedroomId}', 1, 'Kamar Tidur', ${SiteIcons.bedroomIconCode}, 1, 0, '$now'),
      ('${SiteIcons.defaultBalconyId}', 1, 'Balkon', ${SiteIcons.balconyIconCode}, 0, 0, '$now'),
      ('${SiteIcons.defaultKitchenId}', 1, 'Dapur', ${SiteIcons.kitchenIconCode}, 1, 0, '$now'),
      ('${SiteIcons.defaultTerraceId}', 1, 'Teras', ${SiteIcons.terraceIconCode}, 0, 0, '$now');
    ''');

    batch.execute('''
      INSERT OR IGNORE INTO $tableBadges (id, title, description, icon_name, tier_name, level, target_total, bg_color_hex, accent_color_hex) VALUES
      ('first_plant', 'Adopsi Pertama', 'Mengadopsi tanaman pertama untuk memulai perjalanan berkebunmu.', 'sprout', '', 1, 1, '#EBF7F1', '#2D6A4F'),
      ('water_streak', 'Penyiram Setia', 'Menyiram tanaman tepat waktu selama 7 kali berturut-turut.', 'droplets', '', 7, 7, '#FBF3DB', '#956400'),
      ('time_capsule', 'Kapsul Waktu', 'Membuat pesan kapsul waktu pertama saat menanam.', 'hourglass', '', 1, 1, '#E3F0FF', '#1F6C9F'),
      ('plant_collector', 'Kolektor Rimbun', 'Memiliki minimal 5 tanaman aktif di kebun virtualmu.', 'trees', '', 5, 5, '#EBF7F1', '#2D6A4F');
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _customDb?.close();
    _customDb = null;
    await _database?.close();
    _database = null;
  }

  /// Deletes the local SQLite database file.
  Future<void> deleteDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    await close();
    await deleteDatabase(path);
  }
}
