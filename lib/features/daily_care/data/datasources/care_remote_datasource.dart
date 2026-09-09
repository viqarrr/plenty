import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plenty/features/daily_care/domain/models/care_action_log_model.dart';
import 'package:plenty/features/daily_care/domain/models/care_schedule_model.dart';

/// Contract interface for Daily Care schedules and action logs in Cloud Firestore.
abstract interface class CareRemoteDataSource {
  /// Fetches all active care schedules for a specific plant from `care_schedules`.
  Future<List<CareScheduleModel>> getSchedulesForPlant(String userPlantId);

  /// Saves or upserts a care schedule in Firestore collection `care_schedules/{scheduleId}`.
  Future<void> saveSchedule(CareScheduleModel schedule);

  /// Updates an existing care schedule in Firestore collection `care_schedules/{scheduleId}`.
  Future<void> updateSchedule(CareScheduleModel schedule);

  /// Retrieves care action audit logs for a specific plant or date.
  Future<List<CareActionLogModel>> getCareActionLogs({
    String? userPlantId,
    String? logDate,
  });

  /// Saves a new care action audit log in Firestore collection `care_action_logs/{logId}`.
  Future<void> saveCareActionLog(CareActionLogModel log);
}

/// Concrete implementation of [CareRemoteDataSource] backed by Cloud Firestore.
class FirestoreCareRemoteDataSourceImpl implements CareRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  static const String schedulesCollection = 'care_schedules';
  static const String actionLogsCollection = 'care_action_logs';

  FirestoreCareRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  @override
  Future<List<CareScheduleModel>> getSchedulesForPlant(
      String userPlantId) async {
    final querySnap = await _firestore
        .collection(schedulesCollection)
        .where('user_plant_id', isEqualTo: userPlantId)
        .get();

    return querySnap.docs
        .map((doc) => CareScheduleModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> saveSchedule(CareScheduleModel schedule) async {
    await _firestore
        .collection(schedulesCollection)
        .doc(schedule.id)
        .set(schedule.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateSchedule(CareScheduleModel schedule) async {
    await _firestore
        .collection(schedulesCollection)
        .doc(schedule.id)
        .set(schedule.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<List<CareActionLogModel>> getCareActionLogs({
    String? userPlantId,
    String? logDate,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(actionLogsCollection);

    if (userPlantId != null && userPlantId.isNotEmpty) {
      query = query.where('user_plant_id', isEqualTo: userPlantId);
    }
    if (logDate != null && logDate.isNotEmpty) {
      query = query.where('log_date', isEqualTo: logDate);
    }

    final querySnap = await query.get();

    final logs = querySnap.docs
        .map((doc) => CareActionLogModel.fromMap(doc.data()))
        .toList();

    // Sort in memory by completedAt descending
    logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return logs;
  }

  @override
  Future<void> saveCareActionLog(CareActionLogModel log) async {
    await _firestore
        .collection(actionLogsCollection)
        .doc(log.id)
        .set(log.toFirestoreMap(), SetOptions(merge: true));
  }
}
