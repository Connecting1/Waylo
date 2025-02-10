// import 'package:flutter/material.dart';
// import 'screens/homePage.dart';
// import 'screens/chatPage.dart';
// import 'screens/uploadPage.dart';
// import 'screens/searchPage.dart';
// import 'screens/myPage.dart';
// import 'styles/app_styles.dart'; // 스타일 파일 import
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary), // 스타일에서 색상 사용
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
//   TabController? controller;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text('Waylo'),
//         ),
//         body: TabBarView(
//           children: <Widget>[
//             HomePageApp(),
//             ChatPageApp(),
//             UploadPageApp(),
//             SearchPageApp(),
//             MyPageApp(),
//           ],
//           controller: controller,
//         ),
//         bottomNavigationBar: TabBar(
//           tabs: <Tab>[
//             Tab(icon: Icon(Icons.home, color: AppColors.primary)),
//             Tab(icon: Icon(Icons.chat, color: AppColors.primary)),
//             Tab(icon: Icon(Icons.edit, color: AppColors.primary)),
//             Tab(icon: Icon(Icons.search, color: AppColors.primary)),
//             Tab(icon: Icon(Icons.person, color: AppColors.primary)),
//           ],
//           controller: controller,
//         ));
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     controller = TabController(length: 5, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     controller!.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'screens/loginPage.dart'; // 로그인 페이지 경로

void main() {
  runApp(const WayloApp());
}

class WayloApp extends StatelessWidget {
  const WayloApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(), // 로그인 페이지를 초기 화면으로 설정
    );
  }
}



