import 'package:flutter/material.dart';
import '../../styles/app_styles.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';

class AlbumScreenPage extends StatefulWidget {
  const AlbumScreenPage({Key? key}) : super(key: key);

  @override
  _AlbumScreenPageState createState() => _AlbumScreenPageState();
}

class _AlbumScreenPageState extends State<AlbumScreenPage> {
  String _username = "Loading..."; // 기본값 설정
  Color _canvasColor = Colors.white;
  String _canvasPattern = "none";

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // 사용자 정보 불러오기
    _loadCanvasSettings();
  }

  Future<void> _loadUserInfo() async {
    Map<String, dynamic> userInfo = await UserApi.fetchUserInfo(); // 변경 완료

    if (userInfo.containsKey("error")) {
      setState(() {
        _username = "Unknown User"; // 오류 발생 시 기본값 설정
      });
    } else {
      setState(() {
        _username = userInfo["username"] ?? "Unknown User"; // 유저네임 업데이트
      });
    }
  }

  Future<void> _loadCanvasSettings() async {

  }

  Future<void> _saveCanvasSettings(Color color, String pattern) async {

  }

  void _openWidgetSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text("Settings & Add Widget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.color_lens, color: _canvasColor),
                    title: Text("Change Canvas Background"),
                    onTap: () {
                      Navigator.pop(context);
                      _pickCanvasBackground(context);
                    },
                  ),
                  Divider(),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                        _saveCanvasSettings(color, _canvasPattern);
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
                        _saveCanvasSettings(_canvasColor, pattern);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _username.isNotEmpty ? "${_username}'s album" : "Loading...", // 유저 이름 적용
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _openWidgetSelection,
          ),
        ],
        centerTitle: true,
        toolbarHeight: 56,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _canvasColor, // 배경 색상 적용
          image: _canvasPattern == "none"
              ? null
              : DecorationImage(
            image: AssetImage("assets/patterns/${_canvasPattern}.png"), // 패턴 적용
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Center(
          child: Text(
            'Album Screen',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
