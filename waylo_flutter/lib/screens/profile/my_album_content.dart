import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../styles/app_styles.dart';
import 'package:waylo_flutter/widgets/canvas_settings.dart';
import 'package:waylo_flutter/providers/canvas_provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import 'package:waylo_flutter/widgets/draggable_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/profile_image_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/checklist_widget.dart';
import 'package:waylo_flutter/widgets/custom_widgets/textbox_widget.dart';
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
  // 텍스트 상수들
  static const String _settingsAddWidgetTitle = "Settings & Add Widget";
  static const String _addChecklistText = "Add Checklist";
  static const String _addTextBoxText = "Add Text Box";
  static const String _addProfileImageText = "Add Profile Image";
  static const String _profileImageOptionsTitle = "Profile Image Options";
  static const String _useCurrentProfileText = "Use Current Profile Image";
  static const String _uploadNewImageText = "Upload New Image";
  static const String _editWidgetTitle = "Edit Widget";
  static const String _changeShapeText = "Change Shape";
  static const String _addNewItemText = "Add New Item";
  static const String _deleteWidgetText = "Delete Widget";
  static const String _addItemTitle = "Add Item";
  static const String _newItemHint = "New item";
  static const String _cancelText = "Cancel";
  static const String _addText = "Add";

  // 에러 및 성공 메시지 상수들
  static const String _dataLoadErrorMessage = "An error occurred while loading data.";
  static const String _checklistAddedMessage = "Checklist widget added";
  static const String _checklistFailedMessage = "Failed to add checklist widget";
  static const String _noProfileImageMessage = "No profile image available. Please upload an image first.";
  static const String _profileImageAddedMessage = "Profile image added";
  static const String _profileImageFailedMessage = "Failed to add profile image";
  static const String _uploadingImageMessage = "Uploading image...";
  static const String _userIdNotFoundMessage = "User ID not found. Please login again.";
  static const String _profileImageUpdateFailedMessage = "Failed to update profile image: ";
  static const String _profileImageUpdatedAndAddedMessage = "Profile image updated and added to album";
  static const String _profileImageUpdatedButFailedMessage = "Profile image updated but failed to add to album";
  static const String _profileImageUpdatedButEmptyMessage = "Profile image updated but URL is empty";
  static const String _imageUploadErrorMessage = "Error selecting/uploading image: ";
  static const String _textBoxAddedMessage = "Text Box widget added";
  static const String _textBoxFailedMessage = "Failed to add text box widget";

  // API 키 상수들
  static const String _errorKey = "error";

  // 위젯 타입 상수들
  static const String _profileImageType = "profile_image";
  static const String _checklistType = "checklist";
  static const String _textBoxType = "text_box";

  // 모양 타입 상수들
  static const String _circleShape = "circle";
  static const String _rectangleShape = "rectangle";
  static const String _shapeKey = "shape";

  // 폰트 크기 상수들
  static const double _titleFontSize = 18;

  // 크기 상수들
  static const double _containerPadding = 16;
  static const double _titleSpacing = 10;
  static const double _sectionSpacing = 16;

  // 바텀 시트 상수들
  static const double _initialChildSize = 0.4;
  static const double _minChildSize = 0.2;
  static const double _maxChildSize = 0.9;

  // 패턴 상수들
  static const String _nonePattern = "none";
  static const String _patternsAssetPath = "assets/patterns/";
  static const String _patternFileExtension = ".png";

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _handleInitialDataLoad();
  }

  /// 초기 데이터 로드 처리
  Future<void> _handleInitialDataLoad() async {
    if (DataLoadingManager.isInitialized()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DataLoadingManager.initializeAppData(context);
    } catch (e) {
      if (mounted) {
        _handleShowErrorMessage(_dataLoadErrorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 위젯 선택 모달 표시
  void openWidgetSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: _initialChildSize,
          minChildSize: _minChildSize,
          maxChildSize: _maxChildSize,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(_containerPadding),
              child: ListView(
                controller: scrollController,
                children: [
                  _buildModalTitle(_settingsAddWidgetTitle),
                  const SizedBox(height: _titleSpacing),
                  _buildCanvasSettings(),
                  const Divider(),
                  _buildAddProfileImageOption(),
                  _buildAddChecklistOption(),
                  _buildAddTextBoxOption(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 체크리스트 위젯 추가 처리
  Future<void> _handleAddChecklistWidget() async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final AlbumWidget? widget = await widgetProvider.addChecklistWidget();

    if (widget != null) {
      _handleShowSuccessMessage(_checklistAddedMessage);
    } else {
      _handleShowErrorMessage(_checklistFailedMessage);
    }
  }

  /// 텍스트박스 위젯 추가 처리
  Future<void> _handleAddTextBoxWidget() async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final AlbumWidget? widget = await widgetProvider.addTextBoxWidget();

    if (widget != null) {
      _handleShowSuccessMessage(_textBoxAddedMessage);
    } else {
      _handleShowErrorMessage(_textBoxFailedMessage);
    }
  }

  /// 현재 프로필 이미지 사용 처리
  Future<void> _handleUseCurrentProfileImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final String profileImageUrl = userProvider.profileImage;

    if (profileImageUrl.isEmpty) {
      _handleShowErrorMessage(_noProfileImageMessage);
      Navigator.pop(context);
      return;
    }

    final AlbumWidget? widget = await widgetProvider.addProfileWidget(profileImageUrl);

    if (widget != null) {
      _handleShowSuccessMessage(_profileImageAddedMessage);
    } else {
      _handleShowErrorMessage(_profileImageFailedMessage);
    }

    Navigator.pop(context);
  }

  /// 새 이미지 업로드 및 프로필 설정 처리
  Future<void> _handlePickAndUploadProfileImage(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    final String? userId = await ApiService.getUserId();

    if (userId == null || userId.isEmpty) {
      _handleShowErrorMessage(_userIdNotFoundMessage);
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      _handleShowInfoMessage(_uploadingImageMessage);

      final File imageFile = File(image.path);
      final Map<String, dynamic> result = await UserApi.updateProfileImage(
        userId: userId,
        profileImage: imageFile,
      );

      if (result.containsKey(_errorKey)) {
        _handleShowErrorMessage(_profileImageUpdateFailedMessage + result[_errorKey]);
        return;
      }

      await userProvider.loadUserInfo(forceRefresh: true);

      final String profileImageUrl = userProvider.profileImage;
      if (profileImageUrl.isNotEmpty) {
        await widgetProvider.updateAllProfileWidgetsImageUrl(profileImageUrl);

        final AlbumWidget? widget = await widgetProvider.addProfileWidget(profileImageUrl);

        if (widget != null) {
          _handleShowSuccessMessage(_profileImageUpdatedAndAddedMessage);
        } else {
          _handleShowErrorMessage(_profileImageUpdatedButFailedMessage);
        }
      } else {
        _handleShowErrorMessage(_profileImageUpdatedButEmptyMessage);
      }
    } catch (e) {
      _handleShowErrorMessage(_imageUploadErrorMessage + e.toString());
    }
  }

  /// 위젯 편집 메뉴 표시
  void _handleShowWidgetEditMenu(BuildContext context, AlbumWidget widget) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(_containerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalTitle(_editWidgetTitle),
              const SizedBox(height: _titleSpacing),
              ..._buildWidgetSpecificOptions(widget),
              _buildDeleteOption(widget),
            ],
          ),
        );
      },
    );
  }

  /// 프로필 위젯 모양 변경 처리
  void _handleProfileWidgetShapeChange(AlbumWidget widget) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final String currentShape = widget.extraData[_shapeKey] ?? _circleShape;
    final String newShape = currentShape == _circleShape ? _rectangleShape : _circleShape;

    widgetProvider.updateProfileWidgetShape(widget.id, newShape);
    Navigator.pop(context);
  }

  /// 체크리스트 항목 추가 다이얼로그 표시
  void _handleShowAddChecklistItemDialog(AlbumWidget widget) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_addItemTitle),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: _newItemHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(_cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(_addText),
          ),
        ],
      ),
    );
  }

  /// 위젯 삭제 처리
  void _handleDeleteWidget(AlbumWidget widget) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    widgetProvider.deleteWidget(widget.id);
    Navigator.pop(context);
  }

  /// 위젯 선택 처리
  void _handleWidgetTap(AlbumWidget widget) {
    // 위젯 선택 상태 변경 로직
  }

  /// 성공 메시지 표시
  void _handleShowSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 에러 메시지 표시
  void _handleShowErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 정보 메시지 표시
  void _handleShowInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 모달 제목 위젯 생성
  Widget _buildModalTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: _titleFontSize, fontWeight: FontWeight.bold),
    );
  }

  /// 캔버스 설정 위젯 생성
  Widget _buildCanvasSettings() {
    return Consumer<CanvasProvider>(
      builder: (context, canvasProvider, child) {
        return CanvasSettings(
          initialColor: canvasProvider.canvasColor,
          initialPattern: canvasProvider.canvasPattern,
          onSettingsChanged: (color, pattern) {
            canvasProvider.updateCanvasSettings(color, pattern);
          },
        );
      },
    );
  }

  /// 프로필 이미지 추가 옵션 위젯 생성
  Widget _buildAddProfileImageOption() {
    return ListTile(
      leading: const Icon(Icons.account_circle),
      title: const Text(_addProfileImageText),
      onTap: () {
        Navigator.pop(context);
        _showProfileImageOptionsBottomSheet();
      },
    );
  }

  /// 체크리스트 추가 옵션 위젯 생성
  Widget _buildAddChecklistOption() {
    return ListTile(
      leading: const Icon(Icons.checklist),
      title: const Text(_addChecklistText),
      onTap: () {
        Navigator.pop(context);
        _handleAddChecklistWidget();
      },
    );
  }

  /// 텍스트박스 추가 옵션 위젯 생성
  Widget _buildAddTextBoxOption() {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text(_addTextBoxText),
      onTap: () {
        Navigator.pop(context);
        _handleAddTextBoxWidget();
      },
    );
  }

  /// 프로필 이미지 옵션 바텀시트 표시
  void _showProfileImageOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(_containerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalTitle(_profileImageOptionsTitle),
              const SizedBox(height: _sectionSpacing),
              _buildUseCurrentProfileOption(),
              _buildUploadNewImageOption(),
            ],
          ),
        );
      },
    );
  }

  /// 현재 프로필 이미지 사용 옵션 위젯 생성
  Widget _buildUseCurrentProfileOption() {
    return ListTile(
      leading: const Icon(Icons.photo_library),
      title: const Text(_useCurrentProfileText),
      onTap: _handleUseCurrentProfileImage,
    );
  }

  /// 새 이미지 업로드 옵션 위젯 생성
  Widget _buildUploadNewImageOption() {
    return ListTile(
      leading: const Icon(Icons.add_photo_alternate),
      title: const Text(_uploadNewImageText),
      onTap: () async {
        await _handlePickAndUploadProfileImage(context);
        Navigator.pop(context);
      },
    );
  }

  /// 위젯별 특정 옵션들 생성
  List<Widget> _buildWidgetSpecificOptions(AlbumWidget widget) {
    if (widget.type == _profileImageType) {
      return [
        ListTile(
          leading: const Icon(Icons.format_shapes),
          title: const Text(_changeShapeText),
          onTap: () => _handleProfileWidgetShapeChange(widget),
        ),
      ];
    } else if (widget.type == _checklistType) {
      return [
        ListTile(
          leading: const Icon(Icons.add_task),
          title: const Text(_addNewItemText),
          onTap: () {
            Navigator.pop(context);
            _handleShowAddChecklistItemDialog(widget);
          },
        ),
      ];
    }
    return [];
  }

  /// 삭제 옵션 위젯 생성
  Widget _buildDeleteOption(AlbumWidget widget) {
    return ListTile(
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text(_deleteWidgetText, style: TextStyle(color: Colors.red)),
      onTap: () => _handleDeleteWidget(widget),
    );
  }

  /// 위젯 렌더링
  Widget _buildWidget(AlbumWidget widget) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    Widget content;
    if (widget.type == _profileImageType) {
      content = ProfileImageWidget(widget: widget);
    } else if (widget.type == _checklistType) {
      content = ChecklistWidget(widget: widget);
    } else if (widget.type == _textBoxType) {
      content = TextBoxWidget(widget: widget, isSelected: true);
    } else {
      content = Container(
        color: Colors.grey,
        child: Center(child: Text(widget.type)),
      );
    }

    return DraggableWidget(
      key: ValueKey(widget.id),
      initialX: widget.x,
      initialY: widget.y,
      width: widget.width,
      height: widget.height,
      widgetType: widget.type,
      resizeMode: widget.type == _textBoxType ? ResizeMode.free : ResizeMode.aspectRatio,
      onPositionChanged: (x, y) {
        widgetProvider.updateWidgetPosition(widget.id, x, y);
      },
      onSizeChanged: (width, height) {
        widgetProvider.updateWidgetSize(widget.id, width, height);
      },
      onTap: () => _handleWidgetTap(widget),
      onLongPress: () => _handleShowWidgetEditMenu(context, widget),
      child: content,
    );
  }

  /// 캔버스 배경 데코레이션 생성
  BoxDecoration _buildCanvasDecoration(CanvasProvider canvasProvider) {
    return BoxDecoration(
      color: canvasProvider.canvasColor,
      image: canvasProvider.canvasPattern == _nonePattern
          ? null
          : DecorationImage(
        image: AssetImage(
          _patternsAssetPath + canvasProvider.canvasPattern + _patternFileExtension,
        ),
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

    return Consumer2<CanvasProvider, WidgetProvider>(
      builder: (context, canvasProvider, widgetProvider, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _buildCanvasDecoration(canvasProvider),
          child: Stack(
            children: [
              ...widgetProvider.widgets.map((widget) => _buildWidget(widget)),
            ],
          ),
        );
      },
    );
  }
}