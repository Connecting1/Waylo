import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.7:8000";

  // SharedPreferences에서 user_id 가져오기 (모든 API에서 사용)
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id");
  }

  // 인증 토큰 가져오기
  static Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // 공통 HTTP 요청 핸들러 (GET, POST, PATCH) - 동적 반환 타입으로 수정
  static Future<dynamic> sendRequest({
    required String endpoint,
    String method = "GET",
    Map<String, dynamic>? body,
    File? file,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    print("API 요청: $method $url");
    if (body != null) {
      print("요청 본문: $body");
    }

    try {
      // 인증 토큰 가져오기
      String? authToken = await getAuthToken();
      Map<String, String> headers = {
        "Content-Type": "application/json",
      };

      // 인증 토큰이 있으면 헤더에 추가
      if (authToken != null && authToken.isNotEmpty) {
        headers["Authorization"] = "Token $authToken";
      }

      http.Response response;

      // 파일이 있는 경우 MultipartRequest 사용
      if (file != null && (method == "POST" || method == "PATCH")) {
        var request = http.MultipartRequest(method, url);

        // 인증 토큰 헤더 추가
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

        // 중요: 서버에서 기대하는 'image' 필드명으로 파일 추가
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
        // DELETE 메서드 처리 추가
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

        // UTF-8 인코딩 확인 및 처리
        try {
          // JSON 응답 파싱 - 리스트 또는 맵 모두 처리 가능하게 변경
          final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
          return decoded;
        } catch (e) {
          print("[ERROR] JSON 파싱 오류: $e");
          return {"error": "응답 데이터 파싱 오류"};
        }
      } else {
        // 오류 응답에도 UTF-8 디코딩 적용
        try {
          final errorBody = utf8.decode(response.bodyBytes);
          return {"error": errorBody};
        } catch (e) {
          return {"error": "오류 응답 처리 실패"};
        }
      }
    } catch (e) {
      print("[ERROR] API 요청 실패 상세 내용: $e");
      if (e is SocketException) {
        return {"error": "네트워크 연결 실패: ${e.message}"};
      } else if (e is HttpException) {
        return {"error": "HTTP 요청 실패: ${e.message}"};
      } else if (e is FormatException) {
        return {"error": "응답 형식 오류: ${e.message}"};
      } else if (e is TimeoutException) {
        return {"error": "요청 시간 초과"};
      } else {
        return {"error": "Request Failed: ${e.toString()}"};
      }
    }
  }
}