import 'package:flutter/material.dart';
import 'getPasswordPage.dart';

class LoginPage2 extends StatefulWidget {
  const LoginPage2({super.key});

  @override
  State<LoginPage2> createState() => _LoginPage2State();
}

class _LoginPage2State extends State<LoginPage2> {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = false;

  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordValid = false;
  bool _obscurePassword = true;

  // 이메일 유효성 검사 함수
  void _validateEmail(String email) {
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    setState(() {
      _isEmailValid = emailRegex.hasMatch(email);
    });
  }

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
  Future<void> _goToPasswordPage(BuildContext context) async {
    if (_isEmailValid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GetPasswordPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF97DCF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF97DCF1),
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
              "Email",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _emailController,
              onChanged: _validateEmail, // 이메일 입력값이 변경될 때 유효성 검사 실행
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
              ),
              keyboardType: TextInputType.emailAddress, // 이메일 키보드 적용
            ),
            const SizedBox(height: 15),
            const Text(
              "Password",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _passwordController,
              onChanged: _validatePassword,
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

            const SizedBox(height: 30), // 버튼과 간격 추가
            Center(
              child: SizedBox(
                width: 100, // 버튼 크기 조정
                height: 50,
                child: ElevatedButton(
                  onPressed: _isEmailValid ? () => _goToPasswordPage(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailValid ? Colors.white : Colors.grey, // 유효하지 않으면 회색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 버튼 모서리 둥글게
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // color: _isEmailValid ? Colors.grey : Colors.white, // 텍스트 색상
                      color: Colors.grey,
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
    _passwordController.dispose();
    super.dispose();
  }
}
