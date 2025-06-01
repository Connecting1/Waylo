import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/widget_provider.dart';
import '../../models/album_widget.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../styles/app_styles.dart';

/// 편집 가능한 텍스트 박스 위젯
class TextBoxWidget extends StatefulWidget {
  final AlbumWidget widget;
  final bool isSelected;

  const TextBoxWidget({
    Key? key,
    required this.widget,
    this.isSelected = false,
  }) : super(key: key);

  @override
  _TextBoxWidgetState createState() => _TextBoxWidgetState();
}

class _TextBoxWidgetState extends State<TextBoxWidget> {
  late TextEditingController _textController;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  late Color _backgroundColor;
  late double _opacity;
  late bool _hideBorder;

  @override
  void initState() {
    super.initState();
    String savedText = widget.widget.extraData['text'] ?? "";
    _textController = TextEditingController(text: savedText);
    _focusNode.addListener(_onFocusChange);

    _initBackgroundSettings();
  }

  @override
  void didUpdateWidget(TextBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  /// 배경 설정 초기화
  void _initBackgroundSettings() {
    String colorHex = widget.widget.extraData['backgroundColor'] ?? '#FFFFFF';
    try {
      _backgroundColor =
          Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      _backgroundColor = Colors.white;
    }

    var opacityValue = widget.widget.extraData['opacity'];
    if (opacityValue is double) {
      _opacity = opacityValue;
    } else if (opacityValue is int) {
      _opacity = opacityValue.toDouble();
    } else {
      _opacity = 1.0;
    }

    _hideBorder = widget.widget.extraData['hideBorder'] ?? false;
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveText();
    }
  }

  /// 편집 모드 토글
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        Future.delayed(Duration(milliseconds: 50), () {
          _focusNode.requestFocus();
        });
      }
    });
  }

  /// 텍스트 저장
  void _saveText() {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    String currentText = widget.widget.extraData['text'] ?? "";
    String newText = _textController.text;

    if (currentText != newText) {
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['text'] = newText;

      widgetProvider
          .updateWidgetExtraData(widget.widget.id, updatedExtraData)
          .then((success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Text has been saved"),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("An error occurred while saving text"),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }

    setState(() {
      _isEditing = false;
    });
  }

  /// 배경 설정 다이얼로그 표시
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

                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: pickerColor.withOpacity(tempOpacity),
                        borderRadius: BorderRadius.circular(8),
                        border: tempHideBorder
                            ? null
                            : Border.all(
                            color: Colors.black.withOpacity(0.2), width: 1),
                        boxShadow: tempOpacity < 0.05
                            ? []
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

  /// 배경 설정 업데이트
  Future<void> _updateBackgroundSettings(
      Color color, double opacity, bool hideBorder) async {
    String colorHex =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    setState(() {
      _backgroundColor = color;
      _opacity = opacity;
      _hideBorder = hideBorder;
    });

    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
    updatedExtraData['backgroundColor'] = colorHex;
    updatedExtraData['opacity'] = opacity;
    updatedExtraData['hideBorder'] = hideBorder;

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
                fillColor: Colors.transparent,
                filled: true,
              ),
              onEditingComplete: () {
                _saveText();
              },
              onSubmitted: (_) => _saveText(),
            ),
          ),

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
          if (widget.isSelected)
            Positioned(
              top: 4,
              right: 40,
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