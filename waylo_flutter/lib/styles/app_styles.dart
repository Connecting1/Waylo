import 'package:flutter/material.dart';

/// 앱의 색상과 테마를 정의하는 클래스
class AppColors {
  static const Color primary = Color(0xFF97DCF1);
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F5F5);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  static MaterialColor get primarySwatch => createMaterialColor(primary);

  /// 색상으로부터 MaterialColor 생성
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

  /// 라이트 테마
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
      elevation: 0,
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

  /// 다크 테마
  static ThemeData darkTheme = ThemeData(
    primarySwatch: primarySwatch,
    primaryColor: primary,
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

/// 버튼 스타일을 정의하는 클래스
class ButtonStyles {
  /// 로그인 버튼 스타일
  static ButtonStyle loginButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF97DCF1),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: Colors.white, width: 4),
      ),
      shadowColor: Colors.transparent,
      fixedSize: Size(MediaQuery.of(context).size.width * 0.85, 50),
    );
  }

  /// 폼 버튼 스타일
  static ButtonStyle formButtonStyle(BuildContext context, {bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E),
      foregroundColor: const Color(0xFF757575),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      shadowColor: Colors.transparent,
      fixedSize: const Size(100, 50),
      elevation: 0,
    ).copyWith(
      backgroundColor: WidgetStateProperty.all(
          isEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E)
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xFF757575)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}