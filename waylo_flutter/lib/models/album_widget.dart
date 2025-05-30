import 'dart:convert';

/// 앨범에서 사용되는 위젯의 데이터 모델
class AlbumWidget {
  final String id;                        // 위젯의 고유 식별자
  final String type;                      // 위젯 타입 (text, image, video 등)
  double x;                              // 앨범 내 X 좌표
  double y;                              // 앨범 내 Y 좌표
  double width;                          // 위젯의 너비
  double height;                         // 위젯의 높이
  Map<String, dynamic> extraData;        // 위젯 타입별 추가 데이터

  AlbumWidget({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.extraData,
  });

  /// JSON 데이터로부터 AlbumWidget 인스턴스 생성
  factory AlbumWidget.fromJson(Map<String, dynamic> json) {
    dynamic extraData = json['extra_data'];
    Map<String, dynamic> parsedExtraData = {};

    if (extraData is String) {
      try {
        parsedExtraData = jsonDecode(extraData);
      } catch (e) {
        // JSON 파싱 실패 시 빈 Map으로 초기화
      }
    } else if (extraData is Map) {
      parsedExtraData = Map<String, dynamic>.from(extraData);
    }

    return AlbumWidget(
      id: json['id'],
      type: json['type'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      extraData: parsedExtraData,
    );
  }

  /// AlbumWidget을 JSON 형태로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'extra_data': extraData,
    };
  }

  /// 특정 필드만 변경한 새로운 AlbumWidget 인스턴스 생성
  AlbumWidget copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    Map<String, dynamic>? extraData,
  }) {
    return AlbumWidget(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      extraData: extraData ?? this.extraData,
    );
  }
}