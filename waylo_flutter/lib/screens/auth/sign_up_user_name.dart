import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_phone_verification.dart';
import '../../styles/app_styles.dart';

class SignUpUserNamePage extends StatefulWidget {
  const SignUpUserNamePage({super.key});

  @override
  State<SignUpUserNamePage> createState() => _SignUpUserNamePageState();
}

class _SignUpUserNamePageState extends State<SignUpUserNamePage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Create account";
  static const String _questionText = "What's your username?";
  static const String _nextButtonText = "Next";
  static const String _usernameRequirementsText = "• 1-30 characters\n• Can contain letters, numbers, '.' and '_'\n• Cannot start or end with '.' or '_'\nNo consecutive '..' (double periods)";

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
  static const String _usernameRegexPattern = r"^[a-zA-Z0-9](?!.*\.\.)(?!.*__)[a-zA-Z0-9._]{0,28}[a-zA-Z0-9]$";

  final TextEditingController _nickNameController = TextEditingController();
  bool _isNickNameValid = false;

  /// 사용자명 유효성 검사
  void _validateNickName(String nickname) {
    final RegExp emailRegex = RegExp(_usernameRegexPattern);

    setState(() {
      _isNickNameValid = emailRegex.hasMatch(nickname);
    });
  }

  /// 전화번호 인증 페이지로 이동
  Future<void> _goToPasswordPage(BuildContext context) async {
    if (_isNickNameValid) {
      Provider.of<SignUpProvider>(context, listen: false).setUsername(_nickNameController.text);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpPhoneVerificationPage()),
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
              controller: _nickNameController,
              onChanged: _validateNickName,
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
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: _requirementsTopSpacing),
            const Text(
              _usernameRequirementsText,
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
                  onPressed: _isNickNameValid ? () => _goToPasswordPage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isNickNameValid),
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
    _nickNameController.dispose();
    super.dispose();
  }
}