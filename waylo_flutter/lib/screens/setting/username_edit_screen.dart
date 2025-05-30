// lib/screens/setting/username_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/services/api/user_api.dart';
import 'package:waylo_flutter/services/api/api_service.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../providers/theme_provider.dart';

class UsernameEditScreen extends StatefulWidget {
  const UsernameEditScreen({Key? key}) : super(key: key);

  @override
  _UsernameEditScreenState createState() => _UsernameEditScreenState();
}

class _UsernameEditScreenState extends State<UsernameEditScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  void _loadCurrentUsername() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _usernameController.text = userProvider.username;

    // 변경사항 감지를 위한 리스너 추가
    _usernameController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool usernameChanged = _usernameController.text != userProvider.username;

    setState(() {
      _hasChanges = usernameChanged;
    });
  }

  // MultipartRequest를 사용하는 수정된 버전
  Future<void> _saveUsername() async {
    if (!_hasChanges) return;

    // 유효성 검사
    final String newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username cannot be empty")),
      );
      return;
    }

    // 사용자명 형식 체크
    final RegExp usernameRegex = RegExp(
      r"^[a-zA-Z0-9](?!.*\.\.)(?!.*__)[a-zA-Z0-9._]{0,28}[a-zA-Z0-9]$",
    );

    if (!usernameRegex.hasMatch(newUsername)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid username format")),
      );
      return;
    }

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
      request.fields['username'] = newUsername;
      request.fields['email'] = userProvider.email;
      request.fields['gender'] = userProvider.gender;
      request.fields['phone_number'] = userProvider.phoneNumber ?? '';
      request.fields['account_visibility'] = userProvider.accountVisibility;

      // 요청 전송
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 프로바이더의 사용자 데이터 새로고침
        await userProvider.loadUserInfo(forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Username updated successfully")),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to update username: ${response.body}');
      }
    } catch (e) {
      print("[ERROR] Username update failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update username: ${e.toString()}")),
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
  void dispose() {
    _usernameController.removeListener(_checkForChanges);
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: Text(
          "Change Username",
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
            onPressed: _hasChanges ? _saveUsername : null,
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
            SizedBox(height: 20),
            Text(
              "Username",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Enter your username",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              enabled: !_isLoading,
            ),
            SizedBox(height: 8),
            Text(
              "• 1-30 characters\n"
                  "• Can contain letters, numbers, '.' and '_'\n"
                  "• Cannot start or end with '.' or '_'\n"
                  "• No consecutive '..' (double periods)",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}