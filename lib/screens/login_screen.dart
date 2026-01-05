import 'package:clothesapp/screens/forgot_password_screen.dart';
import 'package:clothesapp/screens/home_screen.dart';
import 'package:clothesapp/screens/signup_screen.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ email và mật khẩu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await _authService.login(email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!')));

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: res['data']['user'],
              token: res['data']['token'],
            ),
          ),
        );
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
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        "Chào mừng\ntrở lại.",
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          height: 1.1,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  Text(
                    "Đăng nhập để cập nhật những\nbộ sưu tập mới nhất của chúng tôi.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
              const SizedBox(height: 56),

              Text(
                "ĐỊA CHỈ EMAIL",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary.withOpacity(0.8),
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 400.ms),
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

              Text(
                "MẬT KHẨU",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary.withOpacity(0.8),
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 600.ms),
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
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Quên mật khẩu?",
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.primary, // Gold
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 40),

              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text("Đăng nhập"),
                    ).animate().fadeIn(delay: 800.ms).scale(),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerTheme.color)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Hoặc tiếp tục với",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.dividerTheme.color)),
                ],
              ).animate().fadeIn(delay: 1000.ms),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(Icons.g_mobiledata, theme),
                  const SizedBox(width: 24),
                  _buildSocialIcon(Icons.apple, theme),
                  const SizedBox(width: 24),
                  _buildSocialIcon(Icons.facebook, theme),
                ],
              ).animate().fadeIn(delay: 1200.ms).moveY(begin: 20, end: 0),

              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Chưa có tài khoản? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1400.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.onSurface,
        size: 28,
      ), // Monochrome luxury style
    );
  }
}
