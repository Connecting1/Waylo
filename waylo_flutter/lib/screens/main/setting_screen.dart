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
        "Settings",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
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
        SizedBox(height: 20),
      ],
    );
  }

  /// 계정 설정 섹션
  List<Widget> _buildAccountSettings() {
    return [
      _buildSectionHeader("Account Settings"),
      _buildSettingItem(
        icon: Icons.camera_alt,
        title: "Change Profile Picture",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePictureScreen())),
      ),
      _buildSettingItem(
        icon: Icons.person,
        title: "Change Username",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UsernameEditScreen())),
      ),
      _buildSettingItem(
        icon: Icons.lock_outline,
        title: "Account Privacy",
        subtitle: _getPrivacySubtitle(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPrivacyScreen())),
      ),
    ];
  }

  /// 알림 설정 섹션
  List<Widget> _buildNotificationSettings() {
    return [
      _buildSectionHeader("Notification Settings"),
      _buildSettingItem(
        icon: Icons.location_on,
        title: "Location Sharing",
        subtitle: "Manage location visibility settings",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationSettingsScreen())),
      ),
    ];
  }

  /// 앱 설정 섹션
  List<Widget> _buildAppSettings() {
    return [
      _buildSectionHeader("App Settings"),
      _buildSettingItem(
        icon: Icons.language,
        title: "Language",
        subtitle: "English",
        onTap: () {
          // 언어 설정 기능 추후 구현
        },
      ),
      _buildSettingItem(
        icon: Icons.dark_mode,
        title: "Theme",
        subtitle: _getThemeSubtitle(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThemeSettingsScreen())),
      ),
    ];
  }

  /// 지원 및 정보 섹션
  List<Widget> _buildSupportSettings() {
    return [
      _buildSectionHeader("Support & Information"),
      _buildSettingItem(
        icon: Icons.help_outline,
        title: "Help",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HelpScreen())),
      ),
      _buildSettingItem(
        icon: Icons.privacy_tip_outlined,
        title: "Privacy Policy",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyScreen())),
      ),
      _buildSettingItem(
        icon: Icons.info_outline,
        title: "App Version",
        subtitle: "v1.0.0",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AppVersionScreen())),
      ),
    ];
  }

  /// 로그아웃 버튼
  Widget _buildLogoutButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: GestureDetector(
          onTap: _showLogoutConfirmDialog,
          child: Text(
            "Logout",
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 16,
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
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// 개인정보 보호 설정 부제목 가져오기
  String _getPrivacySubtitle() {
    final userProvider = Provider.of<UserProvider>(context);
    return userProvider.accountVisibility == 'public'
        ? "Public Account"
        : "Private Account";
  }

  /// 테마 설정 부제목 가져오기
  String _getThemeSubtitle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (themeProvider.useSystemTheme) {
      return "System (${themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'})";
    }
    return themeProvider.isDarkMode ? "Dark Mode" : "Light Mode";
  }

  /// 로그아웃 확인 다이얼로그 표시
  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: Text("Logout", style: TextStyle(color: Colors.red)),
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
        SnackBar(content: Text("An error occurred during logout.")),
      );
    }
  }
}