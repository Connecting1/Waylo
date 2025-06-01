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
  bool _isCreatingFeed = false;

  final GlobalKey<MyMapContentWidgetState> mapContentKey = GlobalKey<MyMapContentWidgetState>();
  final GlobalKey<AlbumContentWidgetState> albumContentKey = GlobalKey<AlbumContentWidgetState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  /// 탭 변경 처리
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// 피드 생성 상태 업데이트
  void _handleCreatingFeedChanged(bool isCreating) {
    setState(() {
      _isCreatingFeed = isCreating;
    });
  }

  /// 추가 버튼 클릭 처리
  void _handleAddButtonClick() {
    if (_isCreatingFeed) return;

    if (_tabController.index == _mapTabIndex) {
      mapContentKey.currentState?.createFeed();
    } else {
      albumContentKey.currentState?.openWidgetSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbarHeight,
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return Text(
            "${userProvider.username}",
            style: const TextStyle(
              fontSize: _usernameFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _isCreatingFeed ? null : _handleAddButtonClick,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(_unselectedLabelOpacity),
        tabs: const [
          Tab(text: _mapTabText),
          Tab(text: _albumTabText),
        ],
      ),
      centerTitle: true,
    );
  }

  /// 메인 바디 구성
  Widget _buildBody() {
    return Stack(
      children: [
        _buildTabBarView(),
        if (_isCreatingFeed) _buildLoadingOverlay(),
      ],
    );
  }

  /// 탭 뷰 구성
  Widget _buildTabBarView() {
    return TabBarView(
      physics: _tabBarPhysics,
      controller: _tabController,
      children: [
        MyMapContentWidget(
          key: mapContentKey,
          onCreatingFeedChanged: _handleCreatingFeedChanged,
        ),
        AlbumContentWidget(
          key: albumContentKey,
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
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
}