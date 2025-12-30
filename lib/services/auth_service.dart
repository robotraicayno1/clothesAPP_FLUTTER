import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Use local IP for physical device or emulator
  // 10.0.2.2 for Android Emulator
  // 192.168.2.23 (My IP) for Physical Device
  static const String baseUrl = 'http://192.168.2.23:3000/api';

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['msg'] ?? 'Đã có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['msg'] ?? 'Đã có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
