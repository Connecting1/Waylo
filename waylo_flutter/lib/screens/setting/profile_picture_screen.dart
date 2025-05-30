// lib/screen/setting/profile_picture_screen.dart
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
  bool _isLoading = false;

  // 이미지 선택 및 크롭 (정사각형으로 고정)
  Future<File?> _pickAndCropImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null) return null;

    // ImageCropper로 정사각형 크롭
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // 1:1 정사각형 비율
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true, // 비율 고정
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true, // 비율 고정
          resetAspectRatioEnabled: false, // 비율 리셋 불가
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  // 프로필 이미지 선택, 크롭 및 업로드
  Future<void> _pickAndUploadProfileImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    String? userId = await ApiService.getUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ID not found. Please login again.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 이미지 선택 및 크롭
      File? croppedImage = await _pickAndCropImage();

      if (croppedImage == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploading image...")),
      );

      // 프로필 이미지 업데이트
      Map<String, dynamic> result = await UserApi.updateProfileImage(
        userId: userId,
        profileImage: croppedImage,
      );

      if (result.containsKey("error")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile image: ${result["error"]}")),
        );
        return;
      }

      // 사용자 정보 다시 로드
      await userProvider.loadUserInfo(forceRefresh: true);

      // 프로필 이미지 위젯 업데이트
      String profileImageUrl = userProvider.profileImage;
      if (profileImageUrl.isNotEmpty) {
        // 기존 프로필 위젯의 이미지 URL 모두 업데이트
        await widgetProvider.updateAllProfileWidgetsImageUrl(profileImageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile image updated successfully")),
        );

        // 성공 후 이전 화면으로 돌아가기
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile image updated but URL is empty")),
        );
      }
    } catch (e) {
      print("[ERROR] 이미지 선택/업로드 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: Text(
          "Change Profile Picture",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 현재 프로필 이미지 표시
            GestureDetector(
              onTap: _isLoading ? null : _pickAndUploadProfileImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: userProvider.profileImage.isNotEmpty
                        ? NetworkImage(userProvider.profileImage)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: userProvider.profileImage.isEmpty
                        ? Icon(Icons.person, size: 80, color: Colors.grey[600])
                        : null,
                  ),
                  if (!_isLoading)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            Text(
              "Tap to change profile picture",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            if (_isLoading)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}