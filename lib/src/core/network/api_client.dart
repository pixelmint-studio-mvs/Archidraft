import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(FirebaseAuth.instance);
});

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode $message';
}

class ApiClient {
  final FirebaseAuth _auth;
  final String baseUrl;

  // In production, this would be an environment variable.
  // For local development, point to the local Wrangler D1 server.
  ApiClient(this._auth, {this.baseUrl = 'http://127.0.0.1:8787/api'});

  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Unauthenticated");
    
    // Get the Firebase ID token
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = response.reasonPhrase ?? 'Unknown Error';
      try {
        final body = jsonDecode(response.body);
        if (body['error'] != null) {
          errorMessage = body['error'];
        }
      } catch (_) {}
      throw ApiException(response.statusCode, errorMessage);
    }
  }
}
