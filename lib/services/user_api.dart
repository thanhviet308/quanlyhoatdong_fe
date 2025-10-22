import 'api_client.dart';

class UserApi {
  static Future<Map<String, dynamic>> updateUser(
    int id, {
    String? username,
    String? fullName,
    String? email,
    String? role,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (role != null) body['role'] = role;
    if (newPassword != null) body['new_password'] = newPassword;
    return apiClient.post(
      '/api/users/$id',
      body: body,
    ); // backend expects PUT but apiClient has post/put? We'll add put.
  }

  static Future<Map<String, dynamic>> putUser(
    int id, {
    String? username,
    String? fullName,
    String? email,
    String? role,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (role != null) body['role'] = role;
    return apiClient.put('/api/users/$id', body: body);
  }

  static Future<void> changePassword(
    int id, {
    String? oldPassword,
    required String newPassword,
  }) async {
    final body = <String, dynamic>{'new_password': newPassword};
    if (oldPassword != null && oldPassword.isNotEmpty)
      body['old_password'] = oldPassword;
    await apiClient.patch('/api/users/$id/password', body: body);
  }
}
