import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';

/// Contract interface for Authentication Repository.
abstract interface class IAuthRepository {
  /// Reactive stream of user authentication status changes.
  Stream<UserModel?> get authStateChanges;

  /// The currently signed in user, if any.
  UserModel? get currentUser;

  Future<Result<UserModel>> login({
    required String email,
    required String password,
  });

  Future<Result<bool>> register(UserModel user);

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<List<UserModel>>> getAllUsers();

  Future<Result<bool>> deleteUser(String id);

  Future<Result<bool>> updateUser(UserModel user);

  Future<Result<void>> logout();
}

/// Backwards-compatible alias for [IAuthRepository].
typedef AuthRepository = IAuthRepository;
