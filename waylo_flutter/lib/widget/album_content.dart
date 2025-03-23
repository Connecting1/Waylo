import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../styles/app_styles.dart';
import 'package:waylo_flutter/widgets/canvas_settings.dart';
import 'package:waylo_flutter/providers/canvas_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import 'package:waylo_flutter/widgets/draggable_widget.dart';
import 'package:waylo_flutter/widgets/profile_image_widget.dart';
import 'package:waylo_flutter/widgets/checklist_widget.dart';
import 'package:waylo_flutter/widgets/textbox_widget.dart'; // TextBoxWidget import 추가
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/services/data_loading_manager.dart';

class AlbumContentWidget extends StatefulWidget {
  const AlbumContentWidget({Key? key}) : super(key: key);

  @override
  AlbumContentWidgetState createState() => AlbumContentWidgetState();
}

class AlbumContentWidgetState extends State<AlbumContentWidget> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadData();
  }

  // 데이터가 로드되었는지 확인하고 필요한 경우에만 로드
  Future<void> _checkAndLoadData() async {
    // 이미 초기화되었다면 아무것도 하지 않음
    if (DataLoadingManager.isInitialized()) {
      return;
    }

    // 아직 초기화되지 않았다면 로딩 표시 후 데이터 로드
    setState(() {
      _isLoading = true;
    });

    try {
      await DataLoadingManager.initializeAppData(context);
    } catch (e) {
      print("[ERROR] AlbumContentWidget: 데이터 로드 중 오류 발생: $e");

      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("데이터를 불러오는 중 오류가 발생했습니다."))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 상위 컴포넌트에서 호출할 수 있도록 public 메서드로 변경
  void openWidgetSelection() {
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
                  Text("Settings & Add Widget", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Consumer<CanvasProvider>(
                    builder: (context, canvasProvider, child) {
                      return CanvasSettings(
                        initialColor: canvasProvider.canvasColor,
                        initialPattern: canvasProvider.canvasPattern,
                        onSettingsChanged: (color, pattern) {
                          canvasProvider.updateCanvasSettings(color, pattern);
                        },
                      );
                    },
                  ),
                  Divider(),
                  _buildAddProfileImageWidget(),
                  // 체크리스트 위젯 추가 옵션
                  ListTile(
                    leading: Icon(Icons.checklist),
                    title: Text("Add Checklist"),
                    onTap: () {
                      // 바텀 시트 닫기
                      Navigator.pop(context);

                      // 체크리스트 위젯 추가
                      _addChecklistWidget();
                    },
                  ),
                  ListTile(
                      leading: Icon(Icons.text_fields),
                      title: Text("Add Text Box"),
                      onTap: () {
                        Navigator.pop(context);
                        _addTextBoxWidget();
                      }
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 체크리스트 위젯 추가 메서드
  void _addChecklistWidget() async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    AlbumWidget? widget = await widgetProvider.addChecklistWidget();

    if (widget != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Checklist widget added"))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add checklist widget"))
      );
    }
  }

  // 프로필 이미지 위젯 추가 옵션
  Widget _buildAddProfileImageWidget() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    return ListTile(
      leading: Icon(Icons.account_circle),
      title: Text("Add Profile Image"),
      onTap: () {
        // 바텀 시트를 닫고 새 바텀 시트 표시
        Navigator.pop(context);

        // 프로필 이미지 옵션 표시
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "Profile Image Options",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text("Use Current Profile Image"),
                    onTap: () async {
                      // 현재 프로필 이미지 사용
                      String profileImageUrl = userProvider.profileImage;

                      if (profileImageUrl.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                              "No profile image available. Please upload an image first.")),
                        );
                        Navigator.pop(context);
                        return;
                      }

                      // 위젯 추가
                      AlbumWidget? widget = await widgetProvider
                          .addProfileWidget(profileImageUrl);

                      if (widget != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Profile image added")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Failed to add profile image")),
                        );
                      }

                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.add_photo_alternate),
                    title: Text("Upload New Image"),
                    onTap: () async {
                      // 갤러리에서 이미지 선택
                      await _pickAndUploadProfileImage(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 프로필 이미지 선택 및 업로드
  Future<void> _pickAndUploadProfileImage(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    // ApiService에서 직접 userId 가져오기
    String? userId = await ApiService.getUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ID not found. Please login again.")),
      );
      return;
    }

    try {
      // 이미지 피커 라이브러리 사용
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploading image...")),
      );

      // 이미지 파일로 변환
      File imageFile = File(image.path);

      // 프로필 이미지 업데이트
      Map<String, dynamic> result = await UserApi.updateProfileImage(
        userId: userId,
        profileImage: imageFile,
      );

      if (result.containsKey("error")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              "Failed to update profile image: ${result["error"]}")),
        );
        return;
      }

      // 사용자 정보 다시 로드
      await userProvider.loadUserInfo(forceRefresh: true);

      // 프로필 이미지 위젯 추가
      String profileImageUrl = userProvider.profileImage;
      if (profileImageUrl.isNotEmpty) {
        // 기존 프로필 위젯의 이미지 URL 모두 업데이트
        await widgetProvider.updateAllProfileWidgetsImageUrl(profileImageUrl);

        // 새 위젯 추가
        AlbumWidget? widget = await widgetProvider.addProfileWidget(
            profileImageUrl);

        if (widget != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile image updated and added to album")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                "Profile image updated but failed to add to album")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile image updated but URL is empty")),
        );
      }
    } catch (e) {
      print("[ERROR] 이미지 선택/업로드 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting/uploading image: $e")),
      );
    }
  }

  // 위젯 수정 메뉴 표시
  void _showWidgetEditMenu(BuildContext context, AlbumWidget widget) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Edit Widget",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // 위젯 타입에 따른 수정 옵션
              if (widget.type == "profile_image") ...[
                ListTile(
                  leading: Icon(Icons.format_shapes),
                  title: Text("Change Shape"),
                  onTap: () {
                    // 모양 변경 (원형 <-> 사각형)
                    String currentShape = widget.extraData['shape'] ?? 'circle';
                    String newShape = currentShape == 'circle'
                        ? 'rectangle'
                        : 'circle';
                    widgetProvider.updateProfileWidgetShape(
                        widget.id, newShape);
                    Navigator.pop(context);
                  },
                ),
              ],
              if (widget.type == "checklist") ...[
                ListTile(
                  leading: Icon(Icons.add_task),
                  title: Text("Add New Item"),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddChecklistItemDialog(widget);
                  },
                ),
              ],
              // 삭제 옵션
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                    "Delete Widget", style: TextStyle(color: Colors.red)),
                onTap: () {
                  widgetProvider.deleteWidget(widget.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addTextBoxWidget() async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    AlbumWidget? widget = await widgetProvider.addTextBoxWidget();
    if (widget != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Text Box widget added")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add text box widget")));
    }
  }

  // 체크리스트 항목 추가 다이얼로그
  void _showAddChecklistItemDialog(AlbumWidget widget) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Item'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'New item'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // 체크리스트 위젯에 직접 항목 추가
              // 이렇게 하면 다른 방식으로 항목을 추가할 수도 있습니다
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // 위젯 렌더링
  Widget _buildWidget(AlbumWidget widget) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    bool _isSelected = false; // 선택 상태 변수 추가

    // 위젯 타입에 따라 다른 위젯 반환
    Widget content;

    if (widget.type == "profile_image") {
      content = ProfileImageWidget(widget: widget);
    } else if (widget.type == "checklist") {
      content = ChecklistWidget(widget: widget);
    } else if (widget.type == "text_box") {
      // isSelected 상태 명시적으로 전달
      content = TextBoxWidget(
        widget: widget,
        isSelected: true, // 항상 선택된 상태로 설정 (임시)
      );
    } else {
      // 지원되지 않는 위젯 타입
      content = Container(
        color: Colors.grey,
        child: Center(child: Text(widget.type)),
      );
    }

    // 드래그 가능한 컨테이너로 래핑
    return DraggableWidget(
      key: ValueKey(widget.id),
      initialX: widget.x,
      initialY: widget.y,
      width: widget.width,
      height: widget.height,
      widgetType: widget.type,
      // 텍스트박스인 경우에만 자유 크기 조절 모드 사용
      resizeMode: widget.type == "text_box" ? ResizeMode.free : ResizeMode.aspectRatio,
      onPositionChanged: (x, y) {
        widgetProvider.updateWidgetPosition(widget.id, x, y);
      },
      onSizeChanged: (width, height) {
        widgetProvider.updateWidgetSize(widget.id, width, height);
      },
      onTap: () {
        setState(() {
          _isSelected = true; // 선택 상태로 변경
        });
        print("위젯 선택됨: ${widget.id}");
      },
      onLongPress: () {
        _showWidgetEditMenu(context, widget);
      },
      child: content,
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

    return Consumer2<CanvasProvider, WidgetProvider>(
      builder: (context, canvasProvider, widgetProvider, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: canvasProvider.canvasColor,
            image: canvasProvider.canvasPattern == "none"
                ? null
                : DecorationImage(
              image: AssetImage(
                  "assets/patterns/${canvasProvider.canvasPattern}.png"),
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Stack(
            children: [
              // 모든 위젯 렌더링
              ...widgetProvider.widgets.map((widget) => _buildWidget(widget)),
            ],
          ),
        );
      },
    );
  }
}