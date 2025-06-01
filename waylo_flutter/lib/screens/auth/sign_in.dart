import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/canvas_provider.dart';
import '../../providers/sign_up_provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/services/data_loading_manager.dart';
import '../../providers/user_provider.dart';
import '../../providers/widget_provider.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Sign In";
  static const String _emailLabel = "Email";
  static const String _passwordLabel = "Password";
  static const String _loginButtonText = "Login";
  static const String _loginFailedPrefix = "Login failed: ";
  static const String _defaultLoginError = "Invalid email or password";
  static const String _networkErrorMessage = "Network error: Unable to login";
  static const String _userIdKey = "user_id";
  static const String _authTokenKey = "auth_token";
  static const String _errorKey = "error";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 15;
  static const double _labelFontSize = 25;
  static const double _buttonFontSize = 18;

  // 크기 상수들
  static const double _pageHorizontalPadding = 20;
  static const double _inputSpacing = 15;
  static const double _buttonTopSpacing = 30;
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _inputBorderRadius = 10;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final provider = Provider.of<SignUpProvider>(context, listen: false);

    setState(() { _isLoading = true; });

    try {
      final response = await UserApi.loginUser(email, password);

      if (response.containsKey(_authTokenKey)) {
        // 인증 토큰 설정
        provider.setAuthToken(response[_authTokenKey]);
        provider.setLoggedIn(true);

        // 사용자 ID 저장
        if (response.containsKey(_userIdKey)) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userIdKey, response[_userIdKey]);
        }

        // 로그인 성공 후 데이터 초기화
        await DataLoadingManager.handleLoginSuccess(context);

        setState(() { _isLoading = false; });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainTabPage()),
        );
      } else {
        // 로그인 실패 처리
        setState(() { _isLoading = false; });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_loginFailedPrefix${response[_errorKey] ?? _defaultLoginError}")),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_networkErrorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          _appBarTitle,
          style: TextStyle(
            fontSize: _appBarTitleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(_pageHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _emailLabel,
              style: TextStyle(
                fontSize: _labelFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: _inputSpacing),
            const Text(
              _passwordLabel,
              style: TextStyle(
                fontSize: _labelFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: _buttonTopSpacing),
            Center(
              child: SizedBox(
                width: _buttonWidth,
                height: _buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: !_isLoading),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.grey)
                      : const Text(
                    _loginButtonText,
                    style: TextStyle(
                      fontSize: _buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }
}