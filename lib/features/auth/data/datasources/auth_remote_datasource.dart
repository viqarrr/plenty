import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';

/// Contract interface for Remote Authentication Datasource using Firebase Auth and Firestore.
abstract interface class AuthRemoteDataSource {
  /// Reactive stream of user authentication status changes.
  Stream<UserModel?> get authStateChanges;

  /// The currently authenticated user, or null if unauthenticated.
  UserModel? get currentUser;

  /// Signs in a user with [email] and [password].
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Registers a new user with [email], [password], and [displayName].
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    String? username,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail(String email);

  /// Retrieves a user profile document from Cloud Firestore.
  Future<UserModel?> getUserProfile(String uid);

  /// Saves or updates a user profile document in Cloud Firestore.
  Future<void> saveUserProfile(UserModel user);
}

/// Firebase Auth and Cloud Firestore implementation of [AuthRemoteDataSource].
class FirebaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const String usersCollection = 'users';

  FirebaseAuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
          (user) => user != null ? _mapFirebaseUserToModel(user) : null,
        );
  }

  @override
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? _mapFirebaseUserToModel(user) : null;
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Pengguna tidak ditemukan.',
      );
    }

    try {
      final doc =
          await _firestore.collection(usersCollection).doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      } else {
        // Document does not exist in Firestore yet (e.g. registered before Firestore was added).
        // Automatically create and backfill user record in Firestore.
        final fallbackModel = _mapFirebaseUserToModel(user);
        await _firestore.collection(usersCollection).doc(user.uid).set(
          fallbackModel.toFirestoreMap(),
          SetOptions(merge: true),
        );
        return fallbackModel;
      }
    } catch (_) {
      return _mapFirebaseUserToModel(user);
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    String? username,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Gagal membuat pengguna baru.',
      );
    }

    final trimmedName = displayName.trim();
    if (trimmedName.isNotEmpty) {
      await user.updateDisplayName(trimmedName);
      await user.reload();
    }

    final refreshedUser = _firebaseAuth.currentUser ?? user;
    final model = _mapFirebaseUserToModel(
      refreshedUser,
      displayName: trimmedName.isNotEmpty ? trimmedName : null,
      username: username,
    );

    // Persist new user profile to Cloud Firestore 'users' collection
    await _firestore
        .collection(usersCollection)
        .doc(refreshedUser.uid)
        .set(model.toFirestoreMap(), SetOptions(merge: true));

    return model;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc =
        await _firestore.collection(usersCollection).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    final uid = user.id ?? _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'ID pengguna tidak ditemukan.',
      );
    }
    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .set(user.toFirestoreMap(), SetOptions(merge: true));
  }

  /// Maps Firebase [User] entity to domain [UserModel].
  UserModel _mapFirebaseUserToModel(
    User user, {
    String? displayName,
    String? username,
  }) {
    final email = user.email ?? '';
    final fallbackUsername =
        email.contains('@') ? email.split('@').first : email;
    final effectiveDisplayName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (user.displayName != null && user.displayName!.isNotEmpty
            ? user.displayName!
            : (username ?? fallbackUsername));

    return UserModel(
      id: user.uid,
      email: email,
      displayName: effectiveDisplayName,
      username: username ?? fallbackUsername,
      avatarUrl: user.photoURL,
      createdAt: user.metadata.creationTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    );
  }
}
