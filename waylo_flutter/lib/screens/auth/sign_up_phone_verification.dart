// lib/screen/auth/sign_up_phone_verification.dart
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
import '../../services/data_loading_manager.dart'; // 데이터 로딩 매니저 추가

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

  void _onPhoneChanged(String value) {
    setState(() {
      _isPhoneValid = value.isNotEmpty;
    });

    Provider.of<SignUpProvider>(context, listen: false).setPhoneNumber(value);
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isCodeSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verification code has been sent.")),
    );
  }

  void _onCodeChanged(String value) {
    if (value.length == 6) {
      _verifyCode(value);
    }
  }

  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Phone verification completed!")),
    );
  }

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
          SnackBar(content: Text("[ERROR] Sign up failed: ${response["error"]}")),
        );
      } else {
        // 회원가입 성공 - 이제 자동 로그인 시도

        try {
          // 회원가입에 사용한 이메일과 비밀번호로 로그인 시도
          final loginResponse = await UserApi.loginUser(
              provider.email,
              provider.password ?? ""  // password가 null일 수 있으므로 빈 문자열로 대체
          );

          if (loginResponse.containsKey("auth_token")) {
            // 로그인 성공 및 토큰 저장
            String token = loginResponse["auth_token"];

            await provider.setAuthToken(token);

            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (loginResponse.containsKey("user_id")) {
              await prefs.setString("user_id", loginResponse["user_id"]);
            }

            // 저장 확인
            String? savedToken = await ApiService.getAuthToken();
            String? savedUserId = await ApiService.getUserId();

            // 데이터 로딩 매니저를 통해 앱 데이터 초기화
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

            setState(() {
              _isLoading = false;
            });

            // 로그인 실패 시 사용자에게 알리고 로그인 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sign up was successful but auto-login failed. Please log in.")),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SignInPage()),
            );
          }
        } catch (loginError) {
          print("[ERROR] 자동 로그인 중 오류 발생: $loginError");

          setState(() {
            _isLoading = false;
          });

          // 로그인 오류 시 사용자에게 알리고 로그인 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign up was successful but login failed. Please log in.")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInPage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print("[ERROR] 회원가입 요청 중 예외 발생: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("[ERROR] Network error: Unable to sign up.")),
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
                    style: ButtonStyles.formButtonStyle(context, isEnabled: _isPhoneValid && !_isCodeSent), // 👈 이렇게 변경
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
                      style: ButtonStyles.formButtonStyle(context, isEnabled: !_isLoading), // 👈 이렇게 변경
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.grey) // 로딩 표시 색상도 맞춤
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