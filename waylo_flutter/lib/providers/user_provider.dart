// providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/user_api.dart';

import '../services/api/api_service.dart';

class UserProvider extends ChangeNotifier {
  String _username = "Loading...";
  String _email = "";
  String _gender = "";
  String _phoneNumber = "";
  String _accountVisibility = "";
  String _profileImage = "";
  String _userId = "";
  bool _isLoaded = false;

  // Getters
  String get username => _username;
  String get email => _email;
  String get gender => _gender;
  String get phoneNumber => _phoneNumber;
  String get accountVisibility => _accountVisibility;
  String get profileImage => _profileImage;
  String get userId => _userId;
  bool get isLoaded => _isLoaded;

  // 사용자 정보 로드
  Future<void> loadUserInfo({bool forceRefresh = false}) async {
    // 이미 로드된 경우 중복 로드 방지
    if (!forceRefresh && _isLoaded) return;

    try {
      // UserApi를 사용하여 사용자 정보 가져오기
      Map<String, dynamic> userInfo = await UserApi.fetchUserInfo();

      if (userInfo.containsKey("error")) {
        _username = "Guest";
      } else {
        _username = userInfo["username"] ?? "Guest";
        _email = userInfo["email"] ?? "";
        _gender = userInfo["gender"] ?? "";
        _phoneNumber = userInfo["phone_number"] ?? "";
        _accountVisibility = userInfo["account_visibility"] ?? "";

        // 프로필 이미지 URL 처리 - 상대 경로를 전체 URL로 변환
        _profileImage = userInfo["profile_image"] ?? "";
        if (_profileImage.isNotEmpty && _profileImage.startsWith("/")) {
          _profileImage = "${ApiService.baseUrl}${_profileImage}";
        }

        // 캐시 버스팅을 위한 타임스탬프 추가
        if (_profileImage.isNotEmpty) {
          _profileImage = "$_profileImage?t=${DateTime.now().millisecondsSinceEpoch}";
        }

        _userId = userInfo["id"]?.toString() ?? "";
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _username = "Guest";
      notifyListeners();
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUserInfo({
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
    String? accountVisibility,
  }) async {
    if (_userId.isEmpty) {
      return;
    }

    try {
      Map<String, dynamic> result = await UserApi.updateUserInfo(
        userId: _userId,
        username: username,
        email: email,
        gender: gender,
        phoneNumber: phoneNumber,
        accountVisibility: accountVisibility,
      );

      if (result.containsKey("error")) {
        return;
      }

      // 로컬 상태 업데이트
      _username = username ?? _username;
      _email = email ?? _email;
      _gender = gender ?? _gender;
      _phoneNumber = phoneNumber ?? _phoneNumber;
      _accountVisibility = accountVisibility ?? _accountVisibility;

      notifyListeners();
    } catch (e) {
      print("[ERROR] 사용자 정보 업데이트 실패: $e");
    }
  }

  // 로그아웃 시 상태 초기화
  void reset() {
    _username = "Loading...";
    _email = "";
    _gender = "";
    _phoneNumber = "";
    _accountVisibility = "";
    _profileImage = "";
    _userId = "";
    _isLoaded = false;
    notifyListeners();
  }
}