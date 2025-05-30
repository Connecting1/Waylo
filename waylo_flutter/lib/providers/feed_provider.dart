import 'dart:io';
import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/models/feed_comment.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import '../services/api/api_service.dart';

/// 피드 데이터와 관련 기능을 관리하는 Provider
class FeedProvider extends ChangeNotifier {
  List<Feed> _feeds = [];                               // 전체 피드 목록
  List<Feed> _nearbyFeeds = [];                         // 주변 피드 목록
  List<Feed> _userFeeds = [];                           // 사용자 피드 목록
  List<Feed> _bookmarkedFeeds = [];                     // 북마크한 피드 목록
  List<Feed> _friendsFeeds = [];                        // 친구들의 피드 목록

  Feed? _currentFeed;                                   // 현재 선택된 피드
  List<FeedComment> _comments = [];                     // 댓글 목록

  bool _isLoading = false;                              // 로딩 상태
  bool _hasMoreFeeds = true;                            // 더 많은 피드 존재 여부
  bool _hasMoreNearbyFeeds = true;                      // 더 많은 주변 피드 존재 여부
  bool _hasMoreUserFeeds = true;                        // 더 많은 사용자 피드 존재 여부
  bool _hasMoreBookmarkedFeeds = true;                  // 더 많은 북마크 피드 존재 여부
  bool _hasMoreComments = true;                         // 더 많은 댓글 존재 여부
  bool _hasMoreFriendsFeeds = true;                     // 더 많은 친구 피드 존재 여부

  String _errorMessage = '';                            // 에러 메시지

  List<Feed> get feeds => _feeds;
  List<Feed> get nearbyFeeds => _nearbyFeeds;
  List<Feed> get userFeeds => _userFeeds;
  List<Feed> get bookmarkedFeeds => _bookmarkedFeeds;
  List<Feed> get friendsFeeds => _friendsFeeds;
  Feed? get currentFeed => _currentFeed;
  List<FeedComment> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get hasMoreFeeds => _hasMoreFeeds;
  bool get hasMoreNearbyFeeds => _hasMoreNearbyFeeds;
  bool get hasMoreUserFeeds => _hasMoreUserFeeds;
  bool get hasMoreBookmarkedFeeds => _hasMoreBookmarkedFeeds;
  bool get hasMoreComments => _hasMoreComments;
  bool get hasMoreFriendsFeeds => _hasMoreFriendsFeeds;
  String get errorMessage => _errorMessage;

  /// 모든 피드 가져오기
  Future<void> fetchFeeds({bool refresh = false, int page = 1, int limit = 10}) async {
    if (_isLoading) return;

    if (refresh) {
      _feeds = [];
      _hasMoreFeeds = true;
      page = 1;
    }

    if (!_hasMoreFeeds && !refresh) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await FeedApi.fetchFeeds(page: page, limit: limit);

      if (response is Map && response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return;
      }

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        List<Feed> newFeeds = feedsData.map((data) => Feed.fromJson(data)).toList();

        if (refresh) {
          _feeds = newFeeds;
        } else {
          _feeds.addAll(newFeeds);
        }

        _hasMoreFeeds = newFeeds.length >= limit;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '피드 로드 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 친구들의 피드 가져오기
  Future<void> fetchFriendsFeeds({bool refresh = false, int page = 1, int limit = 10}) async {
    if (_isLoading) return;

    if (refresh) {
      _friendsFeeds = [];
      _hasMoreFriendsFeeds = true;
      page = 1;
    }

    if (!_hasMoreFriendsFeeds && !refresh) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await FeedApi.fetchFriendsFeeds(page: page, limit: limit);

      if (response is Map && response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return;
      }

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        List<Feed> newFeeds = feedsData.map((data) => Feed.fromJson(data)).toList();

        if (refresh) {
          _friendsFeeds = newFeeds;
        } else {
          _friendsFeeds.addAll(newFeeds);
        }

        _hasMoreFriendsFeeds = newFeeds.length >= limit;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '친구 피드 로드 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 주변 피드 가져오기
  Future<void> fetchNearbyFeeds({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    bool refresh = false,
    int page = 1,
    int limit = 20,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _nearbyFeeds = [];
      _hasMoreNearbyFeeds = true;
      page = 1;
    }

    if (!_hasMoreNearbyFeeds && !refresh) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await FeedApi.fetchNearbyFeeds(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: page,
        limit: limit,
      );

      if (response is Map && response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return;
      }

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        List<Feed> newFeeds = feedsData.map((data) => Feed.fromJson(data)).toList();

        if (refresh) {
          _nearbyFeeds = newFeeds;
        } else {
          _nearbyFeeds.addAll(newFeeds);
        }

        _hasMoreNearbyFeeds = newFeeds.length >= limit;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '주변 피드 로드 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 피드 생성
  Future<bool> createFeed({
    required double latitude,
    required double longitude,
    required File image,
    String? description,
    String? visibility,
    String? countryCode,
    String? photoTakenAt,
    Map<String, dynamic>? extraData,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String? authToken = await ApiService.getAuthToken();
      String? userId = await ApiService.getUserId();

      final response = await FeedApi.createFeed(
        latitude: latitude,
        longitude: longitude,
        image: image,
        description: description,
        visibility: visibility,
        countryCode: countryCode,
        photoTakenAt: photoTakenAt,
        extraData: extraData,
      );

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return false;
      }

      await fetchFeeds(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = '피드 생성 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 피드 좋아요 토글
  Future<bool> toggleLike(Feed feed) async {
    try {
      Map<String, dynamic> response;

      if (feed.isLiked) {
        response = await FeedApi.unlikeFeed(feed.id);
      } else {
        response = await FeedApi.likeFeed(feed.id);
      }

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return false;
      }

      await _updateFeedLikeStatus(feed.id, !feed.isLiked, response['likes_count']);
      return true;
    } catch (e) {
      _errorMessage = '좋아요 처리 중 오류가 발생했습니다: $e';
      return false;
    }
  }

  /// 피드 북마크 토글
  Future<bool> toggleBookmark(Feed feed) async {
    try {
      Map<String, dynamic> response;

      if (feed.isBookmarked) {
        response = await FeedApi.unbookmarkFeed(feed.id);
      } else {
        response = await FeedApi.bookmarkFeed(feed.id);
      }

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return false;
      }

      await _updateFeedBookmarkStatus(feed.id, !feed.isBookmarked, response['bookmarks_count']);
      return true;
    } catch (e) {
      _errorMessage = '북마크 처리 중 오류가 발생했습니다: $e';
      return false;
    }
  }

  /// 피드 좋아요 상태 업데이트
  Future<void> _updateFeedLikeStatus(String feedId, bool isLiked, int likesCount) async {
    _updateFeedInList(_feeds, feedId, isLiked, likesCount, null, null);
    _updateFeedInList(_nearbyFeeds, feedId, isLiked, likesCount, null, null);
    _updateFeedInList(_userFeeds, feedId, isLiked, likesCount, null, null);
    _updateFeedInList(_bookmarkedFeeds, feedId, isLiked, likesCount, null, null);

    if (_currentFeed != null && _currentFeed!.id == feedId) {
      _currentFeed = Feed(
        id: _currentFeed!.id,
        userId: _currentFeed!.userId,
        username: _currentFeed!.username,
        profileImage: _currentFeed!.profileImage,
        latitude: _currentFeed!.latitude,
        longitude: _currentFeed!.longitude,
        imageUrl: _currentFeed!.imageUrl,
        thumbnailUrl: _currentFeed!.thumbnailUrl,
        description: _currentFeed!.description,
        visibility: _currentFeed!.visibility,
        countryCode: _currentFeed!.countryCode,
        photoTakenAt: _currentFeed!.photoTakenAt,
        extraData: _currentFeed!.extraData,
        createdAt: _currentFeed!.createdAt,
        likesCount: likesCount,
        bookmarksCount: _currentFeed!.bookmarksCount,
        isLiked: isLiked,
        isBookmarked: _currentFeed!.isBookmarked,
        distance: _currentFeed!.distance,
      );
    }

    notifyListeners();
  }

  /// 피드 북마크 상태 업데이트
  Future<void> _updateFeedBookmarkStatus(String feedId, bool isBookmarked, int bookmarksCount) async {
    _updateFeedInList(_feeds, feedId, null, null, isBookmarked, bookmarksCount);
    _updateFeedInList(_nearbyFeeds, feedId, null, null, isBookmarked, bookmarksCount);
    _updateFeedInList(_userFeeds, feedId, null, null, isBookmarked, bookmarksCount);
    _updateFeedInList(_bookmarkedFeeds, feedId, null, null, isBookmarked, bookmarksCount);

    if (_currentFeed != null && _currentFeed!.id == feedId) {
      _currentFeed = Feed(
        id: _currentFeed!.id,
        userId: _currentFeed!.userId,
        username: _currentFeed!.username,
        profileImage: _currentFeed!.profileImage,
        latitude: _currentFeed!.latitude,
        longitude: _currentFeed!.longitude,
        imageUrl: _currentFeed!.imageUrl,
        thumbnailUrl: _currentFeed!.thumbnailUrl,
        description: _currentFeed!.description,
        visibility: _currentFeed!.visibility,
        countryCode: _currentFeed!.countryCode,
        photoTakenAt: _currentFeed!.photoTakenAt,
        extraData: _currentFeed!.extraData,
        createdAt: _currentFeed!.createdAt,
        likesCount: _currentFeed!.likesCount,
        bookmarksCount: bookmarksCount,
        isLiked: _currentFeed!.isLiked,
        isBookmarked: isBookmarked,
        distance: _currentFeed!.distance,
      );
    }

    notifyListeners();
  }

  /// 피드 목록에서 특정 피드 정보 업데이트
  void _updateFeedInList(List<Feed> feeds, String feedId, bool? isLiked, int? likesCount, bool? isBookmarked, int? bookmarksCount) {
    final index = feeds.indexWhere((feed) => feed.id == feedId);
    if (index != -1) {
      Feed oldFeed = feeds[index];
      feeds[index] = Feed(
        id: oldFeed.id,
        userId: oldFeed.userId,
        username: oldFeed.username,
        profileImage: oldFeed.profileImage,
        latitude: oldFeed.latitude,
        longitude: oldFeed.longitude,
        imageUrl: oldFeed.imageUrl,
        thumbnailUrl: oldFeed.thumbnailUrl,
        description: oldFeed.description,
        visibility: oldFeed.visibility,
        countryCode: oldFeed.countryCode,
        photoTakenAt: oldFeed.photoTakenAt,
        extraData: oldFeed.extraData,
        createdAt: oldFeed.createdAt,
        likesCount: likesCount ?? oldFeed.likesCount,
        bookmarksCount: bookmarksCount ?? oldFeed.bookmarksCount,
        isLiked: isLiked ?? oldFeed.isLiked,
        isBookmarked: isBookmarked ?? oldFeed.isBookmarked,
        distance: oldFeed.distance,
      );
    }
  }

  /// Provider 상태 초기화
  void reset() {
    _feeds = [];
    _nearbyFeeds = [];
    _userFeeds = [];
    _bookmarkedFeeds = [];
    _friendsFeeds = [];
    _currentFeed = null;
    _comments = [];
    _isLoading = false;
    _hasMoreFeeds = true;
    _hasMoreNearbyFeeds = true;
    _hasMoreUserFeeds = true;
    _hasMoreBookmarkedFeeds = true;
    _hasMoreFriendsFeeds = true;
    _hasMoreComments = true;
    _errorMessage = '';
    notifyListeners();
  }
}