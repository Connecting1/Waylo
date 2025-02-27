import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyMapScreenPage extends StatefulWidget {
  @override
  _MapScreenPageState createState() => _MapScreenPageState();
}

class _MapScreenPageState extends State<MyMapScreenPage> with AutomaticKeepAliveClientMixin {
  late MapboxMap mapboxMap;
  late String accessToken;
  PointAnnotationManager? pointAnnotationManager;

  List<String> visitedCountries = [];

  @override
  void initState() {
    super.initState();
    _loadVisitedCountries();  // 방문한 나라 리스트 불러오기
    accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);
  }

  // 방문한 나라 목록 불러오기
  Future<void> _loadVisitedCountries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? countries = prefs.getStringList('visitedCountries');
    if (countries != null) {
      setState(() {
        visitedCountries = countries;
      });
    }
  }

  // 방문한 나라 목록 저장
  Future<void> _saveVisitedCountries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('visitedCountries', visitedCountries);
  }

  // JSON 파일에서 마커 추가
  Future<void> _addVisitedCountryMarkers() async {
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    String data = await rootBundle.loadString('assets/mapbox/countries.json');
    Map<String, dynamic> geoJson = jsonDecode(data);

    for (var feature in geoJson["features"]) {
      String countryName = feature["properties"]["name"];
      if (visitedCountries.contains(countryName)) {
        var coordinates = feature["geometry"]["coordinates"];
        String iconPath = feature["properties"]["icon"];

        Uint8List? imageData;

        if (iconPath.startsWith("http")) {
          imageData = await _downloadImage(iconPath);
        } else {
          final ByteData bytes = await rootBundle.load(iconPath);
          imageData = bytes.buffer.asUint8List();
        }

        if (imageData == null) continue;

        PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(coordinates[0], coordinates[1])),
          image: imageData,
          iconSize: 0.5,
        );

        await pointAnnotationManager?.create(pointAnnotationOptions);
        debugPrint("✅ ${countryName} 마커 추가됨 (${coordinates[1]}, ${coordinates[0]})");
      }
    }
  }

  // 네트워크 이미지 다운로드
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint("❌ 이미지 다운로드 실패: $url");
        return null;
      }
    } catch (e) {
      debugPrint("❌ 이미지 다운로드 중 오류 발생: $e");
      return null;
    }
  }

  // 지도 생성 콜백
  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    await _addVisitedCountryMarkers();
  }

  @override
  bool get wantKeepAlive => true; // 상태 유지 설정

  @override
  Widget build(BuildContext context) {
    super.build(context); // 반드시 super.build(context)를 호출해야 합니다.

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: PageStorageKey('map_key'),  // 페이지 저장 키
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(0, 20)),
              zoom: 2,
            ),
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "국가 이름 입력 (예: South Korea)",
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      visitedCountries.add(value);
                      _saveVisitedCountries();
                      _addVisitedCountryMarkers();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
