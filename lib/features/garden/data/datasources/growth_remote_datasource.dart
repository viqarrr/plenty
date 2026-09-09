import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';

/// Contract interface for Growth tracking and Time Capsules in Cloud Firestore.
abstract interface class GrowthRemoteDataSource {
  /// Fetches historical growth logs for a plant from Firestore collection `growth_logs`.
  Future<List<GrowthLogModel>> getGrowthLogs(String userPlantId);

  /// Saves or upserts a growth log document in Firestore collection `growth_logs/{logId}`.
  Future<void> saveGrowthLog(GrowthLogModel log);

  /// Updates specific attributes of a growth log in Firestore collection `growth_logs/{logId}`.
  Future<void> updateGrowthLog(String logId, Map<String, dynamic> data);

  /// Retrieves the latest time capsule for a plant from Firestore collection `time_capsules`.
  Future<TimeCapsuleModel?> getTimeCapsule(String userPlantId);

  /// Saves a time capsule in Firestore collection `time_capsules/{capsuleId}`.
  Future<void> saveTimeCapsule(TimeCapsuleModel capsule);

  /// Marks a time capsule as unlocked in Firestore collection `time_capsules/{capsuleId}`.
  Future<void> unlockTimeCapsule(String capsuleId);
}

/// Concrete implementation of [GrowthRemoteDataSource] backed by Cloud Firestore.
class FirestoreGrowthRemoteDataSourceImpl implements GrowthRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  static const String growthLogsCollection = 'growth_logs';
  static const String timeCapsulesCollection = 'time_capsules';

  FirestoreGrowthRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  @override
  Future<List<GrowthLogModel>> getGrowthLogs(String userPlantId) async {
    final querySnap = await _firestore
        .collection(growthLogsCollection)
        .where('user_plant_id', isEqualTo: userPlantId)
        .get();

    final logs = querySnap.docs
        .map((doc) => GrowthLogModel.fromMap(doc.data()))
        .toList();

    // Sort in memory by loggedAt ascending
    logs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    return logs;
  }

  @override
  Future<void> saveGrowthLog(GrowthLogModel log) async {
    await _firestore
        .collection(growthLogsCollection)
        .doc(log.id)
        .set(log.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateGrowthLog(
      String logId, Map<String, dynamic> data) async {
    final sanitizedData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null);

    await _firestore
        .collection(growthLogsCollection)
        .doc(logId)
        .set(sanitizedData, SetOptions(merge: true));
  }

  @override
  Future<TimeCapsuleModel?> getTimeCapsule(String userPlantId) async {
    final querySnap = await _firestore
        .collection(timeCapsulesCollection)
        .where('user_plant_id', isEqualTo: userPlantId)
        .get();

    if (querySnap.docs.isEmpty) return null;

    final capsules = querySnap.docs
        .map((doc) => TimeCapsuleModel.fromMap(doc.data()))
        .toList();

    // Sort in memory: newest first
    capsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return capsules.first;
  }

  @override
  Future<void> saveTimeCapsule(TimeCapsuleModel capsule) async {
    await _firestore
        .collection(timeCapsulesCollection)
        .doc(capsule.id)
        .set(capsule.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> unlockTimeCapsule(String capsuleId) async {
    await _firestore
        .collection(timeCapsulesCollection)
        .doc(capsuleId)
        .set({
      'is_unlocked': true,
      'unlocked_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
