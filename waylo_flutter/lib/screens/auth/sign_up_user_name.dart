import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_phone_verification.dart';

class SignUpUserNamePage extends StatefulWidget {
  const SignUpUserNamePage({super.key});

  @override
  State<SignUpUserNamePage> createState() => _SignUpUserNamePageState();
}

class _SignUpUserNamePageState extends State<SignUpUserNamePage> {
  final TextEditingController _nickNameController = TextEditingController();
  bool _isNickNameValid = false;

  // 이메일 유효성 검사 함수
  void _validateNickName(String nickname) {
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9](?!.*\.\.)(?!.*__)[a-zA-Z0-9._]{0,28}[a-zA-Z0-9]$",
    );

    setState(() {
      _isNickNameValid = emailRegex.hasMatch(nickname);
    });
  }

  // 다음 페이지로 이동
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
              "What's your username?",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _nickNameController,
              onChanged: _validateNickName, // 이메일 입력값이 변경될 때 유효성 검사 실행
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
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 5), // 텍스트와 입력 필드 사이 간격 추가

            // 닉네임 조건 텍스트 추가
            Text(
              "• 1-30 characters\n• Can contain letters, numbers, '.' and '_'\n• Cannot start or end with '.' or '_'\nNo consecutive '..' (double periods)",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white, // 닉네임 조건 텍스트는 항상 흰색 유지
              ),
            ),
            const SizedBox(height: 30), // 버튼과 간격 추가
            Center(
              child: SizedBox(
                width: 100, // 버튼 크기 조정
                height: 50,
                child: ElevatedButton(
                  onPressed: _isNickNameValid ? () => _goToPasswordPage(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNickNameValid ? Colors.white : Colors.grey, // 유효하지 않으면 회색
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
    _nickNameController.dispose();
    super.dispose();
  }
}
