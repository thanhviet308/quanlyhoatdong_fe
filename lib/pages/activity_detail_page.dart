import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/registration_api.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  bool _submitting = false;

  String _fmt(DateTime? dt, {String p = 'EEE, dd/MM/yyyy • HH:mm'}) {
    if (dt == null) return '-';
    return DateFormat(p, 'vi_VN').format(dt);
  }

  Future<void> _register() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await RegistrationApi.register(widget.activity.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công')));
      // Quay về danh sách, báo đã thay đổi để ActivitiesTab có thể refresh trạng thái
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đăng ký thất bại: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final now = DateTime.now();
    final afterStart = a.regStart == null || !now.isBefore(a.regStart!);
    final beforeEnd = a.regEnd == null || !now.isAfter(a.regEnd!);
    final canRegister =
        afterStart && beforeEnd; // chỉ cho đăng ký khi đang trong cửa sổ

    String ctaText() {
      if (_submitting) return 'Đang đăng ký…';
      if (!canRegister) {
        if (a.regEnd != null && now.isAfter(a.regEnd!))
          return 'Đã hết hạn đăng ký';
        if (a.regStart != null && now.isBefore(a.regStart!))
          return 'Chưa mở đăng ký';
        return 'Không thể đăng ký';
      }
      return 'Đăng ký tham gia';
    }

    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((a.description ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                a.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    Icons.event,
                    'Thời gian',
                    '${_fmt(a.startTime)} — ${_fmt(a.endTime)}',
                  ),
                  const SizedBox(height: 8),
                  _row(
                    Icons.how_to_reg,
                    'Mở đăng ký',
                    '${_fmt(a.regStart)} — ${_fmt(a.regEnd)}',
                  ),
                  const SizedBox(height: 8),
                  if (a.capacity != null)
                    _row(Icons.people_alt, 'Số lượng', '${a.capacity}'),
                  if ((a.status ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row(Icons.info_outline, 'Trạng thái', a.status!),
                  ],
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
              onPressed: (_submitting || !canRegister) ? null : _register,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(ctaText()),
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
