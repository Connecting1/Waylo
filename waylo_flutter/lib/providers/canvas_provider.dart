import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/album_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';

class CanvasProvider extends ChangeNotifier {
  Color _canvasColor = Colors.white;
  String _canvasPattern = "none";
  bool _isLoaded = false;

  Color get canvasColor => _canvasColor;
  String get canvasPattern => _canvasPattern;
  bool get isLoaded => _isLoaded;

  // 앱 시작 시 호출할 초기화 메서드
  Future<void> loadCanvasSettings() async {
    // 이미 로드된 경우 중복 로드 방지
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

  // 설정 업데이트 메서드
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
      print("[ERROR] 캔버스 설정 저장 실패: $e");
    }
  }

  // 헥스 변환 메서드
  Color _convertHexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void reset() {
    _canvasColor = Colors.white;
    _canvasPattern = "none";
    _isLoaded = false;
    notifyListeners();
  }
}