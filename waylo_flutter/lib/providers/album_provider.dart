import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/album_api.dart';
import 'package:waylo_flutter/services/api/user_api.dart';

/// 앨범의 캔버스 설정을 관리하는 Provider
class AlbumProvider with ChangeNotifier {
  Color _canvasColor = Colors.white;        // 캔버스 배경색
  String _canvasPattern = "none";           // 캔버스 배경 패턴
  bool _isLoaded = false;                   // 데이터 로드 여부

  Color get canvasColor => _canvasColor;
  String get canvasPattern => _canvasPattern;

  /// 앨범 데이터 로드
  Future<void> loadAlbumData(String userId) async {
    if (_isLoaded) return;

    Map<String, dynamic> albumInfo = await UserApi.fetchUserInfo();
    _canvasColor = _convertHexToColor(albumInfo["background_color"] ?? "#FFFFFF");
    _canvasPattern = albumInfo["background_pattern"] ?? "none";

    _isLoaded = true;
    notifyListeners();
  }

  /// 캔버스 설정 업데이트
  Future<void> updateCanvasSettings(Color color, String pattern, String userId) async {
    String hexColor = "#${color.value.toRadixString(16).substring(2).toUpperCase()}";
    Map<String, dynamic> response = await AlbumApi.updateAlbumInfo(
      userId: userId,
      backgroundColor: hexColor,
      backgroundPattern: pattern,
    );

    if (!response.containsKey("error")) {
      _canvasColor = color;
      _canvasPattern = pattern;
      notifyListeners();
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
}