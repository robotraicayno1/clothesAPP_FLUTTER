import 'package:clothesapp/models/voucher.dart';
import 'package:clothesapp/services/voucher_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoucherSelectionDialog extends StatefulWidget {
  final String token;
  const VoucherSelectionDialog({super.key, required this.token});

  @override
  State<VoucherSelectionDialog> createState() => _VoucherSelectionDialogState();
}

class _VoucherSelectionDialogState extends State<VoucherSelectionDialog> {
  final VoucherService _voucherService = VoucherService();
  List<Voucher> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  void _loadVouchers() async {
    final vouchers = await _voucherService.getVouchers();
    if (mounted) {
      setState(() {
        _vouchers = vouchers
            .where((v) => v.isActive && v.expiryDate.isAfter(DateTime.now()))
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return AlertDialog(
      title: Text("Chọn Voucher"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _vouchers.isEmpty
            ? Center(child: Text("Không có voucher khả dụng"))
            : ListView.builder(
                itemCount: _vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = _vouchers[index];
                  return ListTile(
                    title: Text(
                      voucher.code,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Giảm: ${currencyFormat.format(voucher.discountAmount)}",
                        ),
                        Text(
                          "Hạn dùng: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => Navigator.pop(context, voucher.code),
                      child: Text("Chọn"),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
      ],
    );
  }
}
