/// Base Failure class for Clean Architecture domain error handling.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Terjadi kesalahan pada basis data']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Email atau password salah']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Input tidak valid']);
}
