import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Contract interface for remote file storage operations (Firebase Cloud Storage).
abstract interface class StorageRemoteDataSource {
  /// Uploads a local file at [filePath] to [destinationPath] in Firebase Storage.
  /// Returns the publicly accessible download URL on success.
  /// If [filePath] is already a network URL or an asset path, returns it as-is.
  Future<String> uploadFile({
    required String filePath,
    required String destinationPath,
    String? contentType,
  });

  /// Deletes a file in remote storage by its download [fileUrl].
  Future<void> deleteFile(String fileUrl);
}

/// Concrete implementation of [StorageRemoteDataSource] backed by Firebase Cloud Storage.
class FirebaseStorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final FirebaseStorage? _customStorage;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  FirebaseStorageRemoteDataSourceImpl({FirebaseStorage? storage})
      : _customStorage = storage;

  @override
  Future<String> uploadFile({
    required String filePath,
    required String destinationPath,
    String? contentType,
  }) async {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }

    final file = File(trimmed);
    if (!file.existsSync()) {
      return trimmed;
    }

    try {
      final ref = _storage.ref().child(destinationPath);
      final metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : SettableMetadata(contentType: _guessContentType(trimmed));

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      // Offline resilience fallback: keep local path if upload fails
      return trimmed;
    }
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    final trimmed = fileUrl.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return;
    }
    try {
      final ref = _storage.refFromURL(trimmed);
      await ref.delete();
    } catch (_) {
      // Silently ignore delete errors on missing / permission issues
    }
  }

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
