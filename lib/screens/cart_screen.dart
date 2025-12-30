import 'package:clothesapp/models/voucher.dart';
import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/services/voucher_service.dart';
import 'package:clothesapp/screens/profile_screen.dart';
import 'package:clothesapp/widgets/voucher_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String token;
  const CartScreen({super.key, required this.token, this.user});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  final VoucherService _voucherService = VoucherService();
  List<dynamic> _cartItems = [];
  bool _isLoading = true;

  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Voucher? _appliedVoucher;
  bool _isApplyingVoucher = false;

  @override
  void dispose() {
    _voucherController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
    if (widget.user != null && widget.user!['address'] != null) {
      _addressController.text = widget.user!['address'];
    }
  }

  void _loadCart() async {
    try {
      final response = await http.get(
        Uri.parse('${_userService.baseUrl}/cart'),
        headers: {'x-auth-token': widget.token},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cartItems = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeItem(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${_userService.baseUrl}/cart/$productId'),
        headers: {'x-auth-token': widget.token},
      );
      if (response.statusCode == 200) {
        _loadCart(); // Reload cart
      }
    } catch (e) {
      print(e);
    }
  }

  double get _subtotal {
    double total = 0;
    for (var item in _cartItems) {
      if (item['product'] != null) {
        total += (item['product']['price'] ?? 0) * item['quantity'];
      }
    }
    return total;
  }

  double get _totalPrice {
    double total = _subtotal;
    if (_appliedVoucher != null) {
      total -= _appliedVoucher!.discountAmount;
    }
    return total > 0 ? total : 0;
  }

  void _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingVoucher = true);

    final voucher = await _voucherService.validateVoucher(code, widget.token);

    if (mounted) {
      setState(() {
        _isApplyingVoucher = false;
        if (voucher != null) {
          _appliedVoucher = voucher;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Áp dụng mã giảm giá thành công!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mã giảm giá không hợp lệ hoặc đã hết hạn')),
          );
        }
      });
    }
  }

  void _selectVoucher() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => VoucherSelectionDialog(token: widget.token),
    );

    if (code != null) {
      _voucherController.text = code;
      _applyVoucher();
    }
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);

    // Fetch latest user profile to ensure they have phone and address
    final userProfile = await _userService.getProfile(widget.token);

    if (!mounted) return;

    if (userProfile == null ||
        (userProfile['phone'] ?? '').isEmpty ||
        (userProfile['address'] ?? '').isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Vui lòng cập nhật Số điện thoại và Địa chỉ để tiếp tục",
          ),
          duration: Duration(seconds: 3),
        ),
      );
      // Redirect to Profile Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            user: userProfile ?? widget.user ?? {},
            token: widget.token,
          ),
        ),
      ).then((_) => _loadCart()); // Refresh cart/state when back
      return;
    }

    final address = _addressController.text.trim().isEmpty
        ? userProfile['address']
        : _addressController.text.trim();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đang xử lý đơn hàng...")));

    final success = await _orderService.placeOrder(
      totalPrice: _totalPrice,
      address: address,
      cart: _cartItems,
      token: widget.token,
      voucherCode: _appliedVoucher?.code ?? '',
      discountAmount: _appliedVoucher?.discountAmount ?? 0.0,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đặt hàng thành công! Đang chờ Admin duyệt."),
          ),
        );
        _addressController.clear();
        _voucherController.clear();
        setState(() {
          _cartItems = [];
          _appliedVoucher = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi đặt hàng!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: Text("Giỏ Hàng", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? Center(child: Text("Giỏ hàng trống"))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final product = item['product'];
                      if (product == null) return SizedBox.shrink();

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['imageUrl'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.error),
                          ),
                        ),
                        title: Text(product['name'] ?? 'Unknown', maxLines: 1),
                        subtitle: Text(
                          "${currencyFormat.format(product['price'])} x ${item['quantity']}",
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeItem(product['_id']),
                        ),
                      );
                    },
                  ),
                ),
                // Address Input Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: "Nhập địa chỉ nhận hàng",
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Voucher Input Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          decoration: InputDecoration(
                            hintText: "Mã giảm giá",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            suffixIcon: _appliedVoucher != null
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _appliedVoucher = null;
                                        _voucherController.clear();
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isApplyingVoucher ? null : _applyVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isApplyingVoucher
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Áp dụng",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectVoucher,
                  icon: Icon(Icons.list_alt),
                  label: Text("Chọn khuyến mãi từ danh sách"),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_appliedVoucher != null) ...[
                            Text(
                              "Tạm tính: ${currencyFormat.format(_subtotal)}",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              "Giảm giá: -${currencyFormat.format(_appliedVoucher!.discountAmount)}",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          Text(
                            "Tổng cộng",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            currencyFormat.format(_totalPrice),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Thanh Toán"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
