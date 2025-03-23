import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:async';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/screens/feed/feed_detail_sheet.dart';
import '../../styles/app_styles.dart';
import 'dart:ui' as ui;
import 'package:waylo_flutter/services/api/feed_api.dart';

// 마커 클릭 리스너 클래스
class UserPointClickListener implements OnPointAnnotationClickListener {
  final UserMapContentWidgetState state;

  UserPointClickListener(this.state);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    state._handleFeedMarkerClick(annotation);
  }
}

// 마커 클릭 리스너 클래스 추가
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
  late MapboxMap mapboxMap;
  late String accessToken;
  PointAnnotationManager? feedAnnotationManager;
  PointAnnotationManager? countryFeedAnnotationManager;

  Map<String, Map<String, dynamic>> countryData = {};
  double currentZoomLevel = 2.0;

  List<PointAnnotation> feedMarkers = [];
  List<PointAnnotation> countryFeedMarkers = [];
  Map<String, PointAnnotation> feedMarkersMap = {};
  Map<String, Map<String, double>> _countryCenterCache = {};

  List<Feed> userFeeds = [];
  Map<String, List<Feed>> _countryFeeds = {}; // 국가 코드별 피드 그룹
  Map<String, PointAnnotation> _countryMarkerMap = {};
  bool _hasGroupedByCountry = false;

  Timer? _zoomCheckTimer;
  bool isMapInitialized = false;
  bool _isLoadingFeeds = false;

  @override
  void initState() {
    super.initState();
    accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);

    Future.microtask(() {
      _loadUserFeeds();
    });
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
      try {
        Feed feed = userFeeds.firstWhere((feed) => feed.id == feedId);
        print("피드 객체 찾음: ${feed.id}, 사용자=${feed.username}");
        _showFeedDetailSheet(feed);
      } catch (e) {
        print("[ERROR] 피드를 찾을 수 없음: $e");
      }
    } else {
      print("피드 ID를 찾을 수 없음");
    }
  }

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

  // Bottom Sheet 표시 함수 - 읽기 전용 모드
  void _showFeedDetailSheet(Feed feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FeedDetailSheet(
          feed: feed,
          onEditPressed: (_) {
            // 다른 사용자의 피드는 수정할 수 없으므로 바텀시트만 닫음
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _loadUserFeeds() async {
    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      // FeedApi를 사용하여 특정 사용자의 피드 가져오기
      final response = await FeedApi.fetchUserFeeds(widget.userId);

      if (response is Map && response.containsKey('feeds')) {
        List<dynamic> feedsData = response['feeds'];
        setState(() {
          userFeeds = feedsData.map((feedJson) => Feed.fromJson(feedJson)).toList();
        });

        _groupFeedsByCountry(); // 국가별로 피드 그룹화

        if (isMapInitialized) {
          if (userFeeds.isEmpty) {
            // 피드가 없는 경우 처리
          } else {
            if (currentZoomLevel > 4.0) {
              await _addFeedMarkersToMap(userFeeds);
            } else {
              await _addCountryFeedMarkers();
            }
          }
        }
      } else {
        print("[ERROR] 사용자 피드 로드 실패");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("사용자의 피드를 불러오는데 실패했습니다.")),
          );
        }
      }
    } catch (e) {
      print("[ERROR] 사용자 피드 로드 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("사용자의 피드 데이터를 로드하는 중 오류가 발생했습니다.")),
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

  // 국가별 피드 그룹화 메서드
  void _groupFeedsByCountry() {
    if (_hasGroupedByCountry) return;

    _countryFeeds.clear();

    for (Feed feed in userFeeds) {
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
      feedAnnotationManager!.addOnPointAnnotationClickListener(UserPointClickListener(this));
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
    if (_countryFeeds.isEmpty) {
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
    _countryMarkerMap.clear();

    for (String countryCode in _countryFeeds.keys) {
      if (countryCode == "UNKNOWN" || countryCode.isEmpty) continue;

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
        _countryMarkerMap[countryCode] = marker;
      } catch (e) {
        print("[ERROR] 국가 ${countryCode} 마커 추가 실패: $e");
      }
    }
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

  void _updateVisibility() async {
    if (!isMapInitialized) return;

    if (currentZoomLevel > 4.0) {
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
            print("[ERROR] 피드 마커 삭제 오류: $e");
          }
        }
      }

      if (countryFeedMarkers.isEmpty) {
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

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("[ERROR] 다운로드 실패 - 상태 코드: ${response.statusCode}");
      }
    } catch (e) {
      print("[ERROR] 이미지 다운로드 오류: $e");
    }
    return null;
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
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(0, 20)),
            zoom: 2,
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
                _groupFeedsByCountry();
              }

              if (currentZoomLevel > 4.0) {
                _addFeedMarkersToMap(userFeeds);
              } else {
                _addCountryFeedMarkers();
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
                    "피드 로드 중...",
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
    _zoomCheckTimer?.cancel();
    super.dispose();
  }
}