import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['PERENUAL_BASE_URL'] ??
          dotenv.env['BASE_URL'] ??
          'https://perenual.com/api';
    }
    return 'https://perenual.com/api';
  }

  static String get apiKey {
    if (dotenv.isInitialized) {
      return dotenv.env['API_KEY'] ?? 'sk-mCLH6a7d748a06b3519317';
    }
    return 'sk-mCLH6a7d748a06b3519317';
  }

  /// Endpoints
  static const String speciesListEndpoint = '/species-list';
  static const String speciesDetailsEndpoint = '/species/details';
  static const String speciesCareGuideEndpoint = '/species-care-guide-list';

  /// Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
