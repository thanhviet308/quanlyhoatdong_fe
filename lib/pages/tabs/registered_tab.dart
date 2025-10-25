import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/registration_api.dart';
import '../registration_detail_page.dart';

class RegisteredTab extends StatefulWidget {
  const RegisteredTab({super.key});

  @override
  State<RegisteredTab> createState() => _RegisteredTabState();
}

class _RegisteredTabState extends State<RegisteredTab> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await RegistrationApi.myRegistrations(
        page: _page,
        limit: 20,
      );
      final items = (data['items'] as List? ?? [])
          .cast<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      _items = items;
      _page = (data['page'] as int?) ?? 1;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách đăng ký: $e')),
      );
      _items = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56),
            const SizedBox(height: 8),
            const Text('Chưa có hoạt động nào.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Tải lại')),
          ],
        ),
      );
    }

    String _actStatusVi(String? s) {
      final up = (s ?? '').toUpperCase();
      if (up == 'OPEN') return 'Đang mở';
      if (up == 'ONGOING') return 'Đang diễn ra';
      if (up == 'CLOSED') return 'Kết thúc';
      return s ?? '';
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final it = _items[i];
          final activity = (it['activity'] as Map?)?.cast<String, dynamic>();
          final title =
              activity?['title'] as String? ?? 'Hoạt động #${it['id'] ?? ''}';
          final start = activity?['start_time'] as String?;
          final dt = start != null && start.isNotEmpty
              ? DateTime.tryParse(start)
              : null;
          final timeOnly = dt != null
              ? DateFormat('EEE, dd/MM/yyyy', 'vi_VN').format(dt)
              : '';
          final actStatus = (activity?['status'] as String?) ?? '';
          final actColor = switch (actStatus.toUpperCase()) {
            'OPEN' => Colors.blue,
            'ONGOING' => Colors.orange,
            'CLOSED' => Colors.grey,
            _ => Colors.blueGrey,
          };
          final subtitle = [if (timeOnly.isNotEmpty) timeOnly].join(' ');
          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: Chip(
                label: Text(_actStatusVi(actStatus)),
                side: BorderSide.none,
                backgroundColor: actColor.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: actColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => RegistrationDetailPage(registration: it),
                  ),
                );
                if (changed == true) {
                  // Nếu có thay đổi (ví dụ hủy đăng ký), tải lại danh sách
                  await _load();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
