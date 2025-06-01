import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_birth_date.dart';
import '../../styles/app_styles.dart';

class SignUpPasswordPage extends StatefulWidget {
  const SignUpPasswordPage({super.key});

  @override
  State<SignUpPasswordPage> createState() => _SignUpPasswordPageState();
}

class _SignUpPasswordPageState extends State<SignUpPasswordPage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Create account";
  static const String _questionText = "Create a password";
  static const String _nextButtonText = "Next";
  static const String _passwordRequirementsText = "• At least 10 characters\n• Must include letters and numbers";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 15;
  static const double _questionFontSize = 25;
  static const double _requirementsFontSize = 10;
  static const double _buttonFontSize = 18;

  // 크기 상수들
  static const double _toolbarHeight = 56;
  static const double _horizontalPadding = 20;
  static const double _inputBorderRadius = 10.0;
  static const double _inputVerticalPadding = 15.0;
  static const double _inputHorizontalPadding = 20.0;
  static const double _requirementsTopSpacing = 5;
  static const double _buttonTopSpacing = 30;
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;

  // 유효성 검사 상수들
  static const String _passwordRegexPattern = r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{10,}$";

  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordValid = false;
  bool _obscurePassword = true;

  /// 패스워드 유효성 검사
  void _validatePassword(String password) {
    final RegExp passwordRegex = RegExp(_passwordRegexPattern);

    setState(() {
      _isPasswordValid = passwordRegex.hasMatch(password);
    });
  }

  /// 생년월일 입력 페이지로 이동
  Future<void> _goToBirthDatePage(BuildContext context) async {
    if (_isPasswordValid) {
      final password = _passwordController.text;

      Provider.of<SignUpProvider>(context, listen: false).setPassword(password);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpBirthDatePage()),
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
              controller: _passwordController,
              onChanged: _validatePassword,
              style: const TextStyle(color: Colors.black),
              obscureText: _obscurePassword,
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
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: _requirementsTopSpacing),
            const Text(
              _passwordRequirementsText,
              style: TextStyle(
                fontSize: _requirementsFontSize,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: _buttonTopSpacing),
            Center(
              child: SizedBox(
                width: _buttonWidth,
                height: _buttonHeight,
                child: ElevatedButton(
                  onPressed: _isPasswordValid ? () => _goToBirthDatePage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isPasswordValid),
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
    _passwordController.dispose();
    super.dispose();
  }
}