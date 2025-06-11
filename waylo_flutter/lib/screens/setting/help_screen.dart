import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  // 텍스트 상수들
  static const String _appBarTitle = "Help Center";
  static const String _appVersionText = "App Version: 1.0.0";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _sectionTitleFontSize = 18;
  static const double _helpItemTitleFontSize = 16;
  static const double _helpItemContentFontSize = 14;
  static const double _appVersionFontSize = 14;

  // 크기 상수들
  static const double _screenPadding = 16;
  static const double _sectionVerticalPadding = 12;
  static const double _helpItemPadding = 16;
  static const double _dividerHeight = 32;
  static const double _dividerThickness = 1;
  static const double _contentLineHeight = 1.5;
  static const double _bottomSectionSpacing = 30;
  static const double _finalSpacing = 20;

  /// AppBar 구성
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
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

  /// Getting Started 섹션 구성
  Widget _buildGettingStartedSection() {
    return _buildHelpSection(
      title: "Getting Started",
      items: [
        _HelpItem(
            title: "How to create an account",
            content: "Even if I shared my dedication in the report, this is from my my dedication"
        ),
        _HelpItem(
            title: "How to log in",
            content: "If you already have an account, simply tap 'Log in' on the welcome screen and enter your email and password to access your account."
        ),
        _HelpItem(
            title: "How to set up your profile",
            content: "After creating your account, you can personalize your profile by going to the Settings screen and tapping on 'Change Profile Picture' or 'Change Username'."
        ),
      ],
    );
  }

  /// Using the Map 섹션 구성
  Widget _buildUsingMapSection() {
    return _buildHelpSection(
      title: "Using the Map",
      items: [
        _HelpItem(
            title: "How to navigate the map",
            content: "Use pinch gestures to zoom in and out, and drag to move around the map. The app will show your posts and your friends' posts on the map based on their location."
        ),
        _HelpItem(
            title: "How to add a post to the map",
            content: "Tap the '+' button while on the Map tab to add a new post. Choose an image from your gallery, and the app will detect the location or allow you to specify one."
        ),
        _HelpItem(
            title: "Understanding map icons",
            content: "On the map, country flags represent grouped posts in a specific country when zoomed out. Individual post markers appear when zoomed in closer."
        ),
      ],
    );
  }

  /// Album Features 섹션 구성
  Widget _buildAlbumFeaturesSection() {
    return _buildHelpSection(
      title: "Album Features",
      items: [
        _HelpItem(
            title: "How to customize your album",
            content: "In the Album tab, tap the '+' button and select 'Change Canvas Background' to modify the color and pattern of your album background."
        ),
        _HelpItem(
            title: "Adding widgets to your album",
            content: "Tap the '+' button in the Album tab and select the type of widget you want to add, such as Profile Image, Checklist, or Text Box."
        ),
        _HelpItem(
            title: "Editing and moving widgets",
            content: "Tap and hold a widget to edit its properties. To move a widget, simply drag it to the desired position on your album."
        ),
      ],
    );
  }

  /// Friends and Chat 섹션 구성
  Widget _buildFriendsChatSection() {
    return _buildHelpSection(
      title: "Friends and Chat",
      items: [
        _HelpItem(
            title: "How to find friends",
            content: "Go to the Search tab and type a username to search for friends. You can send friend requests to users you want to connect with."
        ),
        _HelpItem(
            title: "Managing friend requests",
            content: "You can view and manage your friend requests in the Friends tab. Accept or decline requests from other users."
        ),
        _HelpItem(
            title: "Starting a chat",
            content: "To start a conversation with a friend, go to their profile or find them in your friends list and tap the chat icon."
        ),
      ],
    );
  }

  /// Account Settings 섹션 구성
  Widget _buildAccountSettingsSection() {
    return _buildHelpSection(
      title: "Account Settings",
      items: [
        _HelpItem(
            title: "Privacy settings",
            content: "Control who can see your content by updating your account privacy settings in the Settings tab."
        ),
        _HelpItem(
            title: "Notification preferences",
            content: "Manage what notifications you receive in the Settings tab under Notification Settings."
        ),
        _HelpItem(
            title: "How to log out",
            content: "To log out of your account, go to the Settings tab and scroll to the bottom to find the 'Logout' button."
        ),
      ],
    );
  }

  /// Troubleshooting 섹션 구성
  Widget _buildTroubleshootingSection() {
    return _buildHelpSection(
      title: "Troubleshooting",
      items: [
        _HelpItem(
            title: "App crashes or freezes",
            content: "If the app crashes or freezes, try closing and reopening it. If the issue persists, try clearing the app cache or reinstalling the app."
        ),
        _HelpItem(
            title: "Login issues",
            content: "If you're having trouble logging in, make sure your internet connection is stable. You can also try resetting your password."
        ),
        _HelpItem(
            title: "Contact support",
            content: "For any other issues or questions, please contact our support team at support@waylo.app."
        ),
      ],
    );
  }

  /// 앱 버전 정보 위젯 구성
  Widget _buildAppVersionInfo() {
    return Center(
      child: Text(
        _appVersionText,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: _appVersionFontSize,
        ),
      ),
    );
  }

  /// 도움말 섹션 위젯 구성
  Widget _buildHelpSection({
    required String title,
    required List<_HelpItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: _sectionVerticalPadding),
          child: Text(
            title,
            style: TextStyle(
              fontSize: _sectionTitleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        ...items.map((item) => _buildHelpItem(item)),
        const Divider(height: _dividerHeight, thickness: _dividerThickness),
      ],
    );
  }

  /// 도움말 항목 위젯 구성
  Widget _buildHelpItem(_HelpItem item) {
    return ExpansionTile(
      title: Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: _helpItemTitleFontSize,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_helpItemPadding, 0, _helpItemPadding, _helpItemPadding),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Text(
                item.content,
                style: TextStyle(
                  fontSize: _helpItemContentFontSize,
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                  height: _contentLineHeight,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.all(_screenPadding),
        children: [
          _buildGettingStartedSection(),
          _buildUsingMapSection(),
          _buildAlbumFeaturesSection(),
          _buildFriendsChatSection(),
          _buildAccountSettingsSection(),
          _buildTroubleshootingSection(),
          const SizedBox(height: _bottomSectionSpacing),
          _buildAppVersionInfo(),
          const SizedBox(height: _finalSpacing),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String title;
  final String content;

  _HelpItem({
    required this.title,
    required this.content,
  });
}
