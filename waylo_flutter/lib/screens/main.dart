import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/sign_up_provider.dart';
import 'screens/auth/sign_up_start.dart';  // 회원가입 화면
import 'screens/main/main_tab.dart';  // 로그인 후 이동할 메인 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

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
        home: isLoggedIn ? MainTabPage() : SignUpStartPage(),  // 로그인 여부에 따라 이동
      ),
    );
  }
}


