import 'package:flutter/material.dart';
import '../../services/activity_api.dart';
import '../../models/activity.dart';
import '../activity_detail_page.dart';
import 'attendance_page.dart';
import 'package:intl/intl.dart';

class OngoingTab extends StatefulWidget {
  const OngoingTab({super.key});

  @override
  State<OngoingTab> createState() => _OngoingTabState();
}

class _OngoingTabState extends State<OngoingTab> {
  bool _loading = false;
  List<Activity> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await ActivityApi.list(page: 1, limit: 50, status: 'ONGOING');
      setState(() => _items = res.items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không tải được danh sách: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('EEE, dd/MM • HH:mm', 'vi_VN').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Không có hoạt động đang diễn ra')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      final subtitle = [
                        if (it.startTime != null) _fmtDate(it.startTime),
                        if (it.endTime != null) '— ${_fmtDate(it.endTime)}',
                        if (it.capacity != null) '• SL: ${it.capacity}',
                      ].join(' ');

                      return Card(
                        child: ListTile(
                          title: Text(it.title),
                          subtitle: Text(subtitle),
                          trailing: const Icon(Icons.playlist_add_check),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendancePage(activity: it),
                              ),
                            );
                            // quay lại thì refresh
                            await _load();
                          },
                          onLongPress: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailPage(
                                activity: it,
                                readOnly: true,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
  }
}
