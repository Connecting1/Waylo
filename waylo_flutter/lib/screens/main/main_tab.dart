import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'upload_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../../styles/app_styles.dart'; // 스타일 파일 import

class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary), // 스타일에서 색상 사용
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  TabController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Waylo'),
        ),
        body: TabBarView(
          children: <Widget>[
            HomeScreenPage(),
            ChatScreenPage(),
            UploadScreenPage(),
            SearchScreenPage(),
            ProfileScreenPage(),
          ],
          controller: controller,
        ),
        bottomNavigationBar: TabBar(
          tabs: <Tab>[
            Tab(icon: Icon(Icons.home, color: AppColors.primary)),
            Tab(icon: Icon(Icons.chat, color: AppColors.primary)),
            Tab(icon: Icon(Icons.edit, color: AppColors.primary)),
            Tab(icon: Icon(Icons.search, color: AppColors.primary)),
            Tab(icon: Icon(Icons.person, color: AppColors.primary)),
          ],
          controller: controller,
        ));
  }

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }
}
