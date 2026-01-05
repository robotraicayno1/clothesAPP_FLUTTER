import 'package:clothesapp/screens/admin/admin_chat_list_screen.dart';
import 'package:clothesapp/screens/admin/admin_order_screen.dart';
import 'package:clothesapp/screens/admin/inventory_management_screen.dart';
import 'package:clothesapp/screens/admin/manage_products_screen.dart';
import 'package:clothesapp/screens/admin/voucher_screen.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final String token;
  const AdminDashboard({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Trang Quản Trị",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
      ),
      body: Stack(
        children: [
          // Ambient background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    Colors.black,
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildAdminCard(
                  context,
                  icon: Icons.storefront,
                  title: "Quản Lý Sản Phẩm",
                  subtitle: "Xem, thêm và xóa sản phẩm",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageProductsScreen(token: token),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                _buildAdminCard(
                  context,
                  icon: Icons.inventory,
                  title: "Quản Lý Kho Hàng",
                  subtitle: "Kiểm soát tồn kho & Giá nhập/bán",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryManagementScreen(token: token),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                _buildAdminCard(
                  context,
                  icon: Icons.discount,
                  title: "Quản Lý Voucher",
                  subtitle: "Tạo mã giảm giá cho khách",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoucherScreen(token: token),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                _buildAdminCard(
                  context,
                  icon: Icons.assignment_turned_in,
                  title: "Duyệt Đơn Hàng",
                  subtitle: "Xử lý các đơn hàng đang chờ",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminOrderScreen(token: token),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                _buildAdminCard(
                  context,
                  icon: Icons.chat,
                  title: "Quản Lý Chat",
                  subtitle: "Hỗ trợ khách hàng trực tuyến",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminChatListScreen(token: token),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
