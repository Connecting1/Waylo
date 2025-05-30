import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.6:8000";

  /// SharedPreferences에서 사용자 ID 가져오기
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id");
  }

  /// 인증 토큰 가져오기
  static Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// HTTP 요청 처리 (GET, POST, PATCH, DELETE)
  static Future<dynamic> sendRequest({
    required String endpoint,
    String method = "GET",
    Map<String, dynamic>? body,
    File? file,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");

    try {
      String? authToken = await getAuthToken();
      Map<String, String> headers = {
        "Content-Type": "application/json",
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers["Authorization"] = "Token $authToken";
      }

      http.Response response;

      if (file != null && (method == "POST" || method == "PATCH")) {
        var request = http.MultipartRequest(method, url);

        if (authToken != null && authToken.isNotEmpty) {
          request.headers["Authorization"] = "Token $authToken";
        }

        if (body != null) {
          body.forEach((key, value) {
            if (value != null) {
              request.fields[key] = value.toString();
            }
          });
        }

        request.files.add(
          await http.MultipartFile.fromPath("image", file.path, filename: basename(file.path)),
        );

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else if (method == "GET") {
        response = await http.get(url, headers: headers);
      } else if (method == "POST") {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == "PATCH") {
        response = await http.patch(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == "DELETE") {
        response = await http.delete(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        return {"error": "Invalid HTTP method"};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {"message": "Success"};
        }

        try {
          final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
          return decoded;
        } catch (e) {
          return {"error": "Response parsing failed"};
        }
      } else {
        try {
          final errorBody = utf8.decode(response.bodyBytes);
          return {"error": errorBody};
        } catch (e) {
          return {"error": "Error response parsing failed"};
        }
      }
    } catch (e) {
      if (e is SocketException) {
        return {"error": "Network connection failed: ${e.message}"};
      } else if (e is HttpException) {
        return {"error": "HTTP request failed: ${e.message}"};
      } else if (e is FormatException) {
        return {"error": "Response format error: ${e.message}"};
      } else if (e is TimeoutException) {
        return {"error": "Request timeout"};
      } else {
        return {"error": "Request failed: ${e.toString()}"};
      }
    }
  }
}