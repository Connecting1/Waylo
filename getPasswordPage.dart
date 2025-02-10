import 'package:flutter/material.dart';
import 'getBirthDatePage.dart';

class GetPasswordPage extends StatefulWidget {
  const GetPasswordPage({super.key});

  @override
  State<GetPasswordPage> createState() => _GetPasswordPageState();
}

class _GetPasswordPageState extends State<GetPasswordPage> {
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GetBirthDatePage()),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPasswordValid ? Colors.white : Colors.grey, // 유효하지 않으면 회색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 버튼 모서리 둥글게
                    ),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, // 텍스트 색상
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
