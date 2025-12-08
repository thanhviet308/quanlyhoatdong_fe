import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

// services
import '../services/auth_api.dart';
import 'login_page.dart'; // ✅ import thêm để quay lại

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();

  bool _ob1 = true, _ob2 = true;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim().toLowerCase();
    final fullName = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().isEmpty
        ? null
        : _emailCtrl.text.trim();
    final password = _pwdCtrl.text;

    setState(() => _submitting = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      await AuthApi.register(
        username: username,
        password: password,
        fullName: fullName,
        email: email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng ký thành công. Vui lòng đăng nhập!"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ✅ Quay về LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: h * 0.22,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
              ),
              child: const Center(child: AppLogo(size: 78)),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 24,
                      color: Color(0x1A000000),
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Đăng ký",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // username
                      TextFormField(
                        controller: _usernameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Tên đăng nhập",
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Nhập tên đăng nhập"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Họ và tên",
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Nhập họ tên"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Email (tuỳ chọn)",
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _pwdCtrl,
                        obscureText: _ob1,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: "Mật khẩu (≥ 6 ký tự)",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ob1 ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _ob1 = !_ob1),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? "Tối thiểu 6 ký tự"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _pwd2Ctrl,
                        obscureText: _ob2,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitRegister(),
                        decoration: InputDecoration(
                          labelText: "Nhập lại mật khẩu",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ob2 ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _ob2 = !_ob2),
                          ),
                        ),
                        validator: (v) =>
                            (v != _pwdCtrl.text) ? "Mật khẩu không khớp" : null,
                      ),
                      const SizedBox(height: 8),

                      const SizedBox(height: 6),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitRegister,
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("TẠO TÀI KHOẢN"),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Thêm dòng "Đã có tài khoản?"
                      Center(
                        child: Wrap(
                          spacing: 6,
                          children: [
                            const Text("Đã có tài khoản?"),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              ),
                              child: const Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  color: AppTheme.secondaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
