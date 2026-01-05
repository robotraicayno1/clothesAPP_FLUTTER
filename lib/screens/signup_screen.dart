import 'package:clothesapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await _authService.signup(name, email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          ),
        );
        Navigator.pop(context); // Go back to login
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                "Tạo tài khoản.",
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                  height: 1.1,
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                "Tham gia cùng chúng tôi để bắt đầu mua sắm những phong cách mới nhất.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 48),

              _buildInputLabel("HỌ VÀ TÊN", theme),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: "Nguyễn Văn A",
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              _buildInputLabel("ĐỊA CHỈ EMAIL", theme),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: "example@email.com",
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              _buildInputLabel("MẬT KHẨU", theme),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: theme.inputDecorationTheme.suffixIconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 48),

              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _signup,
                      child: const Text("Đăng ký"),
                    ).animate().fadeIn(delay: 700.ms).scale(),

              const SizedBox(height: 32),

              Center(
                child: Text(
                  "Bằng cách đăng ký, bạn đồng ý với Điều khoản và\nChính sách của chúng tôi.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.secondary.withOpacity(0.8),
        letterSpacing: 1.5,
        fontSize: 12,
      ),
    );
  }
}
