// lib/screen/main/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/screens/profile/my_map_content.dart';
import 'package:waylo_flutter/screens/profile/my_album_content.dart';

import '../../providers/theme_provider.dart';

class MyPageScreenPage extends StatefulWidget {
  @override
  _MyPageScreenPageState createState() => _MyPageScreenPageState();
}

class _MyPageScreenPageState extends State<MyPageScreenPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCreatingFeed = false;

  final GlobalKey<MyMapContentWidgetState> mapContentKey = GlobalKey<MyMapContentWidgetState>();
  final GlobalKey<AlbumContentWidgetState> albumContentKey = GlobalKey<AlbumContentWidgetState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  // 탭 변경 리스너
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {}); // 탭 변경 시 UI 업데이트
    }
  }

  // 피드 생성 상태 업데이트
  void _handleCreatingFeedChanged(bool isCreating) {
    setState(() {
      _isCreatingFeed = isCreating;
    });
  }

  // + 버튼 클릭 핸들러
  void _handleAddButtonClick() {
    if (_isCreatingFeed) return; // 이미 진행 중이면 무시

    if (_tabController.index == 0) {
      // 지도 탭에서는 피드 생성
      mapContentKey.currentState?.createFeed();
    } else {
      // 앨범 탭에서는 위젯 추가 다이얼로그
      albumContentKey.currentState?.openWidgetSelection();
    }
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼 동작 방지
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          toolbarHeight: 30,
          backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
              ? AppColors.darkSurface
              : AppColors.primary,
          title: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Text(
                "${userProvider.username}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              );
            },
          ),
          actions: [
            // + 버튼 (항상 표시, 탭에 따라 동작 다름)
            IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: _isCreatingFeed ? null : _handleAddButtonClick,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Map"),
              Tab(text: "Album"),
            ],
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            TabBarView(
              physics: NeverScrollableScrollPhysics(), // 슬라이드 비활성화
              controller: _tabController,
              children: [
                // 첫 번째 탭 - 지도 콘텐츠
                MyMapContentWidget(
                  key: mapContentKey,
                  onCreatingFeedChanged: _handleCreatingFeedChanged,
                ),
                // 두 번째 탭 - 앨범 콘텐츠
                AlbumContentWidget(
                  key: albumContentKey,
                ),
              ],
            ),
            // 피드 생성 중일 때 로딩 표시
            if (_isCreatingFeed)
              Container(
                color: Colors.black45,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
}