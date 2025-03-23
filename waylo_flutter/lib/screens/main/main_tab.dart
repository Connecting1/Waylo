import 'package:flutter/material.dart';
import 'my_page_screen.dart';
import 'chat_screen.dart';
import 'shared_map_screen.dart';
import 'search_screen.dart';
import 'album_screen.dart';
import '../../styles/app_styles.dart'; // 스타일 파일 import

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> with SingleTickerProviderStateMixin {
  TabController? controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope (
        onWillPop: () async {
          // 여기서 false를 반환하면 뒤로가기 동작이 무시됩니다
          return false;
        },

        child: Scaffold(
            body: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                MyPageScreenPage(),
                SharedMapScreenPage(),
                SearchScreenPage(),
                ChatScreenPage(),
                AlbumScreenPage(),
              ],
              controller: controller,
            ),
            bottomNavigationBar: TabBar(
              tabs: <Tab>[
                Tab(icon: Icon(Icons.person_pin_circle)),
                Tab(icon: Icon(Icons.public)),
                Tab(icon: Icon(Icons.search)),
                Tab(icon: Icon(Icons.forum)),
                Tab(icon: Icon(Icons.settings)),
              ],
              controller: controller,
              labelColor: AppColors.primary,       // 선택된 탭 아이콘 색상
              unselectedLabelColor: Colors.grey,   // 선택되지 않은 탭 아이콘 색상
              indicatorColor: AppColors.primary,
            ))

    );


  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }
}
