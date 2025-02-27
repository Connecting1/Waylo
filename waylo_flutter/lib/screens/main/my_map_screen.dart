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

class MyMapScreenPage extends StatefulWidget {
  @override
  _MapScreenPageState createState() => _MapScreenPageState();
}

class _MapScreenPageState extends State<MyMapScreenPage> with AutomaticKeepAliveClientMixin {
  late MapboxMap mapboxMap;
  late String accessToken;
  PointAnnotationManager? pointAnnotationManager;
  Map<String, Map<String, dynamic>> countryData = {}; // 나라별 좌표 및 국기 저장

  @override
  void initState() {
    super.initState();
    _loadCountryData();
    accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);
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

  // 📌 사진의 GPS 좌표 추출 후 지도에 마커 추가
  Future<void> _extractLocationAndAddMarker(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty && data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        final lat = _convertToDecimal(data['GPS GPSLatitude']!.values.toList(), data['GPS GPSLatitudeRef']?.printable ?? "N");
        final lon = _convertToDecimal(data['GPS GPSLongitude']!.values.toList(), data['GPS GPSLongitudeRef']?.printable ?? "E");

        Uint8List resizedPhoto = await _resizeImage(imageFile, 150);
        String? countryName = await _getCountryFromCoordinates(lat, lon);

        // 📌 사진 마커 추가 (사진이 찍힌 위치)
        _addMarkerToMap(lat, lon, resizedPhoto, 0.1);

        // 📌 국기 마커 추가 (countries.json의 좌표 사용)
        if (countryName != null && countryData.containsKey(countryName)) {
          String flagUrl = countryData[countryName]!["flagUrl"];
          double flagLat = countryData[countryName]!["latitude"];
          double flagLon = countryData[countryName]!["longitude"];

          Uint8List? flagImage = await _downloadImage(flagUrl);
          if (flagImage != null) {
            _addMarkerToMap(flagLat, flagLon, flagImage, 0.3); // 국기 크기: 0.3
          }
        }
      } else {
        debugPrint("❌ 사진에 위치 정보 없음");
      }
    } catch (e) {
      debugPrint("⚠️ 오류 발생: $e");
    }
  }

  // 📌 지도에 마커 추가 (국기와 사진 크기 다르게 설정)
  Future<void> _addMarkerToMap(double lat, double lon, Uint8List imageData, double size) async {
    if (pointAnnotationManager == null) {
      pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    }

    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lon, lat)),
      image: imageData,
      iconSize: size, // 크기 조정
    );

    await pointAnnotationManager?.create(pointAnnotationOptions);
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
        ],
      ),
    );
  }
}
