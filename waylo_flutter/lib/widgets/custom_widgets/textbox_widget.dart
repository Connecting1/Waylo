// lib/widget/custom_widgets/textbox_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/widget_provider.dart';
import '../../models/album_widget.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../styles/app_styles.dart';

class TextBoxWidget extends StatefulWidget {
  final AlbumWidget widget;
  final bool isSelected; // 부모 DraggableWidget에서의 선택 상태

  const TextBoxWidget({
    Key? key,
    required this.widget,
    this.isSelected = false, // 기본값은 false
  }) : super(key: key);

  @override
  _TextBoxWidgetState createState() => _TextBoxWidgetState();
}

class _TextBoxWidgetState extends State<TextBoxWidget> {
  late TextEditingController _textController;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  // 배경색과 투명도, 테두리 숨김 추가
  late Color _backgroundColor;
  late double _opacity;
  late bool _hideBorder;

  @override
  void initState() {
    super.initState();
    // 위젯의 extraData에서 텍스트 로드
    String savedText = widget.widget.extraData['text'] ?? "";
    _textController = TextEditingController(text: savedText);
    _focusNode.addListener(_onFocusChange);

    // 배경색과 투명도 초기화
    _initBackgroundSettings();

    print(
        "📱 TextBoxWidget 초기화됨: ID=${widget.widget.id}, 로드된 텍스트='$savedText'");
  }

  @override
  void didUpdateWidget(TextBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // extraData가 외부에서 변경되면 UI 업데이트
    if (oldWidget.widget.extraData != widget.widget.extraData) {
      _initBackgroundSettings();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _initBackgroundSettings() {
    // extraData에서 배경색 가져오기 (기본값: 흰색)
    String colorHex = widget.widget.extraData['backgroundColor'] ?? '#FFFFFF';
    try {
      _backgroundColor =
          Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      print("❌ 배경색 파싱 실패: $e");
      _backgroundColor = Colors.white;
    }

    // extraData에서 투명도 가져오기 (기본값: 1.0)
    var opacityValue = widget.widget.extraData['opacity'];
    if (opacityValue is double) {
      _opacity = opacityValue;
    } else if (opacityValue is int) {
      _opacity = opacityValue.toDouble();
    } else {
      _opacity = 1.0;
    }

    // extraData에서 테두리 숨김 여부 가져오기 (기본값: false)
    _hideBorder = widget.widget.extraData['hideBorder'] ?? false;

    print("📱 텍스트 박스 배경 설정: 색상=$colorHex, 투명도=$_opacity");
  }

  // 포커스 변경 시 처리
  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveText();
    }
  }

  void _toggleEditing() {
    print("📱 TextBoxWidget 편집 모드 전환: $_isEditing -> ${!_isEditing}");
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        // 편집 모드로 전환 시 포커스 요청
        Future.delayed(Duration(milliseconds: 50), () {
          _focusNode.requestFocus();
        });
      }
    });
  }

  void _saveText() {
    print("📱 TextBoxWidget 텍스트 저장: ${_textController.text}");
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    // 기존 데이터와 비교하여 변경된 경우에만 업데이트 요청
    String currentText = widget.widget.extraData['text'] ?? "";
    String newText = _textController.text;

    if (currentText != newText) {
      print("📱 TextBoxWidget 텍스트 변경 감지: '$currentText' → '$newText'");

      // 현재 위젯의 extraData 복사 후 text 필드만 업데이트
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['text'] = newText;

      // 데이터베이스 업데이트 요청
      widgetProvider
          .updateWidgetExtraData(widget.widget.id, updatedExtraData)
          .then((success) {
        if (success) {
          print("✅ 텍스트 저장 성공: $newText");
          // DB 저장 성공 시 작은 피드백 표시 (선택적)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Text has been saved"),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          print("❌ 텍스트 저장 실패");
          // 저장 실패 시 사용자에게 알림
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("An error occurred while saving text"),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } else {
      print("📱 텍스트 변경 없음, 저장 건너뜀");
    }

    setState(() {
      _isEditing = false;
    });
  }

  // 배경 설정 대화상자 표시
  void _showBackgroundSettings() {
    Color pickerColor = _backgroundColor;
    double tempOpacity = _opacity;
    bool tempHideBorder = _hideBorder;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Background Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 색상 선택기
                    ColorPicker(
                      pickerColor: pickerColor,
                      onColorChanged: (Color color) {
                        setState(() => pickerColor = color);
                      },
                      showLabel: true,
                      pickerAreaHeightPercent: 0.8,
                      enableAlpha: false,
                    ),
                    SizedBox(height: 16),

                    // 테두리 제거 체크박스
                    Row(
                      children: [
                        Checkbox(
                          value: tempHideBorder,
                          onChanged: (value) {
                            setState(() => tempHideBorder = value ?? false);
                          },
                        ),
                        Text('Hide Border')
                      ],
                    ),

                    // 투명도 슬라이더
                    Text('Opacity: ${(tempOpacity * 100).round()}%'),
                    Slider(
                      value: tempOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      onChanged: (value) {
                        setState(() => tempOpacity = value);
                      },
                    ),

                    // 미리보기
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: pickerColor.withOpacity(tempOpacity),
                        borderRadius: BorderRadius.circular(8),
                        border: tempHideBorder
                            ? null // 테두리 제거
                            : Border.all(
                            color: Colors.black.withOpacity(0.2), width: 1),
                        boxShadow: tempOpacity < 0.05
                            ? [] // 그림자 제거
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Center(child: Text('Preview')),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Apply'),
                  onPressed: () {
                    _updateBackgroundSettings(
                        pickerColor, tempOpacity, tempHideBorder);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 배경 설정 저장
  Future<void> _updateBackgroundSettings(
      Color color, double opacity, bool hideBorder) async {
    // 색상을 HEX 문자열로 변환
    String colorHex =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    setState(() {
      _backgroundColor = color;
      _opacity = opacity;
      _hideBorder = hideBorder;
    });

    // extraData 업데이트
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
    updatedExtraData['backgroundColor'] = colorHex;
    updatedExtraData['opacity'] = opacity;
    updatedExtraData['hideBorder'] = hideBorder; // 테두리 숨김 여부 저장

    // 서버에 업데이트 요청
    bool success = await widgetProvider.updateWidgetExtraData(
        widget.widget.id, updatedExtraData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Background settings have been saved'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save background settings'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    print("📱 TextBoxWidget 빌드: ID=${widget.widget.id}, 편집 모드=$_isEditing");

    Color backgroundColor = _backgroundColor.withOpacity(_opacity);

    bool isFullyTransparent = _opacity == 0.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: _hideBorder
            ? null
            : Border.all(color: Colors.black.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isFullyTransparent
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 텍스트 필드
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 36, 12),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              readOnly: !_isEditing,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: _isEditing
                    ? "Enter text"
                    : _textController.text.isEmpty
                    ? "Please enter text"
                    : "",
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onEditingComplete: () {
                // 편집 완료 시 저장 강제 실행
                print("📱 텍스트 편집 완료: ${_textController.text}");
                _saveText();
              },
              onSubmitted: (_) => _saveText(),
            ),
          ),

          // 편집 버튼
          if (widget.isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (_isEditing) {
                      // 편집 모드에서 버튼 클릭 시 저장 명시적 호출
                      _saveText();
                    } else {
                      _toggleEditing();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      _isEditing ? Icons.check : Icons.edit,
                      size: 18,
                      color: _isEditing ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          // 배경 설정 버튼 (컨트롤이 표시될 때만)
          if (widget.isSelected)
            Positioned(
              top: 4,
              right: 40, // 편집 버튼 옆에 위치
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _showBackgroundSettings,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.format_color_fill,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
