import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_env.dart';

class ApiClient {
  ApiClient({required this.client});

  final http.Client client;
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<dynamic> get(String path) async {
    final response = await _sendWithAndroidFallback(
      path: path,
      send: (uri) => client.get(uri, headers: _headers),
    );

    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final encodedBody = jsonEncode(body);
    final response = await _sendWithAndroidFallback(
      path: path,
      send: (uri) => client.post(uri, headers: _headers, body: encodedBody),
    );

    return _decode(response);
  }

  Future<dynamic> uploadFile({
    required String path,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final baseUrl = AppEnv.apiBaseUrl;
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PATCH', uri);

    final token = _authToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }

  Future<http.Response> _sendWithAndroidFallback({
    required String path,
    required Future<http.Response> Function(Uri uri) send,
  }) async {
    final uris = _requestUris(path);
    Object? lastError;

    for (var index = 0; index < uris.length; index++) {
      final uri = uris[index];

      try {
        return await send(uri).timeout(const Duration(seconds: 20));
      } on TimeoutException catch (error) {
        lastError = error;
        final isLast = index == uris.length - 1;
        if (isLast) {
          rethrow;
        }
      } on SocketException catch (error) {
        lastError = error;
        final isLast = index == uris.length - 1;
        if (isLast) {
          rethrow;
        }
      } on http.ClientException catch (error) {
        lastError = error;
        final isLast = index == uris.length - 1;
        if (isLast) {
          rethrow;
        }
      }
    }

    throw ApiException(
      'Request failed: ${lastError ?? 'unknown network error'}',
    );
  }

  List<Uri> _requestUris(String path) {
    final primary = AppEnv.apiBaseUrl;
    final fallback = AppEnv.androidFallbackApiBaseUrl;
    final urls = <String>[primary];

    if (fallback != null && fallback.isNotEmpty && fallback != primary) {
      urls.add(fallback);
    }

    return urls.map((baseUrl) => Uri.parse('$baseUrl$path')).toList();
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    final responseBody = response.body;

    if (status < 200 || status >= 300) {
      throw ApiException(
        'Request failed (${response.statusCode}): $responseBody',
      );
    }

    if (responseBody.isEmpty) {
      return null;
    }

    return jsonDecode(responseBody);
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
