import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../../services/api/user_api.dart';
import '../../styles/app_styles.dart';
import '../main/main_tab.dart';
import 'sign_up_email.dart';
import 'sign_up_birth_date.dart';
import 'sign_in.dart';

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

  /// 일반 회원가입 페이지로 이동
  Future<void> _handleSignIn(BuildContext context) async {
    Provider.of<SignUpProvider>(context, listen: false).setProvider("local");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpEmailPage()),
    );
  }

  /// 로그인 페이지로 이동
  Future<void> _handleLogIn(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  /// 구글 로그인 처리
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
          await _handleExistingGoogleUser();
        } else {
          await _handleNewGoogleUser();
        }
      }
    } catch (error) {
      // Google 로그인 에러 처리는 사용자에게 표시하지 않음 (일반적으로 사용자가 취소한 경우)
    }
  }

  /// 기존 구글 사용자 로그인 처리
  Future<void> _handleExistingGoogleUser() async {
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
  }

  /// 신규 구글 사용자 회원가입 처리
  Future<void> _handleNewGoogleUser() async {
    Provider.of<SignUpProvider>(context, listen: false).setEmail(_currentUser!.email);
    Provider.of<SignUpProvider>(context, listen: false).setProvider("google");
    Provider.of<SignUpProvider>(context, listen: false).setPassword(null);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpBirthDatePage()),
    );
  }

  /// 구글 로그아웃
  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/logos/logo2.png',
              width: 150,
              height: 150,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 0,
            right: 0,
            child: Text(
              'Enjoy Your Trip\nAnd Write It Down',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: 100,
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
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width: 24,
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
                        textAlign: TextAlign.center,
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