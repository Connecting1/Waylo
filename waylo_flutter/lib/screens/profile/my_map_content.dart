import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:image_cropper/image_cropper.dart';
import 'package:exif/exif.dart';
import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/feed_provider.dart';
import 'package:waylo_flutter/providers/feed_map_provider.dart';
import 'package:waylo_flutter/providers/map_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/screens/feed/create_feed_screen.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';
import 'dart:ui' as ui;
import 'package:waylo_flutter/screens/feed/feed_detail_sheet.dart';
import '../../providers/location_settings_provider.dart';
import '../../screens/feed/edit_feed_screen.dart';
import 'package:geolocator/geolocator.dart' as geo;

// 마커 클릭 리스너 클래스
class FeedPointClickListener implements OnPointAnnotationClickListener {
  final MyMapContentWidgetState state;

  FeedPointClickListener(this.state);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    state._handleFeedMarkerClick(annotation);
  }
}

// 국가 마커 클릭 리스너 클래스
class CountryPointClickListener implements OnPointAnnotationClickListener {
  final MyMapContentWidgetState state;

  CountryPointClickListener(this.state);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    state._handleCountryMarkerClick(annotation);
  }
}

class MyMapContentWidget extends StatefulWidget {
  final Function(bool) onCreatingFeedChanged;

  const MyMapContentWidget({
    Key? key,
    required this.onCreatingFeedChanged,
  }) : super(key: key);

  @override
  MyMapContentWidgetState createState() => MyMapContentWidgetState();
}

class MyMapContentWidgetState extends State<MyMapContentWidget> with AutomaticKeepAliveClientMixin {
  // 텍스트 상수들
  static const String _editPhotoTitle = "Edit Photo";
  static const String _loadingFeedsText = "Loading feeds...";

  // 성공 메시지 상수들
  static const String _feedCreatedSuccessMessage = "Feed created successfully.";

  // 에러 메시지 상수들
  static const String _feedLoadErrorMessage = "An error occurred while loading feed data.";
  static const String _locationInfoErrorMessage = "Unable to get location information.";
  static const String _feedCreationErrorMessage = "An error occurred while creating feed.";
  static const String _noLocationInfoMessage = "The selected photo has no location information.";
  static const String _photoProcessingErrorMessage = "An error occurred while processing photo:";

  // 폰트 크기 상수들
  static const double _loadingTextFontSize = 12;

  // 크기 상수들
  static const double _initialZoomLevel = 2.0;
  static const double _detailZoomLevel = 14.0;
  static const double _countryZoomLevel = 5.0;
  static const double _zoomThreshold = 4.0;
  static const double _userLocationIconSize = 1.2;
  static const double _feedMarkerIconSize = 1.0;
  static const double _countryMarkerIconSize = 0.3;
  static const double _photoMarkerIconSize = 0.1;

  // 이미지 크기 상수들
  static const int _userLocationImageSize = 120;
  static const int _userLocationPhotoSize = 100;
  static const double _userLocationBorderWidth = 7.0;
  static const int _feedMarkerImageSize = 170;
  static const int _feedMarkerPhotoSize = 150;
  static const double _feedMarkerBorderWidth = 7.0;
  static const int _resizedImageWidth = 150;

  // 애니메이션 지속시간 상수들
  static const int _flyToAnimationDuration = 1000;
  static const int _countryFlyToAnimationDuration = 1500;

  // 타이머 간격 상수들
  static const int _zoomCheckTimerInterval = 500;

  // URL 상수들
  static const String _flagUrlPrefix = "https://flagcdn.com/w320/";
  static const String _flagUrlSuffix = ".png";
  static const String _flagUrlAlternativePrefix = "https://flagcdn.com/";
  static const String _mapboxGeocodingBaseUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";
  static const String _countryTypeParam = "?types=country&access_token=";
  static const String _reverseGeocodingParam = ".json?access_token=";
  static const String _countryReverseGeocodingParam = "&types=country";

  // 파일 경로 상수들
  static const String _defaultFlagIconPath = "assets/icons/default_flag.png";

  // 좌표 변환 상수들
  static const double _minutesToDegrees = 60.0;
  static const double _secondsToDegrees = 3600.0;

  // GPS 방향 상수들
  static const String _southDirection = "S";
  static const String _westDirection = "W";
  static const String _northDirection = "N";
  static const String _eastDirection = "E";

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

  late MapboxMap mapboxMap;
  late String accessToken;
  PointAnnotationManager? photoAnnotationManager;
  PointAnnotationManager? feedAnnotationManager;
  PointAnnotationManager? countryFeedAnnotationManager;
  PointAnnotationManager? userLocationAnnotationManager;
  PointAnnotation? userLocationMarker;
  Timer? _locationUpdateTimer;
  bool _isLocationTrackingEnabled = false;

  Map<String, Map<String, dynamic>> countryData = {};
  Map<String, PointAnnotation> _countryMarkerMap = {};
  double currentZoomLevel = _initialZoomLevel;

  List<PointAnnotation> photoMarkers = [];
  List<PointAnnotation> feedMarkers = [];
  List<PointAnnotation> countryFeedMarkers = [];
  Map<String, PointAnnotation> feedMarkersMap = {};
  Map<String, Map<String, double>> _countryCenterCache = {};

  List<Map<String, dynamic>> photoLocations = [];

  Timer? _zoomCheckTimer;
  bool isMapInitialized = false;
  bool _isCreatingFeed = false;
  bool _isLoadingFeeds = false;
  bool _feedsUpdatedFlag = false;

  double? _initialLatitude;
  double? _initialLongitude;
  bool _isInitialPositionLoaded = false;

  @override
  void initState() {
    super.initState();
    accessToken = const String.fromEnvironment(_accessTokenKey);
    MapboxOptions.setAccessToken(accessToken);

    _handleGetCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCheckLocationSettings();
    });

    Future.microtask(() {
      _handleLoadFeedsForMap();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleCheckLocationSettings();
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
      final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
      try {
        Feed feed = feedMapProvider.mapFeeds.firstWhere((feed) => feed.id == feedId);
        _handleShowFeedDetailSheet(feed);
      } catch (e) {
        // 에러 처리
      }
    }
  }

  /// 위치 설정 확인 및 처리
  void _handleCheckLocationSettings() {
    if (!mounted) return;

    final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);

    if (locationSettingsProvider.isLocationSharingEnabled &&
        locationSettingsProvider.isLocationPermissionGranted) {
      if (!_isLocationTrackingEnabled) {
        _handleStartLocationTracking();
      }
    } else {
      if (_isLocationTrackingEnabled) {
        _handleStopLocationTracking();
      }
    }
  }

  /// 위치 공유 시작
  void _handleStartLocationTracking() {
    if (_isLocationTrackingEnabled || !isMapInitialized) return;

    _isLocationTrackingEnabled = true;

    final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
    int intervalMinutes = locationSettingsProvider.updateInterval;

    _locationUpdateTimer = Timer.periodic(
        Duration(minutes: intervalMinutes),
            (_) => _handleUpdateUserLocationMarker()
    );

    _handleUpdateUserLocationMarker();
  }

  /// 위치 공유 중지
  void _handleStopLocationTracking() {
    _isLocationTrackingEnabled = false;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _handleRemoveUserLocationMarker();
  }

  /// 사용자 위치 마커 업데이트
  Future<void> _handleUpdateUserLocationMarker() async {
    if (!isMapInitialized) return;

    try {
      bool permissionGranted = await _checkLocationPermission();
      if (!permissionGranted) {
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String profileImageUrl = userProvider.profileImage;

      if (profileImageUrl.isEmpty) {
        return;
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
        geometry: Point(coordinates: Position(position.longitude, position.latitude)),
        image: circleImage,
        iconSize: _userLocationIconSize,
      );

      userLocationMarker = await userLocationAnnotationManager!.create(pointAnnotationOptions);

    } catch (e) {
      // 에러 처리
    }
  }

  /// 사용자 위치 마커 제거
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

  /// Bottom Sheet 표시
  void _handleShowFeedDetailSheet(Feed feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FeedDetailSheet(
          feed: feed,
          onEditPressed: (feed) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditFeedScreen(feed: feed),
              ),
            ).then((updated) {
              if (updated == true) {
                _handleLoadFeedsForMap();

                setState(() {
                  _feedsUpdatedFlag = true;
                });

                if (currentZoomLevel <= _zoomThreshold) {
                  _handleRefreshCountryMarkers();
                }
              }
            });
          },
        );
      },
    );
  }

  /// 현재 위치 가져오기
  Future<void> _handleGetCurrentLocation() async {
    try {
      bool permissionGranted = await _checkLocationPermission();
      if (!permissionGranted) {
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high
      );

      setState(() {
        _initialLatitude = position.latitude;
        _initialLongitude = position.longitude;
        _isInitialPositionLoaded = true;
      });

      if (isMapInitialized && mounted) {
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: _initialZoomLevel,
          ),
          MapAnimationOptions(duration: _flyToAnimationDuration),
        );
      }
    } catch (e) {
      // 에러 처리
    }
  }

  /// 국기 마커만 새로고침
  Future<void> _handleRefreshCountryMarkers() async {
    final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);

    feedMapProvider.reset();
    await feedMapProvider.loadFeedsForMap(refresh: true);

    feedMapProvider.groupFeedsByCountry();

    if (countryFeedAnnotationManager != null) {
      for (var marker in countryFeedMarkers) {
        await countryFeedAnnotationManager!.delete(marker);
      }
      countryFeedMarkers.clear();
      _countryMarkerMap.clear();
    }

    await _addCountryFeedMarkers();
  }

  /// 지도용 피드 로드
  Future<void> _handleLoadFeedsForMap() async {
    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
      await feedMapProvider.loadFeedsForMap(refresh: true);

      if (isMapInitialized) {
        if (feedMapProvider.mapFeeds.isNotEmpty) {
          if (currentZoomLevel > _zoomThreshold) {
            await _addFeedMarkersToMap(feedMapProvider.mapFeeds);
          } else {
            await _addCountryFeedMarkers();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_feedLoadErrorMessage)),
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
      feedAnnotationManager!.addOnPointAnnotationClickListener(FeedPointClickListener(this));
    }
  }

  /// 국가별 피드 마커 추가
  Future<void> _addCountryFeedMarkers() async {
    final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);

    if (feedMapProvider.countryFeeds.isEmpty) {
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

    for (String countryCode in feedMapProvider.countryFeeds.keys) {
      if (countryCode == _unknownCountryCode || countryCode.isEmpty) continue;

      List<Feed> feedsInCountry = feedMapProvider.countryFeeds[countryCode]!;
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

  /// 가시성 업데이트
  void _handleUpdateVisibility() async {
    if (!isMapInitialized) return;

    _handleCheckLocationSettings();

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

      final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
      if (feedMarkers.isEmpty && feedMapProvider.mapFeeds.isNotEmpty) {
        await _addFeedMarkersToMap(feedMapProvider.mapFeeds);
      }

      if (photoMarkers.isEmpty && photoLocations.isNotEmpty) {
        await _addStoredPhotoMarkers();
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

      if (photoAnnotationManager != null) {
        for (var marker in List.from(photoMarkers)) {
          try {
            await photoAnnotationManager!.delete(marker);
            photoMarkers.remove(marker);
          } catch (e) {
            // 에러 처리
          }
        }
      }

      if (_feedsUpdatedFlag) {
        await _handleRefreshCountryMarkers();

        setState(() {
          _feedsUpdatedFlag = false;
        });
      } else if (countryFeedMarkers.isEmpty) {
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

  /// 좌표에서 국가 코드 가져오기
  Future<String?> _getCountryCodeFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "$_mapboxGeocodingBaseUrl$longitude,$latitude$_reverseGeocodingParam$accessToken$_countryReverseGeocodingParam";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["properties"]["short_code"]?.toUpperCase();
        }
      }
    } catch (e) {
      // 에러 처리
    }
    return null;
  }

  /// 저장된 사진 마커 추가
  Future<void> _addStoredPhotoMarkers() async {
    for (var photoData in photoLocations) {
      await _addMarkerToMap(
          photoData["latitude"],
          photoData["longitude"],
          photoData["image"],
          _photoMarkerIconSize,
          isPhoto: true
      );
    }
  }

  /// 피드 생성
  Future<void> createFeed() async {
    if (_isCreatingFeed) return;

    setState(() {
      _isCreatingFeed = true;
    });
    widget.onCreatingFeedChanged(true);

    try {
      final File? pickedImage = await _handlePickAndCropImage();
      if (pickedImage == null) {
        _handleResetCreatingState();
        return;
      }

      Map<String, dynamic>? locationData = await _extractLocationFromImage(pickedImage);
      double? latitude;
      double? longitude;

      if (locationData != null) {
        latitude = locationData["latitude"];
        longitude = locationData["longitude"];
      } else {
        try {
          CameraState cameraState = await mapboxMap.getCameraState();
          latitude = cameraState.center.coordinates.lat.toDouble();
          longitude = cameraState.center.coordinates.lng.toDouble();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_locationInfoErrorMessage))
          );
          _handleResetCreatingState();
          return;
        }
      }

      _handleResetCreatingState();

      final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedCreatePage(
              imageFile: pickedImage,
              initialLatitude: latitude,
              initialLongitude: longitude,
              accessToken: accessToken,
            ),
          )
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_feedCreatedSuccessMessage))
        );

        final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
        feedMapProvider.reset();

        await _handleLoadFeedsForMap();

        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(longitude!, latitude!)),
            zoom: currentZoomLevel,
          ),
          MapAnimationOptions(duration: _flyToAnimationDuration),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_feedCreationErrorMessage))
      );
      _handleResetCreatingState();
    }
  }

  /// 피드 생성 상태 리셋
  void _handleResetCreatingState() {
    setState(() {
      _isCreatingFeed = false;
    });
    widget.onCreatingFeedChanged(false);
  }

  /// 이미지 선택 및 크롭
  Future<File?> _handlePickAndCropImage() async {
    final picker = image_picker.ImagePicker();
    final image_picker.XFile? pickedImage = await picker.pickImage(source: image_picker.ImageSource.gallery);

    if (pickedImage == null) return null;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: _editPhotoTitle,
          toolbarColor: themeProvider.isDarkMode
              ? AppColors.darkSurface
              : AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: _editPhotoTitle,
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  /// 지도에 이미지 추가
  Future<void> _handleAddImageToMap(File imageFile, double latitude, double longitude) async {
    try {
      Uint8List resizedPhoto = await _resizeImage(imageFile, _resizedImageWidth);

      if (currentZoomLevel > _zoomThreshold) {
        await _addMarkerToMap(latitude, longitude, resizedPhoto, _photoMarkerIconSize, isPhoto: true);
      }

      photoLocations.add({
        "latitude": latitude,
        "longitude": longitude,
        "image": resizedPhoto,
      });

      await _getCountryCodeFromCoordinates(latitude, longitude);

      mapboxMap.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: currentZoomLevel,
        ),
        MapAnimationOptions(duration: _flyToAnimationDuration),
      );
    } catch (e) {
      // 에러 처리
    }
  }

  /// 좌표에서 위치명 가져오기
  Future<String?> _getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "$_mapboxGeocodingBaseUrl$longitude,$latitude$_reverseGeocodingParam$accessToken";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["place_name"];
        }
      }
    } catch (e) {
      // 에러 처리
    }
    return null;
  }

  /// 이미지에서 위치 정보 추출
  Future<Map<String, dynamic>?> _extractLocationFromImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? _northDirection);
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? _eastDirection);

        return {
          "latitude": lat,
          "longitude": lon,
        };
      }
    } catch (e) {
      // 에러 처리
    }
    return null;
  }

  /// 위치 추출 및 마커 추가
  Future<void> _handleExtractLocationAndAddMarker(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? _northDirection);
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? _eastDirection);

        Uint8List resizedPhoto = await _resizeImage(imageFile, _resizedImageWidth);

        photoLocations.add({
          "latitude": lat,
          "longitude": lon,
          "image": resizedPhoto,
        });

        if (currentZoomLevel > _zoomThreshold) {
          await _addMarkerToMap(lat, lon, resizedPhoto, _photoMarkerIconSize, isPhoto: true);
        }

        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lon, lat)),
            zoom: currentZoomLevel,
          ),
          MapAnimationOptions(duration: _flyToAnimationDuration),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_noLocationInfoMessage))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_photoProcessingErrorMessage $e"))
      );
    }
  }

  /// 지도에 마커 추가
  Future<void> _addMarkerToMap(double lat, double lon, Uint8List imageData, double size, {required bool isPhoto}) async {
    if (photoAnnotationManager == null) {
      photoAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lon, lat)),
      image: imageData,
      iconSize: size,
    );

    if (isPhoto) {
      PointAnnotation marker = await photoAnnotationManager!.create(pointAnnotationOptions);
      photoMarkers.add(marker);
    }
  }

  /// 위치 권한 확인
  Future<bool> _checkLocationPermission() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return false;
    }

    return true;
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

  /// 이미지 리사이즈
  Future<Uint8List> _resizeImage(File imageFile, int width) async {
    Uint8List imageData = await imageFile.readAsBytes();
    return imageData;
  }

  /// 십진수로 변환
  double _convertToDecimal(List values, String? ref) {
    double degrees = values[0].numerator / values[0].denominator;
    double minutes = values[1].numerator / values[1].denominator;
    double seconds = values[2].numerator / values[2].denominator;

    double decimal = degrees + (minutes / _minutesToDegrees) + (seconds / _secondsToDegrees);
    if (ref == _southDirection || ref == _westDirection) {
      decimal = -decimal;
    }
    return decimal;
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
          key: PageStorageKey('map_key'),
          styleUri: _getTimeBasedStyle(),
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(
                _initialLongitude ?? 0,
                _initialLatitude ?? 20
            )),
            zoom: _isInitialPositionLoaded ? _detailZoomLevel : _initialZoomLevel,
          ),
          onMapCreated: (MapboxMap mapbox) {
            mapboxMap = mapbox;
            isMapInitialized = true;

            if (_isInitialPositionLoaded && _initialLatitude != null && _initialLongitude != null) {
              mapbox.flyTo(
                CameraOptions(
                  center: Point(coordinates: Position(_initialLongitude!, _initialLatitude!)),
                  zoom: _initialZoomLevel,
                ),
                MapAnimationOptions(duration: _flyToAnimationDuration),
              );
            }

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
              final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
              if (feedMapProvider.mapFeeds.isNotEmpty && !feedMapProvider.hasGroupedByCountry) {
                feedMapProvider.groupFeedsByCountry();
              }

              if (currentZoomLevel > _zoomThreshold) {
                _addFeedMarkersToMap(feedMapProvider.mapFeeds);
              } else {
                _addCountryFeedMarkers();
              }

              final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
              if (locationSettingsProvider.isLocationSharingEnabled &&
                  locationSettingsProvider.isLocationPermissionGranted) {
                _handleUpdateUserLocationMarker();
              }
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