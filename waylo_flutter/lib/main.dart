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

/// 앱의 진입점 - 로그인 상태를 확인하고 앱을 시작합니다
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(WayloApp(isLoggedIn: isLoggedIn));
}

/// SharedPreferences에서 로그인 상태를 확인합니다
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
      // 앱 전역에서 사용할 모든 Provider들을 등록
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
              theme: themeProvider.currentTheme,
              home: isLoggedIn
                  ? AppInitializer(child: MainTabPage())
                  : SignUpStartPage(),
            );
          }
      ),
    );
  }
}

/// 로그인된 사용자를 위한 앱 데이터 초기화 래퍼 위젯
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

  /// 앱에 필요한 초기 데이터를 로드합니다
  Future<void> _initializeData() async {
    await DataLoadingManager.initializeAppData(context);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return _isLoading
        ? Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
                "Loading...",
                style: TextStyle(fontSize: 16, color: themeProvider.textColor)
            ),
          ],
        ),
      ),
    )
        : widget.child;
  }
}