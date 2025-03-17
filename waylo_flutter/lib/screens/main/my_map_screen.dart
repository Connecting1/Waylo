import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:exif/exif.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

class MyMapScreenPage extends StatefulWidget {
  @override
  _MapScreenPageState createState() => _MapScreenPageState();
}

class _MapScreenPageState extends State<MyMapScreenPage> with AutomaticKeepAliveClientMixin {
  late MapboxMap mapboxMap;
  late String accessToken;
  PointAnnotationManager? photoAnnotationManager;
  PointAnnotationManager? flagAnnotationManager;
  Map<String, Map<String, dynamic>> countryData = {}; // 나라별 좌표 및 국기 저장
  double currentZoomLevel = 2.0; // 현재 줌 레벨

  // 사진 마커와 국기 마커 목록
  List<PointAnnotation> photoMarkers = [];
  List<PointAnnotation> flagMarkers = [];

  // 위치별 사진 그룹화를 위한 맵
  Map<String, List<Map<String, dynamic>>> photoLocationGroups = {};

  // 줌 레벨 확인용 타이머
  Timer? _zoomCheckTimer;
  bool isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadCountryData();
    accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);
  }

  // 📌 줌 레벨 확인 타이머 시작
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

  // 📌 줌 레벨에 따라 마커 가시성 업데이트
  void _updateVisibility() async {
    if (photoAnnotationManager == null || flagAnnotationManager == null || !isMapInitialized) {
      return;
    }

    // 확대 시 (줌 레벨이 높음) 사진만 표시
    if (currentZoomLevel > 4.0) {
      // 국기 마커 모두 삭제
      for (var marker in List.from(flagMarkers)) {
        try {
          await flagAnnotationManager!.delete(marker);
          flagMarkers.remove(marker);
        } catch (e) {
          debugPrint("마커 삭제 오류: $e");
        }
      }

      // 사진 마커가 없으면 추가
      if (photoMarkers.isEmpty && photoLocationGroups.isNotEmpty) {
        await _addPhotoMarkersToMap();
      }
    }
    // 축소 시 (줌 레벨이 낮음) 국기만 표시
    else {
      // 사진 마커 모두 삭제
      for (var marker in List.from(photoMarkers)) {
        try {
          await photoAnnotationManager!.delete(marker);
          photoMarkers.remove(marker);
        } catch (e) {
          debugPrint("마커 삭제 오류: $e");
        }
      }

      // 국기 마커가 없으면 추가
      if (flagMarkers.isEmpty) {
        await _addStoredFlagMarkers();
      }
    }
  }

  // 국기 마커 추가
  Future<void> _addStoredFlagMarkers() async {
    for (var countryName in countryData.keys) {
      var country = countryData[countryName]!;
      if (country.containsKey("flagImage") &&
          country.containsKey("latitude") &&
          country.containsKey("longitude")) {

        double flagLat = country["latitude"];
        double flagLon = country["longitude"];
        Uint8List flagImage = country["flagImage"];

        await _addMarkerToMap(flagLat, flagLon, flagImage, 0.3, isPhoto: false);
      }
    }
  }

  // 📌 위치 문자열로 변환 (그룹화 키로 사용)
  String _locationToString(double lat, double lon) {
    // 소수점 5자리까지만 고려하여 근처 위치는 동일하게 취급
    return "${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}";
  }

  // 📌 새로운 사진 마커 추가 함수 - 사각형 프레임과 숫자 표시
  Future<void> _addPhotoMarkersToMap() async {
    if (photoAnnotationManager == null) {
      photoAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    // 위치 그룹별로 마커 생성
    for (var locationKey in photoLocationGroups.keys) {
      var photoList = photoLocationGroups[locationKey]!;
      if (photoList.isEmpty) continue;

      // 위치 정보
      double lat = photoList[0]["latitude"];
      double lon = photoList[0]["longitude"];

      // 가장 최근 추가된 사진을 썸네일로 사용
      Uint8List photoImage = photoList.last["image"];

      // 사진 개수 (숫자 표시용)
      int count = photoList.length;

      // 사각형 프레임과 숫자가 있는 마커 이미지 생성
      Uint8List markerImage = await _createSquareMarkerWithCount(photoImage, count);

      // 마커 추가
      PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(lon, lat)),
        image: markerImage,
        iconSize: 1.0, // 크기를 키움 (생성된 이미지 그대로 표시)
      );

      PointAnnotation marker = await photoAnnotationManager!.create(pointAnnotationOptions);
      photoMarkers.add(marker);
    }
  }

  // 📌 사각형 프레임과 숫자가 있는 마커 이미지 생성
  Future<Uint8List> _createSquareMarkerWithCount(Uint8List photoBytes, int count) async {
    // 캔버스 크기 설정
    final int size = 120; // 최종 이미지 크기
    final int photoSize = 100; // 내부 사진 크기
    final double borderWidth = 4.0; // 테두리 두께
    final Color borderColor = Colors.blue; // 테두리 색상

    // 임시 UI 이미지를 위한 레코더 및 캔버스 생성
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    // 배경을 투명하게 설정
    canvas.drawColor(Colors.transparent, BlendMode.clear);

    // 이미지 로드
    final ui.Codec codec = await ui.instantiateImageCodec(photoBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    // 이미지 크기 계산 (정사각형 유지)
    final double photoLeft = (size - photoSize) / 2;
    final double photoTop = (size - photoSize) / 2;

    // 파란색 사각형 배경 그리기
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(photoLeft - borderWidth, photoTop - borderWidth,
            photoSize + (borderWidth * 2), photoSize + (borderWidth * 2)),
        Radius.circular(8),
      ),
      borderPaint,
    );

    // 사진 그리기 (정사각형으로 자름)
    final Rect srcRect = _centerCrop(frameInfo.image.width, frameInfo.image.height);
    final Rect destRect = Rect.fromLTWH(photoLeft, photoTop, photoSize.toDouble(), photoSize.toDouble());
    canvas.drawImageRect(frameInfo.image, srcRect, destRect, Paint());

    // 사진 개수 표시 (2장 이상일 때만)
    if (count > 1) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 숫자를 오른쪽 상단에 표시
      textPainter.paint(
        canvas,
        Offset(
          photoLeft + photoSize - textPainter.width - 8,
          photoTop + 8,
        ),
      );
    }

    // 이미지로 변환
    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // 이미지를 정사각형으로 자르는 함수 - 타입 오류 수정
  Rect _centerCrop(int width, int height) {
    if (width == height) {
      return Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    }

    if (width > height) {
      // 가로가 더 긴 경우
      double diff = (width - height).toDouble(); // int를 double로 변환
      return Rect.fromLTWH(diff / 2, 0, height.toDouble(), height.toDouble());
    } else {
      // 세로가 더 긴 경우
      double diff = (height - width).toDouble(); // int를 double로 변환
      return Rect.fromLTWH(0, diff / 2, width.toDouble(), width.toDouble());
    }
  }

  // 📌 국기 데이터 로드 (countries.json)
  Future<void> _loadCountryData() async {
    String data = await rootBundle.loadString('assets/mapbox/countries.json');
    Map<String, dynamic> geoJson = jsonDecode(data);

    for (var feature in geoJson["features"]) {
      String countryName = feature["properties"]["name"];
      String flagUrl = feature["properties"]["icon"];
      List coordinates = feature["geometry"]["coordinates"];

      countryData[countryName] = {
        "flagUrl": flagUrl,
        "latitude": coordinates[1], // 위도
        "longitude": coordinates[0], // 경도
      };
    }
  }

  // 📌 사진 선택 후 지도에 마커 추가
  Future<void> _pickImageAndAddMarker() async {
    final picker = image_picker.ImagePicker();
    final image_picker.XFile? image = await picker.pickImage(source: image_picker.ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      await _extractLocationAndAddMarker(file);
    }
  }

  // 📌 EXIF 회전 정보 추출
  Future<int> _getExifOrientation(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.containsKey('Image Orientation')) {
        final orientationTag = data['Image Orientation']!;

        // 방법 1: values에서 추출 시도
        if (orientationTag.values != null) {
          final valuesList = orientationTag.values.toList();
          if (valuesList.isNotEmpty) {
            return valuesList[0];
          }
        }

        // 방법 2: printable에서 추출 시도
        if (orientationTag.printable != null && orientationTag.printable.isNotEmpty) {
          try {
            final printableStr = orientationTag.printable;
            // 숫자만 추출
            final match = RegExp(r'(\d+)').firstMatch(printableStr);
            if (match != null) {
              return int.parse(match.group(1)!);
            }
          } catch (e) {
            debugPrint("방향 값 파싱 오류: $e");
          }
        }
      }

      // 기본값 (회전 없음)
      return 1;
    } catch (e) {
      debugPrint("EXIF 방향 정보 추출 오류: $e");
      return 1; // 오류 시 기본값
    }
  }

  // 📌 사진의 GPS 좌표 추출 후 지도에 마커 추가
  Future<void> _extractLocationAndAddMarker(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? "N");
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? "E");

        // 1. EXIF 방향 정보 가져오기
        int orientation = await _getExifOrientation(imageFile);
        debugPrint("📸 사진 방향 정보: $orientation");

        // 2. 직접 이미지 디코딩 및 처리
        final rawBytes = await imageFile.readAsBytes();
        img.Image? originalImage = img.decodeImage(rawBytes);

        if (originalImage == null) {
          throw Exception("이미지 디코딩 실패");
        }

        // 3. 방향에 따른 회전 적용
        img.Image processedImage;
        switch (orientation) {
          case 1: // 정상
            processedImage = originalImage;
            break;
          case 3: // 180도 회전
            processedImage = img.copyRotate(originalImage, angle: 180);
            break;
          case 6: // 시계 방향으로 90도 (세로 사진의 가장 일반적인 케이스)
            processedImage = img.copyRotate(originalImage, angle: 90);
            break;
          case 8: // 시계 반대 방향으로 90도
            processedImage = img.copyRotate(originalImage, angle: 270);
            break;
          default:
            processedImage = originalImage;
        }

        // 4. 크기 조정 (300픽셀 너비로)
        int targetWidth = 300;
        int targetHeight = (processedImage.height * targetWidth ~/ processedImage.width);
        img.Image resizedImage = img.copyResize(
            processedImage,
            width: targetWidth,
            height: targetHeight,
            interpolation: img.Interpolation.average
        );

        // 5. 최종 이미지를 바이트 배열로 변환
        Uint8List finalImageBytes = Uint8List.fromList(img.encodePng(resizedImage));

        // 6. 위치 문자열 생성 (그룹화 키)
        String locationKey = _locationToString(lat, lon);

        // 7. 위치별 사진 그룹화
        if (!photoLocationGroups.containsKey(locationKey)) {
          photoLocationGroups[locationKey] = [];
        }

        // 8. 새 사진 정보 추가
        photoLocationGroups[locationKey]!.add({
          "latitude": lat,
          "longitude": lon,
          "image": finalImageBytes,
          "timestamp": DateTime.now().millisecondsSinceEpoch, // 시간 정보 추가
        });

        // 9. 기존 사진 마커 삭제 후 재생성
        if (currentZoomLevel > 4.0) {
          // 모든 사진 마커 삭제
          for (var marker in List.from(photoMarkers)) {
            try {
              await photoAnnotationManager!.delete(marker);
              photoMarkers.remove(marker);
            } catch (e) {
              debugPrint("마커 삭제 오류: $e");
            }
          }

          // 마커 다시 생성
          await _addPhotoMarkersToMap();
        }

        // 국가 정보 가져오기
        String? countryName = await _getCountryFromCoordinates(lat, lon);

        if (countryName != null && countryData.containsKey(countryName)) {
          String flagUrl = countryData[countryName]!["flagUrl"];
          double flagLat = countryData[countryName]!["latitude"];
          double flagLon = countryData[countryName]!["longitude"];

          Uint8List? flagImage = await _downloadImage(flagUrl);
          if (flagImage != null) {
            countryData[countryName]!["flagImage"] = flagImage;
            if (currentZoomLevel <= 4.0) {
              await _addMarkerToMap(flagLat, flagLon, flagImage, 0.3, isPhoto: false);
            }
          }
        }

        // 지도 이동
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lon, lat)),
            zoom: currentZoomLevel,
          ),
          MapAnimationOptions(duration: 1000),
        );
      } else {
        debugPrint("❌ 사진에 위치 정보 없음");
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

  // 📌 지도에 마커 추가 (국기용)
  Future<void> _addMarkerToMap(double lat, double lon, Uint8List imageData, double size, {required bool isPhoto}) async {
    // 사진용 어노테이션 매니저와 국기용 어노테이션 매니저를 별도로 생성
    if (photoAnnotationManager == null) {
      photoAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    if (flagAnnotationManager == null) {
      flagAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lon, lat)),
      image: imageData,
      iconSize: size,
    );

    if (isPhoto) {
      PointAnnotation marker = await photoAnnotationManager!.create(pointAnnotationOptions);
      photoMarkers.add(marker);
    } else {
      PointAnnotation marker = await flagAnnotationManager!.create(pointAnnotationOptions);
      flagMarkers.add(marker);
    }
  }

  // 📌 네트워크 이미지 다운로드 (국기 가져오기)
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint("❌ 이미지 다운로드 오류: $e");
    }
    return null;
  }

  // 📌 좌표를 이용하여 나라 이름 가져오기 (Mapbox Geocoding API 사용)
  Future<String?> _getCountryFromCoordinates(double latitude, double longitude) async {
    String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$accessToken&types=country";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["text"];
        }
      }
    } catch (e) {
      debugPrint("❌ 나라 검색 오류: $e");
    }
    return null;
  }

  // 📌 위도/경도 변환 함수
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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: PageStorageKey('map_key'),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(0, 20)),
              zoom: 2,
            ),
            onMapCreated: (MapboxMap mapbox) {
              mapboxMap = mapbox;
              isMapInitialized = true;

              // 현재 카메라 상태 가져오기
              mapbox.getCameraState().then((cameraState) {
                if (mounted) {
                  setState(() {
                    currentZoomLevel = cameraState.zoom;
                  });
                }
              });

              // 줌 레벨 체크 타이머 시작
              _startZoomCheckTimer();

              // 제스처 이벤트 설정
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
            },
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _pickImageAndAddMarker,
              child: Text("사진 선택하여 지도에 추가"),
            ),
          ),
          // 현재 줌 레벨 표시 (개발 중 디버깅용)
          Positioned(
            bottom: 30,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.6),
              child: Text(
                "줌 레벨: ${currentZoomLevel.toStringAsFixed(1)} ${currentZoomLevel > 4.0 ? '(사진 표시)' : '(국기 표시)'}",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // 줌 조절 버튼 (테스트용)
          Positioned(
            bottom: 80,
            right: 20,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    mapboxMap.flyTo(
                      CameraOptions(zoom: 5.0),
                      MapAnimationOptions(duration: 1000), // 1초 = 1000ms (int 타입)
                    );
                  },
                  child: Text("확대 (사진)"),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    mapboxMap.flyTo(
                      CameraOptions(zoom: 2.0),
                      MapAnimationOptions(duration: 1000), // 1초 = 1000ms (int 타입)
                    );
                  },
                  child: Text("축소 (국기)"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 타이머 정리
    _zoomCheckTimer?.cancel();
    super.dispose();
  }
}
