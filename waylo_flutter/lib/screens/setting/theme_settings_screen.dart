import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  // 텍스트 상수들
  static const String _appBarTitle = "Theme Settings";
  static const String _appAppearanceTitle = "App Appearance";
  static const String _appAppearanceDescription = "Choose how Waylo looks on your device. You can use the system setting or choose a specific theme.";
  static const String _useDeviceSettingsTitle = "Use Device Settings";
  static const String _useDeviceSettingsSubtitle = "Automatically switch between light and dark themes based on your device settings";
  static const String _manualThemeSelectionTitle = "Manual Theme Selection";
  static const String _lightModeTitle = "Light Mode";
  static const String _lightModeSubtitle = "Light backgrounds with dark text";
  static const String _darkModeTitle = "Dark Mode";
  static const String _darkModeSubtitle = "Dark backgrounds with light text";
  static const String _currentStatusTitle = "Current Status";
  static const String _usingSystemThemePrefix = "Using system theme (";
  static const String _usingSystemThemeSuffix = ")";
  static const String _usingDarkModeText = "Using Dark Mode";
  static const String _usingLightModeText = "Using Light Mode";
  static const String _darkModeText = "Dark Mode";
  static const String _lightModeText = "Light Mode";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _appAppearanceTitleFontSize = 18;
  static const double _descriptionFontSize = 14;
  static const double _manualThemeSelectionFontSize = 16;
  static const double _statusTextFontSize = 14;

  // 크기 상수들
  static const double _screenPadding = 16;
  static const double _cardInnerPadding = 16;
  static const double _sectionSpacing = 20;
  static const double _titleDescriptionSpacing = 8;
  static const double _iconTextSpacing = 12;
  static const double _statusContentSpacing = 4;
  static const double _finalSpacing = 40;

  // 패딩 상수들
  static const EdgeInsets _manualThemeTitlePadding = EdgeInsets.fromLTRB(16, 16, 16, 8);

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      title: const Text(
        _appBarTitle,
        style: TextStyle(
          fontSize: _appBarTitleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// 앱 외관 설명 카드 구성
  Widget _buildAppAppearanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardInnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _appAppearanceTitle,
              style: TextStyle(
                fontSize: _appAppearanceTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _titleDescriptionSpacing),
            Text(
              _appAppearanceDescription,
              style: TextStyle(
                fontSize: _descriptionFontSize,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시스템 테마 설정 카드 구성
  Widget _buildSystemThemeCard(ThemeProvider themeProvider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              _useDeviceSettingsTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              _useDeviceSettingsSubtitle,
              style: TextStyle(fontSize: _descriptionFontSize),
            ),
            value: themeProvider.useSystemTheme,
            onChanged: (value) {
              themeProvider.setUseSystemTheme(value);
            },
            secondary: const Icon(
              Icons.phone_android,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 수동 테마 선택 카드 구성
  Widget _buildManualThemeCard(ThemeProvider themeProvider) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: _manualThemeTitlePadding,
            child: Text(
              _manualThemeSelectionTitle,
              style: TextStyle(
                fontSize: _manualThemeSelectionFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildLightModeOption(themeProvider),
          _buildDarkModeOption(themeProvider),
        ],
      ),
    );
  }

  /// 라이트 모드 옵션 구성
  Widget _buildLightModeOption(ThemeProvider themeProvider) {
    return RadioListTile<bool>(
      title: const Text(_lightModeTitle),
      subtitle: const Text(_lightModeSubtitle),
      value: false,
      groupValue: themeProvider.isDarkMode,
      onChanged: themeProvider.useSystemTheme
          ? null
          : (value) {
        if (value != null && themeProvider.isDarkMode) {
          themeProvider.toggleTheme();
        }
      },
      secondary: Icon(
        Icons.wb_sunny,
        color: themeProvider.useSystemTheme ? Colors.grey : Colors.orange,
      ),
    );
  }

  /// 다크 모드 옵션 구성
  Widget _buildDarkModeOption(ThemeProvider themeProvider) {
    return RadioListTile<bool>(
      title: const Text(_darkModeTitle),
      subtitle: const Text(_darkModeSubtitle),
      value: true,
      groupValue: themeProvider.isDarkMode,
      onChanged: themeProvider.useSystemTheme
          ? null
          : (value) {
        if (value != null && !themeProvider.isDarkMode) {
          themeProvider.toggleTheme();
        }
      },
      secondary: Icon(
        Icons.nights_stay,
        color: themeProvider.useSystemTheme ? Colors.grey : Colors.indigo,
      ),
    );
  }

  /// 현재 상태 카드 구성
  Widget _buildCurrentStatusCard(ThemeProvider themeProvider) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(_cardInnerPadding),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
            ),
            const SizedBox(width: _iconTextSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStatusTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: _statusContentSpacing),
                  Text(
                    _buildCurrentStatusText(themeProvider),
                    style: TextStyle(
                      fontSize: _statusTextFontSize,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 현재 상태 텍스트 생성
  String _buildCurrentStatusText(ThemeProvider themeProvider) {
    if (themeProvider.useSystemTheme) {
      final currentMode = themeProvider.isDarkMode ? _darkModeText : _lightModeText;
      return "$_usingSystemThemePrefix$currentMode$_usingSystemThemeSuffix";
    } else {
      return themeProvider.isDarkMode ? _usingDarkModeText : _usingLightModeText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(_screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppAppearanceCard(),
                const SizedBox(height: _sectionSpacing),
                _buildSystemThemeCard(themeProvider),
                const SizedBox(height: _sectionSpacing),
                _buildManualThemeCard(themeProvider),
                const SizedBox(height: _sectionSpacing),
                _buildCurrentStatusCard(themeProvider),
                const SizedBox(height: _finalSpacing),
              ],
            ),
          ),
        );
      },
    );
  }
}