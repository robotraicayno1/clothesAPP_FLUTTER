import 'package:clothesapp/models/voucher.dart';
import 'package:clothesapp/services/voucher_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class VoucherScreen extends StatefulWidget {
  final String token;
  const VoucherScreen({super.key, required this.token});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final VoucherService _voucherService = VoucherService();
  late Future<List<Voucher>> _vouchers;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  void _loadVouchers() {
    setState(() {
      _vouchers = _voucherService.getVouchers();
    });
  }

  void _showAddVoucherDialog() {
    final codeController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(Duration(days: 30));

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          "Tạo Voucher Mới",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              codeController,
              "Mã Voucher (VD: SALE50)",
              Icons.qr_code,
              theme,
            ),
            SizedBox(height: 12),
            _buildDialogTextField(
              amountController,
              "Số tiền giảm (VD: 50000)",
              Icons.money,
              theme,
              isNumber: true,
            ),
            SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Hết hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                style: TextStyle(color: Colors.white70),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          onPrimary: Colors.black, // Selected text color
                          surface: theme.cardColor,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) selectedDate = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                final success = await _voucherService.createVoucher(
                  codeController.text,
                  double.tryParse(amountController.text) ?? 0,
                  selectedDate,
                  widget.token,
                );
                if (!mounted) return;
                Navigator.pop(context);
                if (success) _loadVouchers();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text("Tạo"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    ThemeData theme, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Quản Lý Voucher",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        iconTheme: theme.iconTheme,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVoucherDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<Voucher>>(
        future: _vouchers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Chưa có voucher nào",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              final voucher = snapshot.data![index];
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD4AF37).withOpacity(0.15), // Gold tint
                      theme.cardColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFFD4AF37).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
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
                        color: Color(0xFFD4AF37).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: Color(0xFFD4AF37),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.code,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Giảm: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(voucher.discountAmount)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Hết hạn: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: voucher.isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: voucher.isActive
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.red.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            voucher.isActive ? "Đang chạy" : "Ngưng",
                            style: TextStyle(
                              color: voucher.isActive
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.white60,
                          ),
                          onPressed: () async {
                            final success = await _voucherService.deleteVoucher(
                              voucher.id,
                              widget.token,
                            );
                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Xóa voucher thành công!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadVouchers();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
            },
          );
        },
      ),
    );
  }
}
