import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Raised for every non-2xx API response and for network failures.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final bool isNetworkError;

  const ApiException({
    this.statusCode,
    required this.message,
    this.isNetworkError = false,
  });

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin, authenticated JSON client for the Neptune REST API.
///
/// Identity is derived from the JWT server-side; the client never sends
/// collectorId/riderId in payloads.
class ApiClient {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
  });

  static ApiClient? _instance;

  /// Shared instance bound to the configured base URL.
  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient.instance has not been initialized');
    }
    return _instance!;
  }

  static void initialize({required Future<String?> Function() tokenProvider}) {
    _instance = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: tokenProvider,
    );
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated) {
      final token = await tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final uri = _uri(path).replace(queryParameters: query);
    final response = await _send(
      () async => http.get(
        uri,
        headers: await _headers(authenticated: authenticated),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> post(
      String path, {
        Object? body,
        bool authenticated = true,
      }) async {
    final uri = _uri(path);
    final headers = await _headers(authenticated: authenticated);

    print('========== API POST ==========');
    print('URL: $uri');
    print('Authenticated: $authenticated');
    print('Body: $body');
    print('Headers: ${headers.keys}');
    print('==============================');

    final response = await _send(
          () async => http.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );

    print('========== API RESPONSE ======');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('==============================');

    return _decode(response);
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () async => http.patch(
        _uri(path),
        headers: await _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond. Please try again.',
        isNetworkError: true,
      );
    } on SocketException catch (e) {
      throw ApiException(
        message: formatNetworkError(e),
        isNetworkError: true,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: formatNetworkError(e),
        isNetworkError: true,
      );
    } on Exception catch (e) {
      throw ApiException(
        message: 'Unable to reach the server. Check your connection. Details: $e',
        isNetworkError: true,
      );
    }
  }

  static String formatNetworkError(Object error) {
    if (error is SocketException) {
      final details = <String>[];
      if (error.message.isNotEmpty) {
        details.add(error.message);
      }
      if (error.address != null) {
        details.add('address=${error.address}');
      }
      if (error.port != null) {
        details.add('port=${error.port}');
      }
      if (error.osError != null && error.osError!.message.isNotEmpty) {
        details.add(error.osError!.message);
      }
      return details.isEmpty ? error.toString() : details.join(' | ');
    }

    if (error is http.ClientException) {
      final details = <String>[];
      if (error.message.isNotEmpty) {
        details.add(error.message);
      }
      if (error.uri != null) {
        details.add('uri=${error.uri}');
      }
      return details.isEmpty ? error.toString() : details.join(' | ');
    }

    return error.toString();
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    final body = (response.body.isEmpty ||
            response.headers['content-type']?.contains('json') == false)
        ? null
        : _tryDecodeJson(response.body);

    if (status >= 200 && status < 300) {
      return body;
    }

    throw ApiException(
      statusCode: status,
      message: _messageFor(status, body),
    );
  }

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String _messageFor(int status, dynamic body) {
    final raw = body is Map ? body['message'] : null;
    var detail = '';
    if (raw is String) {
      detail = raw;
    } else if (raw is List && raw.isNotEmpty) {
      detail = raw.join('\n');
    }
    final fallback = switch (status) {
      400 => 'Invalid request. Please check the entered data.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested resource was not found.',
      409 => 'The request conflicts with its current state.',
      _ => 'Something went wrong (HTTP $status).',
    };
    return detail.isEmpty ? fallback : detail;
  }
}