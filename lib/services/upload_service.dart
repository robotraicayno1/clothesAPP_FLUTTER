import 'dart:convert';
import 'dart:io';
import 'package:clothesapp/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class UploadService {
  final String baseUrl = ApiConstants.uploadSubRoute;

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
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Upload Failed: $e");
    }
  }
}
