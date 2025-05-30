// lib/screen/auth/sign_up_start.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import '../../services/api/user_api.dart';
import '../main/main_tab.dart';
import 'sign_up_email.dart';
import 'sign_up_birth_date.dart';
import 'sign_in.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../../styles/app_styles.dart';


class SignUpStartPage extends StatefulWidget {
  const SignUpStartPage({Key? key}) : super(key: key);

  @override
  State<SignUpStartPage> createState() => _SignUpStartPageState();
}

class _SignUpStartPageState extends State<SignUpStartPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? _currentUser;

  Future<void> _handleSignIn(BuildContext context) async {
    Provider.of<SignUpProvider>(context, listen: false).setProvider("local");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpEmailPage()),
    );
  }

  Future<void> _handleLogIn(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
      final user = await _googleSignIn.signIn();
      setState(() {
        _currentUser = user;
      });

      if (_currentUser != null) {
        // 기존 사용자인지 확인
        final searchResponse = await UserApi.searchUsers(_currentUser!.email);
        bool userExists = false;

        if (searchResponse is List) {
          userExists = searchResponse.any((u) => u['email'] == _currentUser!.email);
        }

        if (userExists) {
          // 기존 사용자 - 로그인 처리
          final loginResponse = await UserApi.loginUser(_currentUser!.email, "");

          if (!loginResponse.containsKey('error')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', loginResponse['auth_token']);
            await prefs.setString('user_id', loginResponse['user_id']);
            await prefs.setBool('is_logged_in', true);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainTabPage()),
            );
          }
        } else {
          // 신규 사용자 - 회원가입
          Provider.of<SignUpProvider>(context, listen: false).setEmail(_currentUser!.email);
          Provider.of<SignUpProvider>(context, listen: false).setProvider("google");
          Provider.of<SignUpProvider>(context, listen: false).setPassword(null);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpBirthDatePage()),
          );
        }
      }
    } catch (error) {
      print('Sign-In Error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // 배경색 유지
      body: Stack(
        children: [
          // 로고 이미지 - 상단에 배치
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2, // 화면 상단에서 15% 위치
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/logos/logo2.png',
              width: 150,
              height: 150,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45, // 로고 아래 위치
            left: 0,
            right: 0,
            child: Text(
              'Enjoy Your Trip\nAnd Write It Down',
              style: TextStyle(
                fontSize: 35, // 글자 크기
                fontWeight: FontWeight.bold, // 글자 굵기
                color: Colors.white, // 글자 색상
                letterSpacing: 1.0, // 글자 간격
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 버튼 그룹 - 하단에 배치
          Positioned(
            bottom: 100, // 하단에서 50px 위에 위치
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleSignIn(context),
                  label: const Text(
                    'Sign up for free',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ButtonStyles.loginButtonStyle(context),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: _handleGoogleSignIn,
                  style: ButtonStyles.loginButtonStyle(context),
                  child: Stack(
                    alignment: Alignment.center, // 텍스트를 정확히 버튼 중앙 정렬
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max, // 버튼 크기를 넘어서지 않도록 설정
                        children: [
                          SizedBox(
                            width: 24, // 로고 크기 고정
                            height: 24,
                            child: Image.asset(
                              'assets/logos/google_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // 텍스트 중앙 정렬
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => _handleLogIn(context),
                  child: Text(
                    'Log in',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
