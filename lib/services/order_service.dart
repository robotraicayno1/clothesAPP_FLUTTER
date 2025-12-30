import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clothesapp/models/product.dart';

class Order {
  final String id;
  final List<Product> products;
  final List<int> quantities;
  final String address;
  final String userId;
  final String userName;
  final String userEmail;
  final int orderedAt;
  final int status;
  final double totalPrice;

  Order({
    required this.id,
    required this.products,
    required this.quantities,
    required this.address,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.orderedAt,
    required this.status,
    required this.totalPrice,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      List<Product> products = [];
      List<int> quantities = [];

      if (json['products'] != null) {
        for (var item in json['products']) {
          if (item['product'] != null) {
            products.add(Product.fromJson(item['product']));
            quantities.add(item['quantity'] ?? 1);
          }
        }
      }

      // Robustly handle createdAt (can be int or String)
      int parseTime(dynamic value) {
        if (value is int) return value;
        if (value is String) {
          final dt = DateTime.tryParse(value);
          return dt?.millisecondsSinceEpoch ?? 0;
        }
        return 0;
      }

      return Order(
        id: json['_id'] ?? '',
        products: products,
        quantities: quantities,
        address: json['address'] ?? '',
        userId: json['userId'] is Map
            ? (json['userId']['_id'] ?? '')
            : (json['userId'] ?? ''),
        userName: json['userId'] is Map
            ? (json['userId']['name'] ?? 'Guest')
            : 'Guest',
        userEmail: json['userId'] is Map ? (json['userId']['email'] ?? '') : '',
        orderedAt: parseTime(json['createdAt']),
        status: json['status'] ?? 0,
        totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      );
    } catch (e) {
      print('Error parsing Order: $e');
      rethrow;
    }
  }
}

class OrderService {
  final String baseUrl = 'http://192.168.2.23:3000/api/orders';

  // Place an order (Checkout)
  Future<bool> placeOrder({
    required double totalPrice,
    required String address,
    required List<dynamic> cart, // Passing cart structure intact
    required String token,
    String voucherCode = '',
    double discountAmount = 0.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'totalPrice': totalPrice,
          'cart': cart,
          'voucherCode': voucherCode,
          'discountAmount': discountAmount,
          'address': address,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Get My Orders
  Future<List<Order>> getMyOrders(String token) async {
    List<Order> orderList = [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-orders'),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        for (var item in jsonDecode(response.body)) {
          orderList.add(Order.fromJson(item));
        }
      }
    } catch (e) {
      print(e);
    }
    return orderList;
  }

  // Get All Orders (Admin)
  Future<List<Order>> getAllOrders(String token) async {
    List<Order> orderList = [];
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'x-auth-token': token},
      );
      print('Admin Orders Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        for (var item in jsonDecode(response.body)) {
          orderList.add(Order.fromJson(item));
        }
      } else {
        print('Admin Orders Error: ${response.body}');
      }
    } catch (e) {
      print(e);
    }
    return orderList;
  }

  // Update Status (Admin)
  Future<bool> updateOrderStatus(String id, int status, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id/status'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
