import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waylo_flutter/models/feed.dart';

/// 지도의 위치, 줌 레벨 및 위치 권한을 관리하는 Provider
class MapProvider extends ChangeNotifier {
  double _latitude = 0;                                 // 현재 지도 중심 위도
  double _longitude = 0;                                // 현재 지도 중심 경도
  double _zoom = 15.0;                                  // 지도 줌 레벨
  bool _isLocationPermissionGranted = false;            // 위치 권한 승인 여부
  bool _isLoadingLocation = false;                      // 위치 로딩 상태
  String _errorMessage = '';                            // 에러 메시지

  double get latitude => _latitude;
  double get longitude => _longitude;
  double get zoom => _zoom;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isLoadingLocation => _isLoadingLocation;
  String get errorMessage => _errorMessage;

  /// 위치 권한 확인 및 요청
  Future<bool> checkLocationPermission() async {
    _isLoadingLocation = true;
    _errorMessage = '';
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLocationPermissionGranted = false;
          _errorMessage = '위치 권한이 거부되었습니다.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocationPermissionGranted = false;
        _errorMessage = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.';
        notifyListeners();
        return false;
      }

      _isLocationPermissionGranted = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '위치 권한 확인 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// 현재 위치 가져오기
  Future<bool> getCurrentLocation() async {
    _isLoadingLocation = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (!_isLocationPermissionGranted) {
        bool granted = await checkLocationPermission();
        if (!granted) return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '현재 위치를 가져오는 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// 지도 위치 및 줌 레벨 수동 설정
  void setMapPosition(double latitude, double longitude, {double? zoom}) {
    _latitude = latitude;
    _longitude = longitude;
    if (zoom != null) _zoom = zoom;
    notifyListeners();
  }

  /// 선택한 피드 위치로 지도 중심 이동
  void centerMapOnFeed(Feed feed, {double? zoom}) {
    _latitude = feed.latitude;
    _longitude = feed.longitude;
    if (zoom != null) _zoom = zoom;
    notifyListeners();
  }

  /// 지도 줌 레벨 설정
  void setZoom(double zoom) {
    _zoom = zoom;
    notifyListeners();
  }

  /// Provider 상태 초기화
  void reset() {
    _latitude = 0;
    _longitude = 0;
    _zoom = 15.0;
    _isLocationPermissionGranted = false;
    _isLoadingLocation = false;
    _errorMessage = '';
    notifyListeners();
  }
}