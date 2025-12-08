import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../../services/registration_api.dart';
import '../../services/auth_api.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final Activity activity;
  const AttendancePage({super.key, required this.activity});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _me;
  bool get _isAdmin =>
      (_me?['role']?.toString().toUpperCase() ?? '') == 'ADMIN';
  bool get _isTeacher =>
      (_me?['role']?.toString().toUpperCase() ?? '') == 'TEACHER';
  bool get _isOwnerTeacher {
    if (!_isTeacher) return false;
    final meId = _me?['id'];
    return meId != null && widget.activity.createdBy == meId;
  }

  bool get _canManage => _isAdmin || _isOwnerTeacher;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadMe();
    await _load();
  }

  Future<void> _loadMe() async {
    try {
      final me = await AuthApi.me();
      if (mounted) setState(() => _me = me);
    } catch (_) {
      // ignore, treat as null
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final data = await RegistrationApi.listParticipants(
        widget.activity.id,
        page: 1,
        limit: 500,
        status: 'APPROVED',
      );
      final items = (data['items'] as List? ?? [])
          .cast<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _attLabel(String? v) {
    final s = (v ?? '').toUpperCase();
    if (s == 'PRESENT') return 'Có mặt';
    if (s == 'ABSENT') return 'Vắng';
    if (s == 'LATE') return 'Đi trễ';
    return '— Chưa điểm danh —';
  }

  Future<void> _setAttendance(int userId, String status) async {
    try {
      await RegistrationApi.updateAttendance(
        widget.activity.id,
        userId,
        status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật điểm danh')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _fmtDT(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('EEE, dd/MM • HH:mm', 'vi_VN').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    return Scaffold(
      appBar: AppBar(title: Text('Điểm danh — ${a.title}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isTeacher && !_canManage)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Chỉ người tạo hoạt động mới được điểm danh hoạt động này.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Danh sách sinh viên tham gia (${_items.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('— Chưa có —', textAlign: TextAlign.center),
                    )
                  else
                    ..._items.map(_buildParticipantItem),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 6),
              Text('${_fmtDT(a.startTime)} — ${_fmtDT(a.endTime)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantItem(Map<String, dynamic> it) {
    final fullName = (it['full_name'] as String?) ?? it['username'] ?? '—';
    final status = (it['attendance_status'] as String?);
    final userId = (it['user_id'] as int?) ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.person_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _attLabel(status),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (_canManage)
              PopupMenuButton<String>(
                tooltip: 'Chọn điểm danh',
                onSelected: (v) => _setAttendance(userId, v),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'PRESENT', child: Text('Có mặt')),
                  PopupMenuItem(value: 'ABSENT', child: Text('Vắng')),
                  PopupMenuItem(value: 'LATE', child: Text('Đi trễ')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.checklist, color: Colors.green),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.lock_outline, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
