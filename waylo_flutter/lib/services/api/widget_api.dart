// lib/services/api/widget_api.dart

import 'dart:convert';
import 'package:waylo_flutter/services/api/api_service.dart';

class WidgetApi {
  // 앨범의 모든 위젯 가져오기
  static Future<List<Map<String, dynamic>>> fetchAlbumWidgets() async {
    String? userId = await ApiService.getUserId();

    if (userId == null) {
      print("[ERROR] 사용자 ID를 가져올 수 없음");
      return [];
    }

    try {
      Map<String, dynamic> response = await ApiService.sendRequest(
        endpoint: "/api/widgets/$userId/",
      );

      if (response.containsKey("error") || !response.containsKey("widgets")) {
        print("[ERROR] 위젯 데이터 가져오기 실패: ${response["error"] ?? "widgets 키가 없음"}");
        return [];
      }

      List<Map<String, dynamic>> widgets = List<Map<String, dynamic>>.from(response["widgets"]);
      return widgets;
    } catch (e) {
      print("[ERROR] 위젯 데이터 가져오기 실패: $e");
      return [];
    }
  }

  // 위젯 추가하기
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

    try {
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
        print("[ERROR] 위젯 추가 실패: ${response["error"] ?? "Unknown error"}");
        return null;
      }

      return response["widget"];
    } catch (e) {
      print("[ERROR] 위젯 추가 실패: $e");
      return null;
    }
  }

  // 위젯 업데이트
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

    // 업데이트할 필드만 포함
    Map<String, dynamic> body = {};
    if (x != null) body["x"] = x;
    if (y != null) body["y"] = y;
    if (width != null) body["width"] = width;
    if (height != null) body["height"] = height;
    if (extraData != null) body["extra_data"] = extraData;

    try {
      Map<String, dynamic> response = await ApiService.sendRequest(
        endpoint: "/api/widgets/$userId/$widgetId/update/",
        method: "PATCH",
        body: body,
      );

      if (response.containsKey("error")) {
        print("[ERROR] 위젯 업데이트 실패: ${response["error"]}");
        return false;
      }

      return true;
    } catch (e) {
      print("[ERROR] 위젯 업데이트 실패: $e");
      return false;
    }
  }

  // 위젯 삭제
  static Future<bool> deleteWidget(String widgetId) async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return false;

    try {
      Map<String, dynamic> response = await ApiService.sendRequest(
        endpoint: "/api/widgets/$userId/$widgetId/delete/",
        method: "DELETE",
      );

      if (response.containsKey("error")) {
        print("[ERROR] 위젯 삭제 실패: ${response["error"]}");
        return false;
      }

      return true;
    } catch (e) {
      print("[ERROR] 위젯 삭제 실패: $e");
      return false;
    }
  }
}