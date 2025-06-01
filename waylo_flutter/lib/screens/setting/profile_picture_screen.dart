import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import '../../providers/theme_provider.dart';

class ProfilePictureScreen extends StatefulWidget {
  const ProfilePictureScreen({Key? key}) : super(key: key);

  @override
  _ProfilePictureScreenState createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  // 텍스트 상수들
  static const String _appBarTitle = "Change Profile Picture";
  static const String _cropProfilePictureTitle = "Crop Profile Picture";
  static const String _tapToChangeText = "Tap to change profile picture";

  // 성공 메시지 상수들
  static const String _uploadingImageMessage = "Uploading image...";
  static const String _profileImageUpdatedMessage = "Profile image updated successfully";

  // 에러 메시지 상수들
  static const String _userIdNotFoundMessage = "User ID not found. Please login again.";
  static const String _updateFailedMessage = "Failed to update profile image: ";
  static const String _profileImageUpdatedButEmptyMessage = "Profile image updated but URL is empty";
  static const String _uploadErrorMessage = "Error uploading image: ";

  // API 키 상수들
  static const String _errorKey = "error";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _instructionTextFontSize = 16;

  // 크기 상수들
  static const double _profileImageRadius = 80;
  static const double _profileIconSize = 80;
  static const double _cameraIconSize = 24;
  static const double _cameraIconPadding = 8;
  static const double _instructionTextSpacing = 30;
  static const double _loadingIndicatorSpacing = 20;

  // 이미지 크롭 비율 상수들
  static const double _cropAspectRatioX = 1;
  static const double _cropAspectRatioY = 1;

  bool _isLoading = false;

  /// 이미지 선택 및 크롭 처리
  Future<File?> _handlePickAndCropImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null) return null;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      aspectRatio: const CropAspectRatio(ratioX: _cropAspectRatioX, ratioY: _cropAspectRatioY),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: _cropProfilePictureTitle,
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: _cropProfilePictureTitle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  /// 프로필 이미지 선택, 크롭 및 업로드 처리
  Future<void> _handlePickAndUploadProfileImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    String? userId = await ApiService.getUserId();

    if (userId == null || userId.isEmpty) {
      _handleShowErrorMessage(_userIdNotFoundMessage);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      File? croppedImage = await _handlePickAndCropImage();

      if (croppedImage == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _handleShowInfoMessage(_uploadingImageMessage);

      Map<String, dynamic> result = await UserApi.updateProfileImage(
        userId: userId,
        profileImage: croppedImage,
      );

      if (result.containsKey(_errorKey)) {
        _handleShowErrorMessage("$_updateFailedMessage${result[_errorKey]}");
        return;
      }

      await userProvider.loadUserInfo(forceRefresh: true);

      String profileImageUrl = userProvider.profileImage;
      if (profileImageUrl.isNotEmpty) {
        await widgetProvider.updateAllProfileWidgetsImageUrl(profileImageUrl);

        _handleShowSuccessMessage(_profileImageUpdatedMessage);
        Navigator.pop(context, true);
      } else {
        _handleShowErrorMessage(_profileImageUpdatedButEmptyMessage);
      }
    } catch (e) {
      _handleShowErrorMessage("$_uploadErrorMessage$e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 성공 메시지 표시 처리
  void _handleShowSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 에러 메시지 표시 처리
  void _handleShowErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 정보 메시지 표시 처리
  void _handleShowInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: const Text(
        _appBarTitle,
        style: TextStyle(
          fontSize: _appBarTitleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// 프로필 이미지 위젯 구성
  Widget _buildProfileImage(UserProvider userProvider) {
    return GestureDetector(
      onTap: _isLoading ? null : _handlePickAndUploadProfileImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: _profileImageRadius,
            backgroundImage: userProvider.profileImage.isNotEmpty
                ? NetworkImage(userProvider.profileImage)
                : null,
            backgroundColor: Colors.grey[300],
            child: userProvider.profileImage.isEmpty
                ? Icon(Icons.person, size: _profileIconSize, color: Colors.grey[600])
                : null,
          ),
          if (!_isLoading) _buildCameraIcon(),
        ],
      ),
    );
  }

  /// 카메라 아이콘 위젯 구성
  Widget _buildCameraIcon() {
    return Container(
      padding: const EdgeInsets.all(_cameraIconPadding),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.camera_alt,
        color: Colors.white,
        size: _cameraIconSize,
      ),
    );
  }

  /// 안내 텍스트 위젯 구성
  Widget _buildInstructionText() {
    return Text(
      _tapToChangeText,
      style: TextStyle(
        fontSize: _instructionTextFontSize,
        color: Colors.grey[600],
      ),
    );
  }

  /// 로딩 인디케이터 위젯 구성
  Widget _buildLoadingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.only(top: _loadingIndicatorSpacing),
      child: CircularProgressIndicator(),
    );
  }

  /// 메인 콘텐츠 구성
  Widget _buildMainContent(UserProvider userProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileImage(userProvider),
          const SizedBox(height: _instructionTextSpacing),
          _buildInstructionText(),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildMainContent(userProvider),
    );
  }
}