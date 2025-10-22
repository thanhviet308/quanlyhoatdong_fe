import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'register_page.dart';
import 'student_home_page.dart';
// services
import '../services/auth_api.dart';
import '../services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedUsername();
  }

  Future<void> _restoreRememberedUsername() async {
    final sp = await SharedPreferences.getInstance();
    final u = sp.getString('remember_username');
    if (u != null && u.isNotEmpty) {
      setState(() {
        _usernameCtrl.text = u;
        _remember = true;
      });
    }
  }

  Future<void> _persistRememberedUsername(String username) async {
    final sp = await SharedPreferences.getInstance();
    if (_remember) {
      await sp.setString('remember_username', username);
    } else {
      await sp.remove('remember_username');
    }
  }

  Future<void> _submitLogin() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim().toLowerCase();
    final password = _pwdCtrl.text;

    setState(() => _submitting = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      // 1) Đăng nhập -> AuthApi tự lưu token
      await AuthApi.login(username: username, password: password);

      // 2) Ghi nhớ username nếu có chọn
      await _persistRememberedUsername(username);

      // 3) Lấy thông tin người dùng
      final me = await AuthApi.me();

      if (!mounted) return;

      // 4) Thông báo chào mừng (không chặn điều hướng)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xin chào ${me['full_name'] ?? me['username'] ?? ''}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 5) Điều hướng vào Home và xoá lịch sử để không quay lại Login bằng back
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      // Nếu có lỗi → clear token tránh rác
      await TokenStorage.clear();
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header gradient theo màu logo
              Container(
                height: h * 0.30,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppTheme.headerGradient,
                ),
                child: const Center(child: AppLogo(size: 90)),
              ),

              // Card form kéo lên
              Transform.translate(
                offset: const Offset(0, -36),
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
                          "Đăng nhập",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ✅ Đúng với API: nhập username (không phải email/điện thoại)
                        TextFormField(
                          controller: _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: "Tên đăng nhập",
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Vui lòng nhập tên đăng nhập"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _pwdCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitLogin(),
                          decoration: InputDecoration(
                            labelText: "Mật khẩu",
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? "Vui lòng nhập mật khẩu"
                              : null,
                        ),
                        const SizedBox(height: 8),

                        const SizedBox(height: 4),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitLogin,
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("ĐĂNG NHẬP"),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: Wrap(
                            spacing: 6,
                            children: [
                              const Text("Bạn chưa có tài khoản."),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                ),
                                child: const Text(
                                  "Đăng ký ngay",
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
      ),
    );
  }
}
