import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/features/daily_care/data/datasources/care_remote_datasource.dart';
import 'package:plenty/features/daily_care/domain/models/care_action_log_model.dart';
import 'package:plenty/features/daily_care/domain/models/care_schedule_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockSchedulesCollection;
  late MockCollectionReference mockActionLogsCollection;
  late MockDocumentReference mockScheduleDoc;
  late MockDocumentReference mockActionLogDoc;
  late FirestoreCareRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockSchedulesCollection = MockCollectionReference();
    mockActionLogsCollection = MockCollectionReference();
    mockScheduleDoc = MockDocumentReference();
    mockActionLogDoc = MockDocumentReference();

    when(() => mockFirestore.collection('care_schedules'))
        .thenReturn(mockSchedulesCollection);
    when(() => mockFirestore.collection('care_action_logs'))
        .thenReturn(mockActionLogsCollection);

    when(() => mockSchedulesCollection.doc(any())).thenReturn(mockScheduleDoc);
    when(() => mockActionLogsCollection.doc(any())).thenReturn(mockActionLogDoc);

    dataSource = FirestoreCareRemoteDataSourceImpl(firestore: mockFirestore);
  });

  group('FirestoreCareRemoteDataSourceImpl - Care Schedules', () {
    test('getSchedulesForPlant queries care_schedules where user_plant_id matches', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();

      when(() => mockSchedulesCollection.where('user_plant_id', isEqualTo: 'plant_1'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);

      when(() => mockDoc.data()).thenReturn({
        'id': 'sched_1',
        'user_plant_id': 'plant_1',
        'task_type': 'siram',
        'interval_days': 3,
        'next_due_date': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      final schedules = await dataSource.getSchedulesForPlant('plant_1');

      expect(schedules.length, 1);
      expect(schedules.first.id, 'sched_1');
      expect(schedules.first.taskType, 'siram');
      expect(schedules.first.intervalDays, 3);
      expect(schedules.first.isActive, isTrue);
    });

    test('saveSchedule writes schedule with merge', () async {
      when(() => mockScheduleDoc.set(any(), any())).thenAnswer((_) async {});

      final schedule = CareScheduleModel(
        id: 'sched_siram',
        userPlantId: 'plant_1',
        taskType: 'siram',
        intervalDays: 2,
        nextDueDate: DateTime.now(),
        isActive: true,
      );

      await dataSource.saveSchedule(schedule);

      verify(() => mockSchedulesCollection.doc('sched_siram')).called(1);
      verify(() => mockScheduleDoc.set(schedule.toFirestoreMap(), any())).called(1);
    });

    test('updateSchedule writes updated schedule with merge', () async {
      when(() => mockScheduleDoc.set(any(), any())).thenAnswer((_) async {});

      final schedule = CareScheduleModel(
        id: 'sched_bersih',
        userPlantId: 'plant_1',
        taskType: 'bersih',
        intervalDays: 7,
        lastPerformedAt: DateTime.now(),
        nextDueDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );

      await dataSource.updateSchedule(schedule);

      verify(() => mockSchedulesCollection.doc('sched_bersih')).called(1);
      verify(() => mockScheduleDoc.set(schedule.toFirestoreMap(), any())).called(1);
    });
  });

  group('FirestoreCareRemoteDataSourceImpl - Care Action Logs', () {
    test('saveCareActionLog writes action log with merge', () async {
      when(() => mockActionLogDoc.set(any(), any())).thenAnswer((_) async {});

      final log = CareActionLogModel(
        id: 'log_action_1',
        userPlantId: 'plant_1',
        taskType: 'siram',
        completedAt: DateTime.now(),
        logDate: '2026-09-09',
        xpAwarded: 10,
        notes: 'Disiram cukup',
      );

      await dataSource.saveCareActionLog(log);

      verify(() => mockActionLogsCollection.doc('log_action_1')).called(1);
      verify(() => mockActionLogDoc.set(log.toFirestoreMap(), any())).called(1);
    });

    test('getCareActionLogs applies filters and returns logs sorted descending', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      final now = DateTime.now();
      when(() => mockActionLogsCollection.where('user_plant_id', isEqualTo: 'plant_1'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(() => mockDoc1.data()).thenReturn({
        'id': 'log_earlier',
        'user_plant_id': 'plant_1',
        'task_type': 'siram',
        'completed_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'log_date': '2026-09-09',
        'xp_awarded': 10,
      });

      when(() => mockDoc2.data()).thenReturn({
        'id': 'log_later',
        'user_plant_id': 'plant_1',
        'task_type': 'bersih',
        'completed_at': now.toIso8601String(),
        'log_date': '2026-09-09',
        'xp_awarded': 10,
      });

      final logs = await dataSource.getCareActionLogs(userPlantId: 'plant_1');

      expect(logs.length, 2);
      // Newest should be first
      expect(logs.first.id, 'log_later');
      expect(logs.last.id, 'log_earlier');
    });
  });
}
