// lib/screen/setting/account_privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:http/http.dart' as http;

import '../../providers/theme_provider.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({Key? key}) : super(key: key);

  @override
  _AccountPrivacyScreenState createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  String _accountVisibility = 'public';
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _accountVisibility = userProvider.accountVisibility;
    });
  }

  void _onVisibilityChanged(String? value) {
    if (value == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _accountVisibility = value;
      _hasChanges = value != userProvider.accountVisibility;
    });
  }

  Future<void> _savePrivacySettings() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? userId = await ApiService.getUserId();
      String? authToken = await ApiService.getAuthToken();

      if (userId == null || authToken == null) {
        throw Exception("User ID or Auth Token not found");
      }

      // MultipartRequest 사용
      var uri = Uri.parse('${ApiService.baseUrl}/api/users/$userId/update/');
      var request = http.MultipartRequest('PATCH', uri);

      // 헤더 설정
      request.headers['Authorization'] = 'Token $authToken';

      // 필드 추가
      request.fields['username'] = userProvider.username;
      request.fields['email'] = userProvider.email;
      request.fields['gender'] = userProvider.gender;
      request.fields['phone_number'] = userProvider.phoneNumber ?? '';
      request.fields['account_visibility'] = _accountVisibility;

      // 요청 전송
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 프로바이더의 사용자 데이터 새로고침
        await userProvider.loadUserInfo(forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Privacy settings updated successfully")),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to update privacy settings: ${response.body}');
      }
    } catch (e) {
      print("[ERROR] Privacy settings update failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update privacy settings: ${e.toString()}")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: Text(
          "Account Privacy",
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
        actions: [
          _isLoading
              ? Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : TextButton(
            onPressed: _hasChanges ? _savePrivacySettings : null,
            child: Text(
              "Save",
              style: TextStyle(
                color: _hasChanges ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 텍스트
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account Privacy Settings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Choose who can see your profile and feeds.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 공개/비공개 옵션
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(
                      "Public Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Anyone can see your profile, album, and feeds. Your account will appear in search results.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: "public",
                    groupValue: _accountVisibility,
                    onChanged: _isLoading ? null : _onVisibilityChanged,
                    activeColor: AppColors.primary,
                  ),
                  Divider(height: 1),
                  RadioListTile<String>(
                    title: Text(
                      "Private Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Only your approved friends can see your profile, album, and feeds. Your account won't appear in search results to others.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: "private",
                    groupValue: _accountVisibility,
                    onChanged: _isLoading ? null : _onVisibilityChanged,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 현재 상태 표시
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _accountVisibility == 'public'
                                ? "Your account is public. Anyone can see your content."
                                : "Your account is private. Only approved friends can see your content.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 추가 정보
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Important Notes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: "Changing to private will hide your content from non-friends immediately.",
                    ),
                    SizedBox(height: 8),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: "Existing friends will still be able to see your content.",
                    ),
                    SizedBox(height: 8),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: "Individual feeds can be set to private regardless of account setting.",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.green,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}