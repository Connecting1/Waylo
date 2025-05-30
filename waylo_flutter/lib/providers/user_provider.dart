import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import '../services/api/api_service.dart';

/// 사용자 정보를 관리하는 Provider
class UserProvider extends ChangeNotifier {
  String _username = "Loading...";                      // 사용자명
  String _email = "";                                   // 이메일 주소
  String _gender = "";                                  // 성별
  String _phoneNumber = "";                             // 전화번호
  String _accountVisibility = "";                       // 계정 공개 설정
  String _profileImage = "";                            // 프로필 이미지 URL
  String _userId = "";                                  // 사용자 고유 ID
  bool _isLoaded = false;                               // 사용자 정보 로드 완료 여부

  String get username => _username;
  String get email => _email;
  String get gender => _gender;
  String get phoneNumber => _phoneNumber;
  String get accountVisibility => _accountVisibility;
  String get profileImage => _profileImage;
  String get userId => _userId;
  bool get isLoaded => _isLoaded;

  /// 사용자 정보 로드
  Future<void> loadUserInfo({bool forceRefresh = false}) async {
    if (!forceRefresh && _isLoaded) return;

    try {
      Map<String, dynamic> userInfo = await UserApi.fetchUserInfo();

      if (userInfo.containsKey("error")) {
        _username = "Guest";
      } else {
        _username = userInfo["username"] ?? "Guest";
        _email = userInfo["email"] ?? "";
        _gender = userInfo["gender"] ?? "";
        _phoneNumber = userInfo["phone_number"] ?? "";
        _accountVisibility = userInfo["account_visibility"] ?? "";

        _profileImage = userInfo["profile_image"] ?? "";
        if (_profileImage.isNotEmpty && _profileImage.startsWith("/")) {
          _profileImage = "${ApiService.baseUrl}${_profileImage}";
        }

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

  /// 사용자 정보 업데이트
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

      _username = username ?? _username;
      _email = email ?? _email;
      _gender = gender ?? _gender;
      _phoneNumber = phoneNumber ?? _phoneNumber;
      _accountVisibility = accountVisibility ?? _accountVisibility;

      notifyListeners();
    } catch (e) {
      // 업데이트 실패 시 조용히 처리
    }
  }

  /// Provider 상태 초기화
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