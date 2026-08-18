import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/data/models/user_model.dart';
import 'package:plenty/data/repositories/auth_repository.dart';
import 'package:plenty/data/repositories/auth_repository_impl.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthController({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepositoryImpl(),
        super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepo.login(email: email, password: password);
    switch (result) {
      case Success(data: final user):
        state = state.copyWith(user: user, isLoading: false);
        return true;
      case Error(failure: final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final user = UserModel(
      email: email,
      displayName: name,
      username: email.contains('@') ? email.split('@').first : email,
      password: password,
      createdAt: DateTime.now().toIso8601String(),
    );

    final result = await _authRepo.register(user);
    switch (result) {
      case Success():
        state = state.copyWith(user: user, isLoading: false);
        return true;
      case Error(failure: final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
