import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/sign_up_provider.dart';
import 'screens/auth/sign_up_start.dart';  // 회원가입 화면
import 'screens/main/main_tab.dart';  // 로그인 후 이동할 메인 화면
import '../../styles/app_styles.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(WayloApp(isLoggedIn: isLoggedIn)); // 클래스 이름 변경
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

class WayloApp extends StatelessWidget { // 클래스 이름 변경
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
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: AppColors.primarySwatch, // Material 2 기준 적용
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primarySwatch, // ✅ Material 3 기준 적용
            brightness: Brightness.light, // 밝은 테마 유지
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(backgroundColor: Colors.white),
          useMaterial3: true, // ✅ Material 3 적용 (Flutter 최신 버전 대응)
        ),

        home: isLoggedIn ? MainTabPage() : SignUpStartPage(),  // 로그인 여부에 따라 이동
      ),
    );
  }
}
