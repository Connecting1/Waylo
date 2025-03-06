import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:exif/exif.dart';
import 'dart:io';
import 'dart:async';

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

  // 마지막 사진 위치 저장
  List<Map<String, dynamic>> photoLocations = [];

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

  // 📌 줌 레벨에 따라 마커 가시성 업데이트 (로직 반전)
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
      if (photoMarkers.isEmpty && photoLocations.isNotEmpty) {
        await _addStoredPhotoMarkers();
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

  // 저장된 국기 마커 추가
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

  // 저장된 사진 마커 추가
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

  // 📌 사진의 GPS 좌표 추출 후 지도에 마커 추가 (로직 반전)
  Future<void> _extractLocationAndAddMarker(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? "N");
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? "E");

        Uint8List resizedPhoto = await _resizeImage(imageFile, 150);
        String? countryName = await _getCountryFromCoordinates(lat, lon);

        // 사진 정보 저장
        photoLocations.add({
          "latitude": lat,
          "longitude": lon,
          "image": resizedPhoto,
        });

        // 📌 확대/축소 수준에 따라 마커 표시 결정 (로직 반전)
        if (currentZoomLevel > 4.0) {
          // 확대 상태일 때는 사진 마커만 추가
          await _addMarkerToMap(lat, lon, resizedPhoto, 0.1, isPhoto: true);
        }

        // 📌 국기 이미지 다운로드 및 저장
        if (countryName != null && countryData.containsKey(countryName)) {
          String flagUrl = countryData[countryName]!["flagUrl"];
          double flagLat = countryData[countryName]!["latitude"];
          double flagLon = countryData[countryName]!["longitude"];

          Uint8List? flagImage = await _downloadImage(flagUrl);
          if (flagImage != null) {
            // 국기 이미지를 메모리에 캐시
            countryData[countryName]!["flagImage"] = flagImage;

            // 축소 상태일 때는 국기 마커만 추가
            if (currentZoomLevel <= 4.0) {
              await _addMarkerToMap(flagLat, flagLon, flagImage, 0.3, isPhoto: false);
            }
          }
        }

        // 성공적으로 마커 추가 후 카메라 이동
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lon, lat)),
            zoom: currentZoomLevel,
          ),
          MapAnimationOptions(duration: 1000), // 1초 = 1000ms (int 타입)
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

  // 📌 지도에 마커 추가 (국기와 사진 별도 관리)
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

  // 📌 사진 크기 조정 함수
  Future<Uint8List> _resizeImage(File imageFile, int width) async {
    Uint8List imageData = await imageFile.readAsBytes();
    return imageData;
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
