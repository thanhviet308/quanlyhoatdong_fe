import 'package:flutter/material.dart';
import '../../services/auth_api.dart';
import '../../services/token_storage.dart';
import '../../services/user_api.dart';
import '../login_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _me;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() => _loading = true);
    try {
      final me = await AuthApi.me();
      if (mounted) setState(() => _me = me);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải hồ sơ: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (!mounted) return;
    // Quay về màn hình đăng nhập và xoá toàn bộ stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openEditProfile() async {
    final nameCtrl = TextEditingController(text: _me?['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: _me?['email'] ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật hồ sơ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final id = (_me?['id'] as int?) ?? 0;
      if (id <= 0) throw Exception('Thiếu ID người dùng');
      await UserApi.putUser(
        id,
        fullName: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ')));
      await _loadMe();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
    }
  }

  Future<void> _openChangePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu cũ (tuỳ chọn)',
              ),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final id = (_me?['id'] as int?) ?? 0;
      if (id <= 0) throw Exception('Thiếu ID người dùng');
      final newPw = newCtrl.text;
      if (newPw.length < 4) throw Exception('Mật khẩu tối thiểu 4 ký tự');
      final oldPw = oldCtrl.text.trim();
      await UserApi.changePassword(
        id,
        oldPassword: oldPw.isEmpty ? null : oldPw,
        newPassword: newPw,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đổi mật khẩu thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final name = _me?['full_name'] ?? _me?['username'] ?? '';
    final email = _me?['email'] ?? '';
    final role = _me?['role'] ?? 'STUDENT';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(email.isNotEmpty ? email : '—'),
            trailing: Chip(label: Text(role)),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Cập nhật hồ sơ'),
                subtitle: const Text('Tên hiển thị, email...'),
                onTap: _openEditProfile,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Đổi mật khẩu'),
                onTap: _openChangePassword,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
