import 'dart:convert';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:clothesapp/models/order.dart';

class OrderService {
  final String baseUrl = ApiConstants.ordersSubRoute;

  Future<Map<String, dynamic>?> placeOrder({
    required double totalPrice,
    required String address,
    required List<dynamic> cart,
    required String token,
    String voucherCode = '',
    double discountAmount = 0.0,
    double shippingFee = 0.0,
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
          'shippingFee': shippingFee,
          'address': address,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
      // print(e);
    }
    return orderList;
  }

  Future<List<Order>> getAllOrders(String token) async {
    List<Order> orderList = [];
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'x-auth-token': token},
      );
      if (response.statusCode == 200) {
        for (var item in jsonDecode(response.body)) {
          orderList.add(Order.fromJson(item));
        }
      }
    } catch (e) {
      // print(e);
    }
    return orderList;
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String id,
    int status,
    String token, {
    String? trackingNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id/status'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'status': status,
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['msg'] ?? body['error'] ?? 'Đã có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String id, String token) async {
    return await updateOrderStatus(id, 4, token);
  }

  Future<bool> uploadPaymentProof(
    String orderId,
    String imageUrl,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$orderId/payment-proof'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({'paymentProof': imageUrl}),
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(
        "Update Failed: ${response.statusCode} | ${response.body}",
      );
    } catch (e) {
      throw Exception("Service Error: $e");
    }
  }
}
