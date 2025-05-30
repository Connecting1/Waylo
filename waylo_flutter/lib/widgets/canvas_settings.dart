import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// 캔버스 배경색과 패턴을 설정하는 위젯
class CanvasSettings extends StatefulWidget {
  final Color initialColor;
  final String initialPattern;
  final Function(Color, String) onSettingsChanged;

  const CanvasSettings({
    Key? key,
    required this.initialColor,
    required this.initialPattern,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _CanvasSettingsState createState() => _CanvasSettingsState();
}

class _CanvasSettingsState extends State<CanvasSettings> {
  late Color _canvasColor;
  late String _canvasPattern;

  @override
  void initState() {
    super.initState();
    _canvasColor = widget.initialColor;
    _canvasPattern = widget.initialPattern;
  }

  @override
  void didUpdateWidget(CanvasSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor ||
        oldWidget.initialPattern != widget.initialPattern) {
      setState(() {
        _canvasColor = widget.initialColor;
        _canvasPattern = widget.initialPattern;
      });
    }
  }

  /// 캔버스 배경 설정 다이얼로그 표시
  void _pickCanvasBackground(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Canvas Background"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _canvasColor,
                      onColorChanged: (Color color) {
                        setState(() => _canvasColor = color);
                        this.setState(() => _canvasColor = color);
                        widget.onSettingsChanged(color, _canvasPattern);
                      },
                      showLabel: true,
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  Divider(),
                  DropdownButton<String>(
                    value: _canvasPattern,
                    items: [
                      DropdownMenuItem(value: "none", child: Text("No Pattern")),
                      DropdownMenuItem(value: "pattern1", child: Text("Pattern 1")),
                      DropdownMenuItem(value: "pattern2", child: Text("Pattern 2")),
                      DropdownMenuItem(value: "pattern3", child: Text("Pattern 3")),
                      DropdownMenuItem(value: "pattern4", child: Text("Pattern 4")),
                      DropdownMenuItem(value: "pattern5", child: Text("Pattern 5")),
                      DropdownMenuItem(value: "pattern6", child: Text("Pattern 6")),
                    ],
                    onChanged: (String? pattern) {
                      if (pattern != null) {
                        setState(() {
                          _canvasPattern = pattern;
                        });
                        this.setState(() {
                          _canvasPattern = pattern;
                        });
                        widget.onSettingsChanged(_canvasColor, pattern);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.color_lens, color: _canvasColor),
      title: Text("Change Canvas Background"),
      onTap: () => _pickCanvasBackground(context),
    );
  }
}