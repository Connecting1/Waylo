import 'dart:io';
import 'api_service.dart';

class UserApi {
  // 회원가입
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String? password,
    required String gender,
    required String username,
    required String phoneNumber,
    required String provider,
    String? profileImage,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/users/create/",
      method: "POST",
      body: {
        "email": email,
        "password": password,
        "gender": gender.toLowerCase(),
        "username": username,
        "phone_number": phoneNumber,
        "provider": provider,
        "profile_image": profileImage,
      },
    );
  }

  // 로그인
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    return await ApiService.sendRequest(
      endpoint: "/api/users/login/",
      method: "POST",
      body: {"email": email, "password": password},
    );
  }

  // 유저 정보 가져오기 (GET)
  static Future<Map<String, dynamic>> fetchUserInfo() async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return {"error": "No User Logged In"};
    return await ApiService.sendRequest(endpoint: "/api/users/$userId/");
  }

  // 유저 정보 수정 (PATCH)
  static Future<Map<String, dynamic>> updateUserInfo({
    required String userId,
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
    String? accountVisibility,
    File? profileImage,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/users/$userId/update/",
      method: "PATCH",
      body: {
        "username": username,
        "email": email,
        "gender": gender,
        "phone_number": phoneNumber,
        "account_visibility": accountVisibility,
      },
      file: profileImage,
    );
  }

  // 프로필 이미지만 업데이트 (PATCH)
  static Future<Map<String, dynamic>> updateProfileImage({
    required String userId,
    required File profileImage,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/users/$userId/update-profile-image/",
      method: "PATCH",
      file: profileImage,
    );
  }

  static Future<dynamic> searchUsers(String prefix) async {
    return await ApiService.sendRequest(
      endpoint: "/api/users/search/?prefix=$prefix",
      method: "GET",
    );
  }
}



