import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.6:8000";

  // SharedPreferences에서 user_id 가져오기 (모든 API에서 사용)
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id");
  }

  // 공통 HTTP 요청 핸들러 (GET, POST, PATCH)
  static Future<Map<String, dynamic>> sendRequest({
    required String endpoint,
    String method = "GET",
    Map<String, dynamic>? body,
    File? file,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");

    try {
      http.Response response;

      if (method == "GET") {
        response = await http.get(url, headers: {"Content-Type": "application/json"});
      } else if (method == "POST") {
        response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );
      } else if (method == "PATCH") {
        var request = http.MultipartRequest("PATCH", url);
        if (body != null) {
          body.forEach((key, value) => request.fields[key] = value.toString());
        }
        if (file != null) {
          request.files.add(
            await http.MultipartFile.fromPath("file", file.path, filename: basename(file.path)),
          );
        }
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        return {"error": "Invalid HTTP method"};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": response.body};
      }
    } catch (e) {
      return {"error": "Request Failed"};
    }
  }
}
