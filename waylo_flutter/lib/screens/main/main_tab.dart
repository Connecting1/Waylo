import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_page_screen.dart';
import 'chat_screen.dart';
import 'shared_map_screen.dart';
import 'search_screen.dart';
import 'setting_screen.dart';
import '../../styles/app_styles.dart';
import '../../providers/theme_provider.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController? controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  /// 시스템 테마 변경 감지 및 업데이트
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mounted) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      if (themeProvider.useSystemTheme) {
        final isDark = brightness == Brightness.dark;
        if (themeProvider.isDarkMode != isDark) {
          themeProvider.updateSystemTheme(isDark);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _buildTabBarView(),
        bottomNavigationBar: _buildBottomTabBar(themeProvider),
      ),
    );
  }

  /// 탭 화면들 구성
  Widget _buildTabBarView() {
    return TabBarView(
      physics: NeverScrollableScrollPhysics(),
      controller: controller,
      children: <Widget>[
        MyPageScreenPage(),
        SharedMapScreenPage(),
        SearchScreenPage(),
        ChatScreenPage(),
        SettingScreenPage(),
      ],
    );
  }

  /// 하단 탭바 구성
  Widget _buildBottomTabBar(ThemeProvider themeProvider) {
    return Material(
      color: themeProvider.isDarkMode ? AppColors.darkSurface : Colors.white,
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
        indicatorColor: AppColors.primary,
        tabs: <Tab>[
          Tab(icon: Icon(Icons.person_pin_circle)),
          Tab(icon: Icon(Icons.public)),
          Tab(icon: Icon(Icons.search)),
          Tab(icon: Icon(Icons.forum)),
          Tab(icon: Icon(Icons.settings)),
        ],
      ),
    );
  }
}