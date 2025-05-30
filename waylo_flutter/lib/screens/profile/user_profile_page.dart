// lib/screens/profile/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/screens/profile/user_map_content.dart'; // 변경됨
import 'package:waylo_flutter/screens/profile/user_album_content.dart'; // 변경됨
import 'package:waylo_flutter/styles/app_styles.dart';

import '../../providers/theme_provider.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String username;
  final String profileImage;

  const UserProfilePage({
    Key? key,
    required this.userId,
    required this.username,
    required this.profileImage,
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

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

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // 피드 생성 상태 업데이트용 빈 메서드
  void _handleCreatingFeedChanged(bool isCreating) {
    // 빈 구현 - 실제로는 아무 동작도 하지 않음
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true; // 뒤로가기 허용
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true, // 뒤로가기 버튼 활성화
          toolbarHeight: 30,
          backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
              ? AppColors.darkSurface
              : AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            "${widget.username}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
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
                UserMapContentWidget(
                  key: ValueKey('user_map_${widget.userId}'),
                  userId: widget.userId,
                  username: widget.username, // username 추가
                ),

                // 두 번째 탭 - 앨범 콘텐츠
                UserAlbumContentWidget(
                  key: ValueKey('user_album_${widget.userId}'),
                  userId: widget.userId,
                  username: widget.username, // username 추가
                ),
              ],
            ),

            // 로딩 인디케이터
            if (_isLoading)
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
}