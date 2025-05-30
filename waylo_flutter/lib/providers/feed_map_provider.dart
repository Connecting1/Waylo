import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import '../services/api/api_service.dart';

/// 지도에 표시할 피드 데이터를 관리하는 Provider
class FeedMapProvider extends ChangeNotifier {
  List<Feed> _mapFeeds = [];                            // 지도에 표시될 피드 목록
  Map<String, List<Feed>> _countryFeeds = {};           // 국가 코드별 피드 그룹
  bool _hasGroupedByCountry = false;                    // 국가별 그룹화 완료 여부
  bool _isLoading = false;                              // 로딩 상태
  bool _isLoaded = false;                               // 데이터 로드 완료 여부
  String _errorMessage = '';                            // 에러 메시지

  List<Feed> get mapFeeds => _mapFeeds;
  Map<String, List<Feed>> get countryFeeds => _countryFeeds;
  bool get hasGroupedByCountry => _hasGroupedByCountry;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String get errorMessage => _errorMessage;

  /// 지도에 표시할 피드 로드
  Future<void> loadFeedsForMap({bool refresh = false}) async {
    if (_isLoading) return;

    if (_isLoaded && !refresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String? userId = await ApiService.getUserId();
      if (userId == null) {
        _errorMessage = '사용자 ID를 찾을 수 없습니다.';
        notifyListeners();
        return;
      }

      final response = await FeedApi.fetchUserFeeds(userId, limit: 100);

      if (response is Map && response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return;
      }

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        _mapFeeds = feedsData.map((data) => Feed.fromJson(data)).toList();
        groupFeedsByCountry();

        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '피드 로드 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 특정 위치 주변의 피드 로드
  Future<void> loadNearbyFeedsForMap({
    required double latitude,
    required double longitude,
    double radius = 50.0,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await FeedApi.fetchNearbyFeeds(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: 100,
      );

      if (response is Map && response.containsKey('error')) {
        _errorMessage = response['error'];
        notifyListeners();
        return;
      }

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        List<Feed> nearbyFeeds = feedsData.map((data) => Feed.fromJson(data)).toList();

        if (refresh) {
          _mapFeeds = nearbyFeeds;
        } else {
          Set<String> existingIds = _mapFeeds.map((feed) => feed.id).toSet();
          for (var feed in nearbyFeeds) {
            if (!existingIds.contains(feed.id)) {
              _mapFeeds.add(feed);
              existingIds.add(feed.id);
            }
          }
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '주변 피드 로드 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새 피드를 지도에 추가
  void addFeedToMap(Feed feed) {
    if (!_mapFeeds.any((f) => f.id == feed.id)) {
      _mapFeeds.add(feed);

      _hasGroupedByCountry = false;
      groupFeedsByCountry();

      notifyListeners();
    }
  }

  /// 피드를 국가별로 그룹화
  void groupFeedsByCountry() {
    if (_hasGroupedByCountry) return;

    _countryFeeds.clear();

    for (Feed feed in _mapFeeds) {
      String countryCode = feed.countryCode.isNotEmpty ? feed.countryCode : "UNKNOWN";

      if (!_countryFeeds.containsKey(countryCode)) {
        _countryFeeds[countryCode] = [];
      }

      _countryFeeds[countryCode]!.add(feed);
    }

    _hasGroupedByCountry = true;
    notifyListeners();
  }

  /// Provider 상태 초기화
  void reset() {
    _mapFeeds = [];
    _countryFeeds = {};
    _hasGroupedByCountry = false;
    _isLoading = false;
    _isLoaded = false;
    _errorMessage = '';
    notifyListeners();
  }
}