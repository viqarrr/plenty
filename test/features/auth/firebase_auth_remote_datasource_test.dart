import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/features/auth/data/datasources/auth_remote_datasource.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late FirebaseAuthRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();

    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);

    dataSource = FirebaseAuthRemoteDataSourceImpl(
      firebaseAuth: mockAuth,
      firestore: mockFirestore,
    );
  });

  group('FirebaseAuthRemoteDataSourceImpl Firestore Sync Tests', () {
    test('signUp creates user in Auth and saves profile to Firestore users collection', () async {
      when(() => mockUser.uid).thenReturn('uid_firestore_123');
      when(() => mockUser.email).thenReturn('new@plenty.app');
      when(() => mockUser.displayName).thenReturn('New Gardener');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.metadata).thenReturn(MockUserMetadata());
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: 'new@plenty.app',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);

      when(
        () => mockUserDoc.set(any(), any()),
      ).thenAnswer((_) async {});

      final result = await dataSource.signUp(
        email: 'new@plenty.app',
        password: 'Password123!',
        displayName: 'New Gardener',
        username: 'newgardener',
      );

      expect(result.id, 'uid_firestore_123');
      expect(result.email, 'new@plenty.app');
      expect(result.displayName, 'New Gardener');
      expect(result.username, 'newgardener');

      // Verify Firestore collection 'users' was accessed and document set
      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCollection.doc('uid_firestore_123')).called(1);
      verify(
        () => mockUserDoc.set(
          any(that: isA<Map<String, dynamic>>()),
          any(),
        ),
      ).called(1);
    });

    test('signIn retrieves existing profile from Firestore', () async {
      when(() => mockUser.uid).thenReturn('uid_firestore_123');
      when(() => mockUser.email).thenReturn('gardener@plenty.app');
      when(() => mockUser.displayName).thenReturn('Cloud Gardener');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.metadata).thenReturn(MockUserMetadata());

      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'gardener@plenty.app',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);

      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'id': 'uid_firestore_123',
        'email': 'gardener@plenty.app',
        'display_name': 'Cloud Gardener',
        'username': 'cloudgardener',
        'streak_count': 7,
        'total_xp': 350,
        'level': 3,
      });

      when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);

      final result = await dataSource.signIn(
        email: 'gardener@plenty.app',
        password: 'Password123!',
      );

      expect(result.id, 'uid_firestore_123');
      expect(result.displayName, 'Cloud Gardener');
      expect(result.username, 'cloudgardener');
      expect(result.streakCount, 7);
      expect(result.totalXp, 350);
      expect(result.level, 3);

      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCollection.doc('uid_firestore_123')).called(1);
    });

    test('signIn backfills Firestore users document if it did not exist yet', () async {
      when(() => mockUser.uid).thenReturn('uid_legacy_auth');
      when(() => mockUser.email).thenReturn('legacy@plenty.app');
      when(() => mockUser.displayName).thenReturn('Legacy User');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.metadata).thenReturn(MockUserMetadata());

      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'legacy@plenty.app',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);

      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.data()).thenReturn(null);

      when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});

      final result = await dataSource.signIn(
        email: 'legacy@plenty.app',
        password: 'Password123!',
      );

      expect(result.id, 'uid_legacy_auth');
      expect(result.email, 'legacy@plenty.app');

      // Verify Firestore backfill set was executed
      verify(() => mockUserDoc.set(any(), any())).called(1);
    });
  });
}

class MockUserMetadata extends Mock implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime(2026, 1, 1);
}
