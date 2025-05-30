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
    _tabController = TabController(length: 2, vsync: this);
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

      if (response is Map && response.containsKey('friends')) {
        setState(() {
          _myFriendsList = List<Map<String, dynamic>>.from(response['friends']);
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
      if (friendsResponse is Map && friendsResponse.containsKey('friends')) {
        setState(() {
          _myFriendIds = List<Map<String, dynamic>>.from(friendsResponse['friends'])
              .map((friend) => friend['id'] as String)
              .toList();
        });
      }

      final sentRequests = await FriendApi.getSentFriendRequests();
      setState(() {
        _mySentRequests = sentRequests;
      });

      final requests = _friendRequests
          .map((req) => {'from_user_id': req.fromUserId, 'id': req.id})
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

      if (response is Map && response.containsKey('requests')) {
        final List<dynamic> requestsList = response['requests'];
        setState(() {
          _friendRequests = requestsList
              .map((json) => FriendRequest.fromJson(json))
              .toList();

          _myReceivedRequests = _friendRequests
              .map((req) => {'from_user_id': req.fromUserId, 'id': req.id})
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

    _debounceTimer = Timer(Duration(milliseconds: 300), () {
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

      if (response is Map && response.containsKey("error")) {
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

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send friend request: ${response['error']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request has been sent")),
        );

        await _loadFriendStatusData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while sending friend request")),
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

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to accept friend request: ${response['error']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request accepted")),
        );

        await _loadFriendRequests();
        await _loadFriendsList();
        await _loadFriendStatusData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while accepting friend request")),
      );
    }
  }

  /// 친구 요청 거절
  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      final response = await FriendApi.rejectFriendRequest(requestId: requestId);

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to reject friend request: ${response['error']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request rejected")),
        );

        await _loadFriendRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while rejecting friend request")),
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
      final response = await ChatApi.createChatRoom(friendId: friend['id']);

      if (!response.containsKey('error')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              roomId: response['room_id'],
              friendName: friend['username'] ?? 'Unknown',
              friendProfileImage: _getFullProfileImageUrl(friend['profile_image'] ?? ''),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to create chat room')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while creating chat room')),
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
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchField(),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 40,
      automaticallyImplyLeading: false,
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: Text(
        "Search & Friends",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
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
      unselectedLabelColor: Colors.white70,
      tabs: [
        Tab(
          icon: Icon(Icons.person_add_alt),
          text: "Friend Requests (${_friendRequests.length})",
        ),
        Tab(
          icon: Icon(Icons.people),
          text: "My Friends (${_myFriendsList.length})",
        ),
      ],
    );
  }

  /// 검색 입력 필드
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by username',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
      return Center(child: CircularProgressIndicator());
    }

    if (_friendRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_disabled,
        title: 'No friend requests',
        subtitle: 'Search for users to add friends',
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
      return Center(child: CircularProgressIndicator());
    }

    if (_myFriendsList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_alt_outlined,
        title: 'No friends yet',
        subtitle: 'Search for users to add friends',
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
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  /// 친구 요청 아이템
  Widget _buildFriendRequestItem(FriendRequest request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildAvatar(request.fullProfileImageUrl),
        title: Text(request.fromUserName),
        subtitle: Text('Friend request'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _acceptFriendRequest(request.id),
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
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
    final String fullProfileImageUrl = _getFullProfileImageUrl(friend['profile_image'] ?? '');
    final DateTime friendshipDate = friend['friendship_date'] != null
        ? DateTime.parse(friend['friendship_date'])
        : DateTime.now();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildAvatar(fullProfileImageUrl),
        title: Text(friend['username'] ?? 'Unknown'),
        subtitle: Text('Friends since ${_formatDate(friendshipDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chat, color: AppColors.primary),
              onPressed: () => _startChat(friend),
            ),
            Icon(Icons.people, color: Colors.green),
          ],
        ),
        onTap: () => _navigateToProfile(
          friend['id'],
          friend['username'] ?? 'Unknown',
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
      return Center(child: Text('Enter a username to search'));
    }

    if (_searchResults.isEmpty) {
      return Center(child: Text('No results found'));
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
            ? (user.accountVisibility == 'private' ? 'Private account' : 'Public account')
            : statusInfo['text'],
        style: TextStyle(
          color: statusInfo['text'].isEmpty
              ? (user.accountVisibility == 'private' ? Colors.grey : Colors.green[700])
              : statusInfo['color'],
        ),
      ),
      trailing: isPending
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
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
          'text': 'Friends',
          'canSendRequest': false,
        };
      case FriendStatus.requestSent:
        return {
          'icon': Icons.pending,
          'color': Colors.orange,
          'text': 'Request sent',
          'canSendRequest': false,
        };
      case FriendStatus.requestReceived:
        return {
          'icon': Icons.person_add_alt_1,
          'color': Colors.blue,
          'text': 'Request received',
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