import 'package:flutter/foundation.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';

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

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepo;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  bool _isDisposed = false;

  AuthController({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepositoryImpl();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState(AuthState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _updateState(_state.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepo.login(email: email, password: password);
    switch (result) {
      case Success(data: final user):
        _updateState(_state.copyWith(user: user, isLoading: false));
        return true;
      case Error(failure: final failure):
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _updateState(_state.copyWith(isLoading: true, errorMessage: null));
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
        _updateState(_state.copyWith(user: user, isLoading: false));
        return true;
      case Error(failure: final failure):
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _updateState(const AuthState());
  }
}
