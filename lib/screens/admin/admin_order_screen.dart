import 'package:clothesapp/services/order_service.dart';
import 'package:flutter/material.dart';
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
    final orders = await _orderService.getAllOrders(widget.token);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  void _updateStatus(String orderId, int status) async {
    final success = await _orderService.updateOrderStatus(
      orderId,
      status,
      widget.token,
    );
    if (success) {
      _loadOrders(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản Lý Đơn Hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(child: Text("Chưa có đơn hàng nào"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OrderCard(order: order, onStatusUpdate: _updateStatus),
                );
              },
            ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(String, int) onStatusUpdate;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateTime.fromMillisecondsSinceEpoch(order.orderedAt);
    final dateString = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Đơn hàng: ${order.id.substring(0, 8)}...",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(dateString, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  order.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${order.userEmail})",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...order.products.asMap().entries.map((entry) {
              final idx = entry.key;
              final product = entry.value;
              final quantity = order.quantities.length > idx
                  ? order.quantities[idx]
                  : 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      "${product.name} x $quantity",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tổng: ${currencyFormat.format(order.totalPrice)}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusButton(order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(int status) {
    String text;
    Color color;
    VoidCallback? onTap;

    switch (status) {
      case 0:
        text = "Duyệt & Giao hàng";
        color = Colors.orange;
        onTap = () => onStatusUpdate(order.id, 2);
        break;
      case 1:
        text = "Bắt đầu giao";
        color = Colors.blue;
        onTap = () => onStatusUpdate(order.id, 2);
        break;
      case 2:
        text = "Đang vận chuyển";
        color = Colors.indigo;
        onTap = null;
        break;
      case 3:
        text = "Giao thành công";
        color = Colors.green;
        onTap = null;
        break;
      case 4:
        text = "Đã hủy";
        color = Colors.red;
        onTap = null;
        break;
      default:
        text = "Không xác định";
        color = Colors.grey;
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(text),
    );
  }
}
