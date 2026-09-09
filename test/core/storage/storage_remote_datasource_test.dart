import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/storage/storage_remote_datasource.dart';

void main() {
  group('FirebaseStorageRemoteDataSourceImpl Edge Cases', () {
    late FirebaseStorageRemoteDataSourceImpl dataSource;

    setUp(() {
      dataSource = FirebaseStorageRemoteDataSourceImpl();
    });

    test('returns empty string if filePath is empty or whitespace', () async {
      final result1 = await dataSource.uploadFile(
        filePath: '',
        destinationPath: 'growth_logs/plant_1/photo.jpg',
      );
      expect(result1, '');

      final result2 = await dataSource.uploadFile(
        filePath: '   ',
        destinationPath: 'growth_logs/plant_1/photo.jpg',
      );
      expect(result2, '');
    });

    test('returns network URLs unchanged without uploading', () async {
      const httpUrl = 'http://example.com/flower.jpg';
      const httpsUrl = 'https://firebasestorage.googleapis.com/test.jpg';

      final res1 = await dataSource.uploadFile(
        filePath: httpUrl,
        destinationPath: 'growth_logs/plant_1/photo.jpg',
      );
      expect(res1, httpUrl);

      final res2 = await dataSource.uploadFile(
        filePath: httpsUrl,
        destinationPath: 'growth_logs/plant_1/photo.jpg',
      );
      expect(res2, httpsUrl);
    });

    test('returns asset paths unchanged without uploading', () async {
      const assetPath = 'assets/images/monstera.png';

      final res = await dataSource.uploadFile(
        filePath: assetPath,
        destinationPath: 'growth_logs/plant_1/photo.jpg',
      );
      expect(res, assetPath);
    });

    test('returns local path if file does not exist on disk', () async {
      const nonExistentPath = '/non/existent/path/to/img_9999.jpg';

      final res = await dataSource.uploadFile(
        filePath: nonExistentPath,
        destinationPath: 'growth_logs/plant_1/photo.jpg',
      );
      expect(res, nonExistentPath);
    });

    test('deleteFile ignores non-network URLs gracefully', () async {
      await expectLater(
        dataSource.deleteFile('assets/images/sample.jpg'),
        completes,
      );
      await expectLater(
        dataSource.deleteFile('/local/path/sample.jpg'),
        completes,
      );
      await expectLater(
        dataSource.deleteFile(''),
        completes,
      );
    });
  });
}
