import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/registration_api.dart';

class RegistrationDetailPage extends StatefulWidget {
  final Map<String, dynamic>
  registration; // { id, status, registered_at, attendance_status, activity: { id, title, start_time, end_time, capacity, status } }
  const RegistrationDetailPage({super.key, required this.registration});

  @override
  State<RegistrationDetailPage> createState() => _RegistrationDetailPageState();
}

class _RegistrationDetailPageState extends State<RegistrationDetailPage> {
  bool _submitting = false;

  String _fmtDate(String? iso, {String pattern = 'EEE, dd/MM/yyyy'}) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat(pattern, 'vi_VN').format(dt);
  }

  String _regStatusVi(String s) {
    switch (s.toUpperCase()) {
      case 'APPROVED':
        return 'Đã duyệt';
      case 'PENDING':
        return 'Chờ duyệt';
      case 'CANCELED':
        return 'Đã hủy';
      default:
        return s;
    }
  }

  String _actStatusVi(String? s) {
    final up = (s ?? '').toUpperCase();
    if (up == 'OPEN') return 'Đang mở';
    if (up == 'ONGOING') return 'Đang diễn ra';
    if (up == 'CLOSED') return 'Kết thúc';
    return s ?? '';
  }

  Future<void> _confirmAndUnregister(int activityId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đăng ký?'),
        content: const Text('Bạn có chắc muốn hủy đăng ký hoạt động này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _unregister(activityId);
    }
  }

  Future<void> _unregister(int activityId) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await RegistrationApi.unregister(activityId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy đăng ký')));
      Navigator.of(context).pop(true); // báo cho màn trước refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hủy đăng ký thất bại: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.registration;
    final status = (reg['status'] as String? ?? '').toUpperCase();
    final activity = (reg['activity'] as Map?)?.cast<String, dynamic>() ?? {};

    Color statusColor;
    switch (status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        break;
      case 'CANCELED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    final title = activity['title'] as String? ?? 'Hoạt động';
    final start = activity['start_time'] as String?;
    final end = activity['end_time'] as String?;
    final capacity = activity['capacity'];
    final location = activity['location'] as String?;
    final activityStatus = activity['status'] as String? ?? '';
    final activityId = activity['id'] as int?;
    final up = activityStatus.toString().toUpperCase();
    final isOngoing = up == 'ONGOING';
    final isClosed = up == 'CLOSED';

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đăng ký')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                label: Text(_regStatusVi(status)),
                side: BorderSide.none,
                backgroundColor: statusColor.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (activityStatus.isNotEmpty)
                Chip(
                  label: Text(_actStatusVi(activityStatus)),
                  side: BorderSide.none,
                  backgroundColor: Colors.blueGrey.withOpacity(0.1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    Icons.event,
                    'Thời gian',
                    '${_fmtDate(start)} — ${_fmtDate(end)}',
                  ),
                  const SizedBox(height: 8),
                  if ((location ?? '').isNotEmpty) ...[
                    _row(Icons.place_outlined, 'Địa điểm', location!),
                    const SizedBox(height: 8),
                  ],
                  _row(Icons.people, 'Số lượng', capacity?.toString() ?? '-'),
                  const SizedBox(height: 8),
                  _row(
                    Icons.schedule,
                    'Đăng ký lúc',
                    _fmtDate(reg['registered_at'] as String?),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_submitting ||
                      activityId == null ||
                      status == 'CANCELED' ||
                      isOngoing ||
                      isClosed)
                  ? null
                  : () => _confirmAndUnregister(activityId),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(
                _submitting
                    ? 'Đang hủy…'
                    : (status == 'CANCELED'
                          ? 'Đã hủy đăng ký'
                          : (isOngoing
                                ? 'Không thể hủy khi đang diễn ra'
                                : (isClosed
                                      ? 'Không thể hủy khi đã kết thúc'
                                      : 'Hủy đăng ký'))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData ic, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ic, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
