import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'plenty.db';
  static const int _databaseVersion = 1;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableUserPreferences = 'user_preferences';
  static const String tablePlantCatalog = 'plant_catalog';
  static const String tableUserPlants = 'user_plants';
  static const String tableCareSchedules = 'care_schedules';
  static const String tableCareActionLogs = 'care_action_logs';
  static const String tableGrowthLogs = 'growth_logs';
  static const String tableTimeCapsules = 'time_capsules';
  static const String tableBadges = 'badges';
  static const String tableCommunityPosts = 'community_posts';
  static const String tablePostComments = 'post_comments';
  static const String tableCustomSites = 'custom_sites';

  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal() : _dbName = _databaseName;

  DatabaseHelper.forTesting([String? dbName])
    : _dbName = dbName ?? 'test_${DateTime.now().microsecondsSinceEpoch}.db';

  DatabaseHelper.withDatabase(Database db)
    : _dbName = 'in_memory',
      _customDb = db;

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

    // 1. Users
    batch.execute('''
      CREATE TABLE users (
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
      CREATE TABLE user_preferences (
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
      CREATE TABLE plant_catalog (
        id TEXT PRIMARY KEY,
        common_name TEXT NOT NULL,
        scientific_name TEXT,
        family TEXT,
        default_watering_interval INTEGER NOT NULL DEFAULT 3,
        sunlight_level TEXT,
        care_level TEXT,
        image_url TEXT,
        local_image_path TEXT,
        toxicity TEXT,
        dimension TEXT,
        growth_rate TEXT,
        cycle TEXT,
        pruning_month TEXT,
        flowering_season TEXT,
        description TEXT,
        origin TEXT,
        is_toxic INTEGER DEFAULT 0,
        cached_at TEXT
      );
    ''');

    batch.execute('''
      CREATE TABLE user_plants (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        catalog_id TEXT,
        nickname TEXT NOT NULL,
        is_indoor INTEGER NOT NULL DEFAULT 1,
        sunlight_condition TEXT,
        pot_size TEXT,
        site TEXT,
        window_distance TEXT,
        initial_height_cm REAL DEFAULT 30.0,
        growth_stage TEXT NOT NULL DEFAULT 'mature',
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        health_status TEXT NOT NULL DEFAULT 'healthy',
        cover_photo_path TEXT,
        adopted_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (catalog_id) REFERENCES plant_catalog (id) ON DELETE SET NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE care_schedules (
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
      CREATE TABLE care_action_logs (
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
      CREATE TABLE growth_logs (
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
      CREATE TABLE time_capsules (
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
      CREATE TABLE badges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_asset_path TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE community_posts (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        caption TEXT,
        image_url TEXT,
        kudos_count INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

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

    batch.execute('''
      CREATE TABLE custom_sites (
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
