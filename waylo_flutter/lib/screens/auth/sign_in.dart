import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/canvas_provider.dart';
import '../../providers/sign_up_provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/services/data_loading_manager.dart'; // 추가: 데이터 로딩 매니저
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

    // 로그인 전에 현재 저장된 user_id가 있는지 확인
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldUserId = prefs.getString("user_id");

    setState(() { _isLoading = true; });

    try {
      final response = await UserApi.loginUser(email, password);

      if (response.containsKey("auth_token")) { // 로그인 성공
        provider.setAuthToken(response["auth_token"]);
        provider.setLoggedIn(true);

        if (response.containsKey("user_id")) {
          await prefs.setString("user_id", response["user_id"]);
        } else {
          print("[ERROR] user_id 없음");
        }

        // Provider 상태 확인
        final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

        // 로그인 성공 후 데이터 로딩 매니저를 통해 데이터 초기화
        await DataLoadingManager.handleLoginSuccess(context);

        // API에서 사용할 user_id 확인
        String? apiUserId = await ApiService.getUserId();

        setState(() { _isLoading = false; });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainTabPage()),
        );
      } else { // 로그인 실패
        setState(() { _isLoading = false; });

        print("[ERROR] 로그인 실패: ${response["error"] ?? "잘못된 이메일 또는 비밀번호"}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("[ERROR] 로그인 실패: ${response["error"] ?? "잘못된 이메일 또는 비밀번호입니다."}")),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      print("[ERROR] 로그인 요청 중 예외 발생: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("[ERROR] 네트워크 오류: 로그인할 수 없습니다.")),
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
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _inputDecoration()),
            const SizedBox(height: 15),
            const Text("Password", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
            TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration()),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
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