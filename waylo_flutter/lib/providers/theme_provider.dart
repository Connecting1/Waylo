import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/app_styles.dart';

/// 앱의 테마 설정을 관리하는 Provider
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;                             // 다크 모드 활성화 여부
  bool _useSystemTheme = true;                          // 시스템 테마 사용 여부

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  ThemeData get currentTheme => _isDarkMode ? AppColors.darkTheme : AppColors.lightTheme;

  Color get backgroundColor => _isDarkMode ? Color(0xFF121212) : Colors.white;

  Color get cardColor => _isDarkMode ? Color(0xFF2C2C2C) : Colors.white;

  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;

  Color get secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.black54;

  Color get iconColor => _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// 시스템 테마 변경 시 호출 (외부에서 사용)
  void updateSystemTheme(bool isDark) {
    if (_useSystemTheme && _isDarkMode != isDark) {
      _isDarkMode = isDark;
      _updateSystemUIOverlayStyle();
      notifyListeners();

      Future.delayed(Duration(milliseconds: 50), () {
        notifyListeners();
      });
    }
  }

  /// 시스템 테마에 따라 업데이트
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

  /// 시스템 UI 오버레이 스타일 업데이트
  void _updateSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDarkMode ? AppColors.darkBackground : Colors.white,
      systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }

  /// 저장된 테마 설정 로드
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool('use_system_theme') ?? true;

    if (_useSystemTheme) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    } else {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    }

    _updateSystemUIOverlayStyle();
    notifyListeners();
  }

  /// 테마 수동 전환
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _useSystemTheme = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('use_system_theme', _useSystemTheme);

    _updateSystemUIOverlayStyle();
    notifyListeners();
  }

  /// 시스템 테마 사용 설정 변경
  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_system_theme', _useSystemTheme);

    if (_useSystemTheme) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      final newIsDarkMode = brightness == Brightness.dark;

      if (_isDarkMode != newIsDarkMode) {
        _isDarkMode = newIsDarkMode;
        _updateSystemUIOverlayStyle();
      }
    }

    notifyListeners();
  }

  /// Provider 상태 초기화
  void reset() {
    _loadThemePreference();
  }
}