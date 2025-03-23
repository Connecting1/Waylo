import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/widget_api.dart';
import 'package:uuid/uuid.dart';

class WidgetProvider extends ChangeNotifier {
  List<AlbumWidget> _widgets = [];
  bool _isLoaded = false;
  final Uuid _uuid = Uuid();

  List<AlbumWidget> get widgets => _widgets;
  bool get isLoaded => _isLoaded;

  // 위젯 목록 로드
  Future<void> loadWidgets() async {
    if (_isLoaded) return;

    try {
      var widgetsJson = await WidgetApi.fetchAlbumWidgets();

      _widgets = [];
      for (var json in widgetsJson) {
        try {
          // extra_data가 문자열인 경우 파싱 시도
          if (json.containsKey('extra_data') && json['extra_data'] is String) {
            try {
              // 문자열로 저장된 JSON을 파싱
              String extraDataStr = json['extra_data'];

              // 간단한 접근법: 정규식 대신 단계별 치환
              if (extraDataStr.contains(": ") && !extraDataStr.contains(": \"")) {
                // key: value 패턴을 "key": value 패턴으로 변환
                List<String> parts = extraDataStr.split(',');
                List<String> newParts = [];

                for (var part in parts) {
                  if (part.contains(': ')) {
                    var keyValue = part.split(': ');
                    if (keyValue.length == 2) {
                      String key = keyValue[0].trim();
                      // 이미 따옴표가 있는지 확인
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
                // 문자열을 Map으로 변환
                Map<String, dynamic> parsedExtraData = jsonDecode(extraDataStr);
                json['extra_data'] = parsedExtraData;
              } catch (e) {
                // 파싱에 실패한 경우 기본값 사용
                json['extra_data'] = {};
              }
            } catch (e) {
              json['extra_data'] = {};
            }
          }

          // 변환된 객체 추가
          _widgets.add(AlbumWidget.fromJson(json));
        } catch (e) {
          print("[ERROR] 개별 위젯 변환 실패: $e, 위젯 데이터: $json");
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print("[ERROR] 위젯 데이터 로드 실패: $e");
    }
  }

  // 프로필 사진 위젯 추가
  Future<AlbumWidget?> addProfileWidget(String profileImageUrl) async {
    // 기본 위치 및 크기 설정
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
      // 서버에 위젯 추가 요청
      var widgetJson = await WidgetApi.addWidget(
        type: "profile_image",
        x: x,
        y: y,
        width: width,
        height: height,
        extraData: extraData,
      );

      if (widgetJson != null) {
        // 새 위젯 객체 생성
        AlbumWidget newWidget = AlbumWidget.fromJson(widgetJson);

        // 로컬 상태에 추가
        _widgets.add(newWidget);
        notifyListeners();
        return newWidget;
      } else {
        print("[ERROR] 프로필 사진 위젯 추가 실패");
        return null;
      }
    } catch (e) {
      print("[ERROR] 프로필 사진 위젯 추가 실패: $e");
      return null;
    }
  }

  // 체크리스트 위젯 추가
  Future<AlbumWidget?> addChecklistWidget() async {
    // 기본 위치 및 크기 설정
    double x = 50.0;
    double y = 50.0;
    double width = 300.0;
    double height = 200.0;

    Map<String, dynamic> extraData = {
      "items": []  // 초기에는 비어있는 항목 목록
    };

    try {
      // 기존 addWidget API 호출
      var widgetJson = await WidgetApi.addWidget(
        type: "checklist",
        x: x,
        y: y,
        width: width,
        height: height,
        extraData: extraData,
      );

      if (widgetJson != null) {
        // 새 위젯 객체 생성
        AlbumWidget newWidget = AlbumWidget.fromJson(widgetJson);

        // 로컬 상태에 추가
        _widgets.add(newWidget);
        notifyListeners();
        return newWidget;
      } else {
        print("[ERROR] 체크리스트 위젯 추가 실패");
        return null;
      }
    } catch (e) {
      print("[ERROR] 체크리스트 위젯 추가 실패: $e");
      return null;
    }
  }

  Future<AlbumWidget?> addTextBoxWidget() async {
    double x = 50.0;
    double y = 50.0;
    double width = 200.0;
    double height = 100.0;
    Map<String, dynamic> extraData = {
      "text": "",
      "backgroundColor": "#FFFFFF", // 기본 배경색: 흰색
      "opacity": 1.0 // 기본 투명도: 100%
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
      print("❌ 텍스트 박스 위젯 추가 실패: $e");
    }
    return null;
  }

  Future<bool> updateWidgetExtraData(
      String widgetId, Map<String, dynamic> extraData) async {
    print("📦 위젯 extraData 업데이트 시작: widgetId=$widgetId, extraData=$extraData");

    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) {
      print("❌ 위젯을 찾을 수 없음: widgetId=$widgetId");
      return false;
    }

    // extraData 딥 복사하여 로컬 상태 업데이트
    Map<String, dynamic> updatedExtraData =
    Map<String, dynamic>.from(extraData);
    _widgets[index].extraData = updatedExtraData;
    notifyListeners();

    try {
      // 서버에 업데이트 요청
      bool success = await WidgetApi.updateWidget(
          widgetId: widgetId, extraData: extraData);

      if (success) {
        print("✅ 위젯 extraData 업데이트 성공: widgetId=$widgetId");
      } else {
        print("❌ 위젯 extraData 업데이트 실패: widgetId=$widgetId");
        // 실패 시 위젯 목록 다시 로드 (선택적)
        // await loadWidgets();
      }

      return success;
    } catch (e) {
      print("❌ 위젯 extraData 업데이트 중 예외 발생: $e");
      return false;
    }
  }

  // 위젯 위치 업데이트
  Future<bool> updateWidgetPosition(String widgetId, double x, double y) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    // 로컬 상태 업데이트
    _widgets[index].x = x;
    _widgets[index].y = y;
    notifyListeners();

    // 서버에 업데이트 요청
    bool success = await WidgetApi.updateWidget(
      widgetId: widgetId,
      x: x,
      y: y,
    );

    return success;
  }

  // 위젯 크기 업데이트
  Future<bool> updateWidgetSize(String widgetId, double width, double height) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    // 로컬 상태 업데이트
    _widgets[index].width = width;
    _widgets[index].height = height;
    notifyListeners();

    // 서버에 업데이트 요청
    bool success = await WidgetApi.updateWidget(
      widgetId: widgetId,
      width: width,
      height: height,
    );

    return success;
  }

  // 위젯 모양 업데이트 (프로필 사진용)
  Future<bool> updateProfileWidgetShape(String widgetId, String shape) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    // 로컬 상태 업데이트
    Map<String, dynamic> newExtraData = Map.from(_widgets[index].extraData);
    newExtraData['shape'] = shape;
    _widgets[index].extraData = newExtraData;
    notifyListeners();

    // 서버에 업데이트 요청
    bool success = await WidgetApi.updateWidget(
      widgetId: widgetId,
      extraData: newExtraData,
    );

    return success;
  }

  // 모든 프로필 위젯의 이미지 URL 업데이트
  Future<void> updateAllProfileWidgetsImageUrl(String newImageUrl) async {
    // 이미지 URL에 타임스탬프 추가 (캐시 무효화)
    String timestampedUrl = "$newImageUrl?t=${DateTime.now().millisecondsSinceEpoch}";

    // 모든 프로필 이미지 위젯 찾기
    List<AlbumWidget> profileWidgets = _widgets.where((w) => w.type == "profile_image").toList();

    for (var widget in profileWidgets) {
      try {
        // 각 위젯의 extraData 업데이트
        Map<String, dynamic> newExtraData = Map.from(widget.extraData);
        newExtraData['image_url'] = timestampedUrl;

        // 로컬 상태 업데이트
        int index = _widgets.indexWhere((w) => w.id == widget.id);
        if (index != -1) {
          _widgets[index].extraData = newExtraData;
        }

        // 서버에 업데이트 요청
        await WidgetApi.updateWidget(
          widgetId: widget.id,
          extraData: newExtraData,
        );
      } catch (e) {
        print("[ERROR] 위젯 이미지 URL 업데이트 실패: ${widget.id}, 오류: $e");
      }
    }

    // UI 업데이트
    notifyListeners();
  }

  // 위젯 삭제
  Future<bool> deleteWidget(String widgetId) async {
    int index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index == -1) return false;

    // 로컬 상태에서 제거
    _widgets.removeAt(index);
    notifyListeners();

    // 서버에서 삭제 요청
    bool success = await WidgetApi.deleteWidget(widgetId);

    if (!success) {
      // 삭제 실패 시 다시 로컬 상태에 추가 (롤백)
      loadWidgets(); // 전체 위젯 목록 다시 로드
    }

    return success;
  }

  // 상태 초기화
  void reset() {
    _widgets = []; // 위젯 목록 완전히 비우기
    _isLoaded = false; // 로드 상태 초기화
    notifyListeners();
  }
}