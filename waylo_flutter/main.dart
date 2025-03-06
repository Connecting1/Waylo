import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/sign_up_provider.dart';
import 'providers/canvas_provider.dart';
import 'providers/user_provider.dart';
import 'providers/widget_provider.dart';
import 'screens/auth/sign_up_start.dart';  // 회원가입 화면
import 'screens/main/main_tab.dart';  // 로그인 후 이동할 메인 화면
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
    return MultiProvider( // Provider 설정 추가
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final signUpProvider = SignUpProvider();
            signUpProvider.loadAuthToken();
            return signUpProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final canvasProvider = CanvasProvider();
            // 로그인 된 상태일 때만 캔버스 설정 로드
            if (isLoggedIn) {
              Future.microtask(() => canvasProvider.loadCanvasSettings());
            }
            return canvasProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final userProvider = UserProvider();
            if (isLoggedIn) {
              Future.microtask(() => userProvider.loadUserInfo());
            }
            return userProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final widgetProvider = WidgetProvider();
            if (isLoggedIn) {
              Future.microtask(() => widgetProvider.loadWidgets());
            }
            return widgetProvider;
          },
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: AppColors.primarySwatch, // Material 2 기준 적용
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primarySwatch, // Material 3 기준 적용
            brightness: Brightness.light, // 밝은 테마 유지
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(backgroundColor: Colors.white),
          useMaterial3: true, // Material 3 적용 (Flutter 최신 버전 대응)
        ),

        home: isLoggedIn ? MainTabPage() : SignUpStartPage(),  // 로그인 여부에 따라 이동
      ),
    );
  }
}
