import 'package:clothesapp/models/product.dart';

class Order {
  final String id;
  final List<Product> products;
  final List<int> quantities;
  final List<String> selectedColors;
  final List<String> selectedSizes;
  final String address;
  final String userId;
  final String userName;
  final String userEmail;
  final int orderedAt;
  final int status;
  final double totalPrice;
  final double shippingFee;
  final String appTransId;
  final String trackingNumber;
  final String paymentProof;

  Order({
    required this.id,
    required this.products,
    required this.quantities,
    required this.selectedColors,
    required this.selectedSizes,
    required this.address,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.orderedAt,
    required this.status,
    required this.totalPrice,
    required this.shippingFee,
    required this.appTransId,
    required this.trackingNumber,
    required this.paymentProof,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      List<Product> products = [];
      List<int> quantities = [];
      List<String> selectedColors = [];
      List<String> selectedSizes = [];

      if (json['products'] != null) {
        for (var item in json['products']) {
          if (item['product'] != null) {
            products.add(Product.fromJson(item['product']));
            quantities.add(item['quantity'] ?? 1);
            selectedColors.add(item['selectedColor'] ?? '');
            selectedSizes.add(item['selectedSize'] ?? '');
          }
        }
      }

      int parseTime(dynamic value) {
        if (value is int) return value;
        if (value is String) {
          final dt = DateTime.tryParse(value);
          return dt?.millisecondsSinceEpoch ?? 0;
        }
        return 0;
      }

      return Order(
        id: json['_id']?.toString() ?? '',
        products: products,
        quantities: quantities,
        selectedColors: selectedColors,
        selectedSizes: selectedSizes,
        address: json['address']?.toString() ?? '',
        userId: json['userId'] is Map
            ? (json['userId']['_id']?.toString() ?? '')
            : (json['userId']?.toString() ?? ''),
        userName: json['userId'] is Map
            ? (json['userId']['name']?.toString() ?? 'Guest')
            : 'Guest',
        userEmail: json['userId'] is Map
            ? (json['userId']['email']?.toString() ?? '')
            : '',
        orderedAt: parseTime(json['createdAt']),
        status: json['status'] ?? 0,
        totalPrice: (json['totalPrice'] ?? 0).toDouble(),
        shippingFee: (json['shippingFee'] ?? 0).toDouble(),
        appTransId: json['appTransId']?.toString() ?? '',
        trackingNumber: json['trackingNumber']?.toString() ?? '',
        paymentProof: json['paymentProof']?.toString() ?? '',
      );
    } catch (e) {
      // print('Error parsing Order: $e');
      rethrow;
    }
  }
}
