// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/app_styles.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemTheme = true; // 시스템 테마 사용 여부

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  // 현재 활성화된 테마 가져오기
  ThemeData get currentTheme => _isDarkMode ? AppColors.darkTheme : AppColors.lightTheme;

  // 기본 배경색 가져오기
  Color get backgroundColor => _isDarkMode ? Color(0xFF121212) : Colors.white;

  // 카드 배경색 가져오기
  Color get cardColor => _isDarkMode ? Color(0xFF2C2C2C) : Colors.white;

  // 텍스트 색상 가져오기
  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;

  // 보조 텍스트 색상 가져오기
  Color get secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.black54;

  // 아이콘 색상 가져오기
  Color get iconColor => _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

  ThemeProvider() {
    _loadThemePreference();
  }

  // 새로운 메서드: 시스템 테마 직접 설정 (외부에서 호출)
  void updateSystemTheme(bool isDark) {
    if (_useSystemTheme && _isDarkMode != isDark) {
      _isDarkMode = isDark;
      _updateSystemUIOverlayStyle();
      notifyListeners();

      // 일부 위젯이 업데이트되지 않는 경우를 방지하기 위한 지연 알림
      Future.delayed(Duration(milliseconds: 50), () {
        notifyListeners();
      });
    }
  }

  // 시스템 테마 적용 함수
  void updateWithSystemTheme(BuildContext context) {
    if (_useSystemTheme) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final systemIsDark = brightness == Brightness.dark;

      if (_isDarkMode != systemIsDark) {
        _isDarkMode = systemIsDark;
        _updateSystemUIOverlayStyle();
        notifyListeners();
      }
    }
  }

  // 시스템 UI 오버레이 스타일 업데이트 (상태바 등)
  void _updateSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDarkMode ? AppColors.darkBackground : Colors.white,
      systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool('use_system_theme') ?? true; // 기본값: 시스템 테마 사용

    if (_useSystemTheme) {
      // 시스템 테마를 사용하는 경우, 현재 시스템 테마 확인
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    } else {
      // 수동 설정된 테마 사용
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    }

    _updateSystemUIOverlayStyle();
    notifyListeners();
  }

  // 테마 전환 (수동)
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _useSystemTheme = false; // 수동으로 테마 변경 시 시스템 테마 사용 해제

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('use_system_theme', _useSystemTheme);

    _updateSystemUIOverlayStyle();
    notifyListeners();
  }

  // 시스템 테마 사용 설정
  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_system_theme', _useSystemTheme);

    if (_useSystemTheme) {
      // 시스템 테마로 즉시 업데이트
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      final newIsDarkMode = brightness == Brightness.dark;

      if (_isDarkMode != newIsDarkMode) {
        _isDarkMode = newIsDarkMode;
        _updateSystemUIOverlayStyle();
      }
    }

    notifyListeners();
  }

  // 앱 재시작 시 상태 초기화
  void reset() {
    _loadThemePreference();
  }
}