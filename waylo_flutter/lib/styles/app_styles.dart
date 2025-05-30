// lib/styles/app_styles.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF97DCF1);
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F5F5);

  // 다크 모드용 색상 추가
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

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

  // 라이트 테마
  static ThemeData lightTheme = ThemeData(
    primarySwatch: primarySwatch,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:
        0
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.2),
    ),
    iconTheme: IconThemeData(color: Colors.grey[700]),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey,
    ),
    useMaterial3: true,
  );

  // 다크 테마
  static ThemeData darkTheme = ThemeData(
    primarySwatch: primarySwatch,
    primaryColor: primary, // 주요 색상은 동일하게 유지
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: darkCard,
      shadowColor: Colors.black,
    ),
    iconTheme: IconThemeData(color: Colors.grey[300]),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey[400],
      backgroundColor: darkSurface,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkCard,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Color(0xFF3E3E3E),
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.grey[300]),
    ),
    useMaterial3: true,
  );
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

  static ButtonStyle formButtonStyle(BuildContext context, {bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E),
      foregroundColor: const Color(0xFF757575),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      shadowColor: Colors.transparent,
      fixedSize: const Size(100, 50),
      // 테마의 영향을 받지 않도록 강제 설정
      elevation: 0,
    ).copyWith(
      // 모든 상태에서 동일한 색상 강제 적용
      backgroundColor: WidgetStateProperty.all(
          isEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E)
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xFF757575)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}