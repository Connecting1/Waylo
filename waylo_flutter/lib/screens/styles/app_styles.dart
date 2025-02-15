import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF97DCF1);
}

class ButtonStyles {
  static ButtonStyle loginButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF97DCF1), // 배경색
      foregroundColor: Colors.white, // 버튼 텍스트 색상
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // 둥근 버튼
        side: const BorderSide(color: Colors.white, width: 4), // 흰색 테두리 추가
      ),
      shadowColor: Colors.transparent, // 그림자 제거
      fixedSize: Size(MediaQuery.of(context).size.width * 0.85, 50), // 가로 크기 자동 조정
    );
  }
}
