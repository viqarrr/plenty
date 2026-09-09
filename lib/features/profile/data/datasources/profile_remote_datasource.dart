import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/onboarding/domain/models/user_preference_model.dart';

/// Contract interface for Profile and Gamification remote operations using Cloud Firestore.
abstract interface class ProfileRemoteDataSource {
  /// Fetches the user profile document from `users/{uid}`.
  Future<UserModel?> getUserProfile(String uid);

  /// Updates profile attributes in `users/{uid}`.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data);

  /// Retrieves onboarding preferences from `users/{uid}/settings/preferences`.
  Future<UserPreferenceModel?> getUserPreferences(String uid);

  /// Saves or updates onboarding preferences in `users/{uid}/settings/preferences`.
  Future<void> saveUserPreferences(String uid, UserPreferenceModel prefs);

  /// Retrieves all awarded badges from `users/{uid}/badges`.
  Future<List<Map<String, dynamic>>> getUserBadges(String uid);

  /// Awards a badge by writing to `users/{uid}/badges/{badgeId}` and incrementing count.
  Future<void> awardBadge(String uid, String badgeId, String unlockedAt);

  /// Updates streak counters on `users/{uid}`.
  Future<void> updateUserStreak(
    String uid, {
    required int streak,
    required int longestStreak,
    String? lastStreakDate,
  });

  /// Updates user experience points and level on `users/{uid}`.
  Future<void> updateUserXpAndLevel(String uid, {required int totalXp, required int level});

  /// Updates the password of the active Firebase Auth user.
  Future<void> updatePassword(String newPassword);
}

/// Concrete implementation of [ProfileRemoteDataSource] backed by Cloud Firestore & Firebase Auth.
class FirestoreProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => _customAuth ?? FirebaseAuth.instance;

  static const String usersCollection = 'users';
  static const String settingsSubcollection = 'settings';
  static const String preferencesDoc = 'preferences';
  static const String badgesSubcollection = 'badges';

  FirestoreProfileRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _customFirestore = firestore,
        _customAuth = firebaseAuth;

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(usersCollection).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final sanitizedData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null || key == 'password');

    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .set(sanitizedData, SetOptions(merge: true));

    // Also sync displayName to Firebase Auth user profile if present
    final displayName = data['display_name'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      final user = _firebaseAuth.currentUser;
      if (user != null && user.uid == uid) {
        await user.updateDisplayName(displayName);
      }
    }
  }

  @override
  Future<UserPreferenceModel?> getUserPreferences(String uid) async {
    final doc = await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(settingsSubcollection)
        .doc(preferencesDoc)
        .get();

    if (doc.exists && doc.data() != null) {
      return UserPreferenceModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> saveUserPreferences(String uid, UserPreferenceModel prefs) async {
    final data = <String, dynamic>{
      'id': prefs.id.isNotEmpty ? prefs.id : 'pref_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': uid,
      'experience_level': prefs.experienceLevel,
      'daily_time_minutes': prefs.dailyTimeMinutes,
      'has_pets': prefs.hasPets,
      'has_kids': prefs.hasKids,
      'has_completed_onboarding': prefs.hasCompletedOnboarding,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(settingsSubcollection)
        .doc(preferencesDoc)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<List<Map<String, dynamic>>> getUserBadges(String uid) async {
    final query = await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(badgesSubcollection)
        .get();

    return query.docs.map((d) => d.data()).toList();
  }

  @override
  Future<void> awardBadge(String uid, String badgeId, String unlockedAt) async {
    final badgeDoc = _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(badgesSubcollection)
        .doc(badgeId);

    final snapshot = await badgeDoc.get();
    if (snapshot.exists && (snapshot.data()?['is_unlocked'] == true || snapshot.data()?['is_unlocked'] == 1)) {
      return; // Already awarded
    }

    await badgeDoc.set({
      'badge_id': badgeId,
      'is_unlocked': true,
      'current_progress': 1,
      'unlocked_at': unlockedAt,
    }, SetOptions(merge: true));

    // Update total unlocked badges count on the user document
    final allBadges = await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(badgesSubcollection)
        .where('is_unlocked', isEqualTo: true)
        .get();

    final badgeCount = allBadges.docs.length;

    await _firestore.collection(usersCollection).doc(uid).set({
      'unlocked_badges_count': badgeCount,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateUserStreak(
    String uid, {
    required int streak,
    required int longestStreak,
    String? lastStreakDate,
  }) async {
    final data = <String, dynamic>{
      'streak_count': streak,
      'longest_streak': longestStreak,
      if (lastStreakDate != null) 'last_streak_date': lastStreakDate,
    };

    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateUserXpAndLevel(
    String uid, {
    required int totalXp,
    required int level,
  }) async {
    await _firestore.collection(usersCollection).doc(uid).set({
      'total_xp': totalXp,
      'level': level,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Pengguna belum masuk.',
      );
    }
    await user.updatePassword(newPassword);
  }
}
