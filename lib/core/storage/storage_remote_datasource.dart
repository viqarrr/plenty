import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('[StorageRemoteDataSource] File does not exist at: $trimmed');
      return trimmed;
    }

    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint(
          '[StorageRemoteDataSource] File at $trimmed is empty (0 bytes).',
        );
        return trimmed;
      }
    } catch (e) {
      debugPrint(
        '[StorageRemoteDataSource] Failed to read bytes from $trimmed: $e',
      );
      return trimmed;
    }

    // Clean destination path (remove leading slash if present)
    final cleanDest = destinationPath.startsWith('/')
        ? destinationPath.substring(1)
        : destinationPath;

    // Check auth session, attempt anonymous sign-in if unauthenticated
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint(
          '[StorageRemoteDataSource] Attempting anonymous auth for storage upload...',
        );
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {}

    final effectiveContentType = contentType ?? _guessContentType(trimmed);
    final metadata = SettableMetadata(
      contentType: effectiveContentType,
      cacheControl: 'public,max-age=31536000',
    );

    FirebaseStorage storageInstance;
    try {
      storageInstance = _storage;
    } catch (initErr) {
      debugPrint(
        '[StorageRemoteDataSource] FirebaseStorage instance unavailable: $initErr',
      );
      return trimmed;
    }

    try {
      debugPrint(
        '[StorageRemoteDataSource] Uploading ${bytes.length} bytes to $cleanDest...',
      );
      final ref = storageInstance.ref().child(cleanDest);

      String? downloadUrl;
      try {
        final uploadTask = ref.putData(bytes, metadata);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } catch (putDataErr) {
        debugPrint(
          '[StorageRemoteDataSource] putData encountered error: $putDataErr. Retrying with putFile...',
        );
        final uploadTask = ref.putFile(file, metadata);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      if (downloadUrl.isNotEmpty) {
        debugPrint(
          '[StorageRemoteDataSource] Upload success! Download URL: $downloadUrl',
        );
        return downloadUrl;
      }
      return trimmed;
    } on FirebaseException catch (e) {
      debugPrint(
        '[StorageRemoteDataSource] FirebaseException during upload: [${e.code}] ${e.message}',
      );
      if (e.code == 'unauthorized') {
        debugPrint(
          '[StorageRemoteDataSource] PERMISSION DENIED: Firebase Storage Security Rules blocked this upload.\n'
          'Pastikan di Firebase Console -> Storage -> Rules sudah diset:\n'
          '  allow read, write: if true; (atau if request.auth != null;)',
        );
      } else if (e.code == 'bucket-not-found' ||
          e.code == 'project-not-found' ||
          e.code == 'object-not-found') {
        // Try fallback to standard gs://plenty-ae791.appspot.com
        try {
          debugPrint(
            '[StorageRemoteDataSource] Trying fallback bucket gs://plenty-ae791.appspot.com...',
          );
          final fallbackStorage = FirebaseStorage.instanceFor(
            bucket: 'gs://plenty-ae791.appspot.com',
          );
          final fallbackRef = fallbackStorage.ref().child(cleanDest);
          final uploadTask = fallbackRef.putData(bytes, metadata);
          final snapshot = await uploadTask;
          final fallbackUrl = await snapshot.ref.getDownloadURL();
          debugPrint(
            '[StorageRemoteDataSource] Fallback bucket upload succeeded! URL: $fallbackUrl',
          );
          return fallbackUrl;
        } catch (fallbackError) {
          debugPrint(
            '[StorageRemoteDataSource] Fallback bucket also failed: $fallbackError',
          );
        }
      }
      return trimmed;
    } catch (e, st) {
      debugPrint('[StorageRemoteDataSource] Unexpected upload error: $e\n$st');
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
