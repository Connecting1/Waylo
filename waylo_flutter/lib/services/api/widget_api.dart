import 'dart:convert';
import 'package:waylo_flutter/services/api/api_service.dart';

class WidgetApi {
  /// 앨범의 모든 위젯 가져오기
  static Future<List<Map<String, dynamic>>> fetchAlbumWidgets() async {
    String? userId = await ApiService.getUserId();

    if (userId == null) {
      return [];
    }

    Map<String, dynamic> response = await ApiService.sendRequest(
      endpoint: "/api/widgets/$userId/",
    );

    if (response.containsKey("error") || !response.containsKey("widgets")) {
      return [];
    }

    List<Map<String, dynamic>> widgets = List<Map<String, dynamic>>.from(response["widgets"]);
    return widgets;
  }

  /// 위젯 추가
  static Future<Map<String, dynamic>?> addWidget({
    required String type,
    required double x,
    required double y,
    required double width,
    required double height,
    required Map<String, dynamic> extraData,
  }) async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return null;

    Map<String, dynamic> response = await ApiService.sendRequest(
      endpoint: "/api/widgets/$userId/create/",
      method: "POST",
      body: {
        "type": type,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "extra_data": extraData,
      },
    );

    if (response.containsKey("error") || !response.containsKey("widget")) {
      return null;
    }

    return response["widget"];
  }

  /// 위젯 업데이트
  static Future<bool> updateWidget({
    required String widgetId,
    double? x,
    double? y,
    double? width,
    double? height,
    Map<String, dynamic>? extraData,
  }) async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return false;

    Map<String, dynamic> body = {};
    if (x != null) body["x"] = x;
    if (y != null) body["y"] = y;
    if (width != null) body["width"] = width;
    if (height != null) body["height"] = height;
    if (extraData != null) body["extra_data"] = extraData;

    Map<String, dynamic> response = await ApiService.sendRequest(
      endpoint: "/api/widgets/$userId/$widgetId/update/",
      method: "PATCH",
      body: body,
    );

    if (response.containsKey("error")) {
      return false;
    }

    return true;
  }

  /// 위젯 삭제
  static Future<bool> deleteWidget(String widgetId) async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return false;

    Map<String, dynamic> response = await ApiService.sendRequest(
      endpoint: "/api/widgets/$userId/$widgetId/delete/",
      method: "DELETE",
    );

    if (response.containsKey("error")) {
      return false;
    }

    return true;
  }
}