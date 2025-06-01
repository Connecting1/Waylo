import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';
import '../../providers/sign_up_provider.dart';
import '../../providers/canvas_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/feed_map_provider.dart';
import '../../providers/widget_provider.dart';
import '../../providers/location_settings_provider.dart';
import '../../screens/auth/sign_up_start.dart';
import '../setting/profile_picture_screen.dart';
import '../setting/theme_settings_screen.dart';
import '../setting/username_edit_screen.dart';
import '../setting/account_privacy_screen.dart';
import '../setting/help_screen.dart';
import '../setting/privacy_policy_screen.dart';
import '../setting/app_version_screen.dart';
import '../setting/location_settings_screen.dart';

class SettingScreenPage extends StatefulWidget {
  const SettingScreenPage({Key? key}) : super(key: key);

  @override
  _SettingScreenPageState createState() => _SettingScreenPageState();
}

class _SettingScreenPageState extends State<SettingScreenPage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Settings";
  static const String _accountSettingsTitle = "Account Settings";
  static const String _notificationSettingsTitle = "Notification Settings";
  static const String _appSettingsTitle = "App Settings";
  static const String _supportSettingsTitle = "Support & Information";
  static const String _changeProfilePictureTitle = "Change Profile Picture";
  static const String _changeUsernameTitle = "Change Username";
  static const String _accountPrivacyTitle = "Account Privacy";
  static const String _locationSharingTitle = "Location Sharing";
  static const String _locationSharingSubtitle = "Manage location visibility settings";
  static const String _languageTitle = "Language";
  static const String _languageSubtitle = "English";
  static const String _themeTitle = "Theme";
  static const String _helpTitle = "Help";
  static const String _privacyPolicyTitle = "Privacy Policy";
  static const String _appVersionTitle = "App Version";
  static const String _appVersionSubtitle = "v1.0.0";
  static const String _logoutTitle = "Logout";
  static const String _logoutConfirmTitle = "Logout";
  static const String _logoutConfirmContent = "Are you sure you want to logout?";
  static const String _cancelButtonText = "Cancel";
  static const String _publicAccountText = "Public Account";
  static const String _privateAccountText = "Private Account";
  static const String _systemThemePrefix = "System (";
  static const String _systemThemeSuffix = ")";
  static const String _darkModeText = "Dark Mode";
  static const String _lightModeText = "Light Mode";

  // 에러 메시지 상수들
  static const String _logoutErrorMessage = "An error occurred during logout.";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 16;
  static const double _sectionHeaderFontSize = 16;
  static const double _logoutButtonFontSize = 16;

  // 크기 상수들
  static const double _sectionHeaderPaddingHorizontal = 16;
  static const double _sectionHeaderPaddingTop = 16;
  static const double _sectionHeaderPaddingBottom = 8;
  static const double _logoutButtonVerticalPadding = 20.0;
  static const double _bottomSpacing = 20;

  // 계정 관련 상수들
  static const String _publicVisibility = 'public';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildSettingsList(),
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: const Text(
        _appBarTitle,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: _appBarTitleFontSize,
        ),
      ),
      centerTitle: true,
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 설정 목록 구성
  Widget _buildSettingsList() {
    return ListView(
      children: [
        ..._buildAccountSettings(),
        ..._buildNotificationSettings(),
        ..._buildAppSettings(),
        ..._buildSupportSettings(),
        _buildLogoutButton(),
        const SizedBox(height: _bottomSpacing),
      ],
    );
  }

  /// 계정 설정 섹션
  List<Widget> _buildAccountSettings() {
    return [
      _buildSectionHeader(_accountSettingsTitle),
      _buildSettingItem(
        icon: Icons.camera_alt,
        title: _changeProfilePictureTitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePictureScreen())),
      ),
      _buildSettingItem(
        icon: Icons.person,
        title: _changeUsernameTitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UsernameEditScreen())),
      ),
      _buildSettingItem(
        icon: Icons.lock_outline,
        title: _accountPrivacyTitle,
        subtitle: _getPrivacySubtitle(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPrivacyScreen())),
      ),
    ];
  }

  /// 알림 설정 섹션
  List<Widget> _buildNotificationSettings() {
    return [
      _buildSectionHeader(_notificationSettingsTitle),
      _buildSettingItem(
        icon: Icons.location_on,
        title: _locationSharingTitle,
        subtitle: _locationSharingSubtitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationSettingsScreen())),
      ),
    ];
  }

  /// 앱 설정 섹션
  List<Widget> _buildAppSettings() {
    return [
      _buildSectionHeader(_appSettingsTitle),
      _buildSettingItem(
        icon: Icons.language,
        title: _languageTitle,
        subtitle: _languageSubtitle,
        onTap: () {
          // 언어 설정 기능 추후 구현
        },
      ),
      _buildSettingItem(
        icon: Icons.dark_mode,
        title: _themeTitle,
        subtitle: _getThemeSubtitle(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThemeSettingsScreen())),
      ),
    ];
  }

  /// 지원 및 정보 섹션
  List<Widget> _buildSupportSettings() {
    return [
      _buildSectionHeader(_supportSettingsTitle),
      _buildSettingItem(
        icon: Icons.help_outline,
        title: _helpTitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HelpScreen())),
      ),
      _buildSettingItem(
        icon: Icons.privacy_tip_outlined,
        title: _privacyPolicyTitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyScreen())),
      ),
      _buildSettingItem(
        icon: Icons.info_outline,
        title: _appVersionTitle,
        subtitle: _appVersionSubtitle,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AppVersionScreen())),
      ),
    ];
  }

  /// 로그아웃 버튼
  Widget _buildLogoutButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _logoutButtonVerticalPadding),
        child: GestureDetector(
          onTap: _showLogoutConfirmDialog,
          child: const Text(
            _logoutTitle,
            style: TextStyle(
              color: Colors.red,
              fontSize: _logoutButtonFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sectionHeaderPaddingHorizontal,
        _sectionHeaderPaddingTop,
        _sectionHeaderPaddingHorizontal,
        _sectionHeaderPaddingBottom,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: _sectionHeaderFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 설정 아이템 위젯
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// 개인정보 보호 설정 부제목 가져오기
  String _getPrivacySubtitle() {
    final userProvider = Provider.of<UserProvider>(context);
    return userProvider.accountVisibility == _publicVisibility
        ? _publicAccountText
        : _privateAccountText;
  }

  /// 테마 설정 부제목 가져오기
  String _getThemeSubtitle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (themeProvider.useSystemTheme) {
      return "$_systemThemePrefix${themeProvider.isDarkMode ? _darkModeText : _lightModeText}$_systemThemeSuffix";
    }
    return themeProvider.isDarkMode ? _darkModeText : _lightModeText;
  }

  /// 로그아웃 확인 다이얼로그 표시
  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_logoutConfirmTitle),
        content: const Text(_logoutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(_cancelButtonText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text(_logoutTitle, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 로그아웃 처리
  void _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Provider.of<SignUpProvider>(context, listen: false).logout();
      Provider.of<FeedMapProvider>(context, listen: false).reset();
      Provider.of<CanvasProvider>(context, listen: false).reset();
      Provider.of<UserProvider>(context, listen: false).reset();
      Provider.of<WidgetProvider>(context, listen: false).reset();
      Provider.of<ThemeProvider>(context, listen: false).reset();
      Provider.of<LocationSettingsProvider>(context, listen: false).reset();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SignUpStartPage()),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_logoutErrorMessage)),
      );
    }
  }
}