import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/widget_api.dart';
import 'package:uuid/uuid.dart';

/// 앨범 위젯을 관리하는 Provider
class WidgetProvider extends ChangeNotifier {
  List<AlbumWidget> _widgets = [];                      // 앨범 위젯 목록
  bool _isLoaded = false;                               // 위젯 로드 완료 여부
  final Uuid _uuid = Uuid();                            // UUID 생성기

  List<AlbumWidget> get widgets => _widgets;
  bool get isLoaded => _isLoaded;

  /// 앨범 위젯 목록 로드
  Future<void> loadWidgets() async {
    if (_isLoaded) return;

    try {
      var widgetsJson = await WidgetApi.fetchAlbumWidgets();

      _widgets = [];
      for (var json in widgetsJson) {
        try {
          if (json.containsKey('extra_data') && json['extra_data'] is String) {
            try {
              String extraDataStr = json['extra_data'];

              if (extraDataStr.contains(": ") && !extraDataStr.contains(": \"")) {
                List<String> parts = extraDataStr.split(',');
                List<String> newParts = [];

                for (var part in parts) {
                  if (part.contains(': ')) {
                    var keyValue = part.split(': ');
                    if (keyValue.length == 2) {
                      String key = keyValue[0].trim();
                      if (!key.startsWith('"') && !key.startsWith("'")) {
                        key = '"$key"';
                      }
                      newParts.add('$key: ${keyValue[1]}');
                    } else {
                      newParts.add(part);
                    }
                  } else {
                    newParts.add(part);
                  }
                }

                extraDataStr = newParts.join(',');
                extraDataStr = extraDataStr.replaceAll("'", "\"");
                if (!extraDataStr.startsWith("{")) extraDataStr = "{$extraDataStr}";
                if (!extraDataStr.endsWith("}")) extraDataStr = "$extraDataStr}";
              }

              try {
                Map<String, dynamic> parsedExtraData = jsonDecode(extraDataStr);
                json['extra_data'] = parsedExtraData;
              } catch (e) {
                json['extra_data'] = {};
              }
            } catch (e) {
              json['extra_data'] = {};
            }
          }

          _widgets.add(AlbumWidget.fromJson(json));
        } catch (e) {
          // 개별 위젯 변환 실패 시 건너뛰기
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      // 위젯 데이터 로드 실패
    }
  }

  /// 프로필 사진 위젯 추가
  Future<AlbumWidget?> addProfileWidget(String profileImageUrl) async {
    double x = 50.0;
    double y = 50.0;
    double width = 150.0;
    double height = 150.0;

    Map<String, dynamic> extraData = {
      "image_url": profileImageUrl,
      "border_color": "#FFFFFF",
      "border_width": 2.0,
      "shape": "circle",
    };

    try {
      var widgetJson = await WidgetApi.addWidget(
        type: "profile_image",
        x: x,
        y: y,
        width: width,
        height: height,
        extraData: extraData,
      );

      if (widgetJson != null) {
        AlbumWidget newWidget = AlbumWidget.fromJson(widgetJson);
        _widgets.add(newWidget);
        notifyListeners();
        return newWidget;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 체크리스트 위젯 추가
  Future<AlbumWidget?> addChecklistWidget() async {
    double x = 50.0;
    double y = 50.0;
    double width = 300.0;
    double height = 200.0;

    Map<String, dynamic> extraData = {
      "items": []
    };

    try {
      var widgetJson = await WidgetApi.addWidget(
        type: "checklist",
        x: x,
        y: y,
        width: width,
        height: height,
        extraData: extraData,
      );

      if (widgetJson != null) {
        AlbumWidget newWidget = AlbumWidget.fromJson(widgetJson);
        _widgets.add(newWidget);
        notifyListeners();
        return newWidget;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 텍스트 박스 위젯 추가
  Future<AlbumWidget?> addTextBoxWidget() async {
    double x = 50.0;
    double y = 50.0;
    double width = 200.0;
    double height = 100.0;
    Map<String, dynamic> extraData = {
      "text": "",
      "backgroundColor": "#FFFFFF",
      "opacity": 1.0
    };

    try {
      var widgetJson = await WidgetApi.addWidget(
        type: "text_box",
        x: x,
        y: y,
        width: width,
        height: height,
        extraData: extraData,
      );

      if (widgetJson != null) {
        AlbumWidget newWidget = AlbumWidget.fromJson(widgetJson);
        _widgets.add(newWidget);
        notifyListeners();
        return newWidget;
      }
    } catch (e) {
      // 텍스트 박스 위젯 추가 실패
    }
    return null;
  }

  /// 위젯의 추가 데이터 업데이트
  Future<bool> updateWidgetExtraData(String widgetId, Map<String, dynamic> extraData) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) {
      return false;
    }

    Map<String, dynamic> updatedExtraData = Map<String, dynamic>.from(extraData);
    _widgets[index].extraData = updatedExtraData;
    notifyListeners();

    try {
      bool success = await WidgetApi.updateWidget(
          widgetId: widgetId, extraData: extraData);

      return success;
    } catch (e) {
      return false;
    }
  }

  /// 위젯 위치 업데이트
  Future<bool> updateWidgetPosition(String widgetId, double x, double y) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    _widgets[index].x = x;
    _widgets[index].y = y;
    notifyListeners();

    bool success = await WidgetApi.updateWidget(
      widgetId: widgetId,
      x: x,
      y: y,
    );

    return success;
  }

  /// 위젯 크기 업데이트
  Future<bool> updateWidgetSize(String widgetId, double width, double height) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    _widgets[index].width = width;
    _widgets[index].height = height;
    notifyListeners();

    bool success = await WidgetApi.updateWidget(
      widgetId: widgetId,
      width: width,
      height: height,
    );

    return success;
  }

  /// 프로필 위젯 모양 업데이트
  Future<bool> updateProfileWidgetShape(String widgetId, String shape) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    Map<String, dynamic> newExtraData = Map.from(_widgets[index].extraData);
    newExtraData['shape'] = shape;
    _widgets[index].extraData = newExtraData;
    notifyListeners();

    bool success = await WidgetApi.updateWidget(
      widgetId: widgetId,
      extraData: newExtraData,
    );

    return success;
  }

  /// 모든 프로필 위젯의 이미지 URL 업데이트
  Future<void> updateAllProfileWidgetsImageUrl(String newImageUrl) async {
    String timestampedUrl = "$newImageUrl?t=${DateTime.now().millisecondsSinceEpoch}";

    List<AlbumWidget> profileWidgets = _widgets.where((w) => w.type == "profile_image").toList();

    for (var widget in profileWidgets) {
      try {
        Map<String, dynamic> newExtraData = Map.from(widget.extraData);
        newExtraData['image_url'] = timestampedUrl;

        int index = _widgets.indexWhere((w) => w.id == widget.id);
        if (index != -1) {
          _widgets[index].extraData = newExtraData;
        }

        await WidgetApi.updateWidget(
          widgetId: widget.id,
          extraData: newExtraData,
        );
      } catch (e) {
        // 위젯 이미지 URL 업데이트 실패
      }
    }

    notifyListeners();
  }

  /// 위젯 삭제
  Future<bool> deleteWidget(String widgetId) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    _widgets.removeAt(index);
    notifyListeners();

    bool success = await WidgetApi.deleteWidget(widgetId);

    if (!success) {
      loadWidgets();
    }

    return success;
  }

  /// Provider 상태 초기화
  void reset() {
    _widgets = [];
    _isLoaded = false;
    notifyListeners();
  }
}