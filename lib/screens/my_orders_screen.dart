import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/widgets/order_review_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatefulWidget {
  final String token;
  const MyOrdersScreen({super.key, required this.token});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
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
    final orders = await _orderService.getMyOrders(widget.token);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  void _confirmReceipt(Order order) async {
    final success = await _orderService.updateOrderStatus(
      order.id,
      3,
      widget.token,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xác nhận đã nhận hàng thành công!")),
        );
        _loadOrders();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi xác nhận nhận hàng!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đơn Hàng Của Tôi",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text("Bạn chưa có đơn hàng nào"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  order.orderedAt,
                );
                final dateString = DateFormat('dd/MM/yyyy HH:mm').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Mã đơn: ${order.id.substring(order.id.length - 8)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateString,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Divider(),
                        ...order.products.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final product = entry.value;
                          final quantity = order.quantities.length > idx
                              ? order.quantities[idx]
                              : 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(product.name),
                                Text("x$quantity"),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tổng cộng:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currencyFormat.format(order.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (order.status == 2) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _confirmReceipt(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Đã nhận được hàng"),
                            ),
                          ),
                        ],
                        if (order.status == 3) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => OrderReviewListDialog(
                                    order: order,
                                    token: widget.token,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text("Đánh giá sản phẩm"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(int status) {
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
        color = Colors.indigo;
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
        text = "Không xác định";
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
