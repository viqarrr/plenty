import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/features/garden/data/datasources/growth_remote_datasource.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';

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
  late MockCollectionReference mockGrowthLogsCollection;
  late MockCollectionReference mockTimeCapsulesCollection;
  late MockDocumentReference mockGrowthLogDoc;
  late MockDocumentReference mockTimeCapsuleDoc;
  late FirestoreGrowthRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockGrowthLogsCollection = MockCollectionReference();
    mockTimeCapsulesCollection = MockCollectionReference();
    mockGrowthLogDoc = MockDocumentReference();
    mockTimeCapsuleDoc = MockDocumentReference();

    when(() => mockFirestore.collection('growth_logs'))
        .thenReturn(mockGrowthLogsCollection);
    when(() => mockFirestore.collection('time_capsules'))
        .thenReturn(mockTimeCapsulesCollection);

    when(() => mockGrowthLogsCollection.doc(any())).thenReturn(mockGrowthLogDoc);
    when(() => mockTimeCapsulesCollection.doc(any())).thenReturn(mockTimeCapsuleDoc);

    dataSource = FirestoreGrowthRemoteDataSourceImpl(firestore: mockFirestore);
  });

  group('FirestoreGrowthRemoteDataSourceImpl - Growth Logs', () {
    test('getGrowthLogs queries growth_logs and sorts by loggedAt ascending', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      final now = DateTime.now();
      when(() => mockGrowthLogsCollection.where('user_plant_id', isEqualTo: 'plant_1'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(() => mockDoc1.data()).thenReturn({
        'id': 'log_later',
        'user_plant_id': 'plant_1',
        'height_cm': 35.0,
        'logged_at': now.toIso8601String(),
        'source': 'daily_task',
      });
      when(() => mockDoc2.data()).thenReturn({
        'id': 'log_earlier',
        'user_plant_id': 'plant_1',
        'height_cm': 30.0,
        'logged_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'source': 'initial',
      });

      final logs = await dataSource.getGrowthLogs('plant_1');

      expect(logs.length, 2);
      expect(logs.first.id, 'log_earlier');
      expect(logs.last.id, 'log_later');
    });

    test('saveGrowthLog sets log data with merge', () async {
      when(() => mockGrowthLogDoc.set(any(), any())).thenAnswer((_) async {});

      final log = GrowthLogModel(
        id: 'log_new',
        userPlantId: 'plant_1',
        heightCm: 32.5,
        loggedAt: DateTime.now(),
        note: 'Tumbuh subur',
      );

      await dataSource.saveGrowthLog(log);

      verify(() => mockGrowthLogsCollection.doc('log_new')).called(1);
      verify(() => mockGrowthLogDoc.set(log.toFirestoreMap(), any())).called(1);
    });

    test('updateGrowthLog sets sanitized data with merge', () async {
      when(() => mockGrowthLogDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.updateGrowthLog('log_1', {
        'height_cm': 33.0,
        'note': 'Catatan baru',
        'photo_path': null, // Should be sanitized out
      });

      verify(() => mockGrowthLogsCollection.doc('log_1')).called(1);
      verify(() => mockGrowthLogDoc.set({
        'height_cm': 33.0,
        'note': 'Catatan baru',
      }, any())).called(1);
    });
  });

  group('FirestoreGrowthRemoteDataSourceImpl - Time Capsules', () {
    test('getTimeCapsule queries time_capsules and returns newest capsule', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      final now = DateTime.now();
      when(() => mockTimeCapsulesCollection.where('user_plant_id', isEqualTo: 'plant_1'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(() => mockDoc1.data()).thenReturn({
        'id': 'capsule_old',
        'user_plant_id': 'plant_1',
        'note': 'Pesan lama',
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
        'is_unlocked': false,
      });
      when(() => mockDoc2.data()).thenReturn({
        'id': 'capsule_new',
        'user_plant_id': 'plant_1',
        'note': 'Pesan baru',
        'created_at': now.toIso8601String(),
        'is_unlocked': false,
      });

      final capsule = await dataSource.getTimeCapsule('plant_1');

      expect(capsule, isNotNull);
      expect(capsule!.id, 'capsule_new');
      expect(capsule.note, 'Pesan baru');
    });

    test('getTimeCapsule returns null if no documents found', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(() => mockTimeCapsulesCollection.where('user_plant_id', isEqualTo: 'plant_empty'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([]);

      final capsule = await dataSource.getTimeCapsule('plant_empty');

      expect(capsule, isNull);
    });

    test('saveTimeCapsule sets capsule data with merge', () async {
      when(() => mockTimeCapsuleDoc.set(any(), any())).thenAnswer((_) async {});

      final capsule = TimeCapsuleModel(
        id: 'capsule_save',
        userPlantId: 'plant_1',
        photoPath: 'test_photo.jpg',
        note: 'Harapan untuk tanaman',
        createdAt: DateTime.now(),
        unlockAt: DateTime.now().add(const Duration(days: 30)),
        isUnlocked: false,
      );

      await dataSource.saveTimeCapsule(capsule);

      verify(() => mockTimeCapsulesCollection.doc('capsule_save')).called(1);
      verify(() => mockTimeCapsuleDoc.set(capsule.toFirestoreMap(), any())).called(1);
    });

    test('unlockTimeCapsule sets is_unlocked true with merge', () async {
      when(() => mockTimeCapsuleDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.unlockTimeCapsule('capsule_to_unlock');

      verify(() => mockTimeCapsulesCollection.doc('capsule_to_unlock')).called(1);
      verify(() => mockTimeCapsuleDoc.set(
            any(that: predicate<Map<String, dynamic>>((m) => m['is_unlocked'] == true)),
            any(),
          )).called(1);
    });
  });
}
