import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/album_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';

/// 캔버스의 배경 설정을 관리하는 Provider
class CanvasProvider extends ChangeNotifier {
  Color _canvasColor = Colors.white;        // 캔버스 배경색
  String _canvasPattern = "none";           // 캔버스 배경 패턴
  bool _isLoaded = false;                   // 데이터 로드 완료 여부

  Color get canvasColor => _canvasColor;
  String get canvasPattern => _canvasPattern;
  bool get isLoaded => _isLoaded;

  /// 앱 시작 시 캔버스 설정 로드
  Future<void> loadCanvasSettings() async {
    if (_isLoaded) return;

    try {
      Map<String, dynamic> albumInfo = await AlbumApi.fetchAlbumInfo();

      if (albumInfo.containsKey("error")) {
        _canvasColor = Colors.white;
        _canvasPattern = "none";
      } else {
        _canvasColor = _convertHexToColor(albumInfo["background_color"] ?? "#FFFFFF");
        _canvasPattern = albumInfo["background_pattern"] ?? "none";
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _canvasColor = Colors.white;
      _canvasPattern = "none";
      notifyListeners();
    }
  }

  /// 캔버스 설정 업데이트 및 서버 저장
  Future<void> updateCanvasSettings(Color color, String pattern) async {
    _canvasColor = color;
    _canvasPattern = pattern;
    notifyListeners();

    try {
      String? userId = await ApiService.getUserId();
      if (userId == null) {
        return;
      }

      String hexColor = "#${color.value.toRadixString(16).substring(2).toUpperCase()}";

      await AlbumApi.updateAlbumInfo(
        userId: userId,
        backgroundColor: hexColor,
        backgroundPattern: pattern,
      );
    } catch (e) {
      // 저장 실패 시 조용히 처리
    }
  }

  /// Hex 색상 문자열을 Color 객체로 변환
  Color _convertHexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Provider 상태 초기화
  void reset() {
    _canvasColor = Colors.white;
    _canvasPattern = "none";
    _isLoaded = false;
    notifyListeners();
  }
}