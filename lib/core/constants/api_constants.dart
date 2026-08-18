/// Constants for external API configurations (Perenual Plant API).
abstract final class ApiConstants {
  ApiConstants._();

  /// Perenual API Base URL
  static const String baseUrl = 'https://perenual.com/api';

  /// Default API Key with compile-time environment override option:
  /// `--dart-define=PERENUAL_API_KEY=your_key`
  static const String defaultApiKey = "";

  static String get apiKey => const String.fromEnvironment(
    'PERENUAL_API_KEY',
    defaultValue: defaultApiKey,
  );

  /// Endpoints
  static const String speciesListEndpoint = '/species-list';
  static const String speciesDetailsEndpoint = '/species/details';
  static const String speciesCareGuideEndpoint = '/species-care-guide-list';

  /// Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
