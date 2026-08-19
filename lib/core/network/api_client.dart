import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plenty/core/constants/api_constants.dart';
import 'package:plenty/core/error/failure.dart';

/// Centralized API Client wrapping `http.Client` with timeouts, logging, and error mapping.
class ApiClient {
  final http.Client _client;
  final String? _baseUrl;
  final String? _apiKey;

  ApiClient({http.Client? client, String? baseUrl, String? apiKey})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConstants.baseUrl,
      _apiKey = apiKey ?? ApiConstants.apiKey;

  /// Executes a GET request against the Perenual API, injecting API key and query parameters.
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final params = <String, String?>{'key': _apiKey};

    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value != null) {
          params[key] = value.toString();
        }
      });
    }

    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    final uri = Uri.parse(
      '$_baseUrl$normalizedEndpoint',
    ).replace(queryParameters: params);

    if (kDebugMode) {
      debugPrint('[ApiClient] GET: ${uri.toString()}');
    }

    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(ApiConstants.receiveTimeout);

      if (kDebugMode) {
        debugPrint(
          '[ApiClient] Response [${response.statusCode}] from ${uri.path}',
        );
      }

      return _handleResponse(response);
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] SocketException: $e');
      throw const NetworkFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on HttpException catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] HttpException: $e');
      throw const NetworkFailure('Gagal melakukan permintaan HTTP');
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] FormatException: $e');
      throw const ServerFailure('Format respon server tidak valid');
    } on Failure {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] Unexpected error: $e');
      if (e.toString().contains('TimeoutException')) {
        throw const NetworkFailure(
          'Waktu permintaan habis (Connection timeout)',
        );
      }
      throw ServerFailure('Terjadi kesalahan tidak terduga: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (statusCode == 401 || statusCode == 403) {
      throw ServerFailure(
        'Akses API ditolak atau kuota habis (HTTP $statusCode)',
        statusCode,
      );
    } else if (statusCode == 404) {
      throw const NotFoundFailure('Data tanaman tidak ditemukan di server');
    } else if (statusCode == 429) {
      throw const ServerFailure(
        'Batas permintaan harian API Perenual telah tercapai (100 req/hari)',
        429,
      );
    } else {
      throw ServerFailure(
        'Server mengembalikan kode status $statusCode',
        statusCode,
      );
    }
  }

  void close() {
    _client.close();
  }
}
