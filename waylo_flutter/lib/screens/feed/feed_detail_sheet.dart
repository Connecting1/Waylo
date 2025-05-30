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
  final bool showEditButton;

  const FeedDetailSheet({
    Key? key,
    required this.feed,
    required this.onEditPressed,
    this.showEditButton = true,
  }) : super(key: key);

  @override
  _FeedDetailSheetState createState() => _FeedDetailSheetState();
}

class _FeedDetailSheetState extends State<FeedDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late ScrollController _scrollController = ScrollController();

  List<FeedComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likesCount = 0;
  int _bookmarksCount = 0;
  String? _currentUserId;
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _initFeedState();
    _refreshFeedDetails();
    _loadComments();
    _loadCurrentUserId();
  }

  /// 현재 사용자 ID 로드
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await ApiService.getUserId();
    setState(() {});
  }

  /// 피드 상세 정보 새로고침
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
      // 에러는 조용히 처리
    }
  }

  /// 피드 상태 초기화
  void _initFeedState() {
    setState(() {
      _isLiked = widget.feed.isLiked;
      _isBookmarked = widget.feed.isBookmarked;
      _likesCount = widget.feed.likesCount;
      _bookmarksCount = widget.feed.bookmarksCount;
    });
  }

  /// 댓글 목록 로드
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load comments.")),
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
    bool isOwner = _currentUserId != null && _currentUserId == widget.feed.userId;
    bool showEdit = widget.showEditButton && isOwner;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
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
              _buildDragHandle(themeProvider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildHeader(themeProvider, showEdit),
                    _buildImage(),
                    _buildActionButtons(themeProvider),
                    _buildDescription(),
                    _buildCommentsSection(),
                    _buildCommentsContent(),
                    SizedBox(height: 80),
                  ],
                ),
              ),
              _buildCommentInput(themeProvider),
            ],
          ),
        );
      },
    );
  }

  /// 드래그 핸들 위젯
  Widget _buildDragHandle(ThemeProvider themeProvider) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: themeProvider.secondaryTextColor,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  /// 헤더 섹션 (사용자 정보 및 수정 버튼)
  Widget _buildHeader(ThemeProvider themeProvider, bool showEdit) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(widget.feed.userId, widget.feed.username, widget.feed.fullProfileImageUrl),
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
                GestureDetector(
                  onTap: () => _navigateToProfile(widget.feed.userId, widget.feed.username, widget.feed.fullProfileImageUrl),
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
                  style: TextStyle(color: themeProvider.secondaryTextColor),
                ),
              ],
            ),
          ),
          if (showEdit)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                widget.onEditPressed(widget.feed);
              },
              tooltip: 'Edit feed',
            ),
        ],
      ),
    );
  }

  /// 이미지 섹션
  Widget _buildImage() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
              color: Colors.grey[200],
              height: 300,
              child: Center(
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 액션 버튼들 (좋아요, 북마크)
  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
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
          SizedBox(width: 20),
          GestureDetector(
            onTap: _toggleBookmark,
            child: Row(
              children: [
                Icon(
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
        ],
      ),
    );
  }

  /// 피드 설명 섹션
  Widget _buildDescription() {
    if (widget.feed.description.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        widget.feed.description,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  /// 댓글 섹션 헤더
  Widget _buildCommentsSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        'Comments',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 댓글 내용 섹션
  Widget _buildCommentsContent() {
    if (_isLoadingComments) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No comments yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _comments.map((comment) => _buildCommentItem(comment)).toList(),
    );
  }

  /// 댓글 입력 섹션
  Widget _buildCommentInput(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        elevation: 5.0,
        shadowColor: Colors.grey.withOpacity(0.5),
        color: themeProvider.isDarkMode ? Color(0xFF3E3E3E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToUsername != null) _buildReplyIndicator(themeProvider),
            _buildInputRow(themeProvider),
          ],
        ),
      ),
    );
  }

  /// 대댓글 인디케이터
  Widget _buildReplyIndicator(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Replying to $_replyingToUsername',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: themeProvider.iconColor),
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
    );
  }

  /// 입력 행
  Widget _buildInputRow(ThemeProvider themeProvider) {
    return Row(
      children: [
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
                backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
            );
          },
        ),
        Expanded(
          child: TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            decoration: InputDecoration(
              hintText: _replyingToUsername != null
                  ? 'Reply to $_replyingToUsername'
                  : 'Add a comment...',
              hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: themeProvider.textColor),
            minLines: 1,
            maxLines: 3,
          ),
        ),
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

  /// 좋아요 토글
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while processing the like.")),
        );
      }
    }
  }

  /// 북마크 토글
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while processing the bookmark.")),
        );
      }
    }
  }

  /// 댓글 작성
  Future<void> _postComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isPostingComment = true;
    });

    try {
      final response = await FeedApi.createComment(
          widget.feed.id,
          comment,
          parentId: _replyingToCommentId
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      _commentController.clear();

      setState(() {
        _replyingToCommentId = null;
        _replyingToUsername = null;
      });

      await _loadComments();
    } catch (e) {
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

  /// 대댓글 입력 모드 설정
  void _showReplyInput(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
      _commentController.text = '@$username ';
    });

    _commentFocusNode.requestFocus();

    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 댓글 아이템 위젯
  Widget _buildCommentItem(FeedComment comment) {
    final bool isCommentOwner = _currentUserId == comment.userId;
    final bool isFeedOwner = _currentUserId == widget.feed.userId;
    final bool canDelete = isCommentOwner || isFeedOwner;

    Widget commentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(comment.userId, comment.username, comment.fullProfileImageUrl),
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
                        GestureDetector(
                          onTap: () => _navigateToProfile(comment.userId, comment.username, comment.fullProfileImageUrl),
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
                        GestureDetector(
                          onTap: () => _showReplyInput(comment.id, comment.username),
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
            ],
          ),
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 44, top: 0, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comment.replies.map((reply) => _buildReplyItem(reply)).toList(),
            ),
          ),
      ],
    );

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
        confirmDismiss: (direction) => _confirmDeleteComment(comment),
        onDismissed: (direction) => _deleteComment(comment.id),
        child: commentWidget,
      );
    }

    return commentWidget;
  }

  /// 댓글 삭제 확인 다이얼로그
  Future<bool?> _confirmDeleteComment(FeedComment comment) async {
    if (comment.replies.isNotEmpty) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete comment'),
          content: Text('This comment has replies. Deleting it will also delete all replies. Do you want to continue?'),
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
      );
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    );
  }

  /// 대댓글 아이템 위젯
  Widget _buildReplyItem(FeedComment reply) {
    final bool isReplyOwner = _currentUserId == reply.userId;
    final bool isFeedOwner = _currentUserId == widget.feed.userId;
    final bool canDelete = isReplyOwner || isFeedOwner;

    Widget replyWidget = Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(reply.userId, reply.username, reply.fullProfileImageUrl),
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
                    GestureDetector(
                      onTap: () => _navigateToProfile(reply.userId, reply.username, reply.fullProfileImageUrl),
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
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showReplyInput(reply.parentId!, reply.username),
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
        onDismissed: (direction) => _deleteComment(reply.id),
        child: replyWidget,
      );
    }

    return replyWidget;
  }

  /// 멘션이 포함된 댓글 텍스트 렌더링
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
            style: TextStyle(fontSize: fontSize, color: themeProvider.textColor),
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
          style: TextStyle(fontSize: fontSize, color: themeProvider.textColor),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: textSpans),
    );
  }

  /// 댓글 삭제
  Future<void> _deleteComment(String commentId) async {
    try {
      Map<String, dynamic> response = await FeedApi.deleteComment(commentId);

      if (response.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete comment: ${response['error']}")),
          );
        }
        return;
      }

      _removeCommentFromLocal(commentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Comment deleted successfully.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while deleting the comment.")),
        );
      }
    }
  }

  /// 로컬 상태에서 댓글 제거
  void _removeCommentFromLocal(String commentId) {
    setState(() {
      bool foundMainComment = false;
      for (int i = 0; i < _comments.length; i++) {
        if (_comments[i].id == commentId) {
          _comments.removeAt(i);
          foundMainComment = true;
          break;
        }
      }

      if (!foundMainComment) {
        for (int i = 0; i < _comments.length; i++) {
          List<FeedComment> replies = _comments[i].replies;
          for (int j = 0; j < replies.length; j++) {
            if (replies[j].id == commentId) {
              List<FeedComment> updatedReplies = List.from(replies);
              updatedReplies.removeAt(j);

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
                replies: updatedReplies,
              );
              break;
            }
          }
        }
      }
    });
  }

  /// 댓글 좋아요 토글
  Future<void> _toggleCommentLike(FeedComment comment) async {
    try {
      Map<String, dynamic> response;

      if (comment.isLiked) {
        response = await FeedApi.unlikeComment(comment.id);
      } else {
        response = await FeedApi.likeComment(comment.id);
      }

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      _updateCommentLikeStatus(comment, response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while processing the comment like.")),
        );
      }
    }
  }

  /// 댓글 좋아요 상태 업데이트
  void _updateCommentLikeStatus(FeedComment comment, Map<String, dynamic> response) {
    setState(() {
      bool isMainComment = comment.parentId == null;

      if (isMainComment) {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
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
            replies: comment.replies,
          );
        }
      } else {
        for (int i = 0; i < _comments.length; i++) {
          int replyIndex = _comments[i].replies.indexWhere((r) => r.id == comment.id);
          if (replyIndex != -1) {
            List<FeedComment> updatedReplies = List.from(_comments[i].replies);
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
              replies: [],
            );

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
              replies: updatedReplies,
            );
            break;
          }
        }
      }
    });
  }

  /// 날짜 포맷팅 (DD/MM/YYYY)
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// 상대적 시간 표시
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
    _commentFocusNode.dispose();
    super.dispose();
  }
}