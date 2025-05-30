// lib/screen/main/shared_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/feed_provider.dart';
import 'package:waylo_flutter/providers/theme_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/models/feed_comment.dart';
import 'package:waylo_flutter/screens/profile/user_profile_page.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class SharedMapScreenPage extends StatefulWidget {
  @override
  _SharedMapScreenPageState createState() => _SharedMapScreenPageState();
}

class _SharedMapScreenPageState extends State<SharedMapScreenPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendsFeeds(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreFeeds();
    }
  }

  Future<void> _loadFriendsFeeds({bool refresh = false}) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    if (refresh) {
      _currentPage = 1;
    }
    await feedProvider.fetchFriendsFeeds(refresh: refresh, page: _currentPage);
  }

  Future<void> _loadMoreFeeds() async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    if (!feedProvider.hasMoreFriendsFeeds || feedProvider.isLoading) return;

    _currentPage++;
    await feedProvider.fetchFriendsFeeds(page: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: const Text(
          "Friends Feed",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.friendsFeeds.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (feedProvider.errorMessage.isNotEmpty && feedProvider.friendsFeeds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(feedProvider.errorMessage),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadFriendsFeeds(refresh: true),
                    child: Text('재시도'),
                  ),
                ],
              ),
            );
          }

          if (feedProvider.friendsFeeds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No friends\' posts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add friends to see their posts here!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadFriendsFeeds(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: feedProvider.friendsFeeds.length +
                  (feedProvider.hasMoreFriendsFeeds ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= feedProvider.friendsFeeds.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final feed = feedProvider.friendsFeeds[index];
                return FeedCard(feed: feed);
              },
            ),
          );
        },
      ),
    );
  }
}

class FeedCard extends StatefulWidget {
  final Feed feed;

  const FeedCard({Key? key, required this.feed}) : super(key: key);

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  List<FeedComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  bool _isLikeLoading = false; // 좋아요 로딩 상태 추가
  bool _isBookmarkLoading = false; // 북마크 로딩 상태 추가
  String? _currentUserId;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  // 로컬 상태 (실시간 업데이트용)
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  late int _bookmarksCount;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadComments(); // 댓글 바로 로드

    // 초기 상태 설정
    _isLiked = widget.feed.isLiked;
    _isBookmarked = widget.feed.isBookmarked;
    _likesCount = widget.feed.likesCount;
    _bookmarksCount = widget.feed.bookmarksCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await ApiService.getUserId();
    setState(() {});
  }

  Future<void> _loadComments() async {
    if (_isLoadingComments) return;

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final response = await FeedApi.fetchFeedComments(widget.feed.id);

      if (response is Map && response.containsKey('comments')) {
        List<dynamic> commentsData = response['comments'];
        setState(() {
          _comments = commentsData.map((data) => FeedComment.fromJson(data)).toList();
        });
      }
    } catch (e) {
      print("[ERROR] 댓글 로드 중 오류 발생: $e");
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    // 이미 로딩 중이면 무시
    if (_isLikeLoading) return;

    // 원래 상태 저장
    final bool originalIsLiked = _isLiked;
    final int originalLikesCount = _likesCount;

    setState(() {
      _isLikeLoading = true;
      // 즉시 UI 업데이트 (낙관적 업데이트)
      if (_isLiked) {
        _isLiked = false;
        _likesCount = _likesCount > 0 ? _likesCount - 1 : 0;
      } else {
        _isLiked = true;
        _likesCount = _likesCount + 1;
      }
    });

    try {
      Map<String, dynamic> response;
      // 원래 상태 기준으로 API 호출
      if (originalIsLiked) {
        response = await FeedApi.unlikeFeed(widget.feed.id);
      } else {
        response = await FeedApi.likeFeed(widget.feed.id);
      }

      if (response.containsKey('error')) {
        // 오류 발생 시 원복
        setState(() {
          _isLiked = originalIsLiked;
          _likesCount = originalLikesCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다.')),
        );
      } else {
        // 서버 응답으로 정확한 값 업데이트
        setState(() {
          _likesCount = response['likes_count'] ?? _likesCount;
        });
      }
    } catch (e) {
      // 오류 발생 시 원복
      setState(() {
        _isLiked = originalIsLiked;
        _likesCount = originalLikesCount;
      });
      print("[ERROR] 좋아요 토글 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isLikeLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    // 이미 로딩 중이면 무시
    if (_isBookmarkLoading) return;

    // 원래 상태 저장
    final bool originalIsBookmarked = _isBookmarked;
    final int originalBookmarksCount = _bookmarksCount;

    setState(() {
      _isBookmarkLoading = true;
      // 즉시 UI 업데이트 (낙관적 업데이트)
      if (_isBookmarked) {
        _isBookmarked = false;
        _bookmarksCount = _bookmarksCount > 0 ? _bookmarksCount - 1 : 0;
      } else {
        _isBookmarked = true;
        _bookmarksCount = _bookmarksCount + 1;
      }
    });

    try {
      Map<String, dynamic> response;
      // 원래 상태 기준으로 API 호출
      if (originalIsBookmarked) {
        response = await FeedApi.unbookmarkFeed(widget.feed.id);
      } else {
        response = await FeedApi.bookmarkFeed(widget.feed.id);
      }

      if (response.containsKey('error')) {
        // 오류 발생 시 원복
        setState(() {
          _isBookmarked = originalIsBookmarked;
          _bookmarksCount = originalBookmarksCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 처리 중 오류가 발생했습니다.')),
        );
      } else {
        // 서버 응답으로 정확한 값 업데이트
        setState(() {
          _bookmarksCount = response['bookmarks_count'] ?? _bookmarksCount;
        });
      }
    } catch (e) {
      // 오류 발생 시 원복
      setState(() {
        _isBookmarked = originalIsBookmarked;
        _bookmarksCount = originalBookmarksCount;
      });
      print("[ERROR] 북마크 토글 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isBookmarkLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isPostingComment = true;
    });

    try {
      final response = await FeedApi.createComment(widget.feed.id, comment);

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      _commentController.clear();
      await _loadComments(); // 댓글 새로고침
    } catch (e) {
      print("[ERROR] 댓글 작성 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("댓글 작성 중 오류가 발생했습니다.")),
      );
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: themeProvider.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (프로필 이미지, 사용자명, 날짜)
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _navigateToProfile(),
                  borderRadius: BorderRadius.circular(25),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.feed.fullProfileImageUrl.isNotEmpty
                        ? NetworkImage(widget.feed.fullProfileImageUrl)
                        : null,
                    child: widget.feed.fullProfileImageUrl.isEmpty
                        ? Icon(Icons.person)
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToProfile(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.feed.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: themeProvider.textColor,
                            ),
                          ),
                          Text(
                            _formatDate(widget.feed.createdAt),
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 이미지
          Container(
            width: double.infinity,
            // constraints: BoxConstraints(maxHeight: 400),
            child: Image.network(
              widget.feed.fullImageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          // 액션 버튼들 (좋아요, 북마크 - 왼쪽에 나란히)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 좋아요 버튼
                InkWell(
                  onTap: _isLikeLoading ? null : _toggleLike,
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: _isLikeLoading ? 0.6 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLikeLoading
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                            : Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? AppColors.primary : themeProvider.iconColor,
                          size: 24,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _likesCount.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                // 북마크 버튼
                InkWell(
                  onTap: _isBookmarkLoading ? null : _toggleBookmark,
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: _isBookmarkLoading ? 0.6 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isBookmarkLoading
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                            : Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _isBookmarked ? AppColors.primary : themeProvider.iconColor,
                          size: 24,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _bookmarksCount.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 설명
          if (widget.feed.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.feed.description,
                style: TextStyle(fontSize: 14),
              ),
            ),

          // 위치 지도 (댓글 위에 표시)
          InkWell(
            onTap: () => _showLocationOnMap(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 정적 지도 이미지 (Mapbox Static Images API)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        _getMapboxStaticImageUrl(),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined, size: 32, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    'Location',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // 위치 정보 오버레이
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getLocationText(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 클릭 힌트 아이콘
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 댓글 섹션 (항상 표시)
          Divider(color: Colors.grey[300]),

          // 댓글 목록
          if (_isLoadingComments)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...List.generate(
              _comments.length,
                  (index) => _buildCommentItem(_comments[index]),
            ),

          // 댓글 입력
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return CircleAvatar(
                      radius: 16,
                      backgroundImage: userProvider.profileImage.isNotEmpty
                          ? NetworkImage(userProvider.profileImage)
                          : null,
                      child: userProvider.profileImage.isEmpty
                          ? Icon(Icons.person, size: 20)
                          : null,
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: 1,
                    onSubmitted: (_) => _postComment(), // 엔터 키로도 전송 가능
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isPostingComment ? null : _postComment,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: _isPostingComment
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(
                        Icons.send,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCommentItem(FeedComment comment) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: comment.userId,
                    username: comment.username,
                    profileImage: comment.fullProfileImageUrl,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 12,
                backgroundImage: comment.fullProfileImageUrl.isNotEmpty
                    ? NetworkImage(comment.fullProfileImageUrl)
                    : null,
                child: comment.fullProfileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 16)
                    : null,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          userId: comment.userId,
                          username: comment.username,
                          profileImage: comment.fullProfileImageUrl,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: comment.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: themeProvider.textColor,
                            ),
                          ),
                          TextSpan(
                            text: ' ${comment.content}',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2),
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    _timeAgo(comment.createdAt),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: widget.feed.userId,
          username: widget.feed.username,
          profileImage: widget.feed.fullProfileImageUrl,
        ),
      ),
    );
  }

  // 위치를 전체 화면 지도에서 보기
  void _showLocationOnMap() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: Container(
            height: 500,
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getLocationText(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // 인터랙티브 지도 영역
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: MapWidget(
                      key: ValueKey("location-map-${widget.feed.id}"),
                      cameraOptions: CameraOptions(
                        center: Point(
                            coordinates: Position(
                                widget.feed.longitude,
                                widget.feed.latitude
                            )
                        ),
                        zoom: 15.0,
                      ),
                      onMapCreated: (MapboxMap mapboxMap) {
                        _addMarkerToMap(mapboxMap);
                      },
                    ),
                  ),
                ),
                // 좌표 정보
                Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "${widget.feed.latitude.toStringAsFixed(6)}, ${widget.feed.longitude.toStringAsFixed(6)}",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.pan_tool, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "Drag to explore",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 지도에 마커 추가
  Future<void> _addMarkerToMap(MapboxMap mapboxMap) async {
    try {
      await mapboxMap.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: true,
          pinchToZoomEnabled: true,
          scrollEnabled: true,
          doubleTapToZoomInEnabled: true,
        ),
      );

      // 썸네일 이미지 다운로드
      Uint8List? imageData = await _downloadImage(widget.feed.fullThumbnailUrl);
      if (imageData == null) return;

      // 테두리 추가
      Uint8List borderedImage = await _addBorderToImage(imageData);

      // 마커 생성
      final pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      final pointAnnotation = PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(widget.feed.longitude, widget.feed.latitude)
        ),
        image: borderedImage,
        iconSize: 1.0, // my_map과 동일
      );

      await pointAnnotationManager.create(pointAnnotation);
      print("[SUCCESS] 썸네일 마커 추가 완료");

    } catch (e) {
      print("[ERROR] 썸네일 마커 추가 실패: $e");
    }
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("[ERROR] 다운로드 실패 - 상태 코드: ${response.statusCode}");
      }
    } catch (e) {
      print("[ERROR] 이미지 다운로드 오류 상세: $e");
    }
    return null;
  }


  Future<Uint8List> _addBorderToImage(Uint8List imageBytes) async {
    final int size = 170;
    final int photoSize = 150;
    final double borderWidth = 7.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final double photoLeft = (size - photoSize) / 2;
    final double photoTop = (size - photoSize) / 2;

    final Paint borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(photoLeft - borderWidth, photoTop - borderWidth,
            photoSize + (borderWidth * 2), photoSize + (borderWidth * 2)),
        Radius.circular(8),
      ),
      borderPaint,
    );

    double srcWidth = frameInfo.image.width.toDouble();
    double srcHeight = frameInfo.image.height.toDouble();
    double srcX = 0;
    double srcY = 0;

    if (srcWidth > srcHeight) {
      srcX = (srcWidth - srcHeight) / 2;
      srcWidth = srcHeight;
    } else if (srcHeight > srcWidth) {
      srcY = (srcHeight - srcWidth) / 2;
      srcHeight = srcWidth;
    }

    final Rect srcRect = Rect.fromLTWH(srcX, srcY, srcWidth, srcHeight);
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble());

    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // 대안 마커 추가 방법
  Future<void> _addAlternativeMarker(MapboxMap mapboxMap) async {
    try {
      final pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

      // 더 간단한 마커 설정
      final pointAnnotation = PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(
                widget.feed.longitude,
                widget.feed.latitude
            )
        ),
        textField: "📍",
        textSize: 24.0,
        textColor: Colors.red.value,
      );

      await pointAnnotationManager.create(pointAnnotation);
      print("[INFO] 대안 마커가 추가되었습니다.");
    } catch (e) {
      print("[ERROR] 대안 마커 추가도 실패: $e");
    }
  }

  // Mapbox Static Images API URL 생성 (오버로드)
  String _getMapboxStaticImageUrl({int zoom = 14, int width = 400, int height = 200}) {
    const String accessToken = String.fromEnvironment("ACCESS_TOKEN", defaultValue: "pk.eyJ1IjoiY3Nkc2FkYXMiLCJhIjoiY2x4eDB2djJmMDhrcjJtcHhzeWFibHIxMiJ9.yU0tLrRdgUTv5xNj-ug9Ww");
    final double lng = widget.feed.longitude;
    final double lat = widget.feed.latitude;

    // 마커 추가 (빨간 핀)
    final String marker = "pin-s+ff0000($lng,$lat)";

    return "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/$marker/$lng,$lat,$zoom/${width}x$height?access_token=$accessToken";
  }

  // 위치 텍스트 생성
  String _getLocationText() {
    // extra_data에서 location_name 가져오기
    if (widget.feed.extraData.containsKey('location_name') &&
        widget.feed.extraData['location_name'] != null &&
        widget.feed.extraData['location_name'].isNotEmpty) {
      return widget.feed.extraData['location_name'];
    }

    // country_code가 있으면 사용
    if (widget.feed.countryCode.isNotEmpty && widget.feed.countryCode != 'UNKNOWN') {
      return widget.feed.countryCode;
    }

    // 좌표로 대체
    return "${widget.feed.latitude.toStringAsFixed(3)}, ${widget.feed.longitude.toStringAsFixed(3)}";
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'just now';
    }
  }
}