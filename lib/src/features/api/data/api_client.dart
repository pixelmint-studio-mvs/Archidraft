import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_client_io.dart' if (dart.library.html) 'api_client_web.dart' as platform_io;

class ApiClient {
  final FirebaseAuth _firebaseAuth;
  // Use http://localhost:8787 for local dev or the deployed worker URL
  final String baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8787');

  ApiClient(this._firebaseAuth);

  Future<Map<String, String>> _getHeaders() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
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
      ..headers['X-File-Name'] = fileName
      ..headers['X-Action-Id'] = actionId
      ..headers['Content-Length'] = length.toString();

    stream.listen(
      (data) => request.sink.add(data),
      onDone: () => request.sink.close(),
      onError: (e) => request.sink.addError(e),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<List<int>> downloadBinary(String path) async {
    // Deprecated for large files: Use downloadFileStream instead for Mobile
    final uri = Uri.parse('$baseUrl$path');
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> downloadFileStream(String path, String savePath) async {
    final uri = Uri.parse('$baseUrl$path');
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();

    final request = http.Request('GET', uri)
      ..headers['Authorization'] = 'Bearer $token';

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await platform_io.saveFileStream(response.stream, savePath);
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
