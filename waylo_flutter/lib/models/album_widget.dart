// lib/models/album_widget.dart
import 'dart:convert';

class AlbumWidget {
  final String id;
  final String type;
  double x;
  double y;
  double width;
  double height;
  Map<String, dynamic> extraData;

  AlbumWidget({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.extraData,
  });

  factory AlbumWidget.fromJson(Map<String, dynamic> json) {
    dynamic extraData = json['extra_data'];
    Map<String, dynamic> parsedExtraData = {};

    if (extraData is String) {
      try {
        // 문자열 형태의 extra_data를 Map으로 파싱 시도
        parsedExtraData = jsonDecode(extraData);
      } catch (e) {
        print("[ERROR] AlbumWidget.fromJson: extra_data 파싱 실패: $e");
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