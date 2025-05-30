import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

/// 위치 공유 및 권한 설정을 관리하는 Provider
class LocationSettingsProvider with ChangeNotifier {
  bool _isLocationSharingEnabled = false;               // 위치 공유 활성화 여부
  bool _isLocationPermissionGranted = false;            // 위치 권한 승인 여부
  bool _isLoading = false;                              // 로딩 상태
  bool _isRealtimeTracking = false;                     // 실시간 위치 추적 여부
  int _updateInterval = 10;                             // 위치 업데이트 간격 (분)

  bool get isLocationSharingEnabled => _isLocationSharingEnabled;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isLoading => _isLoading;
  bool get isRealtimeTracking => _isRealtimeTracking;
  int get updateInterval => _updateInterval;

  /// Provider 초기화 및 설정 로드
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isLocationSharingEnabled = prefs.getBool('location_sharing_enabled') ?? false;
    _isRealtimeTracking = prefs.getBool('location_realtime_tracking') ?? false;
    _updateInterval = prefs.getInt('location_update_interval') ?? 10;

    await checkLocationPermission();

    _isLoading = false;
    notifyListeners();
  }

  /// 위치 권한 상태 확인
  Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      _isLocationPermissionGranted = (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);

      notifyListeners();
      return _isLocationPermissionGranted;
    } catch (e) {
      _isLocationPermissionGranted = false;
      notifyListeners();
      return false;
    }
  }

  /// 위치 권한 요청
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      _isLocationPermissionGranted = (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);

      notifyListeners();
      return _isLocationPermissionGranted;
    } catch (e) {
      return false;
    }
  }

  /// 위치 공유 설정 변경
  Future<void> setLocationSharingEnabled(bool value) async {
    if (value && !_isLocationPermissionGranted) {
      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        return;
      }
    }

    _isLocationSharingEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_sharing_enabled', value);

    notifyListeners();
  }

  /// 실시간 추적 설정 변경
  Future<void> setRealtimeTracking(bool value) async {
    _isRealtimeTracking = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_realtime_tracking', value);

    notifyListeners();
  }

  /// 위치 업데이트 간격 설정
  Future<void> setUpdateInterval(int minutes) async {
    if (minutes <= 0) minutes = 1;

    _updateInterval = minutes;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('location_update_interval', minutes);

    notifyListeners();
  }

  /// 시스템 위치 설정 화면 열기
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Provider 상태 초기화
  void reset() {
    _isLocationSharingEnabled = false;
    _isLocationPermissionGranted = false;
    _isRealtimeTracking = false;
    _updateInterval = 10;
    _isLoading = false;
    notifyListeners();
  }
}