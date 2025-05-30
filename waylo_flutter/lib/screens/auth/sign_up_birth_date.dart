import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_gender.dart';
import '../../styles/app_styles.dart';

class SignUpBirthDatePage extends StatefulWidget {
  const SignUpBirthDatePage({super.key});

  @override
  State<SignUpBirthDatePage> createState() => _SignUpBirthDatePageState();
}

class _SignUpBirthDatePageState extends State<SignUpBirthDatePage> {
  final TextEditingController _birthDateController = TextEditingController();
  bool _isBirthDateValid = false;

  /// 생년월일 선택 다이얼로그 표시
  Future<void> _selectBirthDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

      setState(() {
        _birthDateController.text = formattedDate;
        _isBirthDateValid = true;
      });
    }
  }

  /// 성별 선택 페이지로 이동
  Future<void> _goToGenderPage(BuildContext context) async {
    if (_isBirthDateValid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpGenderPage()),
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
              "What's your date of birth?",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              controller: _birthDateController,
              readOnly: true,
              style: const TextStyle(color: Colors.black),
              onTap: () => _selectBirthDate(context),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "YYYY-MM-DD",
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
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isBirthDateValid ? () => _goToGenderPage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isBirthDateValid),
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
    _birthDateController.dispose();
    super.dispose();
  }
}