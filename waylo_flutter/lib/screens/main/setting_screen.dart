// lib/screen/main/setting_screen.dart
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          _buildSectionHeader("Account Settings"),
          _buildSettingItem(
            icon: Icons.camera_alt,
            title: "Change Profile Picture",
            onTap: () {
              // ProfilePictureScreen으로 이동 (새로 만들어야 함)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePictureScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.person,
            title: "Change Username",
            onTap: () {
              // UsernameEditScreen으로 이동 (새로 만들어야 함)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsernameEditScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: "Account Privacy",
            subtitle: _getPrivacySubtitle(), // 현재 설정 표시
            onTap: () {
              // AccountPrivacyScreen으로 이동 (새로 만들어야 함)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountPrivacyScreen()),
              );
            },
          ),
          // _buildSettingItem(
          //   icon: Icons.lock,
          //   title: "Change Password",
          //   onTap: () {
          //     // 비밀번호 변경 화면으로 이동
          //   },
          // ),

          _buildSectionHeader("Notification Settings"),

          // _buildSwitchItem(
          //   icon: Icons.notifications,
          //   title: "Push Notifications",
          //   value: true,
          //   onChanged: (value) {
          //     // 푸시 알림 설정 저장
          //   },
          // ),
          // _buildSwitchItem(
          //   icon: Icons.favorite,
          //   title: "Like Notifications",
          //   value: true,
          //   onChanged: (value) {
          //     // 좋아요 알림 설정 저장
          //   },
          // ),
          // _buildSwitchItem(
          //   icon: Icons.comment,
          //   title: "Comment Notifications",
          //   value: true,
          //   onChanged: (value) {
          //     // 댓글 알림 설정 저장
          //   },
          // ),

          _buildSettingItem(
            icon: Icons.location_on,
            title: "Location Sharing",
            subtitle: "Manage location visibility settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationSettingsScreen()),
              );
            },
          ),
          // _buildSettingItem(
          //   icon: Icons.public,
          //   title: "Post Privacy",
          //   subtitle: "Default: Public",
          //   onTap: () {
          //     // 피드 게시물 공개 범위 설정 화면으로 이동
          //   },
          // ),

          _buildSectionHeader("App Settings"),
          _buildSettingItem(
            icon: Icons.language,
            title: "Language",
            subtitle: "English",
            onTap: () {
              // 언어 설정 화면으로 이동
            },
          ),
          _buildSettingItem(
            icon: Icons.dark_mode,
            title: "Theme",
            subtitle: Provider.of<ThemeProvider>(context).useSystemTheme
                ? "System (${Provider.of<ThemeProvider>(context).isDarkMode ? 'Dark Mode' : 'Light Mode'})"
                : Provider.of<ThemeProvider>(context).isDarkMode
                ? "Dark Mode"
                : "Light Mode",
            onTap: () {
              // 테마 설정 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThemeSettingsScreen()),
              );
            },
          ),

          _buildSectionHeader("Support & Information"),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help",
            onTap: () {
              // 도움말 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () {
              // 개인정보 처리방침 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: "App Version",
            subtitle: "v1.0.0",
            onTap: () {
              // 앱 버전 정보 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppVersionScreen()),
              );
            },
          ),

          // 로그아웃 버튼
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: GestureDetector(
                onTap: () {
                  _showLogoutConfirmDialog();
                },
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
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

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

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  String _getPrivacySubtitle() {
    final userProvider = Provider.of<UserProvider>(context);
    return userProvider.accountVisibility == 'public'
        ? "Public Account"
        : "Private Account";
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Cache"),
        content: Text("Are you sure you want to clear the app cache?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // 캐시 정리 로직 구현
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Cache has been cleared.")),
              );
            },
            child: Text("Confirm"),
          ),
        ],
      ),
    );
  }

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

  void _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 모든 Provider 초기화
      Provider.of<SignUpProvider>(context, listen: false).logout();
      Provider.of<FeedMapProvider>(context, listen: false).reset();
      Provider.of<CanvasProvider>(context, listen: false).reset();
      Provider.of<UserProvider>(context, listen: false).reset();
      Provider.of<WidgetProvider>(context, listen: false).reset();
      Provider.of<ThemeProvider>(context, listen: false).reset();
      Provider.of<LocationSettingsProvider>(context, listen: false).reset();

      // 로그인 화면으로 이동
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