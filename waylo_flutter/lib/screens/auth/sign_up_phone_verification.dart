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
      const SnackBar(content: Text("Verification code has been sent.")),
    );
  }

  /// 인증번호 입력 시 자동 검증
  void _onCodeChanged(String value) {
    if (value.length == 6) {
      _verifyCode(value);
    }
  }

  /// 인증번호 검증
  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Phone verification completed!")),
    );
  }

  /// 회원가입 완료 및 자동 로그인 처리
  Future<void> _handleFinalSignUp() async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need to complete phone verification.")),
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

      if (response.containsKey("error")) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign up failed: ${response["error"]}")),
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
        SnackBar(content: Text("Network error: Unable to sign up.")),
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

      if (loginResponse.containsKey("auth_token")) {
        // 로그인 성공 시 토큰 및 사용자 정보 저장
        String token = loginResponse["auth_token"];
        await provider.setAuthToken(token);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (loginResponse.containsKey("user_id")) {
          await prefs.setString("user_id", loginResponse["user_id"]);
        }

        await DataLoadingManager.handleLoginSuccess(context);

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign up and login successful!")),
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
      const SnackBar(content: Text("Sign up was successful but auto-login failed. Please log in.")),
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
        title: const Text("Create account", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("What's your phone number", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _onPhoneChanged,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPhoneValid && !_isCodeSent ? _sendVerificationCode : null,
                    style: ButtonStyles.formButtonStyle(context, isEnabled: _isPhoneValid && !_isCodeSent),
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isCodeSent) ...[
                const SizedBox(height: 20),
                const Text("Enter verification code", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                  controller: _verificationCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  onChanged: _onCodeChanged,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    counterText: "",
                  ),
                ),
              ],
              if (_isVerified) ...[
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleFinalSignUp,
                      style: ButtonStyles.formButtonStyle(context, isEnabled: !_isLoading),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.grey)
                          : const Text(
                        "Next",
                        style: TextStyle(
                          fontSize: 18,
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