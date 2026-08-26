import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'plenty.db';
  static const int _databaseVersion = 1;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableUserPreferences = 'user_preferences';
  static const String tableUserPlants = 'user_plants';
  static const String tableCareSchedules = 'care_schedules';
  static const String tableCareActionLogs = 'care_action_logs';
  static const String tableGrowthLogs = 'growth_logs';
  static const String tableTimeCapsules = 'time_capsules';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableCommunityPosts = 'community_posts';
  static const String tablePostComments = 'post_comments';
  static const String tablePostLikes = 'post_likes';
  static const String tableCustomSites = 'custom_sites';

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
    if (_dbName != _databaseName) {
      _customDb = await _initDatabaseForName(_dbName);
      return _customDb!;
    }
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabaseForName(String name) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, name);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: _onCreate,
    );
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE,
        password TEXT NOT NULL DEFAULT '',
        display_name TEXT NOT NULL,
        bio TEXT,
        avatar_url TEXT,
        streak_count INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        total_xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        unlocked_badges_count INTEGER NOT NULL DEFAULT 0,
        last_streak_date TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableUserPreferences (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        experience_level TEXT NOT NULL,
        daily_time_minutes REAL DEFAULT 15.0,
        has_pets INTEGER DEFAULT 0,
        has_kids INTEGER DEFAULT 0,
        available_time TEXT,
        safety_restriction TEXT,
        has_completed_onboarding INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableUserPlants (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        species_id INTEGER,
        catalog_id TEXT,
        species_name TEXT NOT NULL DEFAULT '',
        scientific_name TEXT,
        nickname TEXT NOT NULL DEFAULT 'Tanaman Hias',
        room_name TEXT NOT NULL DEFAULT 'Ruang Tamu',
        placement_type TEXT NOT NULL DEFAULT 'Indoor',
        window_distance TEXT,
        pot_size TEXT,
        initial_height REAL NOT NULL DEFAULT 30.0,
        current_height REAL NOT NULL DEFAULT 30.0,
        image_path TEXT,
        watering_interval_days INTEGER NOT NULL DEFAULT 7,
        sunlight_preference TEXT,
        is_pet_friendly INTEGER DEFAULT 0,
        adopted_at TEXT NOT NULL DEFAULT '',
        is_indoor INTEGER NOT NULL DEFAULT 1,
        sunlight_condition TEXT,
        site TEXT,
        initial_height_cm REAL DEFAULT 30.0,
        growth_stage TEXT NOT NULL DEFAULT 'mature',
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        health_status TEXT NOT NULL DEFAULT 'healthy',
        cover_photo_path TEXT,
        default_watering_interval INTEGER NOT NULL DEFAULT 7,
        care_level TEXT,
        toxicity TEXT,
        description TEXT,
        growth_rate TEXT,
        growth_cycle TEXT,
        pruning_season TEXT,
        flower_status TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableCareSchedules (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        task_type TEXT NOT NULL,
        interval_days INTEGER NOT NULL,
        last_performed_at TEXT,
        next_due_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_plant_id) REFERENCES user_plants (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableCareActionLogs (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        task_type TEXT NOT NULL,
        action_type TEXT,
        performed_at TEXT,
        completed_at TEXT NOT NULL,
        log_date TEXT,
        xp_awarded INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (user_plant_id) REFERENCES user_plants (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableGrowthLogs (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        height_cm REAL NOT NULL,
        leaf_count INTEGER,
        photo_path TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        note TEXT,
        FOREIGN KEY (user_plant_id) REFERENCES user_plants (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableTimeCapsules (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        photo_path TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        unlock_at TEXT NOT NULL,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_plant_id) REFERENCES user_plants (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableBadges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        tier_name TEXT NOT NULL DEFAULT 'Normal',
        level INTEGER NOT NULL DEFAULT 1,
        target_total INTEGER NOT NULL DEFAULT 1,
        bg_color_hex TEXT NOT NULL DEFAULT '#EBF7F1',
        accent_color_hex TEXT NOT NULL DEFAULT '#2D6A4F'
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableUserBadges (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        badge_id TEXT NOT NULL,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        current_progress INTEGER NOT NULL DEFAULT 0,
        unlocked_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (badge_id) REFERENCES badges (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableCommunityPosts (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        caption TEXT,
        image_url TEXT,
        badge_id TEXT,
        kudos_count INTEGER DEFAULT 0,
        is_liked INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (badge_id) REFERENCES badges (id) ON DELETE SET NULL
      );
    ''');
    /* 
    batch.execute('''
      CREATE TABLE post_comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES community_posts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');
 */
    batch.execute('''
      CREATE TABLE $tablePostLikes (
        post_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES community_posts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE $tableCustomSites (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        is_indoor INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      INSERT OR IGNORE INTO users (id, email, username, password, display_name, streak_count, longest_streak, total_xp, level, unlocked_badges_count, created_at)
      VALUES (1, 'default@plenty.app', 'user_default', '', 'Pecinta Tanaman', 0, 0, 0, 1, 0, '${DateTime.now().toIso8601String()}');
    ''');

    // Initial Badge Seeds
    batch.execute('''
      INSERT OR IGNORE INTO badges (id, title, description, icon_name, tier_name, level, target_total, bg_color_hex, accent_color_hex) VALUES
      ('first_plant', 'Adopsi Pertama', 'Mengadopsi tanaman pertama untuk memulai perjalanan berkebunmu.', 'sprout', '', 1, 1, '#EBF7F1', '#2D6A4F'),
      ('water_streak', 'Penyiram Setia', 'Menyiram tanaman tepat waktu selama 7 kali berturut-turut.', 'droplets', '', 7, 7, '#FBF3DB', '#956400'),
      ('time_capsule', 'Kapsul Waktu', 'Membuat pesan kapsul waktu pertama saat menanam.', 'hourglass', '', 1, 1, '#E3F0FF', '#1F6C9F'),
      ('plant_collector', 'Kolektor Rimbun', 'Memiliki minimal 5 tanaman aktif di kebun virtualmu.', 'trees', '', 5, 5, '#EBF7F1', '#2D6A4F'),
      ('doctor_green', 'Dokter Tanaman', 'Mencatat jurnal kondisi kesehatan tanaman sebanyak 10 kali.', 'activity', '', 10, 10, '#EFEBF7', '#5B4B8A'),
      ('sun_master', 'Pencari Cahaya', 'Menempatkan tanaman di lokasi dengan intensitas cahaya ideal.', 'sun', '', 1, 1, '#FBF3DB', '#956400');
    ''');

    // Default User Initial Progress Seed (User ID 1 starts with 0 unlocked badges)
    batch.execute('''
      INSERT OR IGNORE INTO user_badges (id, user_id, badge_id, is_unlocked, current_progress, unlocked_at) VALUES
      ('ub_1_first_plant', 1, 'first_plant', 0, 0, NULL),
      ('ub_1_water_streak', 1, 'water_streak', 0, 0, NULL),
      ('ub_1_time_capsule', 1, 'time_capsule', 0, 0, NULL),
      ('ub_1_plant_collector', 1, 'plant_collector', 0, 0, NULL),
      ('ub_1_doctor_green', 1, 'doctor_green', 0, 0, NULL),
      ('ub_1_sun_master', 1, 'sun_master', 0, 0, NULL);
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_customDb != null && _customDb!.isOpen) {
      await _customDb!.close();
      _customDb = null;
    }
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes the local SQLite database file.
  Future<void> deleteDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await close();
    await deleteDatabase(path);
  }
}
