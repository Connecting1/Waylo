// lib/screens/profile/user_album_content.dart

import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/services/api/widget_api.dart';
import 'package:waylo_flutter/widgets/custom_widgets/profile_image_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/checklist_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/textbox_widget.dart'; // TextBoxWidget import 추가
import '../../../styles/app_styles.dart';

class UserAlbumContentWidget extends StatefulWidget {
  final String userId;
  final String username;

  const UserAlbumContentWidget({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  _UserAlbumContentWidgetState createState() => _UserAlbumContentWidgetState();
}

class _UserAlbumContentWidgetState extends State<UserAlbumContentWidget> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  List<AlbumWidget> _userWidgets = [];
  Color _canvasColor = Colors.white;
  String _canvasPattern = "none";
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserAlbumData();
  }

  // 사용자 앨범 데이터 로드
  Future<void> _loadUserAlbumData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. 앨범 스타일 정보 가져오기
      final albumResponse = await _fetchUserAlbumInfo();
      if (albumResponse.containsKey('error')) {
        throw Exception(albumResponse['error']);
      }

      // 캔버스 색상 및 패턴 설정
      _canvasColor = _convertHexToColor(albumResponse["background_color"] ?? "#FFFFFF");
      _canvasPattern = albumResponse["background_pattern"] ?? "none";

      // 2. 위젯 정보 가져오기
      final widgets = await _fetchUserWidgets();
      setState(() {
        _userWidgets = widgets;
        _isLoading = false;
      });
    } catch (e) {
      print("[ERROR] 사용자 앨범 데이터 로드 중 오류 발생: $e");
      setState(() {
        _errorMessage = 'An error occurred while loading album data.';
        _isLoading = false;
      });
    }
  }

  // 사용자 앨범 정보 가져오기
  Future<Map<String, dynamic>> _fetchUserAlbumInfo() async {
    try {
      final endpoint = "/api/albums/${widget.userId}/";
      return await ApiService.sendRequest(endpoint: endpoint);
    } catch (e) {
      print("[ERROR] 사용자 앨범 정보 가져오기 실패: $e");
      return {"error": "앨범 정보를 가져오는데 실패했습니다."};
    }
  }

  // 사용자 위젯 정보 가져오기
  Future<List<AlbumWidget>> _fetchUserWidgets() async {
    try {
      final endpoint = "/api/widgets/${widget.userId}/";
      final response = await ApiService.sendRequest(endpoint: endpoint);

      if (response.containsKey("error") || !response.containsKey("widgets")) {
        print("[ERROR] 위젯 데이터 가져오기 실패: ${response["error"] ?? "widgets 키가 없음"}");
        return [];
      }

      List<dynamic> widgetsJson = response["widgets"];
      List<AlbumWidget> widgets = [];

      for (var json in widgetsJson) {
        try {
          // extra_data 처리
          if (json.containsKey('extra_data') && json['extra_data'] is String) {
            try {
              Map<String, dynamic> parsedExtraData = {};
              if (json['extra_data'].isNotEmpty) {
                parsedExtraData = Map<String, dynamic>.from(json['extra_data']);
              }
              json['extra_data'] = parsedExtraData;
            } catch (e) {
              json['extra_data'] = {};
            }
          }

          widgets.add(AlbumWidget.fromJson(json));
        } catch (e) {
          print("[ERROR] 위젯 변환 실패: $e, 데이터: $json");
        }
      }

      return widgets;
    } catch (e) {
      print("[ERROR] 사용자 위젯 정보 가져오기 실패: $e");
      return [];
    }
  }

  // 헥스 코드를 Color 객체로 변환
  Color _convertHexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // 읽기 전용 위젯 렌더링
  Widget _buildReadOnlyWidget(AlbumWidget widget) {
    // 위젯 타입에 따라 다른 위젯 반환
    Widget content;

    if (widget.type == "profile_image") {
      content = ProfileImageWidget(widget: widget);
    } else if (widget.type == "checklist") {
      content = ChecklistWidget(widget: widget);
    } else if (widget.type == "text_box") {
      // 텍스트박스 위젯 처리 추가
      // 읽기 전용 모드를 위해 isSelected를 false로 설정
      content = TextBoxWidget(
        widget: widget,
        isSelected: false, // 읽기 전용 모드
      );
    } else {
      // 지원되지 않는 위젯 타입
      content = Container(
        color: Colors.grey,
        child: Center(child: Text(widget.type)),
      );
    }

    // 고정된 위치에 표시 (드래그 불가능)
    return Positioned(
      left: widget.x,
      top: widget.y,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: content,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 로딩 중이면 로딩 화면 표시
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // 오류 발생 시 오류 메시지 표시
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage, style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserAlbumData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _canvasColor,
        image: _canvasPattern == "none"
            ? null
            : DecorationImage(
          image: AssetImage("assets/patterns/${_canvasPattern}.png"),
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Stack(
        children: [
          // 사용자의 위젯 렌더링 (읽기 전용)
          ..._userWidgets.map((widget) => _buildReadOnlyWidget(widget)),

          // 위젯이 없는 경우 안내 메시지 표시
          if (_userWidgets.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_module_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "${widget.username}'s album has no widgets.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}