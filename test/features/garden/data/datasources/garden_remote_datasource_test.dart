import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/features/garden/data/datasources/garden_remote_datasource.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';

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
  late MockCollectionReference mockSitesCollection;
  late MockCollectionReference mockUserPlantsCollection;
  late MockDocumentReference mockSiteDoc;
  late MockDocumentReference mockPlantDoc;
  late FirestoreGardenRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockSitesCollection = MockCollectionReference();
    mockUserPlantsCollection = MockCollectionReference();
    mockSiteDoc = MockDocumentReference();
    mockPlantDoc = MockDocumentReference();

    when(() => mockFirestore.collection('sites')).thenReturn(mockSitesCollection);
    when(() => mockFirestore.collection('user_plants')).thenReturn(mockUserPlantsCollection);
    when(() => mockSitesCollection.doc(any())).thenReturn(mockSiteDoc);
    when(() => mockUserPlantsCollection.doc(any())).thenReturn(mockPlantDoc);

    dataSource = FirestoreGardenRemoteDataSourceImpl(firestore: mockFirestore);
  });

  group('FirestoreGardenRemoteDataSourceImpl Sites Tests', () {
    test('getSites queries sites collection by user_id and returns sorted sites', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      final now = DateTime.now();
      when(() => mockSitesCollection.where('user_id', isEqualTo: 'user_123'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(() => mockDoc1.data()).thenReturn({
        'id': 'site_custom_1',
        'user_id': 'user_123',
        'name': 'Balkon Atas',
        'icon_code': 58428,
        'is_indoor': false,
        'is_custom': true,
        'created_at': now.add(const Duration(minutes: 1)).toIso8601String(),
      });
      when(() => mockDoc2.data()).thenReturn({
        'id': 'site_default_1',
        'user_id': 'user_123',
        'name': 'Ruang Tamu',
        'icon_code': 58428,
        'is_indoor': true,
        'is_custom': false,
        'created_at': now.toIso8601String(),
      });

      final sites = await dataSource.getSites('user_123');

      expect(sites.length, 2);
      // Default sites should be sorted first (isCustom == false)
      expect(sites.first.isCustom, isFalse);
      expect(sites.first.name, 'Ruang Tamu');
      expect(sites.last.isCustom, isTrue);
      expect(sites.last.name, 'Balkon Atas');
    });

    test('saveSite writes site data with merge', () async {
      when(() => mockSiteDoc.set(any(), any())).thenAnswer((_) async {});

      final site = SiteModel(
        id: 'site_test',
        userId: 'user_123',
        name: 'Dapur',
        iconCode: 12345,
        isIndoor: true,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      await dataSource.saveSite(site);

      verify(() => mockSitesCollection.doc('site_test')).called(1);
      verify(() => mockSiteDoc.set(site.toFirestoreMap(), any())).called(1);
    });

    test('updateSite writes updated site data', () async {
      when(() => mockSiteDoc.set(any(), any())).thenAnswer((_) async {});

      final site = SiteModel(
        id: 'site_test',
        userId: 'user_123',
        name: 'Kamar Tidur Baru',
        iconCode: 12345,
        isIndoor: true,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      await dataSource.updateSite(site);

      verify(() => mockSitesCollection.doc('site_test')).called(1);
      verify(() => mockSiteDoc.set(site.toFirestoreMap(), any())).called(1);
    });

    test('deleteSite calls delete on document reference', () async {
      when(() => mockSiteDoc.delete()).thenAnswer((_) async {});

      await dataSource.deleteSite('site_to_delete');

      verify(() => mockSitesCollection.doc('site_to_delete')).called(1);
      verify(() => mockSiteDoc.delete()).called(1);
    });
  });

  group('FirestoreGardenRemoteDataSourceImpl Plants Tests', () {
    test('getUserPlants queries user_plants by user_id and filters out archived plants', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocActive = MockQueryDocumentSnapshot();
      final mockDocArchived = MockQueryDocumentSnapshot();

      final now = DateTime.now();
      when(() => mockUserPlantsCollection.where('user_id', isEqualTo: 'user_123'))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocActive, mockDocArchived]);

      when(() => mockDocActive.data()).thenReturn({
        'id': 'plant_active_1',
        'user_id': 'user_123',
        'nickname': 'Monstera Hijau',
        'site_id': 'site_1',
        'level': 2,
        'xp': 50,
        'is_archived': false,
        'adopted_at': now.toIso8601String(),
      });
      when(() => mockDocArchived.data()).thenReturn({
        'id': 'plant_archived_1',
        'user_id': 'user_123',
        'nickname': 'Kaktus Lama',
        'site_id': 'site_1',
        'level': 1,
        'xp': 0,
        'is_archived': true,
        'adopted_at': now.subtract(const Duration(days: 10)).toIso8601String(),
      });

      final plants = await dataSource.getUserPlants('user_123');

      expect(plants.length, 1);
      expect(plants.first.id, 'plant_active_1');
      expect(plants.first.nickname, 'Monstera Hijau');
      expect(plants.first.level, 2);
    });

    test('getPlantById returns PlantModel when doc exists', () async {
      final mockDocSnap = MockDocumentSnapshot();
      when(() => mockPlantDoc.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.data()).thenReturn({
        'id': 'plant_single',
        'user_id': 'user_123',
        'nickname': 'Sansevieria',
        'site_id': 'site_1',
        'adopted_at': DateTime.now().toIso8601String(),
      });

      final plant = await dataSource.getPlantById('plant_single');

      expect(plant, isNotNull);
      expect(plant!.id, 'plant_single');
      expect(plant.nickname, 'Sansevieria');
    });

    test('getPlantById returns null when doc does not exist', () async {
      final mockDocSnap = MockDocumentSnapshot();
      when(() => mockPlantDoc.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(false);

      final plant = await dataSource.getPlantById('plant_non_existent');

      expect(plant, isNull);
    });

    test('savePlant writes plant toFirestoreMap with merge', () async {
      when(() => mockPlantDoc.set(any(), any())).thenAnswer((_) async {});

      final plant = PlantModel(
        id: 'plant_save_test',
        userId: 'user_123',
        nickname: 'Aglonema Cantik',
        siteId: 'site_1',
      );

      await dataSource.savePlant(plant);

      verify(() => mockUserPlantsCollection.doc('plant_save_test')).called(1);
      verify(() => mockPlantDoc.set(any(), any())).called(1);
    });

    test('updatePlant updates specified fields', () async {
      when(() => mockPlantDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.updatePlant('plant_update_test', {
        'nickname': 'Nama Baru',
        'cover_photo_path': 'path/to/photo.jpg',
      });

      verify(() => mockUserPlantsCollection.doc('plant_update_test')).called(1);
      verify(() => mockPlantDoc.set({
        'nickname': 'Nama Baru',
        'cover_photo_path': 'path/to/photo.jpg',
      }, any())).called(1);
    });

    test('archivePlant sets is_archived to true', () async {
      when(() => mockPlantDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.archivePlant('plant_archive_test');

      verify(() => mockUserPlantsCollection.doc('plant_archive_test')).called(1);
      verify(() => mockPlantDoc.set({'is_archived': true}, any())).called(1);
    });

    test('deletePlant deletes plant doc', () async {
      when(() => mockPlantDoc.delete()).thenAnswer((_) async {});

      await dataSource.deletePlant('plant_delete_test');

      verify(() => mockUserPlantsCollection.doc('plant_delete_test')).called(1);
      verify(() => mockPlantDoc.delete()).called(1);
    });
  });
}
