import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/models/feed_comment.dart';
import 'package:waylo_flutter/providers/feed_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:intl/intl.dart';

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
  List<FeedComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likesCount = 0;
  int _bookmarksCount = 0;
  String? _currentUserId; // 현재 로그인한 사용자 ID

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
          _comments = commentsData.map((data) => FeedComment.fromJson(data)).toList();
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
    bool isOwner = _currentUserId != null && _currentUserId == widget.feed.userId;

    // 수정 버튼을 표시할지 여부 (showEditButton 프로퍼티 및 소유자 여부에 따라 결정)
    bool showEdit = widget.showEditButton && isOwner;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
                    color: Colors.grey[300],
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
                          CircleAvatar(
                            backgroundImage: widget.feed.fullProfileImageUrl.isNotEmpty
                                ? NetworkImage(widget.feed.fullProfileImageUrl)
                                : null,
                            child: widget.feed.fullProfileImageUrl.isEmpty
                                ? Icon(Icons.person)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.feed.username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  widget.feed.photoTakenAt != null
                                      ? _formatDate(widget.feed.photoTakenAt!)
                                      : "No photo date available",
                                  style: TextStyle(color: Colors.grey[600]),
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
                                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 액션 버튼 (좋아요, 북마크)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // 좋아요 버튼
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.black,
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
                                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: _isBookmarked ? AppColors.primary : Colors.black,
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

              // 댓글 입력 부분 (하단 고정)
              Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
                child: Material(
                  elevation: 5.0,
                  shadowColor: Colors.grey.withOpacity(0.5),
                  color: Colors.white,
                  child: Row(
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
                              backgroundColor: Colors.grey[300],
                            ),
                          );
                        },
                      ),
                      // 댓글 입력 필드
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode, // 추가: FocusNode 연결
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
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
          SnackBar(content: Text("좋아요 처리 중 오류가 발생했습니다.")),
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
          SnackBar(content: Text("북마크 처리 중 오류가 발생했습니다.")),
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
      final response = await FeedApi.createComment(widget.feed.id, comment);

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // 댓글 추가 성공
      _commentController.clear();

      // 댓글 목록 새로고침
      await _loadComments();

    } catch (e) {
      print("[ERROR] 댓글 작성 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("댓글을 작성하는 중 오류가 발생했습니다.")),
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

  Widget _buildCommentItem(FeedComment comment) {
    // 현재 사용자가 댓글 작성자인지 확인
    final bool isCommentOwner = _currentUserId == comment.userId;
    // 현재 사용자가 피드 작성자인지 확인
    final bool isFeedOwner = _currentUserId == widget.feed.userId;
    // 삭제 권한 여부 (자신의 댓글이거나 자신의 피드인 경우)
    final bool canDelete = isCommentOwner || isFeedOwner;

    // 삭제 권한이 없으면 일반 댓글 아이템 반환
    if (!canDelete) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: comment.fullProfileImageUrl.isNotEmpty
                  ? NetworkImage(comment.fullProfileImageUrl)
                  : null,
              backgroundColor: Colors.grey[300],
              child: comment.fullProfileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 18)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                  Text(comment.content),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment),
                        child: Icon(
                          comment.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: comment.isLiked ? Colors.red : Colors.grey,
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 삭제 권한이 있는 경우 Dismissible 위젯으로 감싸기
    return Dismissible(
      key: ObjectKey(comment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // 댓글 삭제 전 포커스 제거
        _commentFocusNode.unfocus();

        // 삭제 확인 다이얼로그
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Comment'),
            content: Text('Are you sure you want to delete this comment?'),
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

        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
        });
        // 댓글 삭제 API 호출
        _deleteComment(comment.id);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: comment.fullProfileImageUrl.isNotEmpty
                  ? NetworkImage(comment.fullProfileImageUrl)
                  : null,
              backgroundColor: Colors.grey[300],
              child: comment.fullProfileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 18)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                  Text(comment.content),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment),
                        child: Icon(
                          comment.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: comment.isLiked ? Colors.red : Colors.grey,
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

      // 성공적으로 삭제됨 - 로컬 상태에서 댓글 제거 (API 호출 대신)
      setState(() {
        _comments.removeWhere((comment) => comment.id == commentId);
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
        // 댓글 목록에서 해당 댓글 찾기
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
              likesCount: response['likes_count'] ?? (comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1),
              isLiked: !comment.isLiked
          );
        }
      });
    } catch (e) {
      print("[ERROR] 댓글 좋아요 토글 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("댓글 좋아요 처리 중 오류가 발생했습니다.")),
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