import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String? password,
    required String gender,
    required String username,
    required String phoneNumber,
    required String provider,
    String? profileImage,
  }) async {
    print("🔵 API 요청 시작");

    final url = Uri.parse("http://172.30.8.184:8000/users/create/");

    try {
      final Map<String, dynamic> requestBody = {
        "email": email,
        "password": password,
        "gender": gender.toLowerCase(),
        "username": username,
        "phone_number": phoneNumber,
        "provider": provider,
      };

      if (profileImage != null) {
        requestBody["profile_image"] = profileImage; // null 값은 전송하지 않도록 수정
      }

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("응답 상태 코드: ${response.statusCode}");
      print("응답 본문: ${response.body}");

      if (response.statusCode == 201) {
        print("User created successfully!");
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.body}");
        return {"error": response.body};
      }
    } catch (e) {
      print("예외 발생: $e"); // 네트워크 오류, JSON 디코딩 오류 등 예외 처리 추가
      return {"error": "Network error or invalid response"};
    }
  }

  static Future<Map<String, dynamic>> loginUser(String email, String password) async { // 로그인 기능 추가
    final url = Uri.parse("http://172.30.8.184:8000/users/login/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "로그인 실패, 이메일 또는 비밀번호를 확인하세요."};
      }
    } catch (e) {
      return {"error": "Network error or invalid response"};
    }
  }
}
