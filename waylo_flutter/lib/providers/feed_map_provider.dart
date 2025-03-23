// providers/feed_map_provider.dart
import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';

import '../services/api/api_service.dart';

class FeedMapProvider extends ChangeNotifier {
  List<Feed> _mapFeeds = [];
  Map<String, List<Feed>> _countryFeeds = {}; // 국가 코드별 피드 그룹
  bool _hasGroupedByCountry = false;
  bool _isLoading = false;
  bool _isLoaded = false;
  String _errorMessage = '';


  // Getters
  List<Feed> get mapFeeds => _mapFeeds;
  Map<String, List<Feed>> get countryFeeds => _countryFeeds;
  bool get hasGroupedByCountry => _hasGroupedByCountry;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String get errorMessage => _errorMessage;

  // 지도에 표시할 피드 로드
  Future<void> loadFeedsForMap({bool refresh = false}) async {
    if (_isLoading) return;

    if (_isLoaded && !refresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 사용자 ID 가져오기
      String? userId = await ApiService.getUserId();
      if (userId == null) {
        _errorMessage = '사용자 ID를 찾을 수 없습니다.';
        notifyListeners();
        return;
      }

      // 사용자 본인의 피드만 가져오기
      final response = await FeedApi.fetchUserFeeds(userId, limit: 100);

      if (response is Map && response.containsKey('error')) {
        _errorMessage = response['error'];
        print("[ERROR] 피드맵: 피드 로드 오류 - $_errorMessage");
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
      print('️[ERROR] 피드맵 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 위치 주변의 피드 로드 (선택적 기능)
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
        print("[ERROR] 피드맵: 주변 피드 로드 오류 - $_errorMessage");
        notifyListeners();
        return;
      }

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        List<Feed> nearbyFeeds = feedsData.map((data) => Feed.fromJson(data)).toList();

        if (refresh) {
          _mapFeeds = nearbyFeeds;
        } else {
          // 기존 피드에 주변 피드 추가 (중복 제거)
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
      print('[ERROR] 주변 피드맵 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새 피드 추가 (새 피드 생성 후 지도에 즉시 표시를 위해)
  void addFeedToMap(Feed feed) {
    if (!_mapFeeds.any((f) => f.id == feed.id)) {
      _mapFeeds.add(feed);

      // 추가: 그룹화 상태 초기화 및 재그룹화
      _hasGroupedByCountry = false;
      groupFeedsByCountry();

      notifyListeners();
    }
  }

  // 추가할 메서드: 국가별 피드 그룹화
  void groupFeedsByCountry() {
    if (_hasGroupedByCountry) return;

    _countryFeeds.clear();

    for (Feed feed in _mapFeeds) {
      // 직접 feed.countryCode 필드에서 국가 코드 가져오기
      String countryCode = feed.countryCode.isNotEmpty ? feed.countryCode : "UNKNOWN";

      if (!_countryFeeds.containsKey(countryCode)) {
        _countryFeeds[countryCode] = [];
      }

      _countryFeeds[countryCode]!.add(feed);
    }

    // 결과 확인
    _countryFeeds.forEach((code, feeds) {
      print("국가 코드: $code, 피드 수: ${feeds.length}");
    });

    _hasGroupedByCountry = true;
    notifyListeners();
  }

  // 상태 초기화
  void reset() {
    _mapFeeds = [];
    _countryFeeds = {}; // 추가
    _hasGroupedByCountry = false; // 추가
    _isLoading = false;
    _isLoaded = false;
    _errorMessage = '';
    notifyListeners();
  }
}