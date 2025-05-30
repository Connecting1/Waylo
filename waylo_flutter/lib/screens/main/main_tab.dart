// lib/screen/main/main_tab.dart

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

    // 시스템 테마 변경 감지를 위한 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // 시스템 밝기 모드가 변경되면 테마 업데이트
    if (mounted) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      if (themeProvider.useSystemTheme) {
        final isDark = brightness == Brightness.dark;
        if (themeProvider.isDarkMode != isDark) {
          // 실제 시스템 테마와 앱 테마가 다르면 강제로 업데이트
          themeProvider.updateSystemTheme(isDark);
        }
      }
    }
  }

  @override
  void dispose() {
    // 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider 사용
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        // 여기서 false를 반환하면 뒤로가기 동작이 무시됩니다
        return false;
      },
      child: Scaffold(
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            MyPageScreenPage(),
            SharedMapScreenPage(),
            SearchScreenPage(),
            ChatScreenPage(),
            SettingScreenPage(),
          ],
          controller: controller,
        ),
        bottomNavigationBar: Material(
          color: themeProvider.isDarkMode ? AppColors.darkSurface : Colors.white,
          child: TabBar(
            tabs: <Tab>[
              Tab(icon: Icon(Icons.person_pin_circle)),
              Tab(icon: Icon(Icons.public)),
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.forum)),
              Tab(icon: Icon(Icons.settings)),
            ],
            controller: controller,
            labelColor: AppColors.primary, // 선택된 탭 아이콘 색상은 앱 기본 색상 유지
            unselectedLabelColor: themeProvider.isDarkMode
                ? Colors.grey[400]
                : Colors.grey, // 선택되지 않은 탭 아이콘 색상 테마에 따라 변경
            indicatorColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}