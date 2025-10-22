import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiClient {
  final String baseUrl;
  ApiClient(this.baseUrl);

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final token = await TokenStorage.read();
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PUT':
        return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PATCH':
        return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw UnsupportedError('Method $method not supported');
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _send('GET', path);
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final res = await _send('POST', path, body: body);
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _send('DELETE', path);
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final res = await _send('PUT', path, body: body);
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final res = await _send('PATCH', path, body: body);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final text = res.body;
    Map<String, dynamic> data = {};
    try {
      data = text.isNotEmpty ? (jsonDecode(text) as Map<String, dynamic>) : {};
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = data['message'] ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }
    return data;
  }
}

// ✅ Khai báo client dùng biến môi trường hoặc mặc định
final apiClient = ApiClient(
  const String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:3000', // dành cho Android emulator
  ),
);
