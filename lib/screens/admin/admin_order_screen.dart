import 'package:clothesapp/models/order.dart';
import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AdminOrderScreen extends StatefulWidget {
  final String token;
  const AdminOrderScreen({super.key, required this.token});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _orderService.getAllOrders(widget.token);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  void _updateStatus(
    String orderId,
    int status, {
    String? trackingNumber,
  }) async {
    final res = await _orderService.updateOrderStatus(
      orderId,
      status,
      widget.token,
      trackingNumber: trackingNumber,
    );
    if (res['success']) {
      _loadOrders();
    }
  }

  void _showTrackingDialog(String orderId) {
    final TextEditingController trackingController = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          "Nhập mã vận đơn",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        content: TextField(
          controller: trackingController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "VD: VN123456789",
            labelText: "Mã vận đơn (Tracking ID)",
            labelStyle: TextStyle(color: Colors.white70),
            hintStyle: TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              final tid = trackingController.text.trim();
              if (tid.isNotEmpty) {
                Navigator.pop(context);
                _updateStatus(orderId, 2, trackingNumber: tid);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text("Xác nhận & Giao hàng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quản Lý Đơn Hàng',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _orders.isEmpty
          ? Center(
              child: Text(
                "Chưa có đơn hàng nào",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return OrderCard(
                      order: order,
                      onStatusUpdate: _updateStatus,
                      onShip: _showTrackingDialog,
                    )
                    .animate()
                    .fadeIn(delay: (50 * index).ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(String, int, {String? trackingNumber}) onStatusUpdate;
  final Function(String) onShip;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
    required this.onShip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateTime.fromMillisecondsSinceEpoch(order.orderedAt);
    final dateString = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: theme.cardColor,
      shadowColor: Colors.black54,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          gradient: LinearGradient(
            colors: [theme.cardColor, theme.cardColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Đơn: #${order.id.substring(order.id.length - 8)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateString,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(height: 32, color: Colors.white12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                  child: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        order.userEmail,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "SẢN PHẨM",
              style: TextStyle(
                letterSpacing: 1.2,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            ...order.products.asMap().entries.map((entry) {
              final idx = entry.key;
              final product = entry.value;
              final quantity = order.quantities.length > idx
                  ? order.quantities[idx]
                  : 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${product.name} x $quantity",
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 32, color: Colors.white12),
            if (order.trackingNumber.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.indigoAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Mã vận đơn: ",
                      style: TextStyle(
                        color: Colors.indigoAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.trackingNumber,
                      style: TextStyle(color: Colors.indigoAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (order.paymentProof.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Image.network(
                        order.paymentProof.startsWith('http')
                            ? order.paymentProof
                            : "${AuthService.baseUrl.replaceAll('/api', '')}/${order.paymentProof.replaceAll('//uploads', '/uploads')}",
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Đã gửi ảnh thanh toán (Nhấn để xem)",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(order.totalPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                _buildActionButton(order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    String text;
    Color color;
    switch (status) {
      case 0:
        text = "Chờ duyệt";
        color = Colors.orange;
        break;
      case 1:
        text = "Đã duyệt";
        color = Colors.blue;
        break;
      case 2:
        text = "Đang giao";
        color = Colors.indigoAccent;
        break;
      case 3:
        text = "Hoàn thành";
        color = Colors.green;
        break;
      case 4:
        text = "Đã hủy";
        color = Colors.red;
        break;
      default:
        text = "K.Xác định";
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(int status) {
    if (status == 0) {
      return ElevatedButton(
        onPressed: () => onShip(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Color(0xFFD4AF37).withOpacity(0.5),
        ),
        child: const Text(
          "Duyệt & Giao hàng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    if (status == 2) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.white54,
        ),
        child: const Text("Đang vận chuyển"),
      );
    }
    return const SizedBox.shrink();
  }
}
