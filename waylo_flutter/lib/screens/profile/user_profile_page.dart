import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/screens/profile/user_map_content.dart';
import 'package:waylo_flutter/screens/profile/user_album_content.dart';
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
  // 텍스트 상수들
  static const String _mapTabText = "Map";
  static const String _albumTabText = "Album";

  // 폰트 크기 상수들
  static const double _usernameFontSize = 20;

  // 크기 상수들
  static const double _toolbarHeight = 30;
  static const int _tabCount = 2;

  // 탭 인덱스 상수들
  static const int _mapTabIndex = 0;
  static const int _albumTabIndex = 1;

  // 색상 투명도 상수들
  static const double _unselectedLabelOpacity = 0.7; // Colors.white70에 해당
  static const double _loadingOverlayOpacity = 0.45; // Colors.black45에 해당

  // 물리 효과 상수
  static const ScrollPhysics _tabBarPhysics = NeverScrollableScrollPhysics();

  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// 탭 변경 처리
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// 피드 생성 상태 변경 처리 (빈 구현)
  void _handleCreatingFeedChanged(bool isCreating) {
    // 읽기 전용 프로필에서는 피드 생성이 불가능하므로 빈 구현
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: true,
      toolbarHeight: _toolbarHeight,
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      foregroundColor: Colors.white,
      title: Text(
        widget.username,
        style: const TextStyle(
          fontSize: _usernameFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottom: _buildTabBar(),
      centerTitle: true,
    );
  }

  /// TabBar 구성
  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(_unselectedLabelOpacity),
      tabs: const [
        Tab(text: _mapTabText),
        Tab(text: _albumTabText),
      ],
    );
  }

  /// 메인 바디 구성
  Widget _buildBody() {
    return Stack(
      children: [
        _buildTabBarView(),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  /// 탭 뷰 구성
  Widget _buildTabBarView() {
    return TabBarView(
      physics: _tabBarPhysics,
      controller: _tabController,
      children: [
        UserMapContentWidget(
          key: ValueKey('user_map_${widget.userId}'),
          userId: widget.userId,
          username: widget.username,
        ),
        UserAlbumContentWidget(
          key: ValueKey('user_album_${widget.userId}'),
          userId: widget.userId,
          username: widget.username,
        ),
      ],
    );
  }

  /// 로딩 오버레이 위젯
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(_loadingOverlayOpacity),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }
}