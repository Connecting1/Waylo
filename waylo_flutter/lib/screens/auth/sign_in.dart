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

      if (response.containsKey("auth_token")) {
        // 인증 토큰 설정
        provider.setAuthToken(response["auth_token"]);
        provider.setLoggedIn(true);

        // 사용자 ID 저장
        if (response.containsKey("user_id")) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_id", response["user_id"]);
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
          SnackBar(content: Text("Login failed: ${response["error"] ?? "Invalid email or password"}")),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: Unable to login")),
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
        title: const Text("Sign In", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Email", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.black), decoration: _inputDecoration()),
            const SizedBox(height: 15),
            const Text("Password", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
            TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.black), decoration: _inputDecoration()),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: !_isLoading),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.grey)
                      : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}