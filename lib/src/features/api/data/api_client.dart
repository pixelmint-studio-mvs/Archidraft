import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_client_io.dart' if (dart.library.html) 'api_client_web.dart' as platform_io;

class ApiClient {
  final FirebaseAuth _firebaseAuth;
  final String baseUrl;

  ApiClient(this._firebaseAuth, {String? baseUrl, bool? isRelease})
      : baseUrl = resolveBaseUrl(overrideUrl: baseUrl, isRelease: isRelease);

  /// Resolves and validates the base API URL.
  ///
  /// In release builds:
  /// - Requires an explicit `--dart-define=API_URL=https://...`
  /// - Fails closed if missing, not HTTPS, or pointing to localhost/127.0.0.1
  ///
  /// In debug/test builds:
  /// - Permits explicit `--dart-define=API_URL=...`
  /// - Defaults safely to `http://localhost:8787` for local development
  static String resolveBaseUrl({
    String? overrideUrl,
    bool? isRelease,
    bool? isAndroidEmulator,
  }) {
    final releaseMode = isRelease ?? kReleaseMode;
    final configured = (overrideUrl ?? const String.fromEnvironment('API_URL')).trim();

    if (releaseMode) {
      if (configured.isEmpty) {
        throw StateError(
          'API_URL must be explicitly configured for release builds via --dart-define=API_URL=https://...',
        );
      }
      final uri = Uri.tryParse(configured);
      if (uri == null || !uri.hasScheme || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) {
        throw StateError(
          'API_URL in release builds must be a valid HTTPS URL (got: "$configured")',
        );
      }
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        throw StateError(
          'API_URL in release builds cannot point to localhost/127.0.0.1 (got: "$configured")',
        );
      }
      return configured;
    }

    final isEmulatorHost = isAndroidEmulator ??
        (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            !platform_io.isUnderFlutterTest());

    if (configured.isNotEmpty) {
      if (isEmulatorHost) {
        final uri = Uri.tryParse(configured);
        if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
          return uri.replace(host: '10.0.2.2').toString();
        }
      }
      return configured;
    }

    if (isEmulatorHost) {
      return 'http://10.0.2.2:8787';
    }

    return 'http://localhost:8787';
  }

  Future<Map<String, String>> getAuthHeaders() async {
    return _getHeaders();
  }

  static const stagingTestUids = {
    'KXAR90JgoVYLuOKzkbxpKTC8ATa2', // Staging Engineer
    'TJjtkBm3lgRlpKtcI5u3jpYPH9s1', // Staging Draughtsman
    '2iypyxUntQX6djOzwjgPo5xWrGD2', // Staging Student
    'QBhduHDU1mYUxvtQ89adVnwQYCg1', // Staging Studio Admin
  };

  Future<Map<String, String>> _getHeaders() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    if (stagingTestUids.contains(user.uid)) {
      headers['X-Staging-Test-Mode'] = 'workflow-e2e';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.delete(
      uri,
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> postFileStream(String path, Stream<List<int>> stream, int length, {required String fileName, required String contentType, required String actionId}) async {
    final uri = Uri.parse('$baseUrl$path');
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    
    final request = http.StreamedRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = contentType
      ..headers['X-File-Name'] = Uri.encodeComponent(fileName)
      ..headers['X-Action-Id'] = actionId
      ..contentLength = length;

    // Pipe the stream into the request sink
    stream.listen(
      request.sink.add,
      onError: request.sink.addError,
      onDone: request.sink.close,
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<List<int>> downloadBinary(String path) async {
    // Deprecated for large files: Use downloadFileStream instead for Mobile
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    headers.remove('Content-Type');
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> downloadFileStream(String path, String savePath, {bool openInBrowser = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    headers.remove('Content-Type');

    final request = http.Request('GET', uri)
      ..headers.addAll(headers);

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentType = response.headers['content-type'];
        await platform_io.saveFileStream(
          response.stream,
          savePath,
          openInBrowser: openInBrowser,
          contentType: contentType,
        );
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('API Error: ${response.statusCode} - $errorBody');
      }
    } finally {
      client.close();
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
