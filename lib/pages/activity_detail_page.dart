import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/registration_api.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;
  final bool readOnly; // ẩn thanh đăng ký khi true (dùng cho giáo viên)
  final bool isRegistered; // sinh viên đã đăng ký rồi
  const ActivityDetailPage({
    super.key,
    required this.activity,
    this.readOnly = false,
    this.isRegistered = false,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  bool _submitting = false;

  // Hiển thị thời gian có giờ/phút cho start/end, và ngày cho reg window
  String _fmtDT(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('EEE, dd/MM • HH:mm', 'vi_VN').format(dt);
  }

  String _fmtD(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(dt);
  }

  String _statusVi(String? s) {
    final up = (s ?? '').toUpperCase();
    if (up == 'OPEN') return 'Đang mở';
    if (up == 'ONGOING') return 'Đang diễn ra';
    if (up == 'CLOSED') return 'Kết thúc';
    return s ?? '';
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
    // Đăng ký dùng DATEONLY trên backend → so sánh theo ngày, không theo giờ
    final today = DateTime(now.year, now.month, now.day);
    final rs = a.regStart == null
        ? null
        : DateTime(a.regStart!.year, a.regStart!.month, a.regStart!.day);
    final re = a.regEnd == null
        ? null
        : DateTime(a.regEnd!.year, a.regEnd!.month, a.regEnd!.day);

    final st = (a.status ?? '').toUpperCase();
    final isOpen = st == 'OPEN';
    final afterStart = rs == null || !today.isBefore(rs);
    final beforeEnd = re == null || !today.isAfter(re);
    final alreadyReg = widget.isRegistered == true;
    final canRegister =
        isOpen &&
        afterStart &&
        beforeEnd &&
        !alreadyReg; // chỉ khi OPEN, trong cửa sổ và chưa đăng ký

    String ctaText() {
      if (_submitting) return 'Đang đăng ký…';
      // Ưu tiên hiển thị đã đăng ký nếu user đã đăng ký trước đó
      if (alreadyReg) return 'Đã đăng ký';
      if (!canRegister) {
        if (!isOpen) {
          return 'Đã hết thời gian đăng ký';
        }
        if (a.regEnd != null && today.isAfter(re!)) {
          return 'Đã hết hạn đăng ký';
        }
        if (a.regStart != null && today.isBefore(rs!)) {
          return 'Chưa mở đăng ký';
        }
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
                    '${_fmtDT(a.startTime)} — ${_fmtDT(a.endTime)}',
                  ),
                  const SizedBox(height: 8),
                  if ((a.location ?? '').isNotEmpty) ...[
                    _row(Icons.place_outlined, 'Địa điểm', a.location!),
                    const SizedBox(height: 8),
                  ],
                  _row(
                    Icons.how_to_reg,
                    'Mở đăng ký',
                    '${_fmtD(a.regStart)} — ${_fmtD(a.regEnd)}',
                  ),
                  const SizedBox(height: 8),
                  if (a.capacity != null)
                    _row(Icons.people_alt, 'Số lượng', '${a.capacity}'),
                  if ((a.status ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row(Icons.info_outline, 'Trạng thái', _statusVi(a.status)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (_submitting || !canRegister) ? null : _register,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(MaterialState.disabled))
                          return Colors.grey;
                        return null; // dùng mặc định khi enabled
                      }),
                      foregroundColor: MaterialStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(MaterialState.disabled))
                          return Colors.white;
                        return null;
                      }),
                    ),
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
