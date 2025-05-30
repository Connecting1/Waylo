import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 회원가입 정보 및 로그인 상태를 관리하는 Provider
class SignUpProvider extends ChangeNotifier {
  String _email = '';                                   // 사용자 이메일
  String? _password = '';                               // 사용자 비밀번호
  String _birthDate = '';                               // 생년월일
  String _gender = '';                                  // 성별
  String _username = '';                                // 사용자명
  String _phoneNumber = '';                             // 전화번호
  String _provider = '';                                // 로그인 제공자 (google, apple 등)
  String _authToken = '';                               // 인증 토큰
  bool _isLoggedIn = false;                             // 로그인 상태

  String get email => _email;
  String? get password => _password;
  String get birthDate => _birthDate;
  String get gender => _gender;
  String get username => _username;
  String get phoneNumber => _phoneNumber;
  String get provider => _provider;
  String get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;

  /// 이메일 설정
  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  /// 비밀번호 설정
  void setPassword(String? password) {
    _password = password;
    notifyListeners();
  }

  /// 생년월일 설정
  void setBirthDate(String birthDate) {
    _birthDate = birthDate;
    notifyListeners();
  }

  /// 성별 설정
  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  /// 사용자명 설정
  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  /// 전화번호 설정
  void setPhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  /// 로그인 제공자 설정
  void setProvider(String provider) {
    _provider = provider;
    notifyListeners();
  }

  /// 인증 토큰 설정 및 저장
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    _isLoggedIn = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('is_logged_in', true);
  }

  /// 저장된 인증 토큰 및 로그인 상태 로드
  Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token') ?? '';
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    notifyListeners();
  }

  /// 로그인 상태 설정 및 저장
  Future<void> setLoggedIn(bool status) async {
    _isLoggedIn = status;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', status);
  }

  /// 로그아웃 처리
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_logged_in');
    _authToken = '';
    _isLoggedIn = false;
    notifyListeners();
  }
}