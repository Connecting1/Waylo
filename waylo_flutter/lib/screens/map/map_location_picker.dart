// lib/screen/map/map_location_picker.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/theme_provider.dart';

class MapLocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String accessToken;
  final Function(double, double, String?) onLocationSelected;

  const MapLocationPicker({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.accessToken,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _MapLocationPickerState createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late MapboxMap mapboxMap;
  bool _isMapInitialized = false;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _selectedPlaceName;
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 테마 프로바이더 사용
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // 다크 모드에 따른 색상 설정
    final backgroundColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintTextColor = isDarkMode ? Colors.white70 : Colors.grey;
    final errorBackgroundColor = isDarkMode ? Colors.red[900]!.withOpacity(0.3) : Colors.red[100]!;
    final errorTextColor = isDarkMode ? Colors.red[100]! : Colors.red[900]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: const Text(
          "Select Location",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map widget
          MapWidget(
            key: const ValueKey("map"),
            cameraOptions: CameraOptions(
              center: Point(
                  coordinates: Position(
                      widget.initialLongitude,
                      widget.initialLatitude
                  )
              ),
              zoom: 10.0,
            ),
            onMapCreated: _onMapCreated,
          ),

          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search location',
                  hintStyle: TextStyle(color: hintTextColor),
                  prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : null),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: isDarkMode ? Colors.white70 : null),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchResults.clear();
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  if (value.length > 1) {
                    _searchPlaces(value);
                  } else if (value.isEmpty) {
                    setState(() {
                      _searchResults.clear();
                    });
                  }
                },
              ),
            ),
          ),

          // Search results list
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 300,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    return ListTile(
                      title: Text(
                        place['place_name'] ?? '',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        place['text'] ?? '',
                        style: TextStyle(color: hintTextColor),
                      ),
                      onTap: () => _onPlaceSelected(place),
                    );
                  },
                ),
              ),
            ),

          // Error message
          if (_errorMessage.isNotEmpty)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: errorTextColor),
                ),
              ),
            ),

          // Loading indicator
          if (_isSearching)
            Positioned(
              top: 72,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.white : AppColors.primary
                    ),
                  ),
                ),
              ),
            ),

          // Center pointer
          Center(
            child: Stack(
              children: [
                // 그림자 효과용 아이콘 (약간 오프셋)
                Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 26,
                ),
                // 메인 아이콘
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 16,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton(
                backgroundColor: isDarkMode ? AppColors.primary : AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _confirmLocation,
                child: Icon(Icons.check),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;

    mapboxMap.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: true,
        pinchToZoomEnabled: true,
        scrollEnabled: true,
        doubleTapToZoomInEnabled: true,
      ),
    );

    setState(() {
      _isMapInitialized = true;
    });
  }

  // 장소 검색 메서드 - 직접 Mapbox Geocoding API 호출
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      // Mapbox Geocoding API 직접 호출 (language 파라미터 추가)
      final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=${widget.accessToken}'
              '&proximity=${widget.initialLongitude},${widget.initialLatitude}'
              '&language=en' // 영어 결과 요청
              '&limit=10');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(features);
          _isSearching = false;
        });

        print("검색 결과: ${_searchResults.length}개");
        if (_searchResults.isNotEmpty) {
          print("첫 번째 결과: ${_searchResults.first['place_name']}");
        }
      } else {
        print('장소 검색 API 오류: ${response.statusCode}');
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error occurred during search (${response.statusCode})';
        });
      }
    } catch (e) {
      print('장소 검색 예외 발생: $e');
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error occurred during search';
        _searchResults.clear();
      });
    }
  }

  // 장소 선택 처리
  void _onPlaceSelected(Map<String, dynamic> place) {
    try {
      // 좌표 추출
      final coordinates = place['geometry']['coordinates'] as List;

      if (coordinates.length >= 2) {
        // Mapbox에서는 [경도, 위도] 순서로 반환
        final double lng = coordinates[0];
        final double lat = coordinates[1];

        setState(() {
          _selectedPlaceName = place['place_name'];
          _searchController.text = place['text'] ?? '';
          _searchResults.clear();
        });

        // 선택한 위치로 지도 이동
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lng, lat)),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      } else {
        print("좌표를 추출할 수 없습니다");
      }
    } catch (e) {
      print("좌표 처리 중 오류 발생: $e");
    }
  }

  void _confirmLocation() async {
    if (!_isMapInitialized) return;

    try {
      final cameraState = await mapboxMap.getCameraState();
      final center = cameraState.center;

      // 선택한 장소 이름 또는 검색어 사용
      String? placeName = _selectedPlaceName;
      if (placeName == null && _searchController.text.isNotEmpty) {
        placeName = _searchController.text;
      }

      widget.onLocationSelected(
          center.coordinates.lat.toDouble(),
          center.coordinates.lng.toDouble(),
          placeName
      );

      Navigator.pop(context);
    } catch (e) {
      print("위치 확인 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to select location.'))
      );
    }
  }
}