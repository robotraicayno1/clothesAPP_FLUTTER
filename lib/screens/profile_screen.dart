import 'package:clothesapp/screens/chat_screen.dart';
import 'package:clothesapp/screens/login_screen.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  const ProfileScreen({super.key, required this.user, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = await _userService.getProfile(widget.token);
    if (mounted && user != null) {
      setState(() {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _addressController.text = user['address'] ?? '';
        _isLoadingUserData = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingUserData = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    setState(() => _isLoading = true);

    Map<String, dynamic> updateData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    if (_passwordController.text.isNotEmpty) {
      updateData['password'] = _passwordController.text;
    }

    final result = await _userService.updateProfile(updateData, widget.token);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật hồ sơ thành công!")),
      );
      _passwordController.clear();
      // Update local data with result
      setState(() {
        _nameController.text = result['name'] ?? '';
        _phoneController.text = result['phone'] ?? '';
        _addressController.text = result['address'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thất bại. Vui lòng thử lại.")),
      );
    }
  }

  void _makeCall() async {
    final Uri url = Uri.parse('tel:0966209249');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể thực hiện cuộc gọi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hồ Sơ Của Tôi",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary, // Gold border
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.2,
                                ),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.cardColor,
                            backgroundImage: const NetworkImage(
                              "https://i.pravatar.cc/300",
                            ), // Placeholder profile image
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user['email'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader("Thông tin cá nhân", theme),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Họ và Tên",
                    _nameController,
                    Icons.person_outline,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Số điện thoại",
                    _phoneController,
                    Icons.phone_android_outlined,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Địa chỉ",
                    _addressController,
                    Icons.location_on_outlined,
                    theme,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Bảo mật", theme),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "Đổi mật khẩu mới",
                    _passwordController,
                    Icons.lock_outline,
                    theme,
                    isPassword: true,
                    hintText: "Nhập mật khẩu mới nếu muốn đổi",
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 10,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                            )
                          : Text(
                              "LƯU THAY ĐỔI",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  Divider(color: Colors.white.withOpacity(0.05), thickness: 1),
                  const SizedBox(height: 24),
                  Text(
                    "Hỗ trợ khách hàng",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSupportButton(
                          "Gọi Hotline",
                          Icons.call,
                          Colors.green,
                          _makeCall,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSupportButton(
                          "Chat hỗ trợ",
                          FontAwesomeIcons.commentDots,
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  user: widget.user,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.secondary,
          fontSize: 12,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSupportButton(
    String label,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    ThemeData theme, {
    bool isPassword = false,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (maxLines == 1 && !isPassword) ...[
          // For simple fields, just show label in decoration or as a header?
          // Let's stick to standard input decoration for cleanliness
        ],
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(icon, color: theme.iconTheme.color, size: 20),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
