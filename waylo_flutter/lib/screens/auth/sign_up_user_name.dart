import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_phone_verification.dart';
import '../../styles/app_styles.dart';

class SignUpUserNamePage extends StatefulWidget {
  const SignUpUserNamePage({super.key});

  @override
  State<SignUpUserNamePage> createState() => _SignUpUserNamePageState();
}

class _SignUpUserNamePageState extends State<SignUpUserNamePage> {
  final TextEditingController _nickNameController = TextEditingController();
  bool _isNickNameValid = false;

  /// 사용자명 유효성 검사
  void _validateNickName(String nickname) {
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9](?!.*\.\.)(?!.*__)[a-zA-Z0-9._]{0,28}[a-zA-Z0-9]$",
    );

    setState(() {
      _isNickNameValid = emailRegex.hasMatch(nickname);
    });
  }

  /// 전화번호 인증 페이지로 이동
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
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
        toolbarHeight: 56,
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
              onChanged: _validateNickName,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
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
            const SizedBox(height: 5),
            Text(
              "• 1-30 characters\n• Can contain letters, numbers, '.' and '_'\n• Cannot start or end with '.' or '_'\nNo consecutive '..' (double periods)",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isNickNameValid ? () => _goToPasswordPage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isNickNameValid),
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
    _nickNameController.dispose();
    super.dispose();
  }
}