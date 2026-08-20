import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';

/// State of a plant's time capsule.
enum TimeCapsuleState { none, locked, unlocked }

/// Repository managing historical plant growth records, photo timelines, and time capsules.
class GrowthRepository {
  final DatabaseHelper _dbHelper;

  GrowthRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Retrieves height data points ordered chronologically for plotting growth graphs.
  Future<List<GrowthLogModel>> getHeightSeries(String userPlantId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableGrowthLogs,
      where: 'user_plant_id = ? AND height_cm IS NOT NULL',
      whereArgs: [userPlantId],
      orderBy: 'logged_at ASC',
    );

    return maps.map((m) => GrowthLogModel.fromMap(m)).toList();
  }

  /// Alias for getHeightSeries.
  Future<List<GrowthLogModel>> getGrowthHistory(String userPlantId) =>
      getHeightSeries(userPlantId);

  /// Retrieves growth logs for the photo timeline and growth history gallery.
  /// Returns all historical growth records ordered from newest to oldest.
  Future<List<GrowthLogModel>> getPhotoGallery(String userPlantId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableGrowthLogs,
      where: 'user_plant_id = ?',
      whereArgs: [userPlantId],
      orderBy: 'logged_at DESC',
    );

    return maps.map((m) => GrowthLogModel.fromMap(m)).toList();
  }

  /// Retrieves the current time capsule state for a plant.
  Future<TimeCapsuleState> getTimeCapsuleState(String userPlantId) async {
    final capsule = await getTimeCapsule(userPlantId);
    if (capsule == null) return TimeCapsuleState.none;
    if (capsule.isUnlocked || DateTime.now().isAfter(capsule.unlockAt)) {
      return TimeCapsuleState.unlocked;
    }
    return TimeCapsuleState.locked;
  }

  /// Retrieves the stored time capsule for a plant.
  Future<TimeCapsuleModel?> getTimeCapsule(String userPlantId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTimeCapsules,
      where: 'user_plant_id = ?',
      whereArgs: [userPlantId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return TimeCapsuleModel.fromMap(maps.first);
  }

  /// Unlocks a time capsule.
  Future<void> unlockTimeCapsule(String capsuleId) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTimeCapsules,
      {'is_unlocked': 1},
      where: 'id = ?',
      whereArgs: [capsuleId],
    );
  }

  /// Creates a time capsule for a plant from plant details screen.
  Future<void> createTimeCapsule({
    required String userPlantId,
    TimeCapsuleDraft? draft,
    String? message,
    int? durationMonths,
    String? photoPath,
  }) async {
    final actualDraft = draft ??
        TimeCapsuleDraft(
          message: message ?? '',
          durationMonths: durationMonths ?? 3,
          photoPath: photoPath ?? '',
        );

    final db = await _dbHelper.database;
    final model = TimeCapsuleModel(
      id: 'capsule_${DateTime.now().millisecondsSinceEpoch}',
      userPlantId: userPlantId,
      photoPath: actualDraft.photoPath,
      note: actualDraft.note,
      createdAt: DateTime.now(),
      unlockAt: actualDraft.unlockAt,
      isUnlocked: false,
    );
    await db.insert(
      DatabaseHelper.tableTimeCapsules,
      model.toMap(),
    );
  }

  /// Updates a specific growth log entry (height, note, photo) and refreshes plant height / cover if latest.
  Future<void> updateGrowthLog({
    required String logId,
    required String userPlantId,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final updateValues = <String, dynamic>{
        'height_cm': heightCm,
        'note': note,
      };
      if (photoPath != null && photoPath.isNotEmpty) {
        updateValues['photo_path'] = photoPath;
      }
      await txn.update(
        DatabaseHelper.tableGrowthLogs,
        updateValues,
        where: 'id = ?',
        whereArgs: [logId],
      );

      // Check if this log is the most recent log for this plant
      final latest = await txn.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ?',
        whereArgs: [userPlantId],
        orderBy: 'logged_at DESC',
        limit: 1,
      );

      if (latest.isNotEmpty && latest.first['id'] == logId) {
        if (photoPath != null && photoPath.isNotEmpty) {
          await txn.update(
            DatabaseHelper.tableUserPlants,
            {'cover_photo_path': photoPath},
            where: 'id = ?',
            whereArgs: [userPlantId],
          );
        }
      }
    });
  }
}
