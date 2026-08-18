import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton Database Helper for PLENTY local SQLite database management.
///
/// Implements SQLite database initialization, lifecycle management, foreign key
/// constraints enforcement, and database schema creation according to the ERD specification.
class DatabaseHelper {
  static const String _databaseName = 'plenty.db';
  static const int _databaseVersion = 3;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableUserPreferences = 'user_preferences';
  static const String tablePlantCatalog = 'plant_catalog';
  static const String tableUserPlants = 'user_plants';
  static const String tableCareSchedules = 'care_schedules';
  static const String tableCareActionLogs = 'care_action_logs';
  static const String tableGrowthLogs = 'growth_logs';
  static const String tableTimeCapsules = 'time_capsules';
  static const String tableUserStreaks = 'user_streaks';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableCommunityPosts = 'community_posts';
  static const String tablePostComments = 'post_comments';

  final String _dbName;
  Database? _customDb;

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal() : _dbName = _databaseName;

  DatabaseHelper.forTesting([String? dbName])
      : _dbName = dbName ?? 'test_${DateTime.now().microsecondsSinceEpoch}.db';

  static Database? _database;

  /// Returns the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_dbName != _databaseName) {
      if (_customDb != null && _customDb!.isOpen) return _customDb!;
      _customDb = await _initDatabaseForName(_dbName);
      return _customDb!;
    }
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabaseForName(String name) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, name);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Initializes the SQLite database at the platform-appropriate database path.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Configures database connection parameters before opening.
  /// Enforces foreign key constraint checks.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Handles schema migrations across database versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN username TEXT;');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN password TEXT NOT NULL DEFAULT "";',
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tablePlantCatalog ADD COLUMN cached_at TEXT;');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUserPreferences ADD COLUMN daily_time_minutes REAL DEFAULT 15.0;',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUserPreferences ADD COLUMN has_pets INTEGER DEFAULT 0;',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableUserPreferences ADD COLUMN has_kids INTEGER DEFAULT 0;',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableGrowthLogs ADD COLUMN leaf_count INTEGER;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableCareActionLogs ADD COLUMN log_date TEXT;');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableCareActionLogs ADD COLUMN xp_awarded INTEGER DEFAULT 0;',
        );
      } catch (_) {}
    }
  }

  /// Runs idempotent column checks to ensure existing installed databases
  /// automatically adapt to any missing columns.
  Future<void> _onOpen(Database db) async {
    try {
      await db.execute('ALTER TABLE $tablePlantCatalog ADD COLUMN cached_at TEXT;');
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE $tableUserPreferences ADD COLUMN daily_time_minutes REAL DEFAULT 15.0;',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE $tableUserPreferences ADD COLUMN has_pets INTEGER DEFAULT 0;',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE $tableUserPreferences ADD COLUMN has_kids INTEGER DEFAULT 0;',
      );
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE $tableGrowthLogs ADD COLUMN leaf_count INTEGER;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE $tableCareActionLogs ADD COLUMN log_date TEXT;');
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE $tableCareActionLogs ADD COLUMN xp_awarded INTEGER DEFAULT 0;',
      );
    } catch (_) {}
  }

  /// Creates all 13 ERD tables and high-frequency query indexes.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. users
    batch.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE,
        password TEXT,
        display_name TEXT NOT NULL,
        bio TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. user_preferences
    batch.execute('''
      CREATE TABLE $tableUserPreferences (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        experience_level TEXT NOT NULL,
        daily_time_minutes REAL DEFAULT 15.0,
        has_pets INTEGER DEFAULT 0,
        has_kids INTEGER DEFAULT 0,
        available_time TEXT,
        safety_restriction TEXT,
        has_completed_onboarding INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      );
    ''');

    // 3. plant_catalog
    batch.execute('''
      CREATE TABLE $tablePlantCatalog (
        id TEXT PRIMARY KEY,
        common_name TEXT NOT NULL,
        scientific_name TEXT,
        family TEXT,
        default_watering_interval INTEGER NOT NULL DEFAULT 3,
        sunlight_level TEXT,
        care_level TEXT,
        image_url TEXT,
        local_image_path TEXT,
        cached_at TEXT
      );
    ''');

    // 4. user_plants
    batch.execute('''
      CREATE TABLE $tableUserPlants (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        catalog_id TEXT,
        nickname TEXT NOT NULL,
        is_indoor INTEGER NOT NULL DEFAULT 1,
        sunlight_condition TEXT,
        pot_size TEXT,
        window_distance TEXT,
        initial_height_cm REAL DEFAULT 30.0,
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        health_status TEXT NOT NULL DEFAULT 'healthy',
        cover_photo_path TEXT,
        adopted_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (catalog_id) REFERENCES $tablePlantCatalog (id) ON DELETE SET NULL
      );
    ''');

    // 5. care_schedules
    batch.execute('''
      CREATE TABLE $tableCareSchedules (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        task_type TEXT NOT NULL,
        interval_days INTEGER NOT NULL,
        last_performed_at TEXT,
        next_due_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      );
    ''');

    // 6. care_action_logs
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
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      );
    ''');

    // 7. growth_logs
    batch.execute('''
      CREATE TABLE $tableGrowthLogs (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        photo_path TEXT,
        height_cm REAL,
        leaf_count INTEGER,
        source TEXT NOT NULL DEFAULT 'manual',
        note TEXT,
        logged_at TEXT NOT NULL,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      );
    ''');

    // 8. time_capsules
    batch.execute('''
      CREATE TABLE $tableTimeCapsules (
        id TEXT PRIMARY KEY,
        user_plant_id TEXT NOT NULL,
        photo_path TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        unlock_at TEXT NOT NULL,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_plant_id) REFERENCES $tableUserPlants (id) ON DELETE CASCADE
      );
    ''');

    // 9. user_streaks
    batch.execute('''
      CREATE TABLE $tableUserStreaks (
        user_id TEXT PRIMARY KEY,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        current_tier INTEGER DEFAULT 1,
        last_streak_date TEXT,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      );
    ''');

    // 10. badges
    batch.execute('''
      CREATE TABLE $tableBadges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_asset_path TEXT NOT NULL
      );
    ''');

    // 11. user_badges
    batch.execute('''
      CREATE TABLE $tableUserBadges (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        badge_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (badge_id) REFERENCES $tableBadges (id) ON DELETE CASCADE
      );
    ''');

    // 12. community_posts
    batch.execute('''
      CREATE TABLE $tableCommunityPosts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category TEXT NOT NULL,
        caption TEXT NOT NULL,
        image_url TEXT,
        kudos_count INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      );
    ''');

    // 13. post_comments
    batch.execute('''
      CREATE TABLE $tablePostComments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES $tableCommunityPosts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      );
    ''');

    // High-frequency query indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_plants_user ON $tableUserPlants (user_id);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_care_schedules_plant ON $tableCareSchedules (user_plant_id);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_growth_logs_plant ON $tableGrowthLogs (user_plant_id);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_community_posts_created ON $tableCommunityPosts (created_at DESC);',
    );

    await batch.commit(noResult: true);
  }

  /// Closes the database connection.
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

  /// Deletes the local database file. Useful for testing or resetting user data.
  Future<void> deleteDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    await close();
    await deleteDatabase(path);
  }
}
