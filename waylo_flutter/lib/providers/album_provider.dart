import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/album_api.dart';
import 'package:waylo_flutter/services/api/user_api.dart';

class AlbumProvider with ChangeNotifier {
  Color _canvasColor = Colors.white;
  String _canvasPattern = "none";
  bool _isLoaded = false;

  Color get canvasColor => _canvasColor;
  String get canvasPattern => _canvasPattern;

  Future<void> loadAlbumData(String userId) async {
    if (_isLoaded) return;

    Map<String, dynamic> albumInfo = await UserApi.fetchUserInfo();
    _canvasColor = _convertHexToColor(albumInfo["background_color"] ?? "#FFFFFF");
    _canvasPattern = albumInfo["background_pattern"] ?? "none";

    _isLoaded = true;
    notifyListeners();
  }

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

  Color _convertHexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
