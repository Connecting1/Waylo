// lib/screens/profile/my_map_content.dart

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
  double currentZoomLevel = 2.0;

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
    accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);

    _getCurrentLocation();

    // 위치 설정 상태 확인을 위한 코드 추가
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationSettings();
    });

    Future.microtask(() {
      _loadFeedsForMap();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLocationSettings();
  }

  // 마커 클릭 처리 함수
  void _handleFeedMarkerClick(PointAnnotation annotation) {
    print("마커 클릭됨: ${annotation.id}");

    // 클릭된 마커에 해당하는 피드 ID 찾기
    String? feedId;
    feedMarkersMap.forEach((id, marker) {
      if (marker.id == annotation.id) {
        feedId = id;
        print("피드 ID 찾음: $id");
      }
    });

    if (feedId != null) {
      // 피드 ID를 이용해 피드 객체 찾기
      final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
      try {
        Feed feed = feedMapProvider.mapFeeds.firstWhere((feed) => feed.id == feedId);
        print("피드 객체 찾음: ${feed.id}, 사용자=${feed.username}");
        _showFeedDetailSheet(feed);
      } catch (e) {
        print("[ERROR] 피드를 찾을 수 없음: $e");
      }
    } else {
      print("피드 ID를 찾을 수 없음");
    }
  }

  // 위치 설정 확인 및 처리 메서드
  void _checkLocationSettings() {
    if (!mounted) return;

    final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);

    if (locationSettingsProvider.isLocationSharingEnabled &&
        locationSettingsProvider.isLocationPermissionGranted) {
      if (!_isLocationTrackingEnabled) {
        _startLocationTracking();
      }
    } else {
      if (_isLocationTrackingEnabled) {
        _stopLocationTracking();
      }
    }
  }

  // 위치 공유 시작 메서드
  void _startLocationTracking() {
    if (_isLocationTrackingEnabled || !isMapInitialized) return;

    _isLocationTrackingEnabled = true;
    print("[위치 추적] 시작");

    final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);

    // 위치 갱신 타이머 설정
    int intervalMinutes = locationSettingsProvider.updateInterval;
    _locationUpdateTimer = Timer.periodic(
        Duration(minutes: intervalMinutes),
            (_) => _updateUserLocationMarker()
    );

    // 최초 한 번 즉시 업데이트
    _updateUserLocationMarker();
  }

// 위치 공유 중지 메서드
  void _stopLocationTracking() {
    _isLocationTrackingEnabled = false;
    print("[위치 추적] 중지");

    // 타이머 취소
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    // 사용자 위치 마커 제거
    _removeUserLocationMarker();
  }

  // 사용자 위치 마커 업데이트
  Future<void> _updateUserLocationMarker() async {
    if (!isMapInitialized) return;

    try {
      // 위치 권한 확인
      bool permissionGranted = await _checkLocationPermission();
      if (!permissionGranted) {
        print("[위치 추적] 권한 없음");
        return;
      }

      // 현재 위치 가져오기
      geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high
      );

      print("[위치 추적] 현재 위치: ${position.latitude}, ${position.longitude}");

      // 사용자 프로필 이미지 가져오기
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String profileImageUrl = userProvider.profileImage;

      if (profileImageUrl.isEmpty) {
        print("[위치 추적] 프로필 이미지 없음");
        return;
      }

      // 프로필 이미지 다운로드
      Uint8List? imageData = await _downloadImage(profileImageUrl);

      if (imageData == null) {
        print("[위치 추적] 이미지 다운로드 실패");
        return;
      }

      // 원형 테두리 추가
      Uint8List circleImage = await _addCircleBorderToImage(imageData);

      // 이전 마커 제거
      if (userLocationMarker != null && userLocationAnnotationManager != null) {
        await userLocationAnnotationManager!.delete(userLocationMarker!);
        userLocationMarker = null;
      }

      // 사용자 위치 마커 매니저 생성
      if (userLocationAnnotationManager == null) {
        userLocationAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      }

      // 마커 생성
      PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(position.longitude, position.latitude)),
        image: circleImage,
        iconSize: 1.2, // 일반 마커보다 약간 크게
      );

      userLocationMarker = await userLocationAnnotationManager!.create(pointAnnotationOptions);
      print("[위치 추적] 마커 생성 완료");

    } catch (e) {
      print("[위치 추적] 오류: $e");
    }
  }

  // 프로필 이미지를 원형으로 처리하는 메서드
  Future<Uint8List> _addCircleBorderToImage(Uint8List imageBytes) async {
    final int size = 120;  // 최종 이미지 크기
    final int photoSize = 100;  // 실제 사진 크기
    final double borderWidth = 7.0;  // 테두리 두께

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    // 이미지 디코딩
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final double photoLeft = (size - photoSize) / 2;
    final double photoTop = (size - photoSize) / 2;

    // 파란색 원형 테두리 그리기
    final Paint borderPaint = Paint()
      ..color = AppColors.primary  // 파란색 테두리
      ..style = PaintingStyle.fill;

    // 테두리용 원
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      photoSize / 2 + borderWidth,
      borderPaint,
    );

    // 이미지를 원형으로 클리핑
    final Path clipPath = Path()
      ..addOval(Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble()));

    canvas.clipPath(clipPath);

    // 이미지 비율 계산
    double srcWidth = frameInfo.image.width.toDouble();
    double srcHeight = frameInfo.image.height.toDouble();
    double srcX = 0;
    double srcY = 0;

    // 정사각형으로 크롭
    if (srcWidth > srcHeight) {
      srcX = (srcWidth - srcHeight) / 2;
      srcWidth = srcHeight;
    } else if (srcHeight > srcWidth) {
      srcY = (srcHeight - srcWidth) / 2;
      srcHeight = srcWidth;
    }

    // 이미지 그리기
    final Rect srcRect = Rect.fromLTWH(srcX, srcY, srcWidth, srcHeight);
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble());

    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    // 최종 이미지 생성
    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // 사용자 위치 마커 생성
  Future<PointAnnotation> _createUserLocationMarker(double latitude, double longitude, Uint8List imageData) async {
    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(longitude, latitude)),
      image: imageData,
      iconSize: 1.2, // 일반 마커보다 약간 크게
    );

    return await userLocationAnnotationManager!.create(pointAnnotationOptions);
  }

  // 사용자 위치 마커 제거 메서드
  Future<void> _removeUserLocationMarker() async {
    if (userLocationMarker != null && userLocationAnnotationManager != null) {
      try {
        await userLocationAnnotationManager!.delete(userLocationMarker!);
        userLocationMarker = null;
        print("[위치 추적] 마커 제거 완료");
      } catch (e) {
        print("[위치 추적] 마커 제거 오류: $e");
      }
    }
  }

  // 위치 마커용 특별 테두리 스타일
  // Future<Uint8List> _addLocationBorderToImage(Uint8List imageBytes) async {
  //   final int size = 170;
  //   final int photoSize = 150;
  //   final double borderWidth = 8.0; // 더 두꺼운 테두리
  //
  //   final ui.PictureRecorder recorder = ui.PictureRecorder();
  //   final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  //
  //   final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
  //   final ui.FrameInfo frameInfo = await codec.getNextFrame();
  //
  //   final double photoLeft = (size - photoSize) / 2;
  //   final double photoTop = (size - photoSize) / 2;
  //
  //   // 푸른 테두리 색상
  //   final Paint borderPaint = Paint()
  //     ..color = Colors.blue // 현재 위치는 파란색 테두리로 강조
  //     ..style = PaintingStyle.fill;
  //
  //   canvas.drawRRect(
  //     RRect.fromRectAndRadius(
  //       Rect.fromLTWH(photoLeft - borderWidth, photoTop - borderWidth,
  //           photoSize + (borderWidth * 2), photoSize + (borderWidth * 2)),
  //       Radius.circular(size / 2), // 완전한 원형
  //     ),
  //     borderPaint,
  //   );
  //
  //   // 프로필 이미지를 원형으로 표시
  //   final Path clipPath = Path()
  //     ..addOval(Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble()));
  //
  //   canvas.clipPath(clipPath);
  //
  //   double srcWidth = frameInfo.image.width.toDouble();
  //   double srcHeight = frameInfo.image.height.toDouble();
  //   double srcX = 0;
  //   double srcY = 0;
  //
  //   if (srcWidth > srcHeight) {
  //     srcX = (srcWidth - srcHeight) / 2;
  //     srcWidth = srcHeight;
  //   } else if (srcHeight > srcWidth) {
  //     srcY = (srcHeight - srcWidth) / 2;
  //     srcHeight = srcWidth;
  //   }
  //
  //   final Rect srcRect = Rect.fromLTWH(srcX, srcY, srcWidth, srcHeight);
  //   final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble());
  //
  //   canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());
  //
  //   final ui.Image image = await recorder.endRecording().toImage(size, size);
  //   final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  //
  //   return byteData!.buffer.asUint8List();
  // }

  // 국가 마커 클릭 처리 함수
  void _handleCountryMarkerClick(PointAnnotation annotation) {
    print("국가 마커 클릭됨: ${annotation.id}");

    // 클릭된 마커에 해당하는 국가 정보 찾기
    String? countryCode;
    for (String code in _countryMarkerMap.keys) {
      if (_countryMarkerMap[code]?.id == annotation.id) {
        countryCode = code;
        break;
      }
    }

    if (countryCode != null) {
      // 해당 국가의 중심 좌표 찾기
      Map<String, double>? centerCoords = _countryCenterCache[countryCode];
      if (centerCoords != null) {
        // 국가로 줌인
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(
                centerCoords['lng']!,
                centerCoords['lat']!
            )),
            zoom: 5.0, // 적절한 줌 레벨 설정
          ),
          MapAnimationOptions(duration: 1500), // 애니메이션 지속시간
        );
      }
    }
  }

  // Bottom Sheet 표시 함수
  void _showFeedDetailSheet(Feed feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FeedDetailSheet(
          feed: feed,
          onEditPressed: (feed) {
            // 수정 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditFeedScreen(feed: feed),
              ),
            ).then((updated) {
              // 업데이트가 성공적으로 이루어졌으면 피드 목록 새로고침
              if (updated == true) {
                _loadFeedsForMap();

                setState(() {
                  _feedsUpdatedFlag = true;
                });

                if (currentZoomLevel <= 4.0) {
                  _refreshCountryMarkers();
                }
              }
            });
          },
        );
      },
    );
  }

  // 현재 위치 가져오기 함수
  Future<void> _getCurrentLocation() async {
    try {
      bool permissionGranted = await _checkLocationPermission();
      if (!permissionGranted) {
        print("위치 권한이 없습니다.");
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
        // 이미 지도가 초기화되었다면 현재 위치로 이동
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom:2.0, // 더 자세한 줌 레벨
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    } catch (e) {
      print("현재 위치 가져오기 오류: $e");
    }
  }


// 위치 권한 확인
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


  // 국기 마커만 새로고침
  Future<void> _refreshCountryMarkers() async {
    final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);

    // 완전히 초기화 및 새로 로드
    feedMapProvider.reset();
    await feedMapProvider.loadFeedsForMap(refresh: true);

    // 기존 국가별 피드 그룹화 초기화
    feedMapProvider.groupFeedsByCountry();

    // 기존 국기 마커 제거
    if (countryFeedAnnotationManager != null) {
      for (var marker in countryFeedMarkers) {
        await countryFeedAnnotationManager!.delete(marker);
      }
      countryFeedMarkers.clear();
      _countryMarkerMap.clear();
    }

    // 국기 마커 다시 추가
    await _addCountryFeedMarkers();

    print("국가별 피드 및 마커 새로고침 완료");
  }

  Future<void> _loadFeedsForMap() async {
    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
      await feedMapProvider.loadFeedsForMap(refresh: true);

      if (isMapInitialized) {
        if (feedMapProvider.mapFeeds.isEmpty) {
        } else {
          if (currentZoomLevel > 4.0) {
            await _addFeedMarkersToMap(feedMapProvider.mapFeeds);
          } else {
            await _addCountryFeedMarkers();
          }
        }
      } else {
        print("[ERROR] 지도가 초기화되지 않았습니다!");
      }
    } catch (e) {
      print("[ERROR] 피드 로드 및 마커 생성 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("피드 데이터를 로드하는 중 오류가 발생했습니다.")),
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
          iconSize: 1,
        );

        PointAnnotation marker = await feedAnnotationManager!.create(pointAnnotationOptions);
        print("피드 마커 생성: ID=${marker.id}, 피드 ID=${feed.id}");

        feedMarkers.add(marker);
        feedMarkersMap[feed.id] = marker;

      } catch (e) {
        print("[ERROR] 피드 마커 추가 오류 (${feed.id}): $e");
      }
    }

    // 마커 생성 후 클릭 리스너 등록
    if (feedAnnotationManager != null) {
      feedAnnotationManager!.addOnPointAnnotationClickListener(FeedPointClickListener(this));
    }
  }

  Future<Uint8List> _addBorderToImage(Uint8List imageBytes) async {
    final int size = 170;
    final int photoSize = 150;
    final double borderWidth = 7.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final double photoLeft = (size - photoSize) / 2;
    final double photoTop = (size - photoSize) / 2;

    final Paint borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(photoLeft - borderWidth, photoTop - borderWidth,
            photoSize + (borderWidth * 2), photoSize + (borderWidth * 2)),
        Radius.circular(8),
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
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble());

    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _addCountryFeedMarkers() async {
    final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);

    if (feedMapProvider.countryFeeds.isEmpty) {
      print("️[ERROR] 표시할 국가별 피드가 없습니다.");
      return;
    }

    if (countryFeedAnnotationManager == null) {
      countryFeedAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    for (var marker in countryFeedMarkers) {
      await countryFeedAnnotationManager!.delete(marker);
    }
    countryFeedMarkers.clear();
    _countryMarkerMap.clear(); // 맵 초기화 추가

    for (String countryCode in feedMapProvider.countryFeeds.keys) {
      if (countryCode == "UNKNOWN" || countryCode.isEmpty) continue;

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

        String flagUrl = "https://flagcdn.com/w320/${countryCode.toLowerCase()}.png";
        flagImage = await _downloadImage(flagUrl);

        if (flagImage == null) {
          flagUrl = "https://flagcdn.com/${countryCode.toLowerCase()}.png";
          flagImage = await _downloadImage(flagUrl);
        }

        if (flagImage == null) {
          ByteData data = await rootBundle.load('assets/icons/default_flag.png');
          flagImage = data.buffer.asUint8List();
        }

        PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(feedLon, feedLat)),
          image: flagImage,
          iconSize: 0.3,
        );

        PointAnnotation marker = await countryFeedAnnotationManager!.create(pointAnnotationOptions);
        countryFeedMarkers.add(marker);
        _countryMarkerMap[countryCode] = marker; // 마커 맵에 추가
      } catch (e) {
        print("[ERROR] 국가 ${countryCode} 마커 추가 실패: $e");
      }
    }

    // 마커 생성 후 클릭 리스너 등록
    if (countryFeedAnnotationManager != null) {
      countryFeedAnnotationManager!.addOnPointAnnotationClickListener(
          CountryPointClickListener(this)
      );
    }
  }

  void _startZoomCheckTimer() {
    _zoomCheckTimer?.cancel();
    _zoomCheckTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (isMapInitialized && mounted) {
        mapboxMap.getCameraState().then((cameraState) {
          if (currentZoomLevel != cameraState.zoom) {
            setState(() {
              currentZoomLevel = cameraState.zoom;
              _updateVisibility();
            });
          }
        });
      }
    });
  }

  // _updateVisibility 메서드에 위치 설정 확인 코드 추가
  void _updateVisibility() async {
    if (!isMapInitialized) return;

    // 위치 공유 설정 확인 - 항상 실행하여 프로필 마커 표시
    _checkLocationSettings();

    if (currentZoomLevel > 4.0) {
      // 줌인 상태 - 개별 피드 마커 표시
      if (countryFeedAnnotationManager != null) {
        for (var marker in List.from(countryFeedMarkers)) {
          try {
            await countryFeedAnnotationManager!.delete(marker);
            countryFeedMarkers.remove(marker);
          } catch (e) {
            print("[ERROR] 국가 피드 마커 삭제 오류: $e");
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
      // 줌아웃 상태 - 국기 마커 표시
      if (feedAnnotationManager != null) {
        for (var marker in List.from(feedMarkers)) {
          try {
            await feedAnnotationManager!.delete(marker);
            feedMarkers.remove(marker);
          } catch (e) {
            print("[ERROR] 피드 마커 삭제 오류: $e");
          }
        }
      }

      if (photoAnnotationManager != null) {
        for (var marker in List.from(photoMarkers)) {
          try {
            await photoAnnotationManager!.delete(marker);
            photoMarkers.remove(marker);
          } catch (e) {
            print("[ERROR] 사진 마커 삭제 오류: $e");
          }
        }
      }

      // 피드가 업데이트된 경우 강제로 데이터 새로고침
      if (_feedsUpdatedFlag) {
        final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);

        // 상태 초기화 및 새로고침
        await _refreshCountryMarkers();

        setState(() {
          _feedsUpdatedFlag = false;
        });
      }
      // 국기 마커가 없는 경우 새로고침
      else if (countryFeedMarkers.isEmpty) {
        await _addCountryFeedMarkers();
      }
    }
  }

  Future<Map<String, double>?> _getCountryCenter(String countryCode) async {
    try {
      if (_countryCenterCache.containsKey(countryCode)) {
        return _countryCenterCache[countryCode];
      }

      String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/${countryCode}.json?types=country&access_token=$accessToken";
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
      print("[ERROR] 국가 중심 좌표 검색 오류: $e");
    }
    return null;
  }

  Future<String?> _getCountryCodeFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$accessToken&types=country";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["properties"]["short_code"]?.toUpperCase();
        }
      }
    } catch (e) {
      print("[ERROR] 국가 코드 검색 오류: $e");
    }
    return null;
  }

  Future<void> _addStoredPhotoMarkers() async {
    for (var photoData in photoLocations) {
      await _addMarkerToMap(
          photoData["latitude"],
          photoData["longitude"],
          photoData["image"],
          0.1,
          isPhoto: true
      );
    }
  }

  // 외부에서 직접 호출할 수 있도록 public 메서드로 변경
  Future<void> createFeed() async {
    if (_isCreatingFeed) return;

    setState(() {
      _isCreatingFeed = true;
    });
    widget.onCreatingFeedChanged(true);

    try {
      final File? pickedImage = await _pickAndCropImage();
      if (pickedImage == null) {
        setState(() {
          _isCreatingFeed = false;
        });
        widget.onCreatingFeedChanged(false);
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
          print("카메라 상태 가져오기 오류: $e");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("위치 정보를 가져올 수 없습니다."))
          );
          setState(() {
            _isCreatingFeed = false;
          });
          widget.onCreatingFeedChanged(false);
          return;
        }
      }

      setState(() {
        _isCreatingFeed = false;
      });
      widget.onCreatingFeedChanged(false);

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
            SnackBar(content: Text("피드가 성공적으로 생성되었습니다."))
        );

        final feedMapProvider = Provider.of<FeedMapProvider>(context, listen: false);
        feedMapProvider.reset();

        await _loadFeedsForMap();

        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(longitude!, latitude!)),
            zoom: currentZoomLevel,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    } catch (e) {
      print("피드 생성 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("피드 생성 중 오류가 발생했습니다."))
      );
      setState(() {
        _isCreatingFeed = false;
      });
      widget.onCreatingFeedChanged(false);
    }
  }

  Future<File?> _pickAndCropImage() async {
    final picker = image_picker.ImagePicker();
    final image_picker.XFile? pickedImage = await picker.pickImage(source: image_picker.ImageSource.gallery);

    if (pickedImage == null) return null;

    File originalFile = File(pickedImage.path);

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Edit Photo',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _addImageToMap(File imageFile, double latitude, double longitude) async {
    try {
      Uint8List resizedPhoto = await _resizeImage(imageFile, 150);

      if (currentZoomLevel > 4.0) {
        await _addMarkerToMap(latitude, longitude, resizedPhoto, 0.1, isPhoto: true);
      }

      photoLocations.add({
        "latitude": latitude,
        "longitude": longitude,
        "image": resizedPhoto,
      });

      String? countryCode = await _getCountryCodeFromCoordinates(latitude, longitude);

      mapboxMap.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: currentZoomLevel,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      print("이미지 지도 추가 중 오류: $e");
    }
  }

  Future<String?> _getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$accessToken";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["place_name"];
        }
      }
    } catch (e) {
      print("위치명 검색 오류: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> _extractLocationFromImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.containsKey('GPS GPSLatitude')) {
        var latTag = data['GPS GPSLatitude'];
        print("위도 태그 전체 내용: $latTag");
        print("위도 태그 타입: ${latTag.runtimeType}");

        // IfdTag의 사용 가능한 모든 속성과 메서드 확인
        print("위도 태그 속성들:");
        print("toString(): ${latTag.toString()}");
        print("hashCode: ${latTag.hashCode}");

        // 직접 속성 접근 시도
        try {
          var props = latTag.toString().split(',');
          for (var prop in props) {
            print("속성: $prop");
          }
        } catch (e) {
          print("속성 분석 실패: $e");
        }
      }

      // GPS 관련 키만 출력
      print("모든 GPS 관련 키:");
      for (var key in data.keys) {
        if (key.toString().contains('GPS')) {
          print("- $key: ${data[key]}");
        }
      }

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? "N");
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? "E");

        print("변환된 좌표: lat=$lat, lon=$lon");

        return {
          "latitude": lat,
          "longitude": lon,
        };
      }
    } catch (e) {
      print("위치 정보 추출 중 오류: $e");
    }
    return null;
  }

  Future<void> _extractLocationAndAddMarker(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? "N");
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? "E");

        Uint8List resizedPhoto = await _resizeImage(imageFile, 150);

        photoLocations.add({
          "latitude": lat,
          "longitude": lon,
          "image": resizedPhoto,
        });

        if (currentZoomLevel > 4.0) {
          await _addMarkerToMap(lat, lon, resizedPhoto, 0.1, isPhoto: true);
        }

        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lon, lat)),
            zoom: currentZoomLevel,
          ),
          MapAnimationOptions(duration: 1000),
        );
      } else {
        debugPrint("[ERROR] 사진에 위치 정보 없음");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("선택한 사진에 위치 정보가 없습니다."))
        );
      }
    } catch (e) {
      debugPrint("⚠️ 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("사진 처리 중 오류가 발생했습니다: $e"))
      );
    }
  }

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

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("[ERROR] 다운로드 실패 - 상태 코드: ${response.statusCode}");
      }
    } catch (e) {
      print("[ERROR] 이미지 다운로드 오류 상세: $e");
    }
    return null;
  }

  Future<Uint8List> _resizeImage(File imageFile, int width) async {
    Uint8List imageData = await imageFile.readAsBytes();
    return imageData;
  }

  double _convertToDecimal(List values, String? ref) {
    double degrees = values[0].numerator / values[0].denominator;
    double minutes = values[1].numerator / values[1].denominator;
    double seconds = values[2].numerator / values[2].denominator;

    double decimal = degrees + (minutes / 60) + (seconds / 3600);
    if (ref == "S" || ref == "W") {
      decimal = -decimal;
    }
    return decimal;
  }

  String _getTimeBasedStyle() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 18) {
      return MapboxStyles.MAPBOX_STREETS; // 낮 시간 스타일
    } else {
      return MapboxStyles.MAPBOX_STREETS; // 밤 시간 스타일
    }
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
            zoom: _isInitialPositionLoaded ? 14.0 : 2.0,
          ),
          onMapCreated: (MapboxMap mapbox) {
            mapboxMap = mapbox;
            isMapInitialized = true;

            // 현재 위치가 이미 로드되었다면 해당 위치로 이동
            if (_isInitialPositionLoaded && _initialLatitude != null && _initialLongitude != null) {
              mapbox.flyTo(
                CameraOptions(
                  center: Point(coordinates: Position(_initialLongitude!, _initialLatitude!)),
                  zoom: 2.0,
                ),
                MapAnimationOptions(duration: 1000),
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

              if (currentZoomLevel > 4.0) {
                _addFeedMarkersToMap(feedMapProvider.mapFeeds);
              } else {
                _addCountryFeedMarkers();
              }

              // 위치 공유 설정에 따라 프로필 핀 생성 (이 부분 추가)
              final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
              if (locationSettingsProvider.isLocationSharingEnabled &&
                  locationSettingsProvider.isLocationPermissionGranted) {
                _updateUserLocationMarker();  // 여기서 프로필 핀 생성
              }
            });
          },
        ),
        if (_isLoadingFeeds)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Loading feeds...",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
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