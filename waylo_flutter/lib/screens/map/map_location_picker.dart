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
  // 텍스트 상수들
  static const String _appBarTitle = "Select Location";
  static const String _searchHintText = "Search location";
  static const String _searchErrorMessage = "Error occurred during search";
  static const String _searchErrorWithCodePrefix = "Error occurred during search (";
  static const String _searchErrorWithCodeSuffix = ")";
  static const String _locationSelectErrorMessage = "Unable to select location.";

  // API 관련 상수들
  static const String _mapboxGeocodingBaseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places/';
  static const String _geocodingUrlSuffix = '.json?access_token=';
  static const String _proximityParam = '&proximity=';
  static const String _languageParam = '&language=en';
  static const String _limitParam = '&limit=';
  static const String _featuresKey = 'features';
  static const String _placeNameKey = 'place_name';
  static const String _textKey = 'text';
  static const String _geometryKey = 'geometry';
  static const String _coordinatesKey = 'coordinates';

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 16;

  // 크기 상수들
  static const double _searchBarTopPosition = 16;
  static const double _searchBarHorizontalPosition = 16;
  static const double _searchResultsTopPosition = 72;
  static const double _errorMessageTopPosition = 72;
  static const double _loadingIndicatorTopPosition = 72;
  static const double _loadingIndicatorRightPosition = 16;
  static const double _fabBottomPosition = 16;
  static const double _fabRightPosition = 16;
  static const double _borderRadius = 8;
  static const double _shadowBlurRadius = 4;
  static const double _shadowOffsetY = 2;
  static const double _searchBarHorizontalPadding = 16;
  static const double _searchBarVerticalPadding = 12;
  static const double _searchResultsMaxHeight = 300;
  static const double _errorMessagePadding = 8;
  static const double _loadingIndicatorPadding = 8;
  static const double _loadingIndicatorSize = 24;
  static const double _loadingIndicatorStroke = 2;
  static const double _centerPointerShadowSize = 26;
  static const double _centerPointerMainSize = 24;

  // 지도 관련 상수들
  static const double _initialMapZoom = 10.0;
  static const double _selectedLocationZoom = 15.0;
  static const int _cameraAnimationDuration = 1000;
  static const int _searchMinLength = 2;
  static const int _searchLimit = 10;

  // 투명도 상수들
  static const double _errorBackgroundOpacity = 0.3;

  // HTTP 상태 코드 상수들
  static const int _httpStatusOk = 200;

  late MapboxMap mapboxMap;
  bool _isMapInitialized = false;
  final TextEditingController _searchController = TextEditingController();
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
    final errorBackgroundColor = isDarkMode ? Colors.red[900]!.withOpacity(_errorBackgroundOpacity) : Colors.red[100]!;
    final errorTextColor = isDarkMode ? Colors.red[100]! : Colors.red[900]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: const Text(
          _appBarTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: _appBarTitleFontSize,
          ),
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
              zoom: _initialMapZoom,
            ),
            onMapCreated: _onMapCreated,
          ),

          // Search bar
          Positioned(
            top: _searchBarTopPosition,
            left: _searchBarHorizontalPosition,
            right: _searchBarHorizontalPosition,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(_borderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: _shadowBlurRadius,
                    offset: Offset(0, _shadowOffsetY),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: _searchHintText,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: _searchBarHorizontalPadding,
                    vertical: _searchBarVerticalPadding,
                  ),
                ),
                onChanged: (value) {
                  if (value.length > _searchMinLength) {
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
              top: _searchResultsTopPosition,
              left: _searchBarHorizontalPosition,
              right: _searchBarHorizontalPosition,
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: _searchResultsMaxHeight,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: _shadowBlurRadius,
                      offset: Offset(0, _shadowOffsetY),
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
                        place[_placeNameKey] ?? '',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        place[_textKey] ?? '',
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
              top: _errorMessageTopPosition,
              left: _searchBarHorizontalPosition,
              right: _searchBarHorizontalPosition,
              child: Container(
                padding: const EdgeInsets.all(_errorMessagePadding),
                decoration: BoxDecoration(
                  color: errorBackgroundColor,
                  borderRadius: BorderRadius.circular(_borderRadius),
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
              top: _loadingIndicatorTopPosition,
              right: _loadingIndicatorRightPosition,
              child: Container(
                padding: const EdgeInsets.all(_loadingIndicatorPadding),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: _shadowBlurRadius,
                      offset: Offset(0, _shadowOffsetY),
                    )
                  ],
                ),
                child: SizedBox(
                  width: _loadingIndicatorSize,
                  height: _loadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: _loadingIndicatorStroke,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.white : AppColors.primary
                    ),
                  ),
                ),
              ),
            ),

          // Center pointer
          const Center(
            child: Stack(
              children: [
                // 그림자 효과용 아이콘 (약간 오프셋)
                Icon(
                  Icons.add,
                  color: Colors.black,
                  size: _centerPointerShadowSize,
                ),
                // 메인 아이콘
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: _centerPointerMainSize,
                ),
              ],
            ),
          ),

          // Confirm button
          Positioned(
            bottom: _fabBottomPosition,
            right: _fabRightPosition,
            child: SafeArea(
              child: FloatingActionButton(
                backgroundColor: isDarkMode ? AppColors.primary : AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _confirmLocation,
                child: const Icon(Icons.check),
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
          '$_mapboxGeocodingBaseUrl$query$_geocodingUrlSuffix${widget.accessToken}'
              '$_proximityParam${widget.initialLongitude},${widget.initialLatitude}'
              '$_languageParam' // 영어 결과 요청
              '$_limitParam$_searchLimit');

      final response = await http.get(url);

      if (response.statusCode == _httpStatusOk) {
        final data = json.decode(response.body);
        final features = data[_featuresKey] as List;

        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(features);
          _isSearching = false;
        });

        print("검색 결과: ${_searchResults.length}개");
        if (_searchResults.isNotEmpty) {
          print("첫 번째 결과: ${_searchResults.first[_placeNameKey]}");
        }
      } else {
        print('장소 검색 API 오류: ${response.statusCode}');
        setState(() {
          _isSearching = false;
          _errorMessage = '$_searchErrorWithCodePrefix${response.statusCode}$_searchErrorWithCodeSuffix';
        });
      }
    } catch (e) {
      print('장소 검색 예외 발생: $e');
      setState(() {
        _isSearching = false;
        _errorMessage = _searchErrorMessage;
        _searchResults.clear();
      });
    }
  }

  // 장소 선택 처리
  void _onPlaceSelected(Map<String, dynamic> place) {
    try {
      // 좌표 추출
      final coordinates = place[_geometryKey][_coordinatesKey] as List;

      if (coordinates.length >= 2) {
        // Mapbox에서는 [경도, 위도] 순서로 반환
        final double lng = coordinates[0];
        final double lat = coordinates[1];

        setState(() {
          _selectedPlaceName = place[_placeNameKey];
          _searchController.text = place[_textKey] ?? '';
          _searchResults.clear();
        });

        // 선택한 위치로 지도 이동
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lng, lat)),
            zoom: _selectedLocationZoom,
          ),
          MapAnimationOptions(duration: _cameraAnimationDuration),
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
          const SnackBar(content: Text(_locationSelectErrorMessage))
      );
    }
  }
}