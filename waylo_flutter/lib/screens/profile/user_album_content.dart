import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/services/api/widget_api.dart';
import 'package:waylo_flutter/widgets/custom_widgets/profile_image_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/checklist_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/textbox_widget.dart';
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
  // 텍스트 상수들
  static const String _retryButtonText = "Retry";
  static const String _noWidgetsMessageSuffix = "'s album has no widgets.";

  // 에러 메시지 상수들
  static const String _albumLoadErrorMessage = "An error occurred while loading album data.";
  static const String _albumInfoFetchErrorMessage = "Failed to fetch album information.";
  static const String _widgetsKeyMissingError = "widgets key is missing";

  // 폰트 크기 상수들
  static const double _errorMessageFontSize = 16;
  static const double _noWidgetsMessageFontSize = 16;

  // 크기 상수들
  static const double _errorIconSize = 48;
  static const double _noWidgetsIconSize = 64;
  static const double _errorIconSpacing = 16;
  static const double _errorButtonSpacing = 24;
  static const double _noWidgetsIconSpacing = 16;

  // 위젯 타입 상수들
  static const String _profileImageType = "profile_image";
  static const String _checklistType = "checklist";
  static const String _textBoxType = "text_box";

  // API 엔드포인트 상수들
  static const String _albumApiPrefix = "/api/albums/";
  static const String _albumApiSuffix = "/";
  static const String _widgetApiPrefix = "/api/widgets/";
  static const String _widgetApiSuffix = "/";

  // 색상 및 패턴 상수들
  static const String _nonePattern = "none";
  static const String _defaultBackgroundColor = "#FFFFFF";
  static const String _hexPrefix = "#";
  static const String _alphaPrefix = "FF";
  static const int _hexColorLength = 6;
  static const int _hexRadix = 16;

  // 파일 경로 상수들
  static const String _patternAssetPath = "assets/patterns/";
  static const String _patternFileExtension = ".png";

  // 데이터 키 상수들
  static const String _errorKey = "error";
  static const String _widgetsKey = "widgets";
  static const String _backgroundColorKey = "background_color";
  static const String _backgroundPatternKey = "background_pattern";
  static const String _extraDataKey = "extra_data";

  bool _isLoading = true;
  List<AlbumWidget> _userWidgets = [];
  Color _canvasColor = Colors.white;
  String _canvasPattern = _nonePattern;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _handleLoadUserAlbumData();
  }

  /// 사용자 앨범 데이터 로드 처리
  Future<void> _handleLoadUserAlbumData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final albumResponse = await _fetchUserAlbumInfo();
      if (albumResponse.containsKey(_errorKey)) {
        throw Exception(albumResponse[_errorKey]);
      }

      _canvasColor = _convertHexToColor(albumResponse[_backgroundColorKey] ?? _defaultBackgroundColor);
      _canvasPattern = albumResponse[_backgroundPatternKey] ?? _nonePattern;

      final widgets = await _fetchUserWidgets();
      setState(() {
        _userWidgets = widgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _albumLoadErrorMessage;
        _isLoading = false;
      });
    }
  }

  /// 사용자 앨범 정보 가져오기
  Future<Map<String, dynamic>> _fetchUserAlbumInfo() async {
    try {
      final endpoint = "$_albumApiPrefix${widget.userId}$_albumApiSuffix";
      return await ApiService.sendRequest(endpoint: endpoint);
    } catch (e) {
      return {_errorKey: _albumInfoFetchErrorMessage};
    }
  }

  /// 사용자 위젯 정보 가져오기
  Future<List<AlbumWidget>> _fetchUserWidgets() async {
    try {
      final endpoint = "$_widgetApiPrefix${widget.userId}$_widgetApiSuffix";
      final response = await ApiService.sendRequest(endpoint: endpoint);

      if (response.containsKey(_errorKey) || !response.containsKey(_widgetsKey)) {
        return [];
      }

      List<dynamic> widgetsJson = response[_widgetsKey];
      List<AlbumWidget> widgets = [];

      for (var json in widgetsJson) {
        try {
          if (json.containsKey(_extraDataKey) && json[_extraDataKey] is String) {
            try {
              Map<String, dynamic> parsedExtraData = {};
              if (json[_extraDataKey].isNotEmpty) {
                parsedExtraData = Map<String, dynamic>.from(json[_extraDataKey]);
              }
              json[_extraDataKey] = parsedExtraData;
            } catch (e) {
              json[_extraDataKey] = {};
            }
          }

          widgets.add(AlbumWidget.fromJson(json));
        } catch (e) {
          // 에러 처리
        }
      }

      return widgets;
    } catch (e) {
      return [];
    }
  }

  /// 헥스 코드를 Color 객체로 변환
  Color _convertHexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll(_hexPrefix, "");
    if (hexColor.length == _hexColorLength) {
      hexColor = "$_alphaPrefix$hexColor";
    }
    return Color(int.parse(hexColor, radix: _hexRadix));
  }

  /// 읽기 전용 위젯 렌더링
  Widget _buildReadOnlyWidget(AlbumWidget widget) {
    Widget content;

    if (widget.type == _profileImageType) {
      content = ProfileImageWidget(widget: widget);
    } else if (widget.type == _checklistType) {
      content = ChecklistWidget(widget: widget);
    } else if (widget.type == _textBoxType) {
      content = TextBoxWidget(
        widget: widget,
        isSelected: false,
      );
    } else {
      content = Container(
        color: Colors.grey,
        child: Center(child: Text(widget.type)),
      );
    }

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

  /// 에러 화면 위젯 생성
  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: _errorIconSize, color: Colors.red),
          SizedBox(height: _errorIconSpacing),
          Text(_errorMessage, style: TextStyle(fontSize: _errorMessageFontSize)),
          SizedBox(height: _errorButtonSpacing),
          ElevatedButton(
            onPressed: _handleLoadUserAlbumData,
            child: Text(_retryButtonText),
          ),
        ],
      ),
    );
  }

  /// 빈 앨범 화면 위젯 생성
  Widget _buildEmptyAlbumScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_module_outlined, size: _noWidgetsIconSize, color: Colors.grey),
          SizedBox(height: _noWidgetsIconSpacing),
          Text(
            "${widget.username}$_noWidgetsMessageSuffix",
            style: TextStyle(fontSize: _noWidgetsMessageFontSize, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  /// 캔버스 배경 데코레이션 생성
  BoxDecoration _buildCanvasDecoration() {
    return BoxDecoration(
      color: _canvasColor,
      image: _canvasPattern == _nonePattern
          ? null
          : DecorationImage(
        image: AssetImage("$_patternAssetPath$_canvasPattern$_patternFileExtension"),
        repeat: ImageRepeat.repeat,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: _buildCanvasDecoration(),
      child: Stack(
        children: [
          ..._userWidgets.map((widget) => _buildReadOnlyWidget(widget)),
          if (_userWidgets.isEmpty) _buildEmptyAlbumScreen(),
        ],
      ),
    );
  }
}