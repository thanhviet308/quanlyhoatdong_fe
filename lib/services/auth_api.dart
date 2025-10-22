import 'api_client.dart';
import 'token_storage.dart';

class AuthApi {
  // POST /api/auth/login
  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final data = await apiClient.post(
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );
    final token = (data['token'] as String?) ?? '';
    if (token.isEmpty) throw Exception('Không nhận được token');
    await TokenStorage.save(token);
  }

  // POST /api/auth/register
  static Future<void> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
  }) async {
    await apiClient.post(
      '/api/auth/register',
      body: {
        'username': username,
        'password': password,
        'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }

  // GET /api/auth/me
  static Future<Map<String, dynamic>> me() async {
    return apiClient.get('/api/auth/me');
  }

  static Future<void> logout() async => TokenStorage.clear();
}
