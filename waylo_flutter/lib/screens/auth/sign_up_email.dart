import 'package:flutter/material.dart';
import 'sign_up_password.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../../styles/app_styles.dart';

class SignUpEmailPage extends StatefulWidget {
  const SignUpEmailPage({super.key});

  @override
  State<SignUpEmailPage> createState() => _SignUpEmailPageState();
}

class _SignUpEmailPageState extends State<SignUpEmailPage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Create account";
  static const String _questionText = "What's your email?";
  static const String _nextButtonText = "Next";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 15;
  static const double _questionFontSize = 25;
  static const double _buttonFontSize = 18;

  // 크기 상수들
  static const double _toolbarHeight = 56;
  static const double _horizontalPadding = 20;
  static const double _inputBorderRadius = 10.0;
  static const double _inputVerticalPadding = 15.0;
  static const double _inputHorizontalPadding = 20.0;
  static const double _buttonTopSpacing = 30;
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;

  // 유효성 검사 상수들
  static const String _emailRegexPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";

  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = false;

  /// 이메일 유효성 검사
  void _validateEmail(String email) {
    final RegExp emailRegex = RegExp(_emailRegexPattern);

    setState(() {
      _isEmailValid = emailRegex.hasMatch(email);
    });
  }

  /// 패스워드 입력 페이지로 이동
  Future<void> _goToPasswordPage(BuildContext context) async {
    if (_isEmailValid) {
      final email = _emailController.text;

      // 이메일을 Provider에 저장
      Provider.of<SignUpProvider>(context, listen: false).setEmail(email);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignUpPasswordPage()),
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
        toolbarHeight: _toolbarHeight,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: _horizontalPadding,
          right: _horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _questionText,
              style: TextStyle(
                fontSize: _questionFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _emailController,
              onChanged: _validateEmail,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_inputBorderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: _inputVerticalPadding,
                  horizontal: _inputHorizontalPadding,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: _buttonTopSpacing),
            Center(
              child: SizedBox(
                width: _buttonWidth,
                height: _buttonHeight,
                child: ElevatedButton(
                  onPressed: _isEmailValid ? () => _goToPasswordPage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isEmailValid),
                  child: const Text(
                    _nextButtonText,
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}