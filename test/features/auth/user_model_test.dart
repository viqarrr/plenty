import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('creates UserModel with string id and default values', () {
      const user = UserModel(
        id: 'usr_firebase_123',
        email: 'gardener@plenty.app',
        displayName: 'Ayu Lestari',
        username: 'ayulestari',
      );

      expect(user.id, 'usr_firebase_123');
      expect(user.email, 'gardener@plenty.app');
      expect(user.displayName, 'Ayu Lestari');
      expect(user.username, 'ayulestari');
      expect(user.password, '');
      expect(user.streakCount, 0);
      expect(user.totalXp, 0);
      expect(user.level, 1);
    });

    test('numericId returns parsed integer for numeric strings', () {
      const user = UserModel(
        id: '42',
        email: 'test@plenty.app',
        displayName: 'Test',
        username: 'test',
      );

      expect(user.numericId, 42);
    });

    test('numericId returns consistent positive hash code for alphanumeric UIDs', () {
      const user = UserModel(
        id: 'wK8x9LmPq2',
        email: 'test@plenty.app',
        displayName: 'Test',
        username: 'test',
      );

      expect(user.numericId, isNotNull);
      expect(user.numericId, greaterThan(0));
      expect(user.numericId, equals(const UserModel(
        id: 'wK8x9LmPq2',
        email: 'other@plenty.app',
        displayName: 'Other',
        username: 'other',
      ).numericId));
    });

    test('fromMap parses legacy integer id from SQLite rows', () {
      final map = {
        'id': 1,
        'email': 'local@plenty.app',
        'password': 'hashed_password',
        'display_name': 'Local User',
        'username': 'local_user',
        'streak_count': 5,
        'total_xp': 250,
        'level': 2,
        'unlocked_badges_count': 3,
      };

      final user = UserModel.fromMap(map);
      expect(user.id, '1');
      expect(user.numericId, 1);
      expect(user.email, 'local@plenty.app');
      expect(user.displayName, 'Local User');
      expect(user.streakCount, 5);
      expect(user.totalXp, 250);
      expect(user.level, 2);
      expect(user.unlockedBadgesCount, 3);
    });

    test('fromMap parses Firebase alphanumeric uid string', () {
      final map = {
        'id': 'fire_uid_999',
        'email': 'cloud@plenty.app',
        'display_name': 'Cloud User',
        'username': 'cloud_user',
      };

      final user = UserModel.fromMap(map);
      expect(user.id, 'fire_uid_999');
      expect(user.email, 'cloud@plenty.app');
      expect(user.displayName, 'Cloud User');
    });

    test('toMap omits password by default for secure serialization', () {
      const user = UserModel(
        id: 'u1',
        email: 'secret@plenty.app',
        password: 'SuperSecretPassword',
        displayName: 'Secret User',
        username: 'secret',
      );

      final map = user.toMap();
      expect(map.containsKey('password'), isFalse);
      expect(map['email'], 'secret@plenty.app');
      expect(map['id'], 'u1');

      final mapWithPassword = user.toMap(includePassword: true);
      expect(mapWithPassword['password'], 'SuperSecretPassword');
    });

    test('copyWith properly updates specified fields', () {
      const original = UserModel(
        id: 'u1',
        email: 'old@plenty.app',
        displayName: 'Old Name',
        username: 'old_user',
      );

      final updated = original.copyWith(
        displayName: 'New Name',
        totalXp: 100,
        level: 3,
      );

      expect(updated.id, 'u1');
      expect(updated.email, 'old@plenty.app');
      expect(updated.displayName, 'New Name');
      expect(updated.totalXp, 100);
      expect(updated.level, 3);
    });
  });
}
