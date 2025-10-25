import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3000', // ⚠️ sửa cho đúng môi trường
);

class PagedActivities {
  final List<Activity> items;
  final int total;
  final int page;
  final int pages;

  PagedActivities({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });
}

class ActivityApi {
  static Future<String?> _getToken() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getString('token'); // nếu backend yêu cầu Bearer
    } catch (_) {
      return null;
    }
  }

  static Future<PagedActivities> list({
    String q = '',
    int page = 1,
    int limit = 20,
    String status =
        '', // EN: OPEN/ONGOING/CLOSED or VI labels accepted by backend
  }) async {
    final uri = Uri.parse('$kApiBase/api/activities').replace(
      queryParameters: {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        'page': page.toString(),
        'limit': limit.toString(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
    );

    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> data = json.decode(resp.body);
      final List list = (data['data'] ?? []) as List;

      final items = list
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (data['total'] ?? 0) as int;
      final curPage = (data['page'] ?? page) as int;
      final pages = (data['pages'] ?? 1) as int;

      return PagedActivities(
        items: items,
        total: total,
        page: curPage,
        pages: pages,
      );
    } else {
      throw Exception('Lỗi tải hoạt động: ${resp.statusCode} ${resp.body}');
    }
  }
}
