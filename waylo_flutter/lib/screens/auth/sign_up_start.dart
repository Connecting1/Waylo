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
  // 텍스트 상수들
  static const String _mainTitle = 'Enjoy Your Trip\nAnd Write It Down';
  static const String _signUpButtonText = 'Sign up for free';
  static const String _googleButtonText = 'Continue with Google';
  static const String _loginButtonText = 'Log in';

  // Provider 타입 상수들
  static const String _providerLocal = "local";
  static const String _providerGoogle = "google";

  // API 키 상수들
  static const String _emailKey = 'email';
  static const String _errorKey = 'error';
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  // Google Sign In 스코프 상수들
  static const List<String> _googleSignInScopes = ['email'];

  // 이미지 경로 상수들
  static const String _logoPath = 'assets/logos/logo2.png';
  static const String _googleLogoPath = 'assets/logos/google_logo.png';

  // 폰트 크기 상수들
  static const double _mainTitleFontSize = 35;
  static const double _buttonFontSize = 18;
  static const double _loginTextFontSize = 15;

  // 크기 상수들
  static const double _logoTopRatio = 0.2;
  static const double _titleTopRatio = 0.45;
  static const double _logoSize = 150;
  static const double _bottomButtonsPosition = 100;
  static const double _buttonSpacing = 15;
  static const double _googleLogoSize = 24;

  // 스타일 상수들
  static const double _letterSpacing = 1.0;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _googleSignInScopes,
  );

  GoogleSignInAccount? _currentUser;

  /// 일반 회원가입 페이지로 이동
  Future<void> _handleSignIn(BuildContext context) async {
    Provider.of<SignUpProvider>(context, listen: false).setProvider(_providerLocal);
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
          userExists = searchResponse.any((u) => u[_emailKey] == _currentUser!.email);
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

    if (!loginResponse.containsKey(_errorKey)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, loginResponse[_authTokenKey]);
      await prefs.setString(_userIdKey, loginResponse[_userIdKey]);
      await prefs.setBool(_isLoggedInKey, true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabPage()),
      );
    }
  }

  /// 신규 구글 사용자 회원가입 처리
  Future<void> _handleNewGoogleUser() async {
    Provider.of<SignUpProvider>(context, listen: false).setEmail(_currentUser!.email);
    Provider.of<SignUpProvider>(context, listen: false).setProvider(_providerGoogle);
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
            top: MediaQuery.of(context).size.height * _logoTopRatio,
            left: 0,
            right: 0,
            child: Image.asset(
              _logoPath,
              width: _logoSize,
              height: _logoSize,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * _titleTopRatio,
            left: 0,
            right: 0,
            child: Text(
              _mainTitle,
              style: TextStyle(
                fontSize: _mainTitleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: _letterSpacing,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: _bottomButtonsPosition,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleSignIn(context),
                  label: const Text(
                    _signUpButtonText,
                    style: TextStyle(
                      fontSize: _buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ButtonStyles.loginButtonStyle(context),
                ),
                const SizedBox(height: _buttonSpacing),
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
                            width: _googleLogoSize,
                            height: _googleLogoSize,
                            child: Image.asset(
                              _googleLogoPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        _googleButtonText,
                        style: TextStyle(
                          fontSize: _buttonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _buttonSpacing),
                GestureDetector(
                  onTap: () => _handleLogIn(context),
                  child: Text(
                    _loginButtonText,
                    style: TextStyle(
                      fontSize: _loginTextFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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