import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/friend_api.dart';
import 'package:waylo_flutter/models/search_user.dart';
import 'package:waylo_flutter/models/friend_request.dart';
import 'package:waylo_flutter/models/friend_status.dart';
import 'package:waylo_flutter/screens/profile/user_profile_page.dart';
import 'package:waylo_flutter/services/api/chat_api.dart';
import 'package:waylo_flutter/screens/chat/chat_room_screen.dart';
import '../../providers/theme_provider.dart';
import '../../services/api/api_service.dart';
import '../../styles/app_styles.dart';

class SearchScreenPage extends StatefulWidget {
  @override
  _SearchScreenPageState createState() => _SearchScreenPageState();
}

class _SearchScreenPageState extends State<SearchScreenPage> with SingleTickerProviderStateMixin {
  // 텍스트 상수들
  static const String _appBarTitle = "Search & Friends";
  static const String _friendRequestsTabPrefix = "Friend Requests (";
  static const String _myFriendsTabPrefix = "My Friends (";
  static const String _tabSuffix = ")";
  static const String _searchHintText = "Search by username";
  static const String _noFriendRequestsTitle = "No friend requests";
  static const String _noFriendsTitle = "No friends yet";
  static const String _searchPromptText = "Search for users to add friends";
  static const String _friendRequestSubtitle = "Friend request";
  static const String _friendsSincePrefix = "Friends since ";
  static const String _searchPromptMessage = "Enter a username to search";
  static const String _noResultsMessage = "No results found";
  static const String _privateAccountText = "Private account";
  static const String _publicAccountText = "Public account";
  static const String _friendsStatusText = "Friends";
  static const String _requestSentText = "Request sent";
  static const String _requestReceivedText = "Request received";
  static const String _unknownUserText = "Unknown";

  // 에러 메시지 상수들
  static const String _sendRequestFailedPrefix = "Failed to send friend request: ";
  static const String _sendRequestSuccessMessage = "Friend request has been sent";
  static const String _sendRequestErrorMessage = "An error occurred while sending friend request";
  static const String _acceptRequestFailedPrefix = "Failed to accept friend request: ";
  static const String _acceptRequestSuccessMessage = "Friend request accepted";
  static const String _acceptRequestErrorMessage = "An error occurred while accepting friend request";
  static const String _rejectRequestFailedPrefix = "Failed to reject friend request: ";
  static const String _rejectRequestSuccessMessage = "Friend request rejected";
  static const String _rejectRequestErrorMessage = "An error occurred while rejecting friend request";
  static const String _createChatFailedMessage = "Failed to create chat room";
  static const String _createChatErrorMessage = "An error occurred while creating chat room";

  // API 키 상수들
  static const String _errorKey = 'error';
  static const String _friendsKey = 'friends';
  static const String _requestsKey = 'requests';
  static const String _roomIdKey = 'room_id';
  static const String _usernameKey = 'username';
  static const String _profileImageKey = 'profile_image';
  static const String _idKey = 'id';
  static const String _friendshipDateKey = 'friendship_date';
  static const String _fromUserIdKey = 'from_user_id';

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 16;
  static const double _emptyStateIconSize = 48;
  static const double _emptyStateTitleFontSize = 16;
  static const double _emptyStateSubtitleFontSize = 14;

  // 크기 상수들
  static const double _toolbarHeight = 40;
  static const int _debounceMilliseconds = 300;
  static const int _tabCount = 2;
  static const double _searchFieldBorderRadius = 25;
  static const double _searchFieldPadding = 16.0;
  static const double _searchFieldVerticalPadding = 12;
  static const double _searchFieldHorizontalPadding = 16;
  static const double _cardHorizontalMargin = 16;
  static const double _cardVerticalMargin = 8;
  static const double _emptyStateSpacing = 16;
  static const double _emptyStateSubSpacing = 8;
  static const double _loadingIndicatorSize = 24;
  static const double _loadingIndicatorStroke = 2;

  // 날짜 포맷팅 상수들
  static const String _datePadCharacter = '0';
  static const int _datePadLength = 2;

  // 색상 투명도 상수들
  static const double _unselectedTabOpacity = 0.7; // Colors.white70

  // 계정 가시성 상수들
  static const String _privateVisibility = 'private';

  final TextEditingController _searchController = TextEditingController();
  List<SearchUser> _searchResults = [];
  List<FriendRequest> _friendRequests = [];
  List<Map<String, dynamic>> _myFriendsList = [];
  bool _isLoading = false;
  bool _isLoadingFriendRequests = false;
  bool _isLoadingFriends = false;
  bool _hasSearched = false;
  String? _currentUserId;
  Timer? _debounceTimer;

  late TabController _tabController;

  Map<String, bool> _pendingFriendRequests = {};
  List<String> _myFriendIds = [];
  List<Map<String, dynamic>> _mySentRequests = [];
  List<Map<String, dynamic>> _myReceivedRequests = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _tabController = TabController(length: _tabCount, vsync: this);
    _loadCurrentUserId();
    _loadFriendRequests();
    _loadFriendsList();
    _loadFriendStatusData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 현재 사용자 ID 로드
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await ApiService.getUserId();
  }

  /// 친구 목록 로드
  Future<void> _loadFriendsList() async {
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      if (_currentUserId == null) {
        _currentUserId = await ApiService.getUserId();
        if (_currentUserId == null) return;
      }

      final response = await FriendApi.getFriends(_currentUserId!);

      if (response is Map && response.containsKey(_friendsKey)) {
        setState(() {
          _myFriendsList = List<Map<String, dynamic>>.from(response[_friendsKey]);
        });
      }
    } catch (e) {
      // 에러는 조용히 처리
    } finally {
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  /// 친구 상태 관련 데이터 로드
  Future<void> _loadFriendStatusData() async {
    if (_currentUserId == null) {
      _currentUserId = await ApiService.getUserId();
      if (_currentUserId == null) return;
    }

    try {
      final friendsResponse = await FriendApi.getFriends(_currentUserId!);
      if (friendsResponse is Map && friendsResponse.containsKey(_friendsKey)) {
        setState(() {
          _myFriendIds = List<Map<String, dynamic>>.from(friendsResponse[_friendsKey])
              .map((friend) => friend[_idKey] as String)
              .toList();
        });
      }

      final sentRequests = await FriendApi.getSentFriendRequests();
      setState(() {
        _mySentRequests = sentRequests;
      });

      final requests = _friendRequests
          .map((req) => {_fromUserIdKey: req.fromUserId, _idKey: req.id})
          .toList();
      setState(() {
        _myReceivedRequests = requests;
      });
    } catch (e) {
      // 에러는 조용히 처리
    }
  }

  /// 친구 요청 목록 로드
  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoadingFriendRequests = true;
    });

    try {
      final response = await FriendApi.getFriendRequests();

      if (response is Map && response.containsKey(_requestsKey)) {
        final List<dynamic> requestsList = response[_requestsKey];
        setState(() {
          _friendRequests = requestsList
              .map((json) => FriendRequest.fromJson(json))
              .toList();

          _myReceivedRequests = _friendRequests
              .map((req) => {_fromUserIdKey: req.fromUserId, _idKey: req.id})
              .toList();
        });
      }
    } catch (e) {
      // 에러는 조용히 처리
    } finally {
      setState(() {
        _isLoadingFriendRequests = false;
      });
    }
  }

  /// 검색어 변경 시 디바운싱 처리
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: _debounceMilliseconds), () {
      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty) {
        _searchUsers(searchText);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  /// 사용자 검색 API 호출
  Future<void> _searchUsers(String prefix) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await UserApi.searchUsers(prefix);

      if (response is Map && response.containsKey(_errorKey)) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      if (response is List) {
        final List<SearchUser> users = response
            .map((json) => SearchUser.fromJson(json as Map<String, dynamic>))
            .where((user) => user.id != _currentUserId)
            .toList();

        setState(() {
          _searchResults = users;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  /// 친구 요청 보내기
  Future<void> _sendFriendRequest(String toUserId) async {
    if (_currentUserId == null) return;

    setState(() {
      _pendingFriendRequests[toUserId] = true;
    });

    try {
      final response = await FriendApi.sendFriendRequest(
        fromUserId: _currentUserId!,
        toUserId: toUserId,
      );

      if (response.containsKey(_errorKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_sendRequestFailedPrefix${response[_errorKey]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_sendRequestSuccessMessage)),
        );

        await _loadFriendStatusData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_sendRequestErrorMessage)),
      );
    } finally {
      setState(() {
        _pendingFriendRequests[toUserId] = false;
      });
    }
  }

  /// 친구 요청 수락
  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      final response = await FriendApi.acceptFriendRequest(requestId: requestId);

      if (response.containsKey(_errorKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_acceptRequestFailedPrefix${response[_errorKey]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_acceptRequestSuccessMessage)),
        );

        await _loadFriendRequests();
        await _loadFriendsList();
        await _loadFriendStatusData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_acceptRequestErrorMessage)),
      );
    }
  }

  /// 친구 요청 거절
  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      final response = await FriendApi.rejectFriendRequest(requestId: requestId);

      if (response.containsKey(_errorKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_rejectRequestFailedPrefix${response[_errorKey]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_rejectRequestSuccessMessage)),
        );

        await _loadFriendRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_rejectRequestErrorMessage)),
      );
    }
  }

  /// 사용자의 친구 상태 확인
  FriendStatus _getFriendStatus(String userId) {
    return FriendStatusHelper.getStatus(
      friendIds: _myFriendIds,
      sentRequests: _mySentRequests,
      receivedRequests: _myReceivedRequests,
      userId: userId,
    );
  }

  /// 채팅방 생성 및 이동
  Future<void> _startChat(Map<String, dynamic> friend) async {
    try {
      final response = await ChatApi.createChatRoom(friendId: friend[_idKey]);

      if (!response.containsKey(_errorKey)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              roomId: response[_roomIdKey],
              friendName: friend[_usernameKey] ?? _unknownUserText,
              friendProfileImage: _getFullProfileImageUrl(friend[_profileImageKey] ?? ''),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response[_errorKey] ?? _createChatFailedMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_createChatErrorMessage)),
      );
    }
  }

  /// 프로필 이미지 URL 변환
  String _getFullProfileImageUrl(String profileImage) {
    if (profileImage.isEmpty) return '';
    if (profileImage.startsWith('http')) return profileImage;
    if (profileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$profileImage";
    }
    return profileImage;
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(_datePadLength, _datePadCharacter)}-${date.day.toString().padLeft(_datePadLength, _datePadCharacter)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchField(),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: const Text(
        _appBarTitle,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: _appBarTitleFontSize,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            _loadFriendRequests();
            _loadFriendsList();
            _loadFriendStatusData();
          },
        ),
      ],
      bottom: _searchController.text.isEmpty ? _buildTabBar() : null,
    );
  }

  /// 탭바 구성
  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(_unselectedTabOpacity),
      tabs: [
        Tab(
          icon: const Icon(Icons.person_add_alt),
          text: "$_friendRequestsTabPrefix${_friendRequests.length}$_tabSuffix",
        ),
        Tab(
          icon: const Icon(Icons.people),
          text: "$_myFriendsTabPrefix${_myFriendsList.length}$_tabSuffix",
        ),
      ],
    );
  }

  /// 검색 입력 필드
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(_searchFieldPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(_searchFieldBorderRadius),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: _searchHintText,
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: _searchFieldVerticalPadding,
              horizontal: _searchFieldHorizontalPadding,
            ),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  /// 메인 콘텐츠 영역
  Widget _buildContent() {
    if (_searchController.text.isEmpty) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildFriendRequestsList(),
          _buildFriendsList(),
        ],
      );
    } else {
      return _buildSearchResults();
    }
  }

  /// 친구 요청 목록
  Widget _buildFriendRequestsList() {
    if (_isLoadingFriendRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_disabled,
        title: _noFriendRequestsTitle,
        subtitle: _searchPromptText,
      );
    }

    return ListView.builder(
      itemCount: _friendRequests.length,
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return _buildFriendRequestItem(request);
      },
    );
  }

  /// 친구 목록
  Widget _buildFriendsList() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myFriendsList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_alt_outlined,
        title: _noFriendsTitle,
        subtitle: _searchPromptText,
      );
    }

    return ListView.builder(
      itemCount: _myFriendsList.length,
      itemBuilder: (context, index) {
        final friend = _myFriendsList[index];
        return _buildFriendItem(friend);
      },
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _emptyStateIconSize, color: Colors.grey),
          const SizedBox(height: _emptyStateSpacing),
          Text(
            title,
            style: TextStyle(
              fontSize: _emptyStateTitleFontSize,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: _emptyStateSubSpacing),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: _emptyStateSubtitleFontSize,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 친구 요청 아이템
  Widget _buildFriendRequestItem(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: _cardHorizontalMargin,
        vertical: _cardVerticalMargin,
      ),
      child: ListTile(
        leading: _buildAvatar(request.fullProfileImageUrl),
        title: Text(request.fromUserName),
        subtitle: const Text(_friendRequestSubtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _acceptFriendRequest(request.id),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _rejectFriendRequest(request.id),
            ),
          ],
        ),
        onTap: () => _navigateToProfile(request.fromUserId, request.fromUserName, request.fullProfileImageUrl),
      ),
    );
  }

  /// 친구 아이템
  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final String fullProfileImageUrl = _getFullProfileImageUrl(friend[_profileImageKey] ?? '');
    final DateTime friendshipDate = friend[_friendshipDateKey] != null
        ? DateTime.parse(friend[_friendshipDateKey])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: _cardHorizontalMargin,
        vertical: _cardVerticalMargin,
      ),
      child: ListTile(
        leading: _buildAvatar(fullProfileImageUrl),
        title: Text(friend[_usernameKey] ?? _unknownUserText),
        subtitle: Text('$_friendsSincePrefix${_formatDate(friendshipDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat, color: AppColors.primary),
              onPressed: () => _startChat(friend),
            ),
            const Icon(Icons.people, color: Colors.green),
          ],
        ),
        onTap: () => _navigateToProfile(
          friend[_idKey],
          friend[_usernameKey] ?? _unknownUserText,
          fullProfileImageUrl,
        ),
      ),
    );
  }

  /// 검색 결과 목록
  Widget _buildSearchResults() {
    if (_isLoading) {
      return Container();
    }

    if (!_hasSearched) {
      return const Center(child: Text(_searchPromptMessage));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text(_noResultsMessage));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserListItem(user);
      },
    );
  }

  /// 사용자 검색 결과 아이템
  Widget _buildUserListItem(SearchUser user) {
    final bool isPending = _pendingFriendRequests[user.id] ?? false;
    final friendStatus = _getFriendStatus(user.id);

    final statusInfo = _getStatusInfo(friendStatus);

    return ListTile(
      leading: _buildAvatar(user.fullProfileImageUrl),
      title: Text(user.username),
      subtitle: Text(
        statusInfo['text'].isEmpty
            ? (user.accountVisibility == _privateVisibility ? _privateAccountText : _publicAccountText)
            : statusInfo['text'],
        style: TextStyle(
          color: statusInfo['text'].isEmpty
              ? (user.accountVisibility == _privateVisibility ? Colors.grey : Colors.green[700])
              : statusInfo['color'],
        ),
      ),
      trailing: isPending
          ? const SizedBox(
        width: _loadingIndicatorSize,
        height: _loadingIndicatorSize,
        child: CircularProgressIndicator(strokeWidth: _loadingIndicatorStroke),
      )
          : IconButton(
        icon: Icon(statusInfo['icon'], color: statusInfo['color']),
        onPressed: statusInfo['canSendRequest'] ? () => _sendFriendRequest(user.id) : null,
      ),
      onTap: () => _navigateToProfile(user.id, user.username, user.fullProfileImageUrl),
    );
  }

  /// 친구 상태 정보 가져오기
  Map<String, dynamic> _getStatusInfo(FriendStatus friendStatus) {
    switch (friendStatus) {
      case FriendStatus.friend:
        return {
          'icon': Icons.people,
          'color': Colors.green,
          'text': _friendsStatusText,
          'canSendRequest': false,
        };
      case FriendStatus.requestSent:
        return {
          'icon': Icons.pending,
          'color': Colors.orange,
          'text': _requestSentText,
          'canSendRequest': false,
        };
      case FriendStatus.requestReceived:
        return {
          'icon': Icons.person_add_alt_1,
          'color': Colors.blue,
          'text': _requestReceivedText,
          'canSendRequest': false,
        };
      case FriendStatus.notFriend:
      default:
        return {
          'icon': Icons.person_add,
          'color': AppColors.primary,
          'text': '',
          'canSendRequest': true,
        };
    }
  }

  /// 아바타 위젯 생성
  Widget _buildAvatar(String profileImageUrl) {
    return CircleAvatar(
      backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
      backgroundColor: Colors.grey[300],
      child: profileImageUrl.isEmpty ? Icon(Icons.person, color: Colors.grey[600]) : null,
    );
  }

  /// 프로필 페이지로 이동
  void _navigateToProfile(String userId, String username, String profileImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          username: username,
          profileImage: profileImage,
        ),
      ),
    );
  }
}