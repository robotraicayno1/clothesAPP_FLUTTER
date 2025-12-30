class Voucher {
  final String id;
  final String code;
  final double discountAmount;
  final DateTime expiryDate;
  final bool isActive;

  Voucher({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.expiryDate,
    required this.isActive,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      expiryDate: DateTime.parse(json['expiryDate']),
      isActive: json['isActive'] ?? true,
    );
  }
}
