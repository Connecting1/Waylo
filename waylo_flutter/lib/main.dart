import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/sign_up_provider.dart';
import 'providers/canvas_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/map_provider.dart';
import 'providers/feed_map_provider.dart';
import 'providers/widget_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/location_settings_provider.dart';
import 'screens/auth/sign_up_start.dart';
import 'screens/main/main_tab.dart';
import 'services/data_loading_manager.dart';
import '../../styles/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(WayloApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

class WayloApp extends StatelessWidget {
  final bool isLoggedIn;
  const WayloApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final signUpProvider = SignUpProvider();
            signUpProvider.loadAuthToken();
            return signUpProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WidgetProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => FeedMapProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocationSettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              theme: themeProvider.currentTheme, // ThemeProvider의 현재 테마 사용
              home: isLoggedIn
                  ? AppInitializer(child: MainTabPage())
                  : SignUpStartPage(),
            );
          }
      ),
    );
  }
}

// 앱 초기화를 위한 위젯 추가
class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({Key? key, required this.child}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 데이터 로딩 매니저를 통해 앱 데이터 초기화
    await DataLoadingManager.initializeAppData(context);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider 가져오기
    final themeProvider = Provider.of<ThemeProvider>(context);

    return _isLoading
        ? Scaffold(
      // 다크 모드에 따른 배경색 적용
      backgroundColor: themeProvider.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            // 다크 모드에 따른 텍스트 색상 적용
            Text("로딩 중...", style: TextStyle(fontSize: 16, color: themeProvider.textColor)),
          ],
        ),
      ),
    )
        : widget.child;
  }
}