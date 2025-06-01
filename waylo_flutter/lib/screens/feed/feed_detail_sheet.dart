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
  // 텍스트 상수들
  static const String _commentsTitle = 'Comments';
  static const String _noCommentsText = 'No comments yet';
  static const String _addCommentHint = 'Add a comment...';
  static const String _replyToPrefix = 'Reply to ';
  static const String _replyingToPrefix = 'Replying to ';
  static const String _editFeedTooltip = 'Edit feed';
  static const String _noPhotoDateText = "No photo date available";
  static const String _replyText = 'Reply';
  static const String _deleteCommentTitle = 'Delete comment';
  static const String _deleteReplyTitle = 'Delete reply';
  static const String _deleteCommentWithRepliesContent = 'This comment has replies. Deleting it will also delete all replies. Do you want to continue?';
  static const String _deleteCommentContent = 'Do you want to delete this comment?';
  static const String _deleteReplyContent = 'Do you want to delete this reply?';
  static const String _cancelButtonText = 'Cancel';
  static const String _deleteButtonText = 'Delete';

  // 에러 메시지 상수들
  static const String _loadCommentsError = "Failed to load comments.";
  static const String _likeError = "An error occurred while processing the like.";
  static const String _bookmarkError = "An error occurred while processing the bookmark.";
  static const String _postCommentError = "An error occurred while posting the comment.";
  static const String _deleteCommentFailedPrefix = "Failed to delete comment: ";
  static const String _deleteCommentError = "An error occurred while deleting the comment.";
  static const String _commentLikeError = "An error occurred while processing the comment like.";

  // 성공 메시지 상수들
  static const String _commentDeletedSuccess = "Comment deleted successfully.";

  // API 키 상수들
  static const String _errorKey = 'error';
  static const String _commentsKey = 'comments';
  static const String _likesCountKey = 'likes_count';
  static const String _bookmarksCountKey = 'bookmarks_count';

  // 시간 단위 상수들
  static const String _yearUnit = 'y';
  static const String _monthUnit = 'mo';
  static const String _weekUnit = 'w';
  static const String _dayUnit = 'd';
  static const String _hourUnit = 'h';
  static const String _minuteUnit = 'm';
  static const String _justNowText = 'just now';

  // 날짜 포맷 상수들
  static const String _dateFormat = 'dd/MM/yyyy';

  // 폰트 크기 상수들
  static const double _usernameFontSize = 16;
  static const double _commentsFontSize = 16;
  static const double _descriptionFontSize = 16;
  static const double _commentUsernameFontSize = 14;
  static const double _commentTimeFontSize = 12;
  static const double _commentTextFontSize = 14;
  static const double _commentLikeFontSize = 12;
  static const double _replyUsernameFontSize = 12;
  static const double _replyTimeFontSize = 10;
  static const double _replyTextFontSize = 13;
  static const double _replyLikeFontSize = 10;
  static const double _replyIndicatorFontSize = 12;

  // 크기 상수들
  static const double _sheetInitialSize = 0.5;
  static const double _sheetMinSize = 0.3;
  static const double _sheetMaxSize = 0.95;
  static const double _dragHandleWidth = 40;
  static const double _dragHandleHeight = 5;
  static const double _dragHandleRadius = 2.5;
  static const double _dragHandleVerticalMargin = 12;
  static const double _sheetBorderRadius = 24;
  static const double _shadowBlurRadius = 10;
  static const double _shadowOffsetY = -3;
  static const double _imageBorderRadius = 12;
  static const double _imageErrorHeight = 300;
  static const double _imageErrorIconSize = 50;
  static const double _actionIconSize = 24;
  static const double _commentIconSize = 16;
  static const double _replyIconSize = 14;
  static const double _userProfileRadius = 16;
  static const double _commentProfileRadius = 16;
  static const double _replyProfileRadius = 12;
  static const double _commentProfileIconSize = 18;
  static const double _replyProfileIconSize = 12;
  static const double _userInputProfileRadius = 16;
  static const double _userInputProfileIconSize = 20;
  static const double _loadingIndicatorSize = 24;
  static const double _loadingIndicatorStroke = 2;
  static const double _replyIndicatorIconSize = 16;

  // 패딩 및 마진 상수들
  static const double _headerHorizontalPadding = 16;
  static const double _headerVerticalPadding = 8;
  static const double _headerSpacing = 12;
  static const double _imageHorizontalMargin = 16;
  static const double _actionHorizontalPadding = 16;
  static const double _actionVerticalPadding = 8;
  static const double _actionItemSpacing = 4;
  static const double _actionButtonSpacing = 20;
  static const double _descriptionPadding = 16;
  static const double _commentsSectionPadding = 16;
  static const double _commentsSectionVerticalPadding = 8;
  static const double _commentsLoadingPadding = 16.0;
  static const double _commentItemHorizontalPadding = 16;
  static const double _commentItemVerticalPadding = 8;
  static const double _commentContentSpacing = 12;
  static const double _commentHeaderSpacing = 8;
  static const double _commentHeaderItemSpacing = 4;
  static const double _commentActionSpacing = 4;
  static const double _commentActionItemSpacing = 16;
  static const double _replyIndentLeft = 44;
  static const double _replyIndentTop = 0;
  static const double _replyIndentBottom = 8;
  static const double _replyItemVerticalPadding = 4;
  static const double _replyContentSpacing = 8;
  static const double _replyHeaderItemSpacing = 4;
  static const double _replyActionItemSpacing = 2;
  static const double _commentInputPaddingHorizontal = 12;
  static const double _commentInputPaddingVertical = 8;
  static const double _commentInputElevation = 5.0;
  static const double _commentInputBorderRadius = 8;
  static const double _replyIndicatorHorizontalPadding = 16;
  static const double _replyIndicatorVerticalPadding = 8;
  static const double _inputRowProfilePadding = 8.0;
  static const double _inputFieldHorizontalPadding = 16;
  static const double _inputFieldVerticalPadding = 12;
  static const double _sendButtonMargin = 8.0;
  static const double _bottomContentSpacing = 80;
  static const double _dismissibleHorizontalPadding = 20;

  // 애니메이션 상수들
  static const int _scrollAnimationDuration = 300;

  // 투명도 상수들
  static const double _shadowOpacity = 0.5;
  static const int _darkInputBackgroundColor = 0xFF3E3E3E;

  // 입력 필드 상수들
  static const int _inputMinLines = 1;
  static const int _inputMaxLines = 3;

  // 시간 계산 상수들
  static const int _daysInYear = 365;
  static const int _daysInMonth = 30;
  static const int _daysInWeek = 7;

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

      if (response != null && !response.containsKey(_errorKey)) {
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

      if (response is Map && response.containsKey(_commentsKey)) {
        List<dynamic> commentsData = response[_commentsKey];
        setState(() {
          _comments = commentsData.map((data) => FeedComment.fromJson(data)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_loadCommentsError)),
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
      initialChildSize: _sheetInitialSize,
      minChildSize: _sheetMinSize,
      maxChildSize: _sheetMaxSize,
      builder: (context, scrollController) {
        _scrollController = scrollController;

        return Container(
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_sheetBorderRadius),
              topRight: Radius.circular(_sheetBorderRadius),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: _shadowBlurRadius,
                offset: Offset(0, _shadowOffsetY),
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
                    const SizedBox(height: _bottomContentSpacing),
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
        margin: const EdgeInsets.symmetric(vertical: _dragHandleVerticalMargin),
        width: _dragHandleWidth,
        height: _dragHandleHeight,
        decoration: BoxDecoration(
          color: themeProvider.secondaryTextColor,
          borderRadius: BorderRadius.circular(_dragHandleRadius),
        ),
      ),
    );
  }

  /// 헤더 섹션 (사용자 정보 및 수정 버튼)
  Widget _buildHeader(ThemeProvider themeProvider, bool showEdit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _headerHorizontalPadding,
        0,
        _headerHorizontalPadding,
        _headerVerticalPadding,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(widget.feed.userId, widget.feed.username, widget.feed.fullProfileImageUrl),
            child: CircleAvatar(
              backgroundImage: widget.feed.fullProfileImageUrl.isNotEmpty
                  ? NetworkImage(widget.feed.fullProfileImageUrl)
                  : null,
              child: widget.feed.fullProfileImageUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          const SizedBox(width: _headerSpacing),
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
                      fontSize: _usernameFontSize,
                      color: themeProvider.textColor,
                    ),
                  ),
                ),
                Text(
                  widget.feed.photoTakenAt != null
                      ? _formatDate(widget.feed.photoTakenAt!)
                      : _noPhotoDateText,
                  style: TextStyle(color: themeProvider.secondaryTextColor),
                ),
              ],
            ),
          ),
          if (showEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                widget.onEditPressed(widget.feed);
              },
              tooltip: _editFeedTooltip,
            ),
        ],
      ),
    );
  }

  /// 이미지 섹션
  Widget _buildImage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _imageHorizontalMargin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_imageBorderRadius),
        child: Image.network(
          widget.feed.fullImageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: _imageErrorHeight,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              height: _imageErrorHeight,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: _imageErrorIconSize,
                  color: Colors.grey,
                ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: _actionHorizontalPadding,
        vertical: _actionVerticalPadding,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? AppColors.primary : themeProvider.iconColor,
                  size: _actionIconSize,
                ),
                const SizedBox(width: _actionItemSpacing),
                Text(
                  _likesCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: _actionButtonSpacing),
          GestureDetector(
            onTap: _toggleBookmark,
            child: Row(
              children: [
                Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? AppColors.primary : themeProvider.iconColor,
                  size: _actionIconSize,
                ),
                const SizedBox(width: _actionItemSpacing),
                Text(
                  _bookmarksCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
    if (widget.feed.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(_descriptionPadding),
      child: Text(
        widget.feed.description,
        style: const TextStyle(fontSize: _descriptionFontSize),
      ),
    );
  }

  /// 댓글 섹션 헤더
  Widget _buildCommentsSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        _commentsSectionPadding,
        _commentsSectionVerticalPadding,
        _commentsSectionPadding,
        _commentsSectionVerticalPadding,
      ),
      child: Text(
        _commentsTitle,
        style: TextStyle(
          fontSize: _commentsFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 댓글 내용 섹션
  Widget _buildCommentsContent() {
    if (_isLoadingComments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(_commentsLoadingPadding),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(_commentsLoadingPadding),
        child: Center(
          child: Text(
            _noCommentsText,
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
      padding: EdgeInsets.fromLTRB(
        _commentInputPaddingHorizontal,
        _commentInputPaddingVertical,
        _commentInputPaddingHorizontal,
        _commentInputPaddingVertical + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        elevation: _commentInputElevation,
        shadowColor: Colors.grey.withOpacity(_shadowOpacity),
        color: themeProvider.isDarkMode
            ? Color(_darkInputBackgroundColor)
            : Colors.white,
        borderRadius: BorderRadius.circular(_commentInputBorderRadius),
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
      padding: const EdgeInsets.symmetric(
        horizontal: _replyIndicatorHorizontalPadding,
        vertical: _replyIndicatorVerticalPadding,
      ),
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$_replyingToPrefix$_replyingToUsername',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: _replyIndicatorFontSize,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: _replyIndicatorIconSize,
              color: themeProvider.iconColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
              padding: const EdgeInsets.symmetric(horizontal: _inputRowProfilePadding),
              child: CircleAvatar(
                radius: _userInputProfileRadius,
                backgroundImage: userProvider.profileImage.isNotEmpty
                    ? NetworkImage(userProvider.profileImage)
                    : null,
                child: userProvider.profileImage.isEmpty
                    ? const Icon(Icons.person, size: _userInputProfileIconSize)
                    : null,
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.grey[700]
                    : Colors.grey[300],
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
                  ? '$_replyToPrefix$_replyingToUsername'
                  : _addCommentHint,
              hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: _inputFieldHorizontalPadding,
                vertical: _inputFieldVerticalPadding,
              ),
            ),
            style: TextStyle(color: themeProvider.textColor),
            minLines: _inputMinLines,
            maxLines: _inputMaxLines,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: _sendButtonMargin),
          child: _isPostingComment
              ? const SizedBox(
            width: _loadingIndicatorSize,
            height: _loadingIndicatorSize,
            child: CircularProgressIndicator(strokeWidth: _loadingIndicatorStroke),
          )
              : IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
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

      if (response.containsKey(_errorKey)) {
        throw Exception(response[_errorKey]);
      }

      setState(() {
        _isLiked = !_isLiked;
        _likesCount = response[_likesCountKey] ?? _likesCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_likeError)),
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

      if (response.containsKey(_errorKey)) {
        throw Exception(response[_errorKey]);
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
        _bookmarksCount = response[_bookmarksCountKey] ?? _bookmarksCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_bookmarkError)),
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

      if (response.containsKey(_errorKey)) {
        throw Exception(response[_errorKey]);
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
          const SnackBar(content: Text(_postCommentError)),
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
          duration: const Duration(milliseconds: _scrollAnimationDuration),
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
          padding: const EdgeInsets.symmetric(
            horizontal: _commentItemHorizontalPadding,
            vertical: _commentItemVerticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(comment.userId, comment.username, comment.fullProfileImageUrl),
                child: CircleAvatar(
                  radius: _commentProfileRadius,
                  backgroundImage: comment.fullProfileImageUrl.isNotEmpty
                      ? NetworkImage(comment.fullProfileImageUrl)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: comment.fullProfileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: _commentProfileIconSize)
                      : null,
                ),
              ),
              const SizedBox(width: _commentContentSpacing),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _commentUsernameFontSize,
                            ),
                          ),
                        ),
                        const SizedBox(width: _commentHeaderSpacing),
                        Text(
                          _timeAgo(comment.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: _commentTimeFontSize,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _commentHeaderItemSpacing),
                    _buildRichTextComment(comment.content, _commentTextFontSize),
                    const SizedBox(height: _commentHeaderItemSpacing),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(comment),
                          child: Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: _commentIconSize,
                            color: comment.isLiked ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: _commentActionSpacing),
                        Text(
                          '${comment.likesCount}',
                          style: const TextStyle(
                            fontSize: _commentLikeFontSize,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: _commentActionItemSpacing),
                        GestureDetector(
                          onTap: () => _showReplyInput(comment.id, comment.username),
                          child: const Text(
                            _replyText,
                            style: TextStyle(
                              fontSize: _commentLikeFontSize,
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
            padding: const EdgeInsets.only(
              left: _replyIndentLeft,
              top: _replyIndentTop,
              bottom: _replyIndentBottom,
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: _dismissibleHorizontalPadding),
          child: const Icon(Icons.delete, color: Colors.white),
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
          title: const Text(_deleteCommentTitle),
          content: const Text(_deleteCommentWithRepliesContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(_cancelButtonText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(_deleteButtonText, style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_deleteCommentTitle),
        content: const Text(_deleteCommentContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(_cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(_deleteButtonText, style: TextStyle(color: Colors.red)),
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
      padding: const EdgeInsets.symmetric(vertical: _replyItemVerticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(reply.userId, reply.username, reply.fullProfileImageUrl),
            child: CircleAvatar(
              radius: _replyProfileRadius,
              backgroundImage: reply.fullProfileImageUrl.isNotEmpty
                  ? NetworkImage(reply.fullProfileImageUrl)
                  : null,
              backgroundColor: Colors.grey[300],
              child: reply.fullProfileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: _replyProfileIconSize)
                  : null,
            ),
          ),
          const SizedBox(width: _replyContentSpacing),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _replyUsernameFontSize,
                        ),
                      ),
                    ),
                    const SizedBox(width: _replyHeaderItemSpacing),
                    Text(
                      _timeAgo(reply.createdAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: _replyTimeFontSize,
                      ),
                    ),
                  ],
                ),
                _buildRichTextComment(reply.content, _replyTextFontSize),
                const SizedBox(height: _replyActionItemSpacing),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(reply),
                      child: Icon(
                        reply.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: _replyIconSize,
                        color: reply.isLiked ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: _commentActionSpacing),
                    Text(
                      '${reply.likesCount}',
                      style: const TextStyle(
                        fontSize: _replyLikeFontSize,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: _commentActionItemSpacing),
                    GestureDetector(
                      onTap: () => _showReplyInput(reply.parentId!, reply.username),
                      child: const Text(
                        _replyText,
                        style: TextStyle(
                          fontSize: _replyLikeFontSize,
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
          padding: const EdgeInsets.symmetric(horizontal: _dismissibleHorizontalPadding),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(_deleteReplyTitle),
              content: const Text(_deleteReplyContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(_cancelButtonText),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(_deleteButtonText, style: TextStyle(color: Colors.red)),
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

      if (response.containsKey(_errorKey)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$_deleteCommentFailedPrefix${response[_errorKey]}")),
          );
        }
        return;
      }

      _removeCommentFromLocal(commentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_commentDeletedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_deleteCommentError)),
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

      if (response.containsKey(_errorKey)) {
        throw Exception(response[_errorKey]);
      }

      _updateCommentLikeStatus(comment, response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_commentLikeError)),
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
            likesCount: response[_likesCountKey] ??
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
              likesCount: response[_likesCountKey] ??
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
    return DateFormat(_dateFormat).format(date);
  }

  /// 상대적 시간 표시
  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays >= _daysInYear) {
      return '${(difference.inDays / _daysInYear).floor()}$_yearUnit';
    } else if (difference.inDays >= _daysInMonth) {
      return '${(difference.inDays / _daysInMonth).floor()}$_monthUnit';
    } else if (difference.inDays >= _daysInWeek) {
      return '${(difference.inDays / _daysInWeek).floor()}$_weekUnit';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}$_dayUnit';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}$_hourUnit';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}$_minuteUnit';
    } else {
      return _justNowText;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
}