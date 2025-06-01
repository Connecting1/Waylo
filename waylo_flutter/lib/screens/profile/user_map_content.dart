import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:async';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/screens/feed/feed_detail_sheet.dart';
import '../../../styles/app_styles.dart';
import 'dart:ui' as ui;
import 'package:waylo_flutter/services/api/feed_api.dart';
import '../../services/api/api_service.dart';

// 마커 클릭 리스너 클래스
class UserPointClickListener implements OnPointAnnotationClickListener {
  final UserMapContentWidgetState state;

  UserPointClickListener(this.state);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    state._handleFeedMarkerClick(annotation);
  }
}

// 국가 마커 클릭 리스너 클래스
class CountryPointClickListener implements OnPointAnnotationClickListener {
  final UserMapContentWidgetState state;

  CountryPointClickListener(this.state);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    state._handleCountryMarkerClick(annotation);
  }
}

class UserMapContentWidget extends StatefulWidget {
  final String userId;
  final String username;

  const UserMapContentWidget({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  UserMapContentWidgetState createState() => UserMapContentWidgetState();
}

class UserMapContentWidgetState extends State<UserMapContentWidget> with AutomaticKeepAliveClientMixin {
  // 텍스트 상수들
  static const String _loadingFeedsText = "Loading feeds...";

  // 에러 메시지 상수들
  static const String _userFeedsLoadFailureMessage = "Failed to load user's feeds.";
  static const String _userFeedsLoadErrorMessage = "An error occurred while loading user's feed data.";

  // 폰트 크기 상수들
  static const double _loadingTextFontSize = 12;

  // 크기 상수들
  static const double _initialZoomLevel = 2.0;
  static const double _countryZoomLevel = 5.0;
  static const double _zoomThreshold = 4.0;
  static const double _userLocationIconSize = 1.2;
  static const double _feedMarkerIconSize = 1.0;
  static const double _countryMarkerIconSize = 0.3;

  // 이미지 크기 상수들
  static const int _userLocationImageSize = 120;
  static const int _userLocationPhotoSize = 100;
  static const double _userLocationBorderWidth = 7.0;
  static const int _feedMarkerImageSize = 170;
  static const int _feedMarkerPhotoSize = 150;
  static const double _feedMarkerBorderWidth = 7.0;

  // 애니메이션 지속시간 상수들
  static const int _countryFlyToAnimationDuration = 1500;

  // 타이머 간격 상수들
  static const int _locationUpdateInterval = 30;
  static const int _zoomCheckTimerInterval = 500;

  // URL 상수들
  static const String _flagUrlPrefix = "https://flagcdn.com/w320/";
  static const String _flagUrlSuffix = ".png";
  static const String _flagUrlAlternativePrefix = "https://flagcdn.com/";
  static const String _mapboxGeocodingBaseUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";
  static const String _countryTypeParam = "?types=country&access_token=";

  // 파일 경로 상수들
  static const String _defaultFlagIconPath = "assets/icons/default_flag.png";

  // API 엔드포인트 상수들
  static const String _locationSettingsApiPrefix = "/api/users/";
  static const String _locationSettingsApiSuffix = "/location-settings/";
  static const String _locationApiSuffix = "/location/";

  // 기타 상수들
  static const String _unknownCountryCode = "UNKNOWN";
  static const String _accessTokenKey = "ACCESS_TOKEN";
  static const double _borderRadius = 8.0;
  static const double _circularBorderRadius = 20.0;
  static const double _loadingIndicatorStrokeWidth = 2.0;
  static const double _loadingContainerPadding = 8.0;
  static const double _loadingSpacing = 8.0;
  static const double _loadingIndicatorSize = 20.0;
  static const double _mapTopPosition = 20.0;
  static const double _mapRightPosition = 20.0;

  // 데이터 키 상수들
  static const String _isSharingKey = "is_sharing";
  static const String _latitudeKey = "latitude";
  static const String _longitudeKey = "longitude";
  static const String _profileImageKey = "profile_image";
  static const String _feedsKey = "feeds";

  late MapboxMap mapboxMap;
  late String accessToken;
  PointAnnotationManager? feedAnnotationManager;
  PointAnnotationManager? countryFeedAnnotationManager;
  PointAnnotationManager? userLocationAnnotationManager;
  PointAnnotation? userLocationMarker;
  bool _isLocationSharing = false;
  Timer? _locationUpdateTimer;

  Map<String, Map<String, dynamic>> countryData = {};
  double currentZoomLevel = _initialZoomLevel;

  List<PointAnnotation> feedMarkers = [];
  List<PointAnnotation> countryFeedMarkers = [];
  Map<String, PointAnnotation> feedMarkersMap = {};
  Map<String, Map<String, double>> _countryCenterCache = {};

  List<Feed> userFeeds = [];
  Map<String, List<Feed>> _countryFeeds = {};
  Map<String, PointAnnotation> _countryMarkerMap = {};
  bool _hasGroupedByCountry = false;

  Timer? _zoomCheckTimer;
  bool isMapInitialized = false;
  bool _isLoadingFeeds = false;

  @override
  void initState() {
    super.initState();
    accessToken = const String.fromEnvironment(_accessTokenKey);
    MapboxOptions.setAccessToken(accessToken);

    Future.microtask(() {
      _handleLoadUserFeeds();
      _handleCheckUserLocationSharing();
    });
  }

  /// 사용자 위치 공유 상태 확인 처리
  Future<void> _handleCheckUserLocationSharing() async {
    try {
      final endpoint = "$_locationSettingsApiPrefix${widget.userId}$_locationSettingsApiSuffix";
      final response = await ApiService.sendRequest(endpoint: endpoint);

      bool isSharing = response[_isSharingKey] == true;

      if (isSharing) {
        _handleStartLocationTracking();
      } else {
        _handleStopLocationTracking();
      }
    } catch (e) {
      // 에러 처리
    }
  }

  /// 위치 추적 시작 처리
  void _handleStartLocationTracking() {
    if (_isLocationSharing || !isMapInitialized) return;

    _isLocationSharing = true;

    _locationUpdateTimer = Timer.periodic(
        Duration(seconds: _locationUpdateInterval),
            (_) => _handleUpdateUserLocationMarker()
    );

    _handleUpdateUserLocationMarker();
  }

  /// 위치 추적 중지 처리
  void _handleStopLocationTracking() {
    _isLocationSharing = false;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _handleRemoveUserLocationMarker();
  }

  /// 사용자 위치 마커 업데이트 처리
  Future<void> _handleUpdateUserLocationMarker() async {
    if (!isMapInitialized) return;

    try {
      final endpoint = "$_locationSettingsApiPrefix${widget.userId}$_locationApiSuffix";
      final response = await ApiService.sendRequest(endpoint: endpoint);

      if (!response.containsKey(_latitudeKey) || !response.containsKey(_longitudeKey)) {
        return;
      }

      double latitude = double.parse(response[_latitudeKey].toString());
      double longitude = double.parse(response[_longitudeKey].toString());

      String profileImageUrl = response[_profileImageKey] ?? "";
      if (profileImageUrl.isEmpty) {
        return;
      }

      if (profileImageUrl.startsWith('/')) {
        profileImageUrl = "${ApiService.baseUrl}$profileImageUrl";
      }

      Uint8List? imageData = await _downloadImage(profileImageUrl);
      if (imageData == null) {
        return;
      }

      Uint8List circleImage = await _addCircleBorderToImage(imageData);

      if (userLocationMarker != null && userLocationAnnotationManager != null) {
        await userLocationAnnotationManager!.delete(userLocationMarker!);
        userLocationMarker = null;
      }

      if (userLocationAnnotationManager == null) {
        userLocationAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      }

      PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(longitude, latitude)),
        image: circleImage,
        iconSize: _userLocationIconSize,
      );

      userLocationMarker = await userLocationAnnotationManager!.create(pointAnnotationOptions);

    } catch (e) {
      // 에러 처리
    }
  }

  /// 사용자 위치 마커 제거 처리
  Future<void> _handleRemoveUserLocationMarker() async {
    if (userLocationMarker != null && userLocationAnnotationManager != null) {
      try {
        await userLocationAnnotationManager!.delete(userLocationMarker!);
        userLocationMarker = null;
      } catch (e) {
        // 에러 처리
      }
    }
  }

  /// 마커 클릭 처리
  void _handleFeedMarkerClick(PointAnnotation annotation) {
    String? feedId;
    feedMarkersMap.forEach((id, marker) {
      if (marker.id == annotation.id) {
        feedId = id;
      }
    });

    if (feedId != null) {
      try {
        Feed feed = userFeeds.firstWhere((feed) => feed.id == feedId);
        _handleShowFeedDetailSheet(feed);
      } catch (e) {
        // 에러 처리
      }
    }
  }

  /// 국가 마커 클릭 처리
  void _handleCountryMarkerClick(PointAnnotation annotation) {
    String? countryCode;
    for (String code in _countryMarkerMap.keys) {
      if (_countryMarkerMap[code]?.id == annotation.id) {
        countryCode = code;
        break;
      }
    }

    if (countryCode != null) {
      Map<String, double>? centerCoords = _countryCenterCache[countryCode];
      if (centerCoords != null) {
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(
                centerCoords['lng']!,
                centerCoords['lat']!
            )),
            zoom: _countryZoomLevel,
          ),
          MapAnimationOptions(duration: _countryFlyToAnimationDuration),
        );
      }
    }
  }

  /// Bottom Sheet 표시 처리
  void _handleShowFeedDetailSheet(Feed feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FeedDetailSheet(
          feed: feed,
          onEditPressed: (_) {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  /// 사용자 피드 로드 처리
  Future<void> _handleLoadUserFeeds() async {
    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      final response = await FeedApi.fetchUserFeeds(widget.userId);

      if (response is Map && response.containsKey(_feedsKey)) {
        List<dynamic> feedsData = response[_feedsKey];
        setState(() {
          userFeeds = feedsData.map((feedJson) => Feed.fromJson(feedJson)).toList();
        });

        _handleGroupFeedsByCountry();

        if (isMapInitialized) {
          if (userFeeds.isNotEmpty) {
            if (currentZoomLevel > _zoomThreshold) {
              await _addFeedMarkersToMap(userFeeds);
            } else {
              await _addCountryFeedMarkers();
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_userFeedsLoadFailureMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_userFeedsLoadErrorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFeeds = false;
        });
      }
    }
  }

  /// 국가별 피드 그룹화 처리
  void _handleGroupFeedsByCountry() {
    if (_hasGroupedByCountry) return;

    _countryFeeds.clear();

    for (Feed feed in userFeeds) {
      String countryCode = feed.countryCode.isNotEmpty ? feed.countryCode : _unknownCountryCode;

      if (!_countryFeeds.containsKey(countryCode)) {
        _countryFeeds[countryCode] = [];
      }

      _countryFeeds[countryCode]!.add(feed);
    }

    _hasGroupedByCountry = true;
  }

  /// 지도에 피드 마커 추가
  Future<void> _addFeedMarkersToMap(List<Feed> feeds) async {
    if (feedAnnotationManager == null) {
      feedAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    for (var marker in feedMarkers) {
      await feedAnnotationManager!.delete(marker);
    }
    feedMarkers.clear();
    feedMarkersMap.clear();

    for (var feed in feeds) {
      try {
        String markerImageUrl = feed.fullThumbnailUrl.isNotEmpty
            ? feed.fullThumbnailUrl
            : feed.fullImageUrl;

        Uint8List? imageData = await _downloadImage(markerImageUrl);
        if (imageData == null) continue;

        Uint8List borderedImage = await _addBorderToImage(imageData);

        PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(feed.longitude, feed.latitude)),
          image: borderedImage,
          iconSize: _feedMarkerIconSize,
        );

        PointAnnotation marker = await feedAnnotationManager!.create(pointAnnotationOptions);

        feedMarkers.add(marker);
        feedMarkersMap[feed.id] = marker;

      } catch (e) {
        // 에러 처리
      }
    }

    if (feedAnnotationManager != null) {
      feedAnnotationManager!.addOnPointAnnotationClickListener(UserPointClickListener(this));
    }
  }

  /// 국가별 피드 마커 추가
  Future<void> _addCountryFeedMarkers() async {
    if (_countryFeeds.isEmpty) {
      return;
    }

    if (countryFeedAnnotationManager == null) {
      countryFeedAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    for (var marker in countryFeedMarkers) {
      await countryFeedAnnotationManager!.delete(marker);
    }
    countryFeedMarkers.clear();
    _countryMarkerMap.clear();

    for (String countryCode in _countryFeeds.keys) {
      if (countryCode == _unknownCountryCode || countryCode.isEmpty) continue;

      List<Feed> feedsInCountry = _countryFeeds[countryCode]!;
      if (feedsInCountry.isEmpty) continue;

      Map<String, double>? centerCoords = await _getCountryCenter(countryCode);

      double feedLat, feedLon;

      if (centerCoords != null) {
        feedLat = centerCoords['lat']!;
        feedLon = centerCoords['lng']!;
      } else {
        Feed firstFeed = feedsInCountry.first;
        feedLat = firstFeed.latitude;
        feedLon = firstFeed.longitude;
      }

      try {
        Uint8List? flagImage;

        String flagUrl = "$_flagUrlPrefix${countryCode.toLowerCase()}$_flagUrlSuffix";
        flagImage = await _downloadImage(flagUrl);

        if (flagImage == null) {
          flagUrl = "$_flagUrlAlternativePrefix${countryCode.toLowerCase()}$_flagUrlSuffix";
          flagImage = await _downloadImage(flagUrl);
        }

        if (flagImage == null) {
          ByteData data = await rootBundle.load(_defaultFlagIconPath);
          flagImage = data.buffer.asUint8List();
        }

        PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(feedLon, feedLat)),
          image: flagImage,
          iconSize: _countryMarkerIconSize,
        );

        PointAnnotation marker = await countryFeedAnnotationManager!.create(pointAnnotationOptions);
        countryFeedMarkers.add(marker);
        _countryMarkerMap[countryCode] = marker;
      } catch (e) {
        // 에러 처리
      }
    }

    if (countryFeedAnnotationManager != null) {
      countryFeedAnnotationManager!.addOnPointAnnotationClickListener(
          CountryPointClickListener(this)
      );
    }
  }

  /// 줌 체크 타이머 시작
  void _startZoomCheckTimer() {
    _zoomCheckTimer?.cancel();
    _zoomCheckTimer = Timer.periodic(Duration(milliseconds: _zoomCheckTimerInterval), (timer) {
      if (isMapInitialized && mounted) {
        mapboxMap.getCameraState().then((cameraState) {
          if (currentZoomLevel != cameraState.zoom) {
            setState(() {
              currentZoomLevel = cameraState.zoom;
              _handleUpdateVisibility();
            });
          }
        });
      }
    });
  }

  /// 가시성 업데이트 처리
  void _handleUpdateVisibility() async {
    if (!isMapInitialized) return;

    if (_isLocationSharing) {
      _handleUpdateUserLocationMarker();
    }

    if (currentZoomLevel > _zoomThreshold) {
      if (countryFeedAnnotationManager != null) {
        for (var marker in List.from(countryFeedMarkers)) {
          try {
            await countryFeedAnnotationManager!.delete(marker);
            countryFeedMarkers.remove(marker);
          } catch (e) {
            // 에러 처리
          }
        }
      }

      if (feedMarkers.isEmpty && userFeeds.isNotEmpty) {
        await _addFeedMarkersToMap(userFeeds);
      }
    } else {
      if (feedAnnotationManager != null) {
        for (var marker in List.from(feedMarkers)) {
          try {
            await feedAnnotationManager!.delete(marker);
            feedMarkers.remove(marker);
          } catch (e) {
            // 에러 처리
          }
        }
      }

      if (countryFeedMarkers.isEmpty) {
        await _addCountryFeedMarkers();
      }
    }
  }

  /// 국가 중심 좌표 가져오기
  Future<Map<String, double>?> _getCountryCenter(String countryCode) async {
    try {
      if (_countryCenterCache.containsKey(countryCode)) {
        return _countryCenterCache[countryCode];
      }

      String url = "$_mapboxGeocodingBaseUrl${countryCode}.json$_countryTypeParam$accessToken";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          var center = data["features"][0]["center"];
          Map<String, double> coordinates = {
            'lng': center[0],
            'lat': center[1]
          };

          _countryCenterCache[countryCode] = coordinates;

          return coordinates;
        }
      }
    } catch (e) {
      // 에러 처리
    }
    return null;
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

  /// 시간 기반 스타일 가져오기
  String _getTimeBasedStyle() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 18) {
      return MapboxStyles.MAPBOX_STREETS;
    } else {
      return MapboxStyles.MAPBOX_STREETS;
    }
  }

  /// 프로필 이미지를 원형으로 처리
  Future<Uint8List> _addCircleBorderToImage(Uint8List imageBytes) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _userLocationImageSize.toDouble(), _userLocationImageSize.toDouble()));

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final double photoLeft = (_userLocationImageSize - _userLocationPhotoSize) / 2;
    final double photoTop = (_userLocationImageSize - _userLocationPhotoSize) / 2;

    final Paint borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(_userLocationImageSize / 2, _userLocationImageSize / 2),
      _userLocationPhotoSize / 2 + _userLocationBorderWidth,
      borderPaint,
    );

    final Path clipPath = Path()
      ..addOval(Rect.fromLTWH(photoLeft, photoTop, _userLocationPhotoSize.toDouble(), _userLocationPhotoSize.toDouble()));

    canvas.clipPath(clipPath);

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
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, _userLocationPhotoSize.toDouble(), _userLocationPhotoSize.toDouble());

    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    final ui.Image image = await recorder.endRecording().toImage(_userLocationImageSize, _userLocationImageSize);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// 이미지에 테두리 추가
  Future<Uint8List> _addBorderToImage(Uint8List imageBytes) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _feedMarkerImageSize.toDouble(), _feedMarkerImageSize.toDouble()));

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final double photoLeft = (_feedMarkerImageSize - _feedMarkerPhotoSize) / 2;
    final double photoTop = (_feedMarkerImageSize - _feedMarkerPhotoSize) / 2;

    final Paint borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(photoLeft - _feedMarkerBorderWidth, photoTop - _feedMarkerBorderWidth,
            _feedMarkerPhotoSize + (_feedMarkerBorderWidth * 2), _feedMarkerPhotoSize + (_feedMarkerBorderWidth * 2)),
        Radius.circular(_borderRadius),
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
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, _feedMarkerPhotoSize.toDouble(), _feedMarkerPhotoSize.toDouble());

    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    final ui.Image image = await recorder.endRecording().toImage(_feedMarkerImageSize, _feedMarkerImageSize);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// 로딩 인디케이터 위젯 생성
  Widget _buildLoadingIndicator() {
    return Positioned(
      top: _mapTopPosition,
      right: _mapRightPosition,
      child: Container(
        padding: EdgeInsets.all(_loadingContainerPadding),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(_circularBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _loadingIndicatorSize,
              height: _loadingIndicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: _loadingIndicatorStrokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: _loadingSpacing),
            Text(
              _loadingFeedsText,
              style: TextStyle(color: Colors.white, fontSize: _loadingTextFontSize),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        MapWidget(
          key: ValueKey('user_map_${widget.userId}'),
          styleUri: _getTimeBasedStyle(),
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(0, 20)),
            zoom: _initialZoomLevel,
          ),
          onMapCreated: (MapboxMap mapbox) {
            mapboxMap = mapbox;
            isMapInitialized = true;

            mapbox.getCameraState().then((cameraState) {
              if (mounted) {
                setState(() {
                  currentZoomLevel = cameraState.zoom;
                });
              }
            });

            _startZoomCheckTimer();

            mapbox.gestures.updateSettings(
              GesturesSettings(
                rotateEnabled: true,
                pinchToZoomEnabled: true,
                scrollEnabled: true,
                doubleTapToZoomInEnabled: true,
                doubleTouchToZoomOutEnabled: true,
                pinchToZoomDecelerationEnabled: true,
                rotateDecelerationEnabled: true,
                scrollDecelerationEnabled: true,
                quickZoomEnabled: true,
              ),
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (userFeeds.isNotEmpty && !_hasGroupedByCountry) {
                _handleGroupFeedsByCountry();
              }

              if (currentZoomLevel > _zoomThreshold) {
                _addFeedMarkersToMap(userFeeds);
              } else {
                _addCountryFeedMarkers();
              }

              _handleCheckUserLocationSharing();
            });
          },
        ),
        if (_isLoadingFeeds) _buildLoadingIndicator(),
      ],
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _zoomCheckTimer?.cancel();
    super.dispose();
  }
}