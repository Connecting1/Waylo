import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/sign_up_provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';

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
  bool _isLoading = false; // API 요청 중 로딩 상태

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
      const SnackBar(content: Text("인증 코드가 전송되었습니다.")),
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
      const SnackBar(content: Text("휴대폰 인증 완료!")),
    );
  }

  Future<void> _handleFinalSignUp() async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("휴대폰 인증을 완료해야 합니다.")),
      );
      return;
    }

    final provider = Provider.of<SignUpProvider>(context, listen: false);

    print("🚀 회원가입 요청 데이터:");
    print("📧 Email: ${provider.email}");
    print("🔑 Password: ${provider.password}");
    print("🧑‍🦰 Gender: ${provider.gender}");
    print("👤 Username: ${provider.username}");
    print("📱 Phone Number: ${provider.phoneNumber}");
    print("🌍 Provider: ${provider.provider}"); // 여기서 google이 맞는지 확인

    // API 요청 시작 (로딩 상태 적용)
    setState(() {
      _isLoading = true;
    });

    final response = await UserApi.createUser(
      email: provider.email,
      password: provider.password,
      gender: provider.gender,
      username: provider.username,
      phoneNumber: provider.phoneNumber,
      provider: provider.provider,
    );

    print("🟡 회원가입 API 응답: $response");

    setState(() {
      _isLoading = false; // API 요청 완료 후 로딩 해제
    });

    if (response.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 회원가입 실패: ${response["error"]}")),
      );
    } else {
      provider.setLoggedIn(true);
      provider.setAuthToken(response["auth_token"] ?? "");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (response.containsKey("id")) {
        await prefs.setString("user_id", response["id"]);
        print("✅ 회원가입 후 user_id 저장 완료: ${response["id"]}");
      } else {
        print("❌ 회원가입 응답에 id 없음");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 회원가입 성공!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabPage()),
      );
      print("✅ 회원가입 성공!"); // 콘솔 로그 확인용

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPhoneValid && !_isCodeSent ? Colors.white : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                      onPressed: _isLoading ? null : _handleFinalSignUp, // API 요청 중이면 버튼 비활성화
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : Colors.white, // 로딩 중이면 회색
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator() // 로딩 표시 추가
                          : const Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
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
