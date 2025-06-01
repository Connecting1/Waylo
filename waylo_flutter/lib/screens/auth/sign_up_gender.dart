import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_user_name.dart';
import '../../styles/app_styles.dart';

class SignUpGenderPage extends StatefulWidget {
  const SignUpGenderPage({super.key});

  @override
  State<SignUpGenderPage> createState() => _SignUpGenderPageState();
}

class _SignUpGenderPageState extends State<SignUpGenderPage> {
  // 텍스트 상수들
  static const String _appBarTitle = "Create account";
  static const String _questionText = "What's your gender?";
  static const String _dropdownHintText = "Select your gender";
  static const String _nextButtonText = "Next";

  // 성별 옵션 상수들
  static const String _genderMale = "Male";
  static const String _genderFemale = "Female";
  static const String _genderNonBinary = "Non-binary";
  static const String _genderOther = "Other";
  static const String _genderPreferNotToSay = "Prefer not to say";

  static const List<String> _genderOptions = [
    _genderMale,
    _genderFemale,
    _genderNonBinary,
    _genderOther,
    _genderPreferNotToSay,
  ];

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 15;
  static const double _questionFontSize = 25;
  static const double _hintFontSize = 16;
  static const double _dropdownItemFontSize = 16;
  static const double _buttonFontSize = 18;

  // 크기 상수들
  static const double _toolbarHeight = 56;
  static const double _horizontalPadding = 20;
  static const double _dropdownHeight = 60;
  static const double _dropdownBorderRadius = 10;
  static const double _dropdownHorizontalPadding = 20;
  static const double _buttonTopSpacing = 30;
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;

  String? _selectedGender;
  bool _isGenderSelected = false;

  /// 성별 선택 처리
  void _onGenderSelected(String? gender) {
    setState(() {
      _selectedGender = gender;
      _isGenderSelected = gender != null;
    });
  }

  /// 사용자명 입력 페이지로 이동
  Future<void> _goToPasswordPage(BuildContext context) async {
    if (_isGenderSelected) {
      Provider.of<SignUpProvider>(context, listen: false).setGender(_selectedGender!);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpUserNamePage()),
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
            Container(
              height: _dropdownHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_dropdownBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _dropdownHorizontalPadding),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    hint: const Text(
                      _dropdownHintText,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: _hintFontSize,
                      ),
                    ),
                    items: _genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: const TextStyle(fontSize: _dropdownItemFontSize),
                        ),
                      );
                    }).toList(),
                    onChanged: _onGenderSelected,
                    isExpanded: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: _buttonTopSpacing),
            Center(
              child: SizedBox(
                width: _buttonWidth,
                height: _buttonHeight,
                child: ElevatedButton(
                  onPressed: _isGenderSelected ? () => _goToPasswordPage(context) : null,
                  style: ButtonStyles.formButtonStyle(context, isEnabled: _isGenderSelected),
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
}