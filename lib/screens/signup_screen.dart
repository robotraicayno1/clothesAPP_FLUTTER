import 'package:clothesapp/services/auth_service.dart';
import 'package:clothesapp/widgets/custom_button.dart';
import 'package:clothesapp/widgets/custom_textfield.dart';
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

  void _signup() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _authService.signup(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
      );
      Navigator.pop(context); // Go back to login
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                "Tạo tài khoản",
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
              SizedBox(height: 10),
              Text(
                "Đăng ký để bắt đầu trải nghiệm",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 18),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
              SizedBox(height: 50),
              CustomTextField(
                controller: _nameController,
                hintText: "Họ và tên",
                prefixIcon: Icons.person_outline,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              SizedBox(height: 20),
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
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              SizedBox(height: 50),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Đăng ký",
                      onPressed: _signup,
                    ).animate().fadeIn(delay: 700.ms).scale(),
              SizedBox(height: 30),
              Center(
                child: Text(
                  "Bằng cách đăng ký, bạn đồng ý với Điều khoản và Chính sách của chúng tôi.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ).animate().fadeIn(delay: 900.ms),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
