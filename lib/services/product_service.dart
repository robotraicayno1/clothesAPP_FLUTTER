import 'dart:convert';
import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/services/auth_service.dart';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = AuthService.baseUrl.replaceAll(
    '/api',
    '/api/products',
  );

  Future<List<Product>> getProducts({
    String category = 'All',
    bool isFeatured = false,
    bool isBestSeller = false,
    String search = '',
  }) async {
    try {
      String query = "?category=$category";
      if (isFeatured) query += "&isFeatured=true";
      if (isBestSeller) query += "&isBestSeller=true";
      if (search.isNotEmpty) query += "&search=$search";

      final response = await http.get(Uri.parse('$baseUrl$query'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Product> products = body
            .map((dynamic item) => Product.fromJson(item))
            .toList();
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Future<bool> createProduct(Product product, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: jsonEncode({
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'isFeatured': product.isFeatured,
          'isBestSeller': product.isBestSeller,
          'gender': product.gender,
          'colors': product.colors,
          'sizes': product.sizes,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> deleteProduct(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
