// lib/screen/auth/sign_up_password.dart
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
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordValid = false;
  bool _obscurePassword = true;

  // 패스워드 유효성 검사 함수
  void _validatePassword(String password) {
    final RegExp passwordRegex = RegExp(
      r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{10,}$", // 최소 10자, 문자+숫자 포함
    );

    setState(() {
      _isPasswordValid = passwordRegex.hasMatch(password);
    });
  }

  // 다음 페이지로 이동
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Create account",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 56, // 기본 AppBar 높이
      ),

      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create a password",
              style: TextStyle(
                fontSize: 25,
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
                fillColor: Colors.white, // 입력 필드 배경색
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword; // 패스워드 표시/숨기기 기능 추가
                    });
                  },
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 5),
            Text(
              "• At least 10 characters\n• Must include letters and numbers",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                // color: _isPasswordValid ? Colors.white : Colors.red,
              ),
            ),

            const SizedBox(height: 30), // 버튼과 간격 추가
            Center(
              child: SizedBox(
                width: 100, // 버튼 크기 조정
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPasswordValid ? () => _goToBirthDatePage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isPasswordValid),
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
