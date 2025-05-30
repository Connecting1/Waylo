// lib/services/data_loading_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/canvas_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import '../providers/location_settings_provider.dart';

class DataLoadingManager {
  static bool _hasInitialized = false;

  // 앱 시작시 또는 로그인 성공 후 호출할 메서드
  // services/data_loading_manager.dart 수정
  static Future<void> initializeAppData(BuildContext context, {bool forceRefresh = false}) async {
    if (_hasInitialized && !forceRefresh) {
      return;
    }

    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final locationSettingsProvider = Provider.of<LocationSettingsProvider>(context, listen: false);

    // 데이터 로드 시작
    List<Future> loadingFutures = [];

    if (!canvasProvider.isLoaded || forceRefresh) {
      loadingFutures.add(canvasProvider.loadCanvasSettings());
    }

    if (!userProvider.isLoaded || forceRefresh) {
      loadingFutures.add(userProvider.loadUserInfo(forceRefresh: forceRefresh));
    }

    if (!widgetProvider.isLoaded || forceRefresh) {
      loadingFutures.add(widgetProvider.loadWidgets().then((_) {

      }));
    }

    loadingFutures.add(locationSettingsProvider.init());

    // 모든 데이터 로드 대기
    await Future.wait(loadingFutures);

    // 프로필 이미지 새로고침
    await _refreshWidgetImagesOnInit(context);

    _hasInitialized = true;
  }

  // 위젯 이미지 새로고침 (앱 시작 또는 로그인 시)
  static Future<void> _refreshWidgetImagesOnInit(BuildContext context) async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widgetProvider.isLoaded && userProvider.isLoaded) {
      if (userProvider.profileImage.isNotEmpty) {
        // 프로필 위젯이 있는지 확인
        var profileWidgets = widgetProvider.widgets.where((w) => w.type == "profile_image").toList();
        if (profileWidgets.isNotEmpty) {
          // 모든 프로필 위젯 이미지 URL 업데이트
          await widgetProvider.updateAllProfileWidgetsImageUrl(userProvider.profileImage);
        }
      }
    }
  }

  // 로그인 성공 후 호출할 메서드
  static Future<void> handleLoginSuccess(BuildContext context) async {
    // 로그인 후 모든 Provider 강제 초기화
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    // 모든 Provider 강제 초기화
    canvasProvider.reset();
    userProvider.reset();
    widgetProvider.reset();

    _hasInitialized = false;

    // 데이터 초기화 (강제 새로고침)
    await initializeAppData(context, forceRefresh: true);
  }

  // 앱 재시작 또는 로그아웃 시 상태 초기화
  static void reset() {
    _hasInitialized = false;
  }

  // 데이터가 이미 로드되었는지 확인
  static bool isInitialized() {
    return _hasInitialized;
  }
}