import 'api_client.dart';

class RegistrationApi {
  // POST /api/activities/:id/register
  static Future<void> register(int activityId) async {
    await apiClient.post('/api/activities/$activityId/register');
  }

  // DELETE /api/activities/:id/register
  static Future<void> unregister(int activityId) async {
    await apiClient.delete('/api/activities/$activityId/register');
  }

  // GET /api/me/registrations
  // Trả về cấu trúc từ backend: { items: [...], total, page, pages, limit }
  static Future<Map<String, dynamic>> myRegistrations({
    int page = 1,
    int limit = 20,
    String status = '',
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
    };
    final query = qp.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final res = await apiClient.get(
      '/api/me/registrations${query.isNotEmpty ? '?$query' : ''}',
    );
    return res;
  }
}
