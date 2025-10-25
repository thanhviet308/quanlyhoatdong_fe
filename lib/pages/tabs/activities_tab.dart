import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../../services/activity_api.dart';
import '../../services/registration_api.dart';
import 'package:intl/intl.dart';
import '../activity_detail_page.dart';

class ActivitiesTab extends StatefulWidget {
  final bool readOnly; // dùng cho teacher để chỉ xem, không đăng ký
  const ActivitiesTab({super.key, this.readOnly = false});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = false;
  bool _loadingMore = false;
  List<Activity> _items = [];
  final Set<int> _registeredIds = <int>{};

  // phân trang
  int _page = 1;
  final int _limit = 10;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _loadRegistered();

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (reset) {
        _page = 1;
        _pages = 1;
      }
      final res = await ActivityApi.list(
        q: _search.text,
        page: _page,
        limit: _limit,
      );
      // Ẩn các hoạt động đã kết thúc (CLOSED)
      final filtered = res.items
          .where((a) => (a.status ?? '').toUpperCase() != 'CLOSED')
          .toList();
      setState(() {
        _pages = res.pages;
        _items = filtered;
      });
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

  Future<void> _loadRegistered() async {
    try {
      final data = await RegistrationApi.myRegistrations(page: 1, limit: 1000);
      final items = (data['items'] as List? ?? []);
      final ids = <int>{};
      for (final e in items) {
        final m = (e as Map).cast<String, dynamic>();
        final act = (m['activity'] as Map?)?.cast<String, dynamic>();
        final id = act?['id'];
        final status = (m['status'] as String?) ?? '';
        if (id is int && status.isNotEmpty) ids.add(id);
      }
      if (mounted)
        setState(() {
          _registeredIds
            ..clear()
            ..addAll(ids);
        });
    } catch (_) {
      // im lặng nếu lỗi auth/network; UI vẫn hoạt động
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _pages) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final res = await ActivityApi.list(
        q: _search.text,
        page: next,
        limit: _limit,
      );
      final filtered = res.items
          .where((a) => (a.status ?? '').toUpperCase() != 'CLOSED')
          .toList();
      setState(() {
        _page = res.page;
        _pages = res.pages;
        _items.addAll(filtered);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không tải thêm được: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    // Tuỳ locale: vi_VN
    return DateFormat('EEE, dd/MM • HH:mm', 'vi_VN').format(dt);
  }

  // _statusVi no longer used (status now displayed as Chip)

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Tìm hoạt động...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Làm mới',
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await _load(reset: true);
                    await _loadRegistered();
                  },
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('Không có hoạt động nào')),
                          ],
                        )
                      : ListView.separated(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _items.length + 1, // +1 cho loadingMore
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            if (i == _items.length) {
                              // dòng cuối: hiển thị đang tải thêm
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: _loadingMore
                                      ? const CircularProgressIndicator()
                                      : (_page < _pages
                                            ? TextButton(
                                                onPressed: _loadMore,
                                                child: const Text('Tải thêm'),
                                              )
                                            : const Text('— Hết —')),
                                ),
                              );
                            }

                            final it = _items[i];
                            final subtitle = [
                              if (it.startTime != null) _fmtDate(it.startTime),
                              if (it.capacity != null) '• SL: ${it.capacity}',
                            ].join(' ');

                            final isReg = _registeredIds.contains(it.id);
                            return Card(
                              child: ListTile(
                                title: Text(it.title),
                                subtitle: Text(subtitle),
                                trailing: isReg
                                    ? Chip(
                                        label: const Text('Đã đăng ký'),
                                        side: BorderSide.none,
                                        backgroundColor: Colors.green
                                            .withOpacity(0.12),
                                        labelStyle: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final changed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ActivityDetailPage(
                                        activity: it,
                                        readOnly: widget.readOnly,
                                        isRegistered: isReg,
                                      ),
                                    ),
                                  );
                                  if (changed == true) {
                                    // sau khi đăng ký xong ở trang chi tiết
                                    await _loadRegistered();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
