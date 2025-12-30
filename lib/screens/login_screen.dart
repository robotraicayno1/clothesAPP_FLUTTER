import 'package:clothesapp/screens/home_screen.dart';
import 'package:clothesapp/screens/signup_screen.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:clothesapp/widgets/custom_button.dart';
import 'package:clothesapp/widgets/custom_textfield.dart';
import 'package:clothesapp/widgets/social_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (res['success']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đăng nhập thành công!')));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacer(),
              Text(
                "Chào mừng\ntrở lại,",
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
              SizedBox(height: 10),
              Text(
                "Đăng nhập để tiếp tục mua sắm",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 18),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
              SizedBox(height: 50),
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: "Mật khẩu",
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Quên mật khẩu?",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),
              SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Đăng nhập",
                      onPressed: _login,
                    ).animate().fadeIn(delay: 1000.ms).scale(),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialButton(
                    icon: Icons.facebook,
                    color: Color(0xFF1877F2),
                    onPressed: () {},
                  ),
                  SizedBox(width: 20),
                  SocialButton(
                    icon: Icons.g_translate, // Placeholder for Google
                    color: Colors.red,
                    onPressed: () {},
                  ),
                  SizedBox(width: 20),
                  SocialButton(
                    icon: Icons.apple,
                    color: Colors.black,
                    onPressed: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 1200.ms).moveY(begin: 20, end: 0),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                    },
                    child: Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1400.ms),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
