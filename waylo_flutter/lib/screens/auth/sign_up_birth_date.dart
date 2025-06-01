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
  // 텍스트 상수들
  static const String _appBarTitle = "Create account";
  static const String _questionText = "What's your date of birth?";
  static const String _dateHintText = "YYYY-MM-DD";
  static const String _nextButtonText = "Next";
  static const String _datePadCharacter = "0";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 15;
  static const double _questionFontSize = 25;
  static const double _buttonFontSize = 18;

  // 크기 상수들
  static const double _toolbarHeight = 56;
  static const double _horizontalPadding = 20;
  static const double _inputBorderRadius = 10.0;
  static const double _inputVerticalPadding = 15.0;
  static const double _inputHorizontalPadding = 20.0;
  static const double _buttonTopSpacing = 30;
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;

  // 날짜 관련 상수들
  static const int _minYear = 1900;
  static const int _minMonth = 1;
  static const int _minDay = 1;
  static const int _datePadLength = 2;

  final TextEditingController _birthDateController = TextEditingController();
  bool _isBirthDateValid = false;

  /// 생년월일 선택 다이얼로그 표시
  Future<void> _selectBirthDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(_minYear, _minMonth, _minDay),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(_datePadLength, _datePadCharacter)}-${pickedDate.day.toString().padLeft(_datePadLength, _datePadCharacter)}";

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
          _appBarTitle,
          style: TextStyle(
            fontSize: _appBarTitleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        toolbarHeight: _toolbarHeight,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: _horizontalPadding,
          right: _horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _questionText,
              style: TextStyle(
                fontSize: _questionFontSize,
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
                hintText: _dateHintText,
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_inputBorderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: _inputVerticalPadding,
                  horizontal: _inputHorizontalPadding,
                ),
              ),
            ),
            const SizedBox(height: _buttonTopSpacing),
            Center(
              child: SizedBox(
                width: _buttonWidth,
                height: _buttonHeight,
                child: ElevatedButton(
                  onPressed: _isBirthDateValid ? () => _goToGenderPage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isBirthDateValid),
                  child: const Text(
                    _nextButtonText,
                    style: TextStyle(
                      fontSize: _buttonFontSize,
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