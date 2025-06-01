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
  // 텍스트 상수들
  static const String _appBarTitle = "Friends Feed";
  static const String _retryButtonText = "Retry";
  static const String _noFriendsPostsTitle = "No friends' posts yet";
  static const String _noFriendsPostsSubtitle = "Add friends to see their posts here!";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 16;
  static const double _noFriendsPostsTitleFontSize = 18;
  static const double _noFriendsPostsSubtitleFontSize = 14;

  // 크기 상수들
  static const double _errorIconSize = 64;
  static const double _noFriendsIconSize = 64;
  static const double _errorSpacing = 16;
  static const double _noFriendsSpacing = 16;
  static const double _noFriendsSubSpacing = 8;
  static const double _loadingIndicatorPadding = 16.0;

  // 페이지네이션 상수들
  static const int _initialPage = 1;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = _initialPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendsFeeds(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트 처리
  void _handleScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreFeeds();
    }
  }

  /// 친구 피드 로드
  Future<void> _loadFriendsFeeds({bool refresh = false}) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    if (refresh) {
      _currentPage = _initialPage;
    }
    await feedProvider.fetchFriendsFeeds(refresh: refresh, page: _currentPage);
  }

  /// 추가 피드 로드
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
          _appBarTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: _appBarTitleFontSize,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.friendsFeeds.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (feedProvider.errorMessage.isNotEmpty && feedProvider.friendsFeeds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: _errorIconSize, color: Colors.grey),
                  const SizedBox(height: _errorSpacing),
                  Text(feedProvider.errorMessage),
                  const SizedBox(height: _errorSpacing),
                  ElevatedButton(
                    onPressed: () => _loadFriendsFeeds(refresh: true),
                    child: const Text(_retryButtonText),
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
                  const Icon(Icons.people_outline, size: _noFriendsIconSize, color: Colors.grey),
                  const SizedBox(height: _noFriendsSpacing),
                  Text(
                    _noFriendsPostsTitle,
                    style: TextStyle(
                      fontSize: _noFriendsPostsTitleFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: _noFriendsSubSpacing),
                  const Text(
                    _noFriendsPostsSubtitle,
                    style: TextStyle(
                      fontSize: _noFriendsPostsSubtitleFontSize,
                      color: Colors.grey,
                    ),
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(_loadingIndicatorPadding),
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
  // 텍스트 상수들
  static const String _addCommentHint = 'Add a comment...';
  static const String _noCommentsText = 'No comments yet';
  static const String _locationText = 'Location';
  static const String _dragToExploreText = "Drag to explore";
  static const String _likeErrorMessage = 'An error occurred while processing like.';
  static const String _networkErrorMessage = 'A network error occurred.';
  static const String _bookmarkErrorMessage = 'An error occurred while processing bookmark.';
  static const String _commentErrorMessage = "An error occurred while posting comment.";
  static const String _unknownCountryCode = 'UNKNOWN';

  // 시간 단위 상수들
  static const String _yearUnit = 'y';
  static const String _monthUnit = 'mo';
  static const String _weekUnit = 'w';
  static const String _dayUnit = 'd';
  static const String _hourUnit = 'h';
  static const String _minuteUnit = 'm';
  static const String _nowText = 'now';
  static const String _justNowText = 'just now';

  // API 키 상수들
  static const String _errorKey = 'error';
  static const String _commentsKey = 'comments';
  static const String _likesCountKey = 'likes_count';
  static const String _bookmarksCountKey = 'bookmarks_count';
  static const String _locationNameKey = 'location_name';

  // 지도 관련 상수들
  static const String _accessTokenEnvKey = "ACCESS_TOKEN";
  static const String _defaultAccessToken = "pk.eyJ1IjoiY3Nkc2FkYXMiLCJhIjoiY2x4eDB2djJmMDhrcjJtcHhzeWFibHIxMiJ9.yU0tLrRdgUTv5xNj-ug9Ww";
  static const String _mapboxStaticBaseUrl = "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/";
  static const String _mapboxMarkerPrefix = "pin-s+ff0000(";
  static const String _mapboxMarkerSuffix = ")";
  static const String _mapboxAccessTokenParam = "?access_token=";
  static const double _defaultMapZoom = 15.0;
  static const int _defaultStaticMapZoom = 14;
  static const int _defaultStaticMapWidth = 400;
  static const int _defaultStaticMapHeight = 200;
  static const double _mapDialogHeight = 500;

  // 폰트 크기 상수들
  static const double _usernameFontSize = 16;
  static const double _dateFontSize = 12;
  static const double _descriptionFontSize = 14;
  static const double _locationDialogTitleFontSize = 16;
  static const double _coordinatesFontSize = 12;
  static const double _commentUsernameFontSize = 14;
  static const double _commentContentFontSize = 14;
  static const double _commentTimeFontSize = 12;

  // 크기 상수들
  static const double _cardVerticalMargin = 4;
  static const double _headerPadding = 12;
  static const double _headerVerticalPadding = 8;
  static const double _profileRadius = 20;
  static const double _profileSpacing = 12;
  static const double _actionsPadding = 16;
  static const double _actionsVerticalPadding = 8;
  static const double _actionsSpacing = 20;
  static const double _actionIconSize = 24;
  static const double _actionIconSpacing = 4;
  static const double _descriptionHorizontalPadding = 12;
  static const double _locationMapHeight = 120;
  static const double _locationMapMargin = 12;
  static const double _locationMapVerticalMargin = 8;
  static const double _locationMapBorderRadius = 12;
  static const double _locationOverlayPadding = 8;
  static const double _locationOverlayHorizontalPadding = 8;
  static const double _locationOverlayVerticalPadding = 4;
  static const double _locationIconSize = 16;
  static const double _locationIconSpacing = 4;
  static const double _fullscreenIconSize = 16;
  static const double _commentsPadding = 16;
  static const double _commentItemHorizontalPadding = 12;
  static const double _commentItemVerticalPadding = 4;
  static const double _commentProfileRadius = 12;
  static const double _commentProfileSpacing = 8;
  static const double _commentContentSpacing = 2;
  static const double _commentTimePadding = 4;
  static const double _commentInputPadding = 12;
  static const double _commentInputProfileRadius = 16;
  static const double _commentInputProfileSpacing = 12;
  static const double _commentInputBorderRadius = 20;
  static const double _commentInputHorizontalPadding = 16;
  static const double _commentInputVerticalPadding = 8;
  static const double _commentInputSpacing = 8;
  static const double _sendIconSize = 20;
  static const double _sendButtonPadding = 8;
  static const double _bottomSpacing = 8;
  static const double _imageLoadingHeight = 300;
  static const double _imageErrorIconSize = 50;
  static const double _loadingIndicatorSize = 24;
  static const double _loadingIndicatorStroke = 2;
  static const double _commentProfileIconSize = 16;
  static const double _commentInputProfileIconSize = 20;

  // 지도 다이얼로그 상수들
  static const double _mapDialogInsets = 20;
  static const double _mapDialogPadding = 16;
  static const double _mapDialogTitleSpacing = 8;
  static const double _mapDialogBottomPadding = 12;
  static const double _mapDialogCoordinatesSpacing = 4;
  static const double _mapDialogHintSpacing = 16;

  // 마커 이미지 상수들
  static const int _markerSize = 170;
  static const int _markerPhotoSize = 150;
  static const double _markerBorderWidth = 7.0;
  static const double _markerBorderRadius = 8;

  // 투명도 상수들
  static const double _loadingOpacity = 0.6;
  static const double _locationOverlayOpacity = 0.7;
  static const double _fullscreenOverlayOpacity = 0.5;

  // 시간 계산 상수들
  static const int _daysInYear = 365;
  static const int _daysInMonth = 30;
  static const int _daysInWeek = 7;

  // 좌표 표시 정밀도 상수들
  static const int _coordinateDecimalPlaces = 6;
  static const int _locationTextDecimalPlaces = 3;

  List<FeedComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  bool _isLikeLoading = false;
  bool _isBookmarkLoading = false;
  String? _currentUserId;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  late int _bookmarksCount;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadComments();

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

  /// 현재 사용자 ID 로드
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await ApiService.getUserId();
    setState(() {});
  }

  /// 댓글 목록 로드
  Future<void> _loadComments() async {
    if (_isLoadingComments) return;

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
      // 에러 처리
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  /// 좋아요 토글 처리
  Future<void> _handleLikeToggle() async {
    if (_isLikeLoading) return;

    final bool originalIsLiked = _isLiked;
    final int originalLikesCount = _likesCount;

    setState(() {
      _isLikeLoading = true;
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
      if (originalIsLiked) {
        response = await FeedApi.unlikeFeed(widget.feed.id);
      } else {
        response = await FeedApi.likeFeed(widget.feed.id);
      }

      if (response.containsKey(_errorKey)) {
        setState(() {
          _isLiked = originalIsLiked;
          _likesCount = originalLikesCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_likeErrorMessage)),
        );
      } else {
        setState(() {
          _likesCount = response[_likesCountKey] ?? _likesCount;
        });
      }
    } catch (e) {
      setState(() {
        _isLiked = originalIsLiked;
        _likesCount = originalLikesCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_networkErrorMessage)),
      );
    } finally {
      setState(() {
        _isLikeLoading = false;
      });
    }
  }

  /// 북마크 토글 처리
  Future<void> _handleBookmarkToggle() async {
    if (_isBookmarkLoading) return;

    final bool originalIsBookmarked = _isBookmarked;
    final int originalBookmarksCount = _bookmarksCount;

    setState(() {
      _isBookmarkLoading = true;
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
      if (originalIsBookmarked) {
        response = await FeedApi.unbookmarkFeed(widget.feed.id);
      } else {
        response = await FeedApi.bookmarkFeed(widget.feed.id);
      }

      if (response.containsKey(_errorKey)) {
        setState(() {
          _isBookmarked = originalIsBookmarked;
          _bookmarksCount = originalBookmarksCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_bookmarkErrorMessage)),
        );
      } else {
        setState(() {
          _bookmarksCount = response[_bookmarksCountKey] ?? _bookmarksCount;
        });
      }
    } catch (e) {
      setState(() {
        _isBookmarked = originalIsBookmarked;
        _bookmarksCount = originalBookmarksCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_bookmarkErrorMessage)),
      );
    } finally {
      setState(() {
        _isBookmarkLoading = false;
      });
    }
  }

  /// 댓글 작성 처리
  Future<void> _handleCommentPost() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isPostingComment = true;
    });

    try {
      final response = await FeedApi.createComment(widget.feed.id, comment);

      if (response.containsKey(_errorKey)) {
        throw Exception(response[_errorKey]);
      }

      _commentController.clear();
      await _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_commentErrorMessage)),
      );
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  /// 프로필 페이지로 이동
  void _handleProfileNavigation() {
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

  /// 위치 지도 표시
  void _handleLocationMapShow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(_mapDialogInsets),
          child: SizedBox(
            height: _mapDialogHeight,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(_mapDialogPadding),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(_locationMapBorderRadius),
                      topRight: Radius.circular(_locationMapBorderRadius),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white),
                      const SizedBox(width: _mapDialogTitleSpacing),
                      Expanded(
                        child: Text(
                          _getLocationText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _locationDialogTitleFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(_locationMapBorderRadius),
                      bottomRight: Radius.circular(_locationMapBorderRadius),
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
                        zoom: _defaultMapZoom,
                      ),
                      onMapCreated: (MapboxMap mapboxMap) {
                        _addMarkerToMap(mapboxMap);
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(_mapDialogBottomPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_fixed, size: _locationIconSize, color: Colors.grey),
                      const SizedBox(width: _mapDialogCoordinatesSpacing),
                      Text(
                        "${widget.feed.latitude.toStringAsFixed(_coordinateDecimalPlaces)}, ${widget.feed.longitude.toStringAsFixed(_coordinateDecimalPlaces)}",
                        style: const TextStyle(color: Colors.grey, fontSize: _coordinatesFontSize),
                      ),
                      const SizedBox(width: _mapDialogHintSpacing),
                      const Icon(Icons.pan_tool, size: _locationIconSize, color: Colors.grey),
                      const SizedBox(width: _mapDialogCoordinatesSpacing),
                      const Text(
                        _dragToExploreText,
                        style: TextStyle(color: Colors.grey, fontSize: _coordinatesFontSize),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: _cardVerticalMargin),
      elevation: 0,
      color: themeProvider.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _headerPadding,
              _headerVerticalPadding,
              _headerPadding,
              _headerVerticalPadding,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _handleProfileNavigation,
                  borderRadius: BorderRadius.circular(25),
                  child: CircleAvatar(
                    radius: _profileRadius,
                    backgroundImage: widget.feed.fullProfileImageUrl.isNotEmpty
                        ? NetworkImage(widget.feed.fullProfileImageUrl)
                        : null,
                    child: widget.feed.fullProfileImageUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(width: _profileSpacing),
                Expanded(
                  child: InkWell(
                    onTap: _handleProfileNavigation,
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
                              fontSize: _usernameFontSize,
                              color: themeProvider.textColor,
                            ),
                          ),
                          Text(
                            _formatDate(widget.feed.createdAt),
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: _dateFontSize,
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

          SizedBox(
            width: double.infinity,
            child: Image.network(
              widget.feed.fullImageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: _imageLoadingHeight,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: _imageLoadingHeight,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: _imageErrorIconSize, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _actionsPadding,
              vertical: _actionsVerticalPadding,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _isLikeLoading ? null : _handleLikeToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: _isLikeLoading ? _loadingOpacity : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLikeLoading
                            ? const SizedBox(
                          width: _loadingIndicatorSize,
                          height: _loadingIndicatorSize,
                          child: CircularProgressIndicator(
                            strokeWidth: _loadingIndicatorStroke,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                            : Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? AppColors.primary : themeProvider.iconColor,
                          size: _actionIconSize,
                        ),
                        const SizedBox(width: _actionIconSpacing),
                        Text(
                          _likesCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: _actionsSpacing),
                InkWell(
                  onTap: _isBookmarkLoading ? null : _handleBookmarkToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: _isBookmarkLoading ? _loadingOpacity : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isBookmarkLoading
                            ? const SizedBox(
                          width: _loadingIndicatorSize,
                          height: _loadingIndicatorSize,
                          child: CircularProgressIndicator(
                            strokeWidth: _loadingIndicatorStroke,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                            : Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _isBookmarked ? AppColors.primary : themeProvider.iconColor,
                          size: _actionIconSize,
                        ),
                        const SizedBox(width: _actionIconSpacing),
                        Text(
                          _bookmarksCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.feed.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _descriptionHorizontalPadding),
              child: Text(
                widget.feed.description,
                style: const TextStyle(fontSize: _descriptionFontSize),
              ),
            ),

          InkWell(
            onTap: _handleLocationMapShow,
            borderRadius: BorderRadius.circular(_locationMapBorderRadius),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: _locationMapMargin,
                vertical: _locationMapVerticalMargin,
              ),
              height: _locationMapHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_locationMapBorderRadius),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_locationMapBorderRadius),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        _getMapboxStaticImageUrl(),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined, size: 32, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    _locationText,
                                    style: TextStyle(color: Colors.grey, fontSize: _coordinatesFontSize),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: _locationOverlayPadding,
                      left: _locationOverlayPadding,
                      right: _locationOverlayPadding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _locationOverlayHorizontalPadding,
                          vertical: _locationOverlayVerticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(_locationOverlayOpacity),
                          borderRadius: BorderRadius.circular(_locationOverlayHorizontalPadding),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: _locationIconSize),
                            const SizedBox(width: _locationIconSpacing),
                            Expanded(
                              child: Text(
                                _getLocationText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: _coordinatesFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: _locationOverlayPadding,
                      right: _locationOverlayPadding,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(_fullscreenOverlayOpacity),
                          borderRadius: BorderRadius.circular(_locationMapBorderRadius),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: _fullscreenIconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Divider(color: Colors.grey[300]),

          if (_isLoadingComments)
            const Padding(
              padding: EdgeInsets.all(_commentsPadding),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(_commentsPadding),
              child: Center(
                child: Text(
                  _noCommentsText,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...List.generate(
              _comments.length,
                  (index) => _buildCommentItem(_comments[index]),
            ),

          Padding(
            padding: const EdgeInsets.all(_commentInputPadding),
            child: Row(
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return CircleAvatar(
                      radius: _commentInputProfileRadius,
                      backgroundImage: userProvider.profileImage.isNotEmpty
                          ? NetworkImage(userProvider.profileImage)
                          : null,
                      child: userProvider.profileImage.isEmpty
                          ? const Icon(Icons.person, size: _commentInputProfileIconSize)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: _commentInputProfileSpacing),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: _addCommentHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_commentInputBorderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: _commentInputHorizontalPadding,
                        vertical: _commentInputVerticalPadding,
                      ),
                    ),
                    maxLines: 1,
                    onSubmitted: (_) => _handleCommentPost(),
                  ),
                ),
                const SizedBox(width: _commentInputSpacing),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isPostingComment ? null : _handleCommentPost,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(_sendButtonPadding),
                      child: _isPostingComment
                          ? const SizedBox(
                        width: _sendIconSize,
                        height: _sendIconSize,
                        child: CircularProgressIndicator(strokeWidth: _loadingIndicatorStroke),
                      )
                          : const Icon(
                        Icons.send,
                        color: AppColors.primary,
                        size: _sendIconSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: _bottomSpacing),
        ],
      ),
    );
  }

  /// 댓글 아이템 위젯
  Widget _buildCommentItem(FeedComment comment) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _commentItemHorizontalPadding,
        vertical: _commentItemVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _navigateToCommentProfile(comment),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: _commentProfileRadius,
                backgroundImage: comment.fullProfileImageUrl.isNotEmpty
                    ? NetworkImage(comment.fullProfileImageUrl)
                    : null,
                child: comment.fullProfileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: _commentProfileIconSize)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: _commentProfileSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _navigateToCommentProfile(comment),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: comment.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _commentUsernameFontSize,
                              color: themeProvider.textColor,
                            ),
                          ),
                          TextSpan(
                            text: ' ${comment.content}',
                            style: TextStyle(
                              fontSize: _commentContentFontSize,
                              color: themeProvider.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _commentContentSpacing),
                Padding(
                  padding: const EdgeInsets.only(left: _commentTimePadding),
                  child: Text(
                    _timeAgo(comment.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: _commentTimeFontSize,
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

  /// 댓글 작성자 프로필로 이동
  void _navigateToCommentProfile(FeedComment comment) {
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
  }

  /// 지도에 마커 추가
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

      Uint8List? imageData = await _downloadImage(widget.feed.fullThumbnailUrl);
      if (imageData == null) return;

      Uint8List borderedImage = await _addBorderToImage(imageData);

      final pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      final pointAnnotation = PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(widget.feed.longitude, widget.feed.latitude)
        ),
        image: borderedImage,
        iconSize: 1.0,
      );

      await pointAnnotationManager.create(pointAnnotation);
    } catch (e) {
      // 에러 처리
    }
  }

  /// 이미지 다운로드
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      // 에러 처리
    }
    return null;
  }

  /// 이미지에 테두리 추가
  Future<Uint8List> _addBorderToImage(Uint8List imageBytes) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _markerSize.toDouble(), _markerSize.toDouble()));

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final double photoLeft = (_markerSize - _markerPhotoSize) / 2;
    final double photoTop = (_markerSize - _markerPhotoSize) / 2;

    final Paint borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(photoLeft - _markerBorderWidth, photoTop - _markerBorderWidth,
            _markerPhotoSize + (_markerBorderWidth * 2), _markerPhotoSize + (_markerBorderWidth * 2)),
        const Radius.circular(_markerBorderRadius),
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
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, _markerPhotoSize.toDouble(), _markerPhotoSize.toDouble());

    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    final ui.Image image = await recorder.endRecording().toImage(_markerSize, _markerSize);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Mapbox Static Images API URL 생성
  String _getMapboxStaticImageUrl({int zoom = _defaultStaticMapZoom, int width = _defaultStaticMapWidth, int height = _defaultStaticMapHeight}) {
    const String accessToken = String.fromEnvironment(_accessTokenEnvKey,
        defaultValue: _defaultAccessToken);
    final double lng = widget.feed.longitude;
    final double lat = widget.feed.latitude;

    final String marker = "$_mapboxMarkerPrefix$lng,$lat$_mapboxMarkerSuffix";

    return "$_mapboxStaticBaseUrl$marker/$lng,$lat,$zoom/${width}x$height$_mapboxAccessTokenParam$accessToken";
  }

  /// 위치 텍스트 가져오기
  String _getLocationText() {
    if (widget.feed.extraData.containsKey(_locationNameKey) &&
        widget.feed.extraData[_locationNameKey] != null &&
        widget.feed.extraData[_locationNameKey].isNotEmpty) {
      return widget.feed.extraData[_locationNameKey];
    }

    if (widget.feed.countryCode.isNotEmpty && widget.feed.countryCode != _unknownCountryCode) {
      return widget.feed.countryCode;
    }

    return "${widget.feed.latitude.toStringAsFixed(_locationTextDecimalPlaces)}, ${widget.feed.longitude.toStringAsFixed(_locationTextDecimalPlaces)}";
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
      return _nowText;
    }
  }

  /// 시간 경과 표시
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
}