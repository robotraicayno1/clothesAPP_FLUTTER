import 'dart:convert';
import 'dart:io';
import 'package:clothesapp/services/auth_service.dart';
import 'package:http/http.dart' as http;

class UploadService {
  final String baseUrl = AuthService.baseUrl.replaceAll('/api', '/api/upload');

  Future<String?> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var resJson = jsonDecode(response.body);
        return resJson['url'];
      } else {
        return null;
      }
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
}
