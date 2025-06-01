import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waylo_flutter/screens/auth/sign_in.dart';
import '../../providers/sign_up_provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import '../../services/api/api_service.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';
import '../../services/data_loading_manager.dart';

class SignUpPhoneVerificationPage extends StatefulWidget {
  const SignUpPhoneVerificationPage({Key? key}) : super(key: key);

  @override
  State<SignUpPhoneVerificationPage> createState() => _SignUpPhoneVerificationPageState();
}

class _SignUpPhoneVerificationPageState extends State<SignUpPhoneVerificationPage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Create account";
  static const String _phoneQuestionText = "What's your phone number";
  static const String _codeQuestionText = "Enter verification code";
  static const String _nextButtonText = "Next";
  static const String _codeSentMessage = "Verification code has been sent.";
  static const String _verificationCompleteMessage = "Phone verification completed!";
  static const String _verificationRequiredMessage = "You need to complete phone verification.";
  static const String _signUpFailedPrefix = "Sign up failed: ";
  static const String _networkErrorMessage = "Network error: Unable to sign up.";
  static const String _signUpSuccessMessage = "Sign up and login successful!";
  static const String _autoLoginFailedMessage = "Sign up was successful but auto-login failed. Please log in.";
  static const String _errorKey = "error";
  static const String _authTokenKey = "auth_token";
  static const String _userIdKey = "user_id";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 15;
  static const double _questionFontSize = 25;
  static const double _buttonFontSize = 18;

  // 크기 상수들
  static const double _pageHorizontalPadding = 20;
  static const double _questionSpacing = 10;
  static const double _sectionSpacing = 20;
  static const double _inputBorderRadius = 10;
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;

  // 인증번호 관련 상수들
  static const int _verificationCodeLength = 6;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool _isCodeSent = false;
  bool _isVerified = false;
  bool _isPhoneValid = false;
  bool _isLoading = false;

  /// 전화번호 입력 시 유효성 검사 및 Provider 업데이트
  void _onPhoneChanged(String value) {
    setState(() {
      _isPhoneValid = value.isNotEmpty;
    });

    Provider.of<SignUpProvider>(context, listen: false).setPhoneNumber(value);
  }

  /// 인증번호 발송
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isCodeSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_codeSentMessage)),
    );
  }

  /// 인증번호 입력 시 자동 검증
  void _onCodeChanged(String value) {
    if (value.length == _verificationCodeLength) {
      _verifyCode(value);
    }
  }

  /// 인증번호 검증
  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_verificationCompleteMessage)),
    );
  }

  /// 회원가입 완료 및 자동 로그인 처리
  Future<void> _handleFinalSignUp() async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_verificationRequiredMessage)),
      );
      return;
    }

    final provider = Provider.of<SignUpProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // 회원가입 요청
      final response = await UserApi.createUser(
        email: provider.email,
        password: provider.password,
        gender: provider.gender,
        username: provider.username,
        phoneNumber: provider.phoneNumber,
        provider: provider.provider,
      );

      if (response.containsKey(_errorKey)) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_signUpFailedPrefix${response[_errorKey]}")),
        );
      } else {
        // 회원가입 성공 후 자동 로그인 시도
        await _attemptAutoLogin(provider);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_networkErrorMessage)),
      );
    }
  }

  /// 자동 로그인 시도
  Future<void> _attemptAutoLogin(SignUpProvider provider) async {
    try {
      final loginResponse = await UserApi.loginUser(
          provider.email,
          provider.password ?? ""
      );

      if (loginResponse.containsKey(_authTokenKey)) {
        // 로그인 성공 시 토큰 및 사용자 정보 저장
        String token = loginResponse[_authTokenKey];
        await provider.setAuthToken(token);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (loginResponse.containsKey(_userIdKey)) {
          await prefs.setString(_userIdKey, loginResponse[_userIdKey]);
        }

        await DataLoadingManager.handleLoginSuccess(context);

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_signUpSuccessMessage)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainTabPage()),
        );
      } else {
        _handleLoginFailure();
      }
    } catch (loginError) {
      _handleLoginFailure();
    }
  }

  /// 로그인 실패 시 로그인 화면으로 이동
  void _handleLoginFailure() {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_autoLoginFailedMessage)),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInPage()),
    );
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(_pageHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                _phoneQuestionText,
                style: TextStyle(
                  fontSize: _questionFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: _questionSpacing),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _onPhoneChanged,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_inputBorderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: _sectionSpacing),
              Center(
                child: SizedBox(
                  width: _buttonWidth,
                  height: _buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isPhoneValid && !_isCodeSent ? _sendVerificationCode : null,
                    style: ButtonStyles.formButtonStyle(context, isEnabled: _isPhoneValid && !_isCodeSent),
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
              if (_isCodeSent) ...[
                const SizedBox(height: _sectionSpacing),
                const Text(
                  _codeQuestionText,
                  style: TextStyle(
                    fontSize: _questionFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: _questionSpacing),
                TextField(
                  controller: _verificationCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: _verificationCodeLength,
                  onChanged: _onCodeChanged,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_inputBorderRadius),
                      borderSide: BorderSide.none,
                    ),
                    counterText: "",
                  ),
                ),
              ],
              if (_isVerified) ...[
                const SizedBox(height: _sectionSpacing),
                Center(
                  child: SizedBox(
                    width: _buttonWidth,
                    height: _buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleFinalSignUp,
                      style: ButtonStyles.formButtonStyle(context, isEnabled: !_isLoading),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.grey)
                          : const Text(
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
            ],
          ),
        ),
      ),
    );
  }
}