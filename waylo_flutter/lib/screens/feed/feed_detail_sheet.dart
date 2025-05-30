// lib/screen/feed/feed_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/models/feed_comment.dart';
import 'package:waylo_flutter/providers/feed_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/providers/theme_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:intl/intl.dart';
import 'package:waylo_flutter/screens/profile/user_profile_page.dart';

class FeedDetailSheet extends StatefulWidget {
  final Feed feed;
  final Function(Feed) onEditPressed;
  final bool showEditButton; // 수정 버튼 표시 여부를 제어하는 새 프로퍼티

  const FeedDetailSheet({
    Key? key,
    required this.feed,
    required this.onEditPressed,
    this.showEditButton = true, // 기본값은 true로 설정
  }) : super(key: key);

  @override
  _FeedDetailSheetState createState() => _FeedDetailSheetState();
}

class _FeedDetailSheetState extends State<FeedDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode(); // 추가: 댓글 입력 FocusNode
  late ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러 추가
  List<FeedComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likesCount = 0;
  int _bookmarksCount = 0;
  String? _currentUserId; // 현재 로그인한 사용자 ID
  String? _replyingToCommentId; // 대댓글 작성 시 부모 댓글 ID 저장
  String? _replyingToUsername; // 대댓글 대상 사용자 이름 저장

  @override
  void initState() {
    super.initState();
    _initFeedState();
    _refreshFeedDetails();
    _loadComments();
    _loadCurrentUserId();
  }

  // 현재 사용자 ID 가져오기
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await ApiService.getUserId();
    setState(() {});
  }

  // 피드 상세 정보 새로고침 함수
  Future<void> _refreshFeedDetails() async {
    try {
      final response = await FeedApi.fetchFeedDetail(widget.feed.id);

      if (response != null && !response.containsKey('error')) {
        final updatedFeed = Feed.fromJson(response);
        if (mounted) {
          setState(() {
            _isLiked = updatedFeed.isLiked;
            _likesCount = updatedFeed.likesCount;
            _isBookmarked = updatedFeed.isBookmarked;
            _bookmarksCount = updatedFeed.bookmarksCount;
          });
        }
      }
    } catch (e) {
      print("[ERROR] 피드 상세 정보 새로고침 중 오류 발생: $e");
    }
  }

  void _initFeedState() {
    setState(() {
      _isLiked = widget.feed.isLiked;
      _isBookmarked = widget.feed.isBookmarked;
      _likesCount = widget.feed.likesCount;
      _bookmarksCount = widget.feed.bookmarksCount;
    });
  }

  // 댓글 로드 함수
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final response = await FeedApi.fetchFeedComments(widget.feed.id);

      if (response is Map && response.containsKey('comments')) {
        List<dynamic> commentsData = response['comments'];
        setState(() {
          _comments =
              commentsData.map((data) => FeedComment.fromJson(data)).toList();
        });
      }
    } catch (e) {
      print("[ERROR] 댓글 로드 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("댓글을 불러오는 중 오류가 발생했습니다.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 사용자가 피드 작성자인지 확인
    bool isOwner = _currentUserId != null &&
        _currentUserId == widget.feed.userId;

    // 수정 버튼을 표시할지 여부 (showEditButton 프로퍼티 및 소유자 여부에 따라 결정)
    bool showEdit = widget.showEditButton && isOwner;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        // 스크롤 컨트롤러 업데이트
        _scrollController = scrollController;

        return Container(
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: themeProvider.secondaryTextColor,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // 피드 내용 스크롤 영역
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // 헤더 부분 (사용자 정보 및 수정 버튼)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          // 프로필 이미지를 GestureDetector로 감싸기
                          GestureDetector(
                            onTap: () {
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
                            },
                            child: CircleAvatar(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 사용자 이름을 GestureDetector로 감싸기
                                GestureDetector(
                                  onTap: () {
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
                                  },
                                  child: Text(
                                    widget.feed.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: themeProvider.textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.feed.photoTakenAt != null
                                      ? _formatDate(widget.feed.photoTakenAt!)
                                      : "No photo date available",
                                  style: TextStyle(color: themeProvider.secondaryTextColor,),
                                ),
                              ],
                            ),
                          ),
                          // 수정 버튼 (조건부 표시)
                          if (showEdit)
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                // 바텀 시트 닫기
                                Navigator.pop(context);
                                // 수정 기능 호출
                                widget.onEditPressed(widget.feed);
                              },
                              tooltip: 'Edit feed',
                            ),
                        ],
                      ),
                    ),

                    // 이미지
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.feed.fullImageUrl,
                          fit: BoxFit.contain, // 이미지 비율 유지
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              height: 300,
                              child: Center(
                                child: Icon(Icons.image_not_supported, size: 50,
                                    color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 액션 버튼 (좋아요, 북마크)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // 좋아요 버튼
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _isLiked ? Icons.favorite : Icons
                                      .favorite_border,
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
                          SizedBox(width: 20),
                          // 북마크 버튼
                          GestureDetector(
                            onTap: _toggleBookmark,
                            child: Row(
                              children: [
                                Icon(
                                  _isBookmarked ? Icons.bookmark : Icons
                                      .bookmark_border,
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
                        ],
                      ),
                    ),

                    // 피드 내용
                    if (widget.feed.description.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          widget.feed.description,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                    // 댓글 섹션 헤더
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 댓글 로딩 인디케이터
                    if (_isLoadingComments)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // 댓글 목록
                    if (!_isLoadingComments && _comments.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    if (!_isLoadingComments && _comments.isNotEmpty)
                      ...List.generate(
                        _comments.length,
                            (index) => _buildCommentItem(_comments[index]),
                      ),

                    // 여백 추가
                    SizedBox(height: 80), // 댓글 입력 필드를 위한 하단 여백
                  ],
                ),
              ),

              // 댓글 입력 부분
              Container(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
                child: Material(
                  elevation: 5.0,
                  shadowColor: Colors.grey.withOpacity(0.5),
                  color: themeProvider.isDarkMode ? Color(0xFF3E3E3E) : Colors.white, // 하드코딩된 white 대신 테마의 배경색 사용
                  borderRadius: BorderRadius.circular(8), // 모서리를 둥글게 해서 더 보기 좋게 만듦
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 대댓글 작성 중일 때 상단에 표시
                      if (_replyingToUsername != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100], // 다크모드에 맞춰 색상 조정
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to ${_replyingToUsername}',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 16, color: themeProvider.iconColor), // 테마 아이콘 색상 사용
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _replyingToCommentId = null;
                                    _replyingToUsername = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          // 현재 사용자 프로필 이미지
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: userProvider.profileImage.isNotEmpty
                                      ? NetworkImage(userProvider.profileImage)
                                      : null,
                                  child: userProvider.profileImage.isEmpty
                                      ? Icon(Icons.person, size: 20)
                                      : null,
                                  backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300], // 다크모드에 맞게 조정
                                ),
                              );
                            },
                          ),
                          // 댓글 입력 필드
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              decoration: InputDecoration(
                                hintText: _replyingToUsername != null
                                    ? 'Reply to ${_replyingToUsername}'
                                    : 'Add a comment...',
                                hintStyle: TextStyle(color: themeProvider.secondaryTextColor), // 힌트 텍스트 색상 테마에 맞게 조정
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(color: themeProvider.textColor), // 입력 텍스트 색상 테마에 맞게 조정
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                          // 게시 버튼
                          Container(
                            margin: EdgeInsets.only(right: 8.0),
                            child: _isPostingComment
                                ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : IconButton(
                              icon: Icon(Icons.send, color: AppColors.primary),
                              onPressed: _postComment,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLike() async {
    try {
      Map<String, dynamic> response;

      if (_isLiked) {
        response = await FeedApi.unlikeFeed(widget.feed.id);
      } else {
        response = await FeedApi.likeFeed(widget.feed.id);
      }

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      setState(() {
        _isLiked = !_isLiked;
        _likesCount = response['likes_count'] ?? _likesCount;
      });
    } catch (e) {
      print("[ERROR] 좋아요 토글 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while processing the like.")),
        );
      }
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      Map<String, dynamic> response;

      if (_isBookmarked) {
        response = await FeedApi.unbookmarkFeed(widget.feed.id);
      } else {
        response = await FeedApi.bookmarkFeed(widget.feed.id);
      }

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
        _bookmarksCount = response['bookmarks_count'] ?? _bookmarksCount;
      });
    } catch (e) {
      print("[ERROR] 북마크 토글 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while processing the bookmark.")),
        );
      }
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
      // API 호출 시 부모 댓글 ID 전달 (있는 경우)
      final response = await FeedApi.createComment(
          widget.feed.id,
          comment,
          parentId: _replyingToCommentId
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // 댓글 추가 성공
      _commentController.clear();

      // 대댓글 모드 초기화
      setState(() {
        _replyingToCommentId = null;
        _replyingToUsername = null;
      });

      // 댓글 목록 새로고침
      await _loadComments();
    } catch (e) {
      print("[ERROR] 댓글 작성 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while posting the comment.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  // _buildRichTextComment 메서드 수정
  Widget _buildRichTextComment(String content, double fontSize) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    RegExp mentionRegex = RegExp(r'@([a-zA-Z0-9._]+)');
    List<TextSpan> textSpans = [];
    int currentPos = 0;

    for (Match match in mentionRegex.allMatches(content)) {
      if (match.start > currentPos) {
        textSpans.add(
          TextSpan(
            text: content.substring(currentPos, match.start),
            style: TextStyle(fontSize: fontSize, color: themeProvider.textColor), // 테마 색상 사용
          ),
        );
      }

      textSpans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      currentPos = match.end;
    }

    if (currentPos < content.length) {
      textSpans.add(
        TextSpan(
          text: content.substring(currentPos),
          style: TextStyle(fontSize: fontSize, color: themeProvider.textColor), // 테마 색상 사용
        ),
      );
    }

    return RichText(
      text: TextSpan(children: textSpans),
    );
  }

  // 대댓글 입력 모드 설정 함수 추가
  void _showReplyInput(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
      _commentController.text = '@$username '; // 입력 필드에 @username 추가
    });

    // 입력 필드에 포커스
    _commentFocusNode.requestFocus();

    // 커서를 @username 뒤에 위치시키기
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    // 입력 필드로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildCommentItem(FeedComment comment) {
    // 현재 사용자가 댓글 작성자인지 확인
    final bool isCommentOwner = _currentUserId == comment.userId;
    // 현재 사용자가 피드 작성자인지 확인
    final bool isFeedOwner = _currentUserId == widget.feed.userId;
    // 삭제 권한 여부 (자신의 댓글이거나 자신의 피드인 경우)
    final bool canDelete = isCommentOwner || isFeedOwner;

    // 댓글 위젯
    Widget commentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지에 GestureDetector 추가
              GestureDetector(
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
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.fullProfileImageUrl.isNotEmpty
                      ? NetworkImage(comment.fullProfileImageUrl)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: comment.fullProfileImageUrl.isEmpty
                      ? Icon(Icons.person, size: 18)
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 사용자 이름에 GestureDetector 추가
                        GestureDetector(
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
                          child: Text(
                            comment.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _timeAgo(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    _buildRichTextComment(comment.content, 14),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(comment),
                          child: Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: comment.isLiked ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${comment.likesCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 16),
                        // 대댓글 버튼 추가
                        GestureDetector(
                          onTap: () {
                            _showReplyInput(comment.id, comment.username);
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 삭제 버튼
              // if (canDelete)
              //   IconButton(
              //     icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              //     onPressed: () => _deleteComment(comment.id),
              //     padding: EdgeInsets.all(4),
              //     constraints: BoxConstraints(),
              //   ),
            ],
          ),
        ),

        // 대댓글 목록 표시
        if (comment.replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 44, top: 0, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comment.replies.map((reply) => _buildReplyItem(reply))
                  .toList(),
            ),
          ),
      ],
    );

    // 삭제 기능이 있는 경우 Dismissible 위젯으로 감싸기
    if (canDelete) {
      return Dismissible(
        key: ObjectKey(comment.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          // 대댓글이 있는 경우 별도 처리
          if (comment.replies.isNotEmpty) {
            return await showDialog<bool>(
              context: context,
              builder: (context) =>
                  AlertDialog(
                    title: Text('Delete comment'),
                    content: Text(
                        'This comment has replies. Deleting it will also delete all replies. Do you want to continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
            ) ?? false;
          }

          // 일반 댓글 삭제 확인
          return await showDialog<bool>(
            context: context,
            builder: (context) =>
                AlertDialog(
                  title: Text('Delete comment'),
                  content: Text('Do you want to delete this comment?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
          ) ?? false;
        },
        onDismissed: (direction) {
          _deleteComment(comment.id);
        },
        child: commentWidget,
      );
    }

    return commentWidget;
  }

  Widget _buildReplyItem(FeedComment reply) {
    final bool isReplyOwner = _currentUserId == reply.userId;
    final bool isFeedOwner = _currentUserId == widget.feed.userId;
    final bool canDelete = isReplyOwner || isFeedOwner;

    Widget replyWidget = Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지에 GestureDetector 추가
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: reply.userId,
                    username: reply.username,
                    profileImage: reply.fullProfileImageUrl,
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 12,
              backgroundImage: reply.fullProfileImageUrl.isNotEmpty
                  ? NetworkImage(reply.fullProfileImageUrl)
                  : null,
              backgroundColor: Colors.grey[300],
              child: reply.fullProfileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 12)
                  : null,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 사용자 이름에 GestureDetector 추가
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userId: reply.userId,
                              username: reply.username,
                              profileImage: reply.fullProfileImageUrl,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        reply.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _timeAgo(reply.createdAt),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                _buildRichTextComment(reply.content, 13),
                SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(reply),
                      child: Icon(
                        reply.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: reply.isLiked ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${reply.likesCount}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    // 여기에 대댓글에 대한 Reply 버튼 추가
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        _showReplyInput(reply.parentId!, reply.username);
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // 삭제 권한이 있는 경우 Dismissible로 감싸기
    if (canDelete) {
      return Dismissible(
        key: ObjectKey(reply.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Delete reply'),
              content: Text('Do you want to delete this reply?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) {
          _deleteComment(reply.id);
        },
        child: replyWidget,
      );
    }

    return replyWidget;
  }

  // 댓글 삭제 메서드 수정
  Future<void> _deleteComment(String commentId) async {
    try {
      Map<String, dynamic> response = await FeedApi.deleteComment(commentId);

      if (response.containsKey('error')) {
        // 오류 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete comment: ${response['error']}")),
          );
        }
        return;
      }

      // 성공적으로 삭제됨 - 로컬 상태에서 댓글 또는 답글 제거
      setState(() {
        // 메인 댓글인지 확인
        bool foundMainComment = false;
        for (int i = 0; i < _comments.length; i++) {
          if (_comments[i].id == commentId) {
            // 메인 댓글 삭제
            _comments.removeAt(i);
            foundMainComment = true;
            break;
          }
        }

        // 메인 댓글이 아니라면 답글 중에서 찾기
        if (!foundMainComment) {
          for (int i = 0; i < _comments.length; i++) {
            List<FeedComment> replies = _comments[i].replies;
            for (int j = 0; j < replies.length; j++) {
              if (replies[j].id == commentId) {
                // 답글 찾음 - 해당 답글만 삭제
                List<FeedComment> updatedReplies = List.from(replies);
                updatedReplies.removeAt(j);

                // 업데이트된 답글 목록으로 부모 댓글 갱신
                _comments[i] = FeedComment(
                  id: _comments[i].id,
                  feedId: _comments[i].feedId,
                  userId: _comments[i].userId,
                  username: _comments[i].username,
                  profileImage: _comments[i].profileImage,
                  content: _comments[i].content,
                  createdAt: _comments[i].createdAt,
                  likesCount: _comments[i].likesCount,
                  isLiked: _comments[i].isLiked,
                  parentId: _comments[i].parentId,
                  replies: updatedReplies, // 업데이트된 답글 목록
                );
                break;
              }
            }
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Comment deleted successfully.")),
        );
      }
    } catch (e) {
      print("[ERROR] 댓글 삭제 중 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while deleting the comment.")),
        );
      }
    }
  }

  // 댓글 좋아요 토글
  Future<void> _toggleCommentLike(FeedComment comment) async {
    try {
      Map<String, dynamic> response;

      if (comment.isLiked) {
        // 좋아요 취소
        response = await FeedApi.unlikeComment(comment.id);
      } else {
        // 좋아요 추가
        response = await FeedApi.likeComment(comment.id);
      }

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // 로컬 상태 업데이트 (새로고침 대신)
      setState(() {
        // 메인 댓글인지 답글인지 확인
        bool isMainComment = comment.parentId == null;

        if (isMainComment) {
          // 메인 댓글인 경우
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            // 댓글 객체 업데이트
            _comments[index] = FeedComment(
              id: comment.id,
              feedId: comment.feedId,
              userId: comment.userId,
              username: comment.username,
              profileImage: comment.profileImage,
              content: comment.content,
              createdAt: comment.createdAt,
              likesCount: response['likes_count'] ??
                  (comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1),
              isLiked: !comment.isLiked,
              parentId: comment.parentId,
              replies: comment.replies, // 대댓글 목록 유지
            );
          }
        } else {
          // 답글인 경우 - 부모 댓글을 찾아서 그 안의 replies 배열을 수정
          for (int i = 0; i < _comments.length; i++) {
            int replyIndex = _comments[i].replies.indexWhere((r) => r.id == comment.id);
            if (replyIndex != -1) {
              // 해당 답글의 부모 댓글을 찾음
              List<FeedComment> updatedReplies = List.from(_comments[i].replies);
              // 답글 객체 업데이트
              updatedReplies[replyIndex] = FeedComment(
                id: comment.id,
                feedId: comment.feedId,
                userId: comment.userId,
                username: comment.username,
                profileImage: comment.profileImage,
                content: comment.content,
                createdAt: comment.createdAt,
                likesCount: response['likes_count'] ??
                    (comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1),
                isLiked: !comment.isLiked,
                parentId: comment.parentId,
                replies: [], // 대댓글의 대댓글은 없음
              );

              // 부모 댓글 객체 업데이트
              _comments[i] = FeedComment(
                id: _comments[i].id,
                feedId: _comments[i].feedId,
                userId: _comments[i].userId,
                username: _comments[i].username,
                profileImage: _comments[i].profileImage,
                content: _comments[i].content,
                createdAt: _comments[i].createdAt,
                likesCount: _comments[i].likesCount,
                isLiked: _comments[i].isLiked,
                parentId: _comments[i].parentId,
                replies: updatedReplies, // 업데이트된 답글 목록
              );
              break;
            }
          }
        }
      });
    } catch (e) {
      print("[ERROR] 댓글 좋아요 토글 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while processing the comment like.")),
        );
      }
    }
  }

  // 날짜 포맷팅 (DD/MM/YYYY)
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // 상대적 시간 표시 (예: "2 hours ago")
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

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose(); // 추가: FocusNode 해제
    super.dispose();
  }
}