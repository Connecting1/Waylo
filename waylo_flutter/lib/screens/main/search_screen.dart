import 'dart:async';
import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/friend_api.dart';
import 'package:waylo_flutter/models/search_user.dart';
import 'package:waylo_flutter/models/friend_request.dart';
import 'package:waylo_flutter/models/friend_status.dart';
import 'package:waylo_flutter/screens/main/user_profile_page.dart';
import 'package:waylo_flutter/services/api/chat_api.dart';
import 'package:waylo_flutter/screens/chat/chat_room_screen.dart';
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

  // 탭 컨트롤러
  late TabController _tabController;

  // 친구 요청 상태 관리
  Map<String, bool> _pendingFriendRequests = {};

  // 친구 상태 정보 저장
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

  // 현재 사용자 ID 로드
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await ApiService.getUserId();
  }

  // 내 친구 목록 로드
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
      } else {
        print("[ERROR] 친구 목록 로드 실패: 응답 형식 오류");
      }
    } catch (e) {
      print("[ERROR] 친구 목록 로드 중 오류 발생: $e");
    } finally {
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  // 친구 상태 관련 데이터 로드
  Future<void> _loadFriendStatusData() async {
    if (_currentUserId == null) {
      _currentUserId = await ApiService.getUserId();
      if (_currentUserId == null) return;
    }

    try {
      // 내 친구 목록 로드
      final friendsResponse = await FriendApi.getFriends(_currentUserId!);
      if (friendsResponse is Map && friendsResponse.containsKey('friends')) {
        setState(() {
          _myFriendIds = List<Map<String, dynamic>>.from(friendsResponse['friends'])
              .map((friend) => friend['id'] as String)
              .toList();
        });
      }

      // 내가 보낸 친구 요청 로드
      final sentRequests = await FriendApi.getSentFriendRequests();
      setState(() {
        _mySentRequests = sentRequests;
      });

      // 받은 친구 요청은 이미 _loadFriendRequests()에서 로드됨
      final requests = _friendRequests
          .map((req) => {'from_user_id': req.fromUserId, 'id': req.id})
          .toList();
      setState(() {
        _myReceivedRequests = requests;
      });

    } catch (e) {
      print("[ERROR] 친구 상태 데이터 로드 중 오류: $e");
    }
  }

  // 친구 요청 목록 로드
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

          // 받은 요청 정보 업데이트
          _myReceivedRequests = _friendRequests
              .map((req) => {'from_user_id': req.fromUserId, 'id': req.id})
              .toList();
        });
      } else {
        print("[ERROR] 친구 요청 로드 실패: 응답 형식 오류");
      }
    } catch (e) {
      print("[ERROR] 친구 요청 로드 중 오류 발생: $e");
    } finally {
      setState(() {
        _isLoadingFriendRequests = false;
      });
    }
  }

  // 검색어 변경 시 호출되는 메서드
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // 디바운싱 적용 (타이핑이 멈추고 300ms 후에 검색 실행)
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

  // 사용자 검색 API 호출
  Future<void> _searchUsers(String prefix) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await UserApi.searchUsers(prefix);

      // 에러 응답인 경우 처리
      if (response is Map && response.containsKey("error")) {
        print("[ERROR] 사용자 검색 실패: ${response["error"]}");
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      // 리스트 응답인 경우 처리
      if (response is List) {
        // 자기 자신을 검색 결과에서 제외
        final List<SearchUser> users = response
            .map((json) => SearchUser.fromJson(json as Map<String, dynamic>))
            .where((user) => user.id != _currentUserId) // 자기 자신 제외
            .toList();

        setState(() {
          _searchResults = users;
          _isLoading = false;
        });
        return;
      }

      // 그 외 응답 처리
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    } catch (e) {
      print("[ERROR] 사용자 검색 중 오류 발생: $e");
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  // 친구 요청 보내기
  Future<void> _sendFriendRequest(String toUserId) async {
    if (_currentUserId == null) {
      print("[ERROR] 현재 사용자 ID를 찾을 수 없습니다");
      return;
    }

    // 요청 중 상태로 설정
    setState(() {
      _pendingFriendRequests[toUserId] = true;
    });

    try {
      final response = await FriendApi.sendFriendRequest(
        fromUserId: _currentUserId!,
        toUserId: toUserId,
      );

      if (response.containsKey('error')) {
        print("[ERROR] 친구 요청 전송 실패: ${response['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 전송 실패: ${response['error']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청을 보냈습니다")),
        );

        // 친구 상태 데이터 새로고침
        await _loadFriendStatusData();
      }
    } catch (e) {
      print("[ERROR] 친구 요청 전송 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구 요청 전송 중 오류가 발생했습니다")),
      );
    } finally {
      setState(() {
        _pendingFriendRequests[toUserId] = false;
      });
    }
  }

  // 친구 요청 수락
  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      final response = await FriendApi.acceptFriendRequest(
        requestId: requestId,
      );

      if (response.containsKey('error')) {
        print("[ERROR] 친구 요청 수락 실패: ${response['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 수락 실패: ${response['error']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청을 수락했습니다")),
        );

        // 친구 요청 목록 및 친구 상태 데이터 새로고침
        await _loadFriendRequests();
        await _loadFriendsList();
        await _loadFriendStatusData();
      }
    } catch (e) {
      print("[ERROR] 친구 요청 수락 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구 요청 수락 중 오류가 발생했습니다")),
      );
    }
  }

  // 친구 요청 거절
  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      final response = await FriendApi.rejectFriendRequest(
        requestId: requestId,
      );

      if (response.containsKey('error')) {
        print("[ERROR] 친구 요청 거절 실패: ${response['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 거절 실패: ${response['error']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청을 거절했습니다")),
        );

        // 친구 요청 목록 새로고침
        await _loadFriendRequests();
      }
    } catch (e) {
      print("[ERROR] 친구 요청 거절 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구 요청 거절 중 오류가 발생했습니다")),
      );
    }
  }

  // 사용자의 친구 상태 확인
  FriendStatus _getFriendStatus(String userId) {
    return FriendStatusHelper.getStatus(
      friendIds: _myFriendIds,
      sentRequests: _mySentRequests,
      receivedRequests: _myReceivedRequests,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: Text(
          "Search & Friends",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadFriendRequests();
              _loadFriendsList();
              _loadFriendStatusData();
            },
          ),
        ],
        bottom: _searchController.text.isEmpty
            ? TabBar(
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
        )
            : null,
      ),
      body: Column(
        children: [
          // 검색 입력 필드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25), // 더 둥근 모서리
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
          ),

          // 로딩 인디케이터
          if (_isLoading)
            Center(child: CircularProgressIndicator()),

          // 검색 결과 또는 친구 요청/목록 탭
          Expanded(
            child: _searchController.text.isEmpty
                ? TabBarView(
              controller: _tabController,
              children: [
                _buildFriendRequestsList(),
                _buildFriendsList(),
              ],
            )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestsList() {
    if (_isLoadingFriendRequests) {
      return Center(child: CircularProgressIndicator());
    }

    if (_friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No friend requests',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text('Search for users to add friends',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
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

  Widget _buildFriendsList() {
    if (_isLoadingFriends) {
      return Center(child: CircularProgressIndicator());
    }

    if (_myFriendsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No friends yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text('Search for users to add friends',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
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

  Widget _buildFriendRequestItem(FriendRequest request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: request.fullProfileImageUrl.isNotEmpty
              ? NetworkImage(request.fullProfileImageUrl)
              : null,
          backgroundColor: Colors.grey[300],
          child: request.fullProfileImageUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
        title: Text(request.fromUserName),
        subtitle: Text('Friend request'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 수락 버튼
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _acceptFriendRequest(request.id),
            ),
            // 거절 버튼
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _rejectFriendRequest(request.id),
            ),
          ],
        ),
        onTap: () {
          // 친구 요청 항목 클릭 시 프로필 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                userId: request.fromUserId,
                username: request.fromUserName,
                profileImage: request.fullProfileImageUrl,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final String fullProfileImageUrl = _getFullProfileImageUrl(friend['profile_image'] ?? '');
    final DateTime friendshipDate = friend['friendship_date'] != null
        ? DateTime.parse(friend['friendship_date'])
        : DateTime.now();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: fullProfileImageUrl.isNotEmpty
              ? NetworkImage(fullProfileImageUrl)
              : null,
          backgroundColor: Colors.grey[300],
          child: fullProfileImageUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
        title: Text(friend['username'] ?? 'Unknown'),
        subtitle: Text('Friends since ${_formatDate(friendshipDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 채팅 버튼 추가
            IconButton(
              icon: Icon(Icons.chat, color: AppColors.primary),
              onPressed: () async {
                try {
                  // 채팅방 생성 API 호출
                  final response = await ChatApi.createChatRoom(
                    friendId: friend['id'],
                  );

                  if (!response.containsKey('error')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          roomId: response['room_id'],
                          friendName: friend['username'] ?? 'Unknown',
                          friendProfileImage: fullProfileImageUrl,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response['error'] ?? '채팅방 생성에 실패했습니다')),
                    );
                  }
                } catch (e) {
                  print("채팅방 생성 오류: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('채팅방 생성 중 오류가 발생했습니다')),
                  );
                }
              },
            ),
            Icon(Icons.people, color: Colors.green),
          ],
        ),
        onTap: () {
          // 친구 항목 클릭 시 프로필 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                userId: friend['id'],
                username: friend['username'] ?? 'Unknown',
                profileImage: fullProfileImageUrl,
              ),
            ),
          );
        },
      ),
    );
  }

  // 프로필 이미지 URL 변환
  String _getFullProfileImageUrl(String profileImage) {
    if (profileImage.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (profileImage.startsWith('http')) return profileImage;

    // 상대 경로를 전체 URL로 변환 - ApiService.baseUrl 사용
    if (profileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$profileImage";
    }

    return profileImage;
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Container(); // 로딩 중이면 빈 컨테이너 반환
    }

    if (!_hasSearched) {
      return Center(
        child: Text('Enter a username to search'),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserListItem(user);
      },
    );
  }

  Widget _buildUserListItem(SearchUser user) {
    final bool isPending = _pendingFriendRequests[user.id] ?? false;
    final friendStatus = _getFriendStatus(user.id);

    // 친구 상태에 따라 아이콘과 색상 결정
    IconData trailingIcon;
    Color iconColor;
    String statusText = '';
    bool canSendRequest = true;

    switch (friendStatus) {
      case FriendStatus.friend:
        trailingIcon = Icons.people;
        iconColor = Colors.green;
        statusText = 'Friends';
        canSendRequest = false;
        break;
      case FriendStatus.requestSent:
        trailingIcon = Icons.pending;
        iconColor = Colors.orange;
        statusText = 'Request sent';
        canSendRequest = false;
        break;
      case FriendStatus.requestReceived:
        trailingIcon = Icons.person_add_alt_1;
        iconColor = Colors.blue;
        statusText = 'Request received';
        canSendRequest = false;
        break;
      case FriendStatus.notFriend:
      default:
        trailingIcon = Icons.person_add;
        iconColor = AppColors.primary;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.fullProfileImageUrl.isNotEmpty
            ? NetworkImage(user.fullProfileImageUrl)
            : null,
        backgroundColor: Colors.grey[300],
        child: user.fullProfileImageUrl.isEmpty
            ? Icon(Icons.person, color: Colors.grey[600])
            : null,
      ),
      title: Text(user.username),
      subtitle: Text(
        statusText.isEmpty
            ? (user.accountVisibility == 'private' ? 'Private account' : 'Public account')
            : statusText,
        style: TextStyle(
          color: statusText.isEmpty
              ? (user.accountVisibility == 'private' ? Colors.grey : Colors.green[700])
              : iconColor,
        ),
      ),
      trailing: isPending
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : IconButton(
        icon: Icon(trailingIcon, color: iconColor),
        onPressed: canSendRequest
            ? () {
          // 친구 요청 버튼 클릭 시 요청만 보내고 페이지 이동은 하지 않음
          _sendFriendRequest(user.id);
          // 이벤트 전파 중지
          return;
        }
            : null,
      ),
      // 프로필 아이템 클릭 시 프로필 페이지로 이동
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
              userId: user.id,
              username: user.username,
              profileImage: user.fullProfileImageUrl,
            ),
          ),
        );
      },
    );
  }
}