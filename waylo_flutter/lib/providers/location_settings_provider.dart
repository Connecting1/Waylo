// lib/providers/location_setting_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LocationSettingsProvider with ChangeNotifier {
  bool _isLocationSharingEnabled = false;
  bool _isLocationPermissionGranted = false;
  bool _isLoading = false;
  bool _isRealtimeTracking = false;  // 추가
  int _updateInterval = 10;  // 추가: 기본값 10분

  // Getters
  bool get isLocationSharingEnabled => _isLocationSharingEnabled;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isLoading => _isLoading;
  bool get isRealtimeTracking => _isRealtimeTracking;  // 추가
  int get updateInterval => _updateInterval;  // 추가

  // 프로바이더 초기화
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 저장된 설정 불러오기
    final prefs = await SharedPreferences.getInstance();
    _isLocationSharingEnabled = prefs.getBool('location_sharing_enabled') ?? false;
    _isRealtimeTracking = prefs.getBool('location_realtime_tracking') ?? false;
    _updateInterval = prefs.getInt('location_update_interval') ?? 10;

    // 위치 권한 확인
    await checkLocationPermission();

    _isLoading = false;
    notifyListeners();
  }

  // 위치 권한 확인
  Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      _isLocationPermissionGranted = (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);

      notifyListeners();
      return _isLocationPermissionGranted;
    } catch (e) {
      print("[ERROR] 위치 권한 확인 중 오류 발생: $e");
      _isLocationPermissionGranted = false;
      notifyListeners();
      return false;
    }
  }

  // 위치 권한 요청
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      _isLocationPermissionGranted = (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);

      notifyListeners();
      return _isLocationPermissionGranted;
    } catch (e) {
      print("[ERROR] 위치 권한 요청 중 오류 발생: $e");
      return false;
    }
  }

  // 위치 공유 설정 변경
  Future<void> setLocationSharingEnabled(bool value) async {
    // 활성화하려는 경우 권한 확인
    if (value && !_isLocationPermissionGranted) {
      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        // 권한이 거부된 경우 설정 변경 불가
        return;
      }
    }

    _isLocationSharingEnabled = value;

    // 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_sharing_enabled', value);

    notifyListeners();
  }

  // 실시간 추적 설정 변경 (추가)
  Future<void> setRealtimeTracking(bool value) async {
    _isRealtimeTracking = value;

    // 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_realtime_tracking', value);

    notifyListeners();
  }

  // 업데이트 간격 설정 (추가)
  Future<void> setUpdateInterval(int minutes) async {
    if (minutes <= 0) minutes = 1; // 최소 1분

    _updateInterval = minutes;

    // 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('location_update_interval', minutes);

    notifyListeners();
  }

  // 위치 권한 설정 화면으로 이동
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // 상태 초기화 (로그아웃 시)
  void reset() {
    _isLocationSharingEnabled = false;
    _isLocationPermissionGranted = false;
    _isRealtimeTracking = false;  // 추가
    _updateInterval = 10;  // 추가
    _isLoading = false;
    notifyListeners();
  }
}