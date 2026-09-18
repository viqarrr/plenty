import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/features/onboarding/domain/models/user_preference_model.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
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

  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;
  late MockCollectionReference mockSubcollection;
  late MockDocumentReference mockSubDoc;
  late FirestoreProfileRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockSubcollection = MockCollectionReference();
    mockSubDoc = MockDocumentReference();

    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection(any())).thenReturn(mockSubcollection);
    when(() => mockSubcollection.doc(any())).thenReturn(mockSubDoc);

    dataSource = FirestoreProfileRemoteDataSourceImpl(
      firestore: mockFirestore,
      firebaseAuth: mockAuth,
    );
  });

  group('FirestoreProfileRemoteDataSourceImpl Profile Tests', () {
    const testUid = 'user_abc_123';

    test('getUserProfile returns UserModel when doc exists', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'id': testUid,
        'email': 'tester@plenty.app',
        'display_name': 'Green Thumb',
        'username': 'greenthumb',
        'streak_count': 5,
        'longest_streak': 10,
        'total_xp': 250,
        'level': 2,
      });

      final result = await dataSource.getUserProfile(testUid);

      expect(result, isNotNull);
      expect(result!.id, equals(testUid));
      expect(result.email, equals('tester@plenty.app'));
      expect(result.displayName, equals('Green Thumb'));
      expect(result.streakCount, equals(5));
      expect(result.totalXp, equals(250));
      expect(result.level, equals(2));
      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCollection.doc(testUid)).called(1);
    });

    test('getUserProfile returns null when doc does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final result = await dataSource.getUserProfile(testUid);

      expect(result, isNull);
    });

    test('updateUserProfile merges data and updates auth displayName if matched', () async {
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(testUid);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});

      await dataSource.updateUserProfile(testUid, {
        'display_name': 'Updated Name',
        'bio': 'Loves succulents',
        'password': 'should_be_stripped',
      });

      verify(
        () => mockUserDoc.set(
          {'display_name': 'Updated Name', 'bio': 'Loves succulents'},
          any(),
        ),
      ).called(1);
      verify(() => mockUser.updateDisplayName('Updated Name')).called(1);
    });

    test('updatePassword calls currentUser.updatePassword', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.updatePassword(any())).thenAnswer((_) async {});

      await dataSource.updatePassword('NewSecretPassword123!');

      verify(() => mockUser.updatePassword('NewSecretPassword123!')).called(1);
    });

    test('updatePassword throws if currentUser is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => dataSource.updatePassword('NewSecretPassword123!'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('FirestoreProfileRemoteDataSourceImpl Preferences Tests', () {
    const testUid = 'user_abc_123';

    test('getUserPreferences returns UserPreferenceModel when doc exists', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSubDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'id': 'pref_1',
        'user_id': testUid,
        'experience_level': 'Pemula',
        'daily_time_minutes': 15,
        'has_pets': true,
        'has_kids': false,
        'has_completed_onboarding': true,
      });

      final result = await dataSource.getUserPreferences(testUid);

      expect(result, isNotNull);
      expect(result!.experienceLevel, equals('Pemula'));
      expect(result.dailyTimeMinutes, equals(15));
      expect(result.hasPets, isTrue);
      expect(result.hasKids, isFalse);
      expect(result.hasCompletedOnboarding, isTrue);
      verify(() => mockUserDoc.collection('settings')).called(1);
      verify(() => mockSubcollection.doc('preferences')).called(1);
    });

    test('saveUserPreferences writes model data to settings/preferences', () async {
      when(() => mockSubDoc.set(any(), any())).thenAnswer((_) async {});

      final prefs = UserPreferenceModel(
        id: 'pref_1',
        userId: testUid,
        experienceLevel: 'Menengah',
        dailyTimeMinutes: 30,
        hasPets: false,
        hasKids: true,
        hasCompletedOnboarding: true,
      );

      await dataSource.saveUserPreferences(testUid, prefs);

      verify(() => mockUserDoc.collection('settings')).called(1);
      verify(() => mockSubcollection.doc('preferences')).called(1);
      verify(
        () => mockSubDoc.set(
          any(that: isA<Map<String, dynamic>>()),
          any(),
        ),
      ).called(1);
    });
  });

  group('FirestoreProfileRemoteDataSourceImpl Badges & Gamification Tests', () {
    const testUid = 'user_abc_123';

    test('getUserBadges returns list of badge maps', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      when(() => mockSubcollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(() => mockDoc1.data()).thenReturn({
        'badge_id': 'first_plant',
        'is_unlocked': true,
        'current_progress': 1,
      });
      when(() => mockDoc2.data()).thenReturn({
        'badge_id': 'streak_7',
        'is_unlocked': true,
        'current_progress': 7,
      });

      final result = await dataSource.getUserBadges(testUid);

      expect(result.length, equals(2));
      expect(result.first['badge_id'], equals('first_plant'));
      expect(result.last['badge_id'], equals('streak_7'));
      verify(() => mockUserDoc.collection('badges')).called(1);
    });

    test('awardBadge saves badge doc and updates unlocked_badges_count', () async {
      final mockBadgeDocSnapshot = MockDocumentSnapshot();
      when(() => mockSubDoc.get()).thenAnswer((_) async => mockBadgeDocSnapshot);
      when(() => mockBadgeDocSnapshot.exists).thenReturn(false);
      when(() => mockSubDoc.set(any(), any())).thenAnswer((_) async {});
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});

      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();
      when(() => mockSubcollection.where('is_unlocked', isEqualTo: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);

      await dataSource.awardBadge(testUid, 'first_plant', '2026-03-09T00:00:00Z');

      verify(
        () => mockSubDoc.set({
          'badge_id': 'first_plant',
          'is_unlocked': true,
          'current_progress': 1,
          'unlocked_at': '2026-03-09T00:00:00Z',
        }, any()),
      ).called(1);

      verify(
        () => mockUserDoc.set({
          'unlocked_badges_count': 1,
        }, any()),
      ).called(1);
    });

    test('updateUserStreak updates streak fields on users/{uid}', () async {
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.updateUserStreak(
        testUid,
        streak: 5,
        longestStreak: 12,
        lastStreakDate: '2026-03-09',
      );

      verify(
        () => mockUserDoc.set({
          'streak_count': 5,
          'longest_streak': 12,
          'last_streak_date': '2026-03-09',
        }, any()),
      ).called(1);
    });

    test('updateUserXpAndLevel updates XP and level on users/{uid}', () async {
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.updateUserXpAndLevel(
        testUid,
        totalXp: 500,
        level: 3,
      );

      verify(
        () => mockUserDoc.set({
          'total_xp': 500,
          'level': 3,
        }, any()),
      ).called(1);
    });
  });
}
