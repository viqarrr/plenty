import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton Database Helper for PLENTY local SQLite database management.
///
/// Implements complete SQLite database schema creation in `_onCreate` with
/// INTEGER PRIMARY KEY AUTOINCREMENT on users table and integer user_id foreign keys across tables.
class DatabaseHelper {
  static const String _databaseName = 'plenty.db';
  static const int _databaseVersion = 2;

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

  DatabaseHelper.withDatabase(Database db)
      : _dbName = 'in_memory',
        _customDb = db;

  static Database? _database;

  /// Returns the database instance, initializing it if necessary.
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

  /// Handles schema upgrades across database versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchemaColumns(db);
  }

  /// Ensures required columns exist even on existing legacy local databases.
  Future<void> _onOpen(Database db) async {
    await _ensureSchemaColumns(db);
  }

  Future<void> _ensureSchemaColumns(Database db) async {
    try {
      final userPlantsColumns =
          await db.rawQuery('PRAGMA table_info($tableUserPlants)');
      final columnNames =
          userPlantsColumns.map((col) => col['name'] as String).toSet();

      if (!columnNames.contains('growth_stage')) {
        await db.execute(
          'ALTER TABLE $tableUserPlants ADD COLUMN growth_stage TEXT NOT NULL DEFAULT \'mature\';',
        );
      }
      if (!columnNames.contains('initial_height_cm')) {
        await db.execute(
          'ALTER TABLE $tableUserPlants ADD COLUMN initial_height_cm REAL DEFAULT 30.0;',
        );
      }
    } catch (_) {}

    try {
      final growthLogsColumns =
          await db.rawQuery('PRAGMA table_info($tableGrowthLogs)');
      final logColumnNames =
          growthLogsColumns.map((col) => col['name'] as String).toSet();

      if (!logColumnNames.contains('source')) {
        await db.execute(
          'ALTER TABLE $tableGrowthLogs ADD COLUMN source TEXT NOT NULL DEFAULT \'manual\';',
        );
      }
    } catch (_) {}
  }

  /// Creates all 13 ERD tables and default indexes directly in _onCreate without migrations.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. users: INTEGER PRIMARY KEY AUTOINCREMENT
    batch.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE,
        password TEXT NOT NULL DEFAULT '',
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
        user_id INTEGER NOT NULL,
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

    // 4. user_plants
    batch.execute('''
      CREATE TABLE $tableUserPlants (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        catalog_id TEXT,
        nickname TEXT NOT NULL,
        is_indoor INTEGER NOT NULL DEFAULT 1,
        sunlight_condition TEXT,
        pot_size TEXT,
        window_distance TEXT,
        initial_height_cm REAL DEFAULT 30.0,
        growth_stage TEXT NOT NULL DEFAULT 'mature',
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
        logged_at TEXT NOT NULL,
        height_cm REAL NOT NULL,
        leaf_count INTEGER,
        photo_path TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        note TEXT,
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
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL UNIQUE,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        current_tier INTEGER NOT NULL DEFAULT 1,
        last_streak_date TEXT,
        last_completed_date TEXT,
        freeze_tokens_available INTEGER DEFAULT 1,
        freeze_used_on TEXT,
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
        user_id INTEGER NOT NULL,
        badge_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        UNIQUE(user_id, badge_id),
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        FOREIGN KEY (badge_id) REFERENCES $tableBadges (id) ON DELETE CASCADE
      );
    ''');

    // 12. community_posts
    batch.execute('''
      CREATE TABLE $tableCommunityPosts (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        caption TEXT,
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
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES $tableCommunityPosts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      );
    ''');

    // Indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_care_schedules_plant ON $tableCareSchedules(user_plant_id);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_care_logs_plant_date ON $tableCareActionLogs(user_plant_id, log_date);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_growth_logs_plant ON $tableGrowthLogs(user_plant_id, logged_at);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_community_posts_created ON $tableCommunityPosts(created_at DESC);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_community_posts_category ON $tableCommunityPosts(category);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_plants_user ON $tableUserPlants(user_id);',
    );

    // Seed Initial Default User (id: 1)
    batch.execute('''
      INSERT OR IGNORE INTO $tableUsers (id, email, username, password, display_name, created_at)
      VALUES (1, 'default@plenty.app', 'user_default', '', 'Pecinta Tanaman', '${DateTime.now().toIso8601String()}');
    ''');

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
