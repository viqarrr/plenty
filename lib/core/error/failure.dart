/// Base Failure class for error handling across the application.
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

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Terjadi kesalahan pada server', this.statusCode]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Koneksi internet bermasalah']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal memuat cache lokal']);
}
