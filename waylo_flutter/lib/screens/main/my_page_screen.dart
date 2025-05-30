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

    if (_tabController.index == 0) {
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
      physics: NeverScrollableScrollPhysics(),
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
      color: Colors.black45,
      child: Center(
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