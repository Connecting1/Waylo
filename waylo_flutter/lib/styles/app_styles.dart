import 'package:flutter/material.dart';

class AppColors {
  // 기존 Color 타입 유지 (일반 UI 요소에서 사용)
  static const Color primary = Color(0xFF97DCF1);
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F5F5);

  // MaterialColor 변환 함수 추가 (primarySwatch에서 사용)
  static MaterialColor get primarySwatch => createMaterialColor(primary);

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
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
