import 'package:clothesapp/models/voucher.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/services/voucher_service.dart';
import 'package:clothesapp/screens/profile_screen.dart';
import 'package:clothesapp/widgets/voucher_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clothesapp/utils/vietnam_provinces.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clothesapp/services/upload_service.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

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
  final UploadService _uploadService = UploadService();
  List<dynamic> _cartItems = [];
  bool _isLoading = true;

  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Voucher? _appliedVoucher;
  bool _isApplyingVoucher = false;
  String _paymentMethod = 'COD'; // 'COD' or 'Transfer'
  VietnamProvince? _selectedProvince;

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
      final userAddress = widget.user!['address'] as String;
      _addressController.text = userAddress;
      _selectedProvince = _findProvince(userAddress);
    } else {
      _fetchProfile();
    }

    // Listen for changes to auto-detect
    _addressController.addListener(() {
      final found = _findProvince(_addressController.text);
      if (found != _selectedProvince) {
        setState(() {
          _selectedProvince = found;
        });
      }
    });
  }

  void _fetchProfile() async {
    try {
      final user = await _userService.getProfile(widget.token);
      if (user != null && user['address'] != null && mounted) {
        final address = user['address'] as String;
        if (_addressController.text.isEmpty) {
          _addressController.text = address;
          setState(() {
            _selectedProvince = _findProvince(address);
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  VietnamProvince? _findProvince(String address) {
    if (address.isEmpty) return null;
    final lowerAddress = address.toLowerCase();

    // Map common aliases to official names
    String searchAddress = lowerAddress;
    if (lowerAddress.contains('hcm') ||
        lowerAddress.contains('hồ chí minh') ||
        lowerAddress.contains('saigon')) {
      searchAddress += ' tp hồ chí minh';
    }
    if (lowerAddress.contains('hanoi') || lowerAddress.contains('hà nội')) {
      searchAddress += ' hà nội';
    }
    if (lowerAddress.contains('đà nẵng') || lowerAddress.contains('danang')) {
      searchAddress += ' đà nẵng';
    }
    if (lowerAddress.contains('can tho') || lowerAddress.contains('cần thơ')) {
      searchAddress += ' cần thơ';
    }
    if (lowerAddress.contains('hai phong') ||
        lowerAddress.contains('hải phòng')) {
      searchAddress += ' hải phòng';
    }

    try {
      return vietnamProvinces.firstWhere((p) {
        final pName = p.name.toLowerCase();
        return searchAddress.contains(pName);
      });
    } catch (e) {
      return null;
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
      // print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getItemPrice(dynamic item) {
    final product = item['product'];
    if (product == null) return 0;

    final variants = product['variants'] as List?;
    if (variants == null || variants.isEmpty) {
      return (product['price'] ?? 0).toDouble();
    }

    final selectedColor = item['selectedColor'];
    final selectedSize = item['selectedSize'];

    final variant = variants.firstWhere(
      (v) => v['color'] == selectedColor && v['size'] == selectedSize,
      orElse: () => variants.first,
    );

    return (variant['sellingPrice'] ?? product['price'] ?? 0).toDouble();
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
      // print(e);
    }
  }

  double get _subtotal {
    double total = 0;
    for (var item in _cartItems) {
      total += _getItemPrice(item) * item['quantity'];
    }
    return total;
  }

  double get _shippingFee {
    if (_selectedProvince == null) return 0;
    if (_subtotal >= 1000000) return 0;

    if (_selectedProvince!.name == "TP Hồ Chí Minh") {
      return 20000;
    } else if (_selectedProvince!.region == "South") {
      return 30000;
    } else {
      return 45000;
    }
  }

  double get _totalPrice {
    double total = _subtotal + _shippingFee;
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
      setState(() => _isApplyingVoucher = false);
      if (voucher != null) {
        setState(() {
          _appliedVoucher = voucher;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Áp dụng mã giảm giá thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã giảm giá không hợp lệ hoặc đã hết hạn'),
          ),
        );
      }
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

    if (_selectedProvince == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn Tỉnh/Thành phố")),
      );
      return;
    }

    final String address =
        "${_addressController.text.trim()}, ${_selectedProvince!.name}";

    final res = await _orderService.placeOrder(
      totalPrice: _totalPrice,
      address: address,
      cart: _cartItems,
      token: widget.token,
      voucherCode: _appliedVoucher?.code ?? '',
      discountAmount: _appliedVoucher?.discountAmount ?? 0.0,
      shippingFee: _shippingFee,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (res != null) {
        if (_paymentMethod == 'Transfer') {
          print("DEBUG: Payment Dialog Order ID: ${res['_id']}");
          _showBankTransferDialog(res['_id'], _totalPrice);
        } else {
          _showOrderSuccess();
        }
      } else {
        _showError("Lỗi dịch vụ đặt hàng!");
      }
    }
  }

  Future<void> _pickAndUploadBill(String orderId) async {
    try {
      // Request Runtime Permission checks
      PermissionStatus status = PermissionStatus.granted;
      if (Platform.isAndroid) {
        // Try to detect if permission_handler is working
        try {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            status = await Permission.photos.request();
          }
        } catch (e) {
          // Permission handler failed (maybe missing plugin), ignore and let image_picker handle it
          // print("Permission Handler Error: $e");
        }
      }

      if (status.isPermanentlyDenied) {
        if (mounted)
          _showError("Vui lòng cấp quyền truy cập ảnh trong Cài đặt");
        // openAppSettings(); // Can crash if plugin missing
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đang tải ảnh lên...')));
      }

      // Upload Image
      String? imageUrl = await _uploadService.uploadImage(File(image.path));

      if (imageUrl != null && mounted) {
        // Update Order with Payment Proof
        final success = await _orderService.uploadPaymentProof(
          orderId,
          imageUrl,
          widget.token,
        );

        if (success && mounted) {
          Navigator.pop(context); // Close dialog
          _showOrderSuccess(
            msg: "Gửi ảnh giao dịch thành công! Admin sẽ duyệt sớm.",
          );
        } else {
          if (mounted) _showError("Lỗi cập nhật trạng thái đơn hàng!");
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains("Connection refused")) {
          errorMsg = "Không thể kết nối Server. Vui lòng kiểm tra lại IP/WIFI.";
        }
        _showError("Lỗi: $errorMsg");
      }
    }
  }

  void _showBankTransferDialog(String orderId, double amount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final theme = Theme.of(context);
    // Ensure we handle both full IDs and potential short IDs safely
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId;

    // Mock Bank Information - In real app, fetch from config or constants
    const bankName = "Sacombank";
    const accountNumber = "050138116155";
    const accountName = "NGUYEN MINH TAI";
    final content = "THANHTOAN $shortId";

    // Construct VietQR URL
    final String qrUrl =
        "https://img.vietqr.io/image/STB-050138116155-compact.png?amount=${amount.toInt()}&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName)}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Thanh toán QR",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.iconTheme.color),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Thanh toán thất bại"),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  qrUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildInfoRow("Ngân hàng", bankName, theme),
              _buildInfoRow("STK", accountNumber, theme, isCopyable: true),
              _buildInfoRow("Chủ TK", accountName, theme),
              _buildInfoRow(
                "Số tiền",
                currencyFormat.format(amount),
                theme,
                isHighLight: true,
              ),
              _buildInfoRow("Nội dung", content, theme, isCopyable: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndUploadBill(orderId),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Gửi ảnh giao dịch"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Đang kiểm tra...",
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );

                try {
                  final response = await http.post(
                    Uri.parse(
                      '${AuthService.baseUrl}/payment/verify-transaction',
                    ),
                    headers: {
                      'Content-Type': 'application/json',
                      'x-auth-token': widget.token,
                    },
                    body: jsonEncode({'orderId': orderId}),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    if (data['success'] == true) {
                      nav.pop();
                      _showOrderSuccess(msg: "Thanh toán thành công!");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(data['msg'] ?? "Chưa thấy giao dịch"),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // ignore
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("TÔI ĐÃ CHUYỂN KHOẢN"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isCopyable = false,
    bool isHighLight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isHighLight
                          ? theme.colorScheme.primary
                          : Colors.white,
                    ),
                  ),
                ),
                if (isCopyable)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Đã sao chép: $value")),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccess({String? msg}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg ?? "Đặt hàng thành công! Đang chờ Admin duyệt."),
        backgroundColor: Colors.green,
      ),
    );
    _addressController.clear();
    _voucherController.clear();
    setState(() {
      _cartItems = [];
      _appliedVoucher = null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Giỏ Hàng",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Giỏ hàng trống",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final product = item['product'];
                      if (product == null) return const SizedBox.shrink();

                      return Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Builder(
                                  builder: (context) {
                                    String imageUrl = product['imageUrl'] ?? '';
                                    if (!imageUrl.startsWith('http')) {
                                      String serverBase = AuthService.baseUrl
                                          .replaceAll('/api', '');
                                      imageUrl = "$serverBase/$imageUrl"
                                          .replaceAll('//uploads', '/uploads');
                                    }
                                    return Image.network(
                                      imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.error),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Unknown',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${currencyFormat.format(_getItemPrice(item))}",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if ((item['selectedColor'] ?? '')
                                            .isNotEmpty ||
                                        (item['selectedSize'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "${item['selectedColor']} • ${item['selectedSize']}",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.white54),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "x${item['quantity']}",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => _removeItem(item['_id']),
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error
                                      .withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Panel for Checkout
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Province
                      DropdownButtonFormField<VietnamProvince>(
                        dropdownColor: theme.cardColor,
                        style: theme.textTheme.bodyMedium,
                        decoration: _inputDecoration(
                          theme,
                          "Tỉnh/Thành phố",
                          Icons.map_outlined,
                        ),
                        isExpanded: true,
                        value: _selectedProvince,
                        items: vietnamProvinces.map((province) {
                          return DropdownMenuItem<VietnamProvince>(
                            value: province,
                            child: Text(province.name),
                          );
                        }).toList(),
                        onChanged: (province) {
                          setState(() {
                            _selectedProvince = province;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Address
                      TextField(
                        controller: _addressController,
                        style: theme.textTheme.bodyLarge,
                        decoration: _inputDecoration(
                          theme,
                          "Địa chỉ cụ thể",
                          Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Voucher
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _voucherController,
                              style: theme.textTheme.bodyLarge,
                              decoration:
                                  _inputDecoration(
                                    theme,
                                    "Mã giảm giá",
                                    Icons.confirmation_number_outlined,
                                  ).copyWith(
                                    suffixIcon: _appliedVoucher != null
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: theme.colorScheme.error,
                                            ),
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
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isApplyingVoucher
                                ? null
                                : _applyVoucher,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: theme.colorScheme.secondary,
                            ),
                            child: _isApplyingVoucher
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Áp dụng"),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _selectVoucher,
                          child: Text(
                            "Chọn voucher có sẵn",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Payment Methods
                      Row(
                        children: [
                          _buildPaymentOption(
                            icon: Icons.money,
                            label: "COD",
                            value: "COD",
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          _buildPaymentOption(
                            icon: Icons.account_balance,
                            label: "Chuyển khoản",
                            value: "Transfer",
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      // Totals
                      _buildSummaryRow(
                        "Tạm tính",
                        currencyFormat.format(_subtotal),
                        theme,
                      ),
                      if (_shippingFee > 0)
                        _buildSummaryRow(
                          "Phí vận chuyển",
                          currencyFormat.format(_shippingFee),
                          theme,
                        ),
                      if (_appliedVoucher != null)
                        _buildSummaryRow(
                          "Giảm giá",
                          "-${currencyFormat.format(_appliedVoucher!.discountAmount)}",
                          theme,
                          isGreen: true,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TỔNG CỘNG",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            currencyFormat.format(_totalPrice),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 10,
                            shadowColor: theme.colorScheme.primary.withOpacity(
                              0.4,
                            ),
                          ),
                          child: Text(
                            "THANH TOÁN",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.iconTheme.color, size: 20),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.white.withOpacity(0.05),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : Colors.white54,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isGreen = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.greenAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
