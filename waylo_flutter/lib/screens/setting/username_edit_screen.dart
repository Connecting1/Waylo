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
  // 텍스트 상수들
  static const String _appBarTitle = "Change Username";
  static const String _saveButtonText = "Save";
  static const String _usernameLabel = "Username";
  static const String _usernameHint = "Enter your username";
  static const String _usernameRules = "• 1-30 characters\n"
      "• Can contain letters, numbers, '.' and '_'\n"
      "• Cannot start or end with '.' or '_'\n"
      "• No consecutive '..' (double periods)";

  // 성공 메시지 상수들
  static const String _usernameUpdatedMessage = "Username updated successfully";

  // 에러 메시지 상수들
  static const String _usernameEmptyMessage = "Username cannot be empty";
  static const String _invalidUsernameFormatMessage = "Invalid username format";
  static const String _userIdTokenNotFoundError = "User ID or Auth Token not found";
  static const String _usernameUpdateFailedError = "Failed to update username: ";
  static const String _usernameUpdateFailedMessage = "Failed to update username: ";

  // API 관련 상수들
  static const String _apiUsersPath = "/api/users/";
  static const String _apiUpdatePath = "/update/";
  static const String _authorizationHeader = "Authorization";
  static const String _tokenPrefix = "Token ";

  // 필드명 상수들
  static const String _usernameField = "username";
  static const String _emailField = "email";
  static const String _genderField = "gender";
  static const String _phoneNumberField = "phone_number";
  static const String _accountVisibilityField = "account_visibility";

  // HTTP 상태 코드 상수들
  static const int _httpSuccessMin = 200;
  static const int _httpSuccessMax = 300;

  // 유효성 검사 상수들
  static const String _usernameRegexPattern = r"^[a-zA-Z0-9](?!.*\.\.)(?!.*__)[a-zA-Z0-9._]{0,28}[a-zA-Z0-9]$";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _usernameLabelFontSize = 16;
  static const double _usernameRulesFontSize = 12;

  // 크기 상수들
  static const double _screenPadding = 16;
  static const double _topSpacing = 20;
  static const double _labelFieldSpacing = 8;
  static const double _fieldRulesSpacing = 8;
  static const double _textFieldBorderRadius = 8;
  static const double _textFieldHorizontalPadding = 16;
  static const double _textFieldVerticalPadding = 12;
  static const double _progressIndicatorPadding = 10;
  static const double _progressIndicatorStrokeWidth = 2;

  // 색상 투명도 상수들
  static const double _disabledSaveButtonOpacity = 0.5;

  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _handleLoadCurrentUsername();
  }

  @override
  void dispose() {
    _usernameController.removeListener(_handleCheckForChanges);
    _usernameController.dispose();
    super.dispose();
  }

  /// 현재 사용자명 로드 처리
  void _handleLoadCurrentUsername() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _usernameController.text = userProvider.username;
    _usernameController.addListener(_handleCheckForChanges);
  }

  /// 변경사항 확인 처리
  void _handleCheckForChanges() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool usernameChanged = _usernameController.text != userProvider.username;

    setState(() {
      _hasChanges = usernameChanged;
    });
  }

  /// 사용자명 저장 처리
  Future<void> _handleSaveUsername() async {
    if (!_hasChanges) return;

    final String newUsername = _usernameController.text.trim();

    if (!_validateUsername(newUsername)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? userId = await ApiService.getUserId();
      String? authToken = await ApiService.getAuthToken();

      if (userId == null || authToken == null) {
        throw Exception(_userIdTokenNotFoundError);
      }

      var uri = Uri.parse('${ApiService.baseUrl}$_apiUsersPath$userId$_apiUpdatePath');
      var request = http.MultipartRequest('PATCH', uri);

      request.headers[_authorizationHeader] = '$_tokenPrefix$authToken';

      request.fields[_usernameField] = newUsername;
      request.fields[_emailField] = userProvider.email;
      request.fields[_genderField] = userProvider.gender;
      request.fields[_phoneNumberField] = userProvider.phoneNumber ?? '';
      request.fields[_accountVisibilityField] = userProvider.accountVisibility;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= _httpSuccessMin && response.statusCode < _httpSuccessMax) {
        await userProvider.loadUserInfo(forceRefresh: true);

        if (mounted) {
          _handleShowSuccessMessage(_usernameUpdatedMessage);
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('$_usernameUpdateFailedError${response.body}');
      }
    } catch (e) {
      if (mounted) {
        _handleShowErrorMessage("$_usernameUpdateFailedMessage${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 사용자명 유효성 검사
  bool _validateUsername(String username) {
    if (username.isEmpty) {
      _handleShowErrorMessage(_usernameEmptyMessage);
      return false;
    }

    final RegExp usernameRegex = RegExp(_usernameRegexPattern);
    if (!usernameRegex.hasMatch(username)) {
      _handleShowErrorMessage(_invalidUsernameFormatMessage);
      return false;
    }

    return true;
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
      actions: [_buildAppBarAction()],
    );
  }

  /// AppBar 액션 구성
  Widget _buildAppBarAction() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(_progressIndicatorPadding),
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: _progressIndicatorStrokeWidth,
        ),
      );
    }

    return TextButton(
      onPressed: _hasChanges ? _handleSaveUsername : null,
      child: Text(
        _saveButtonText,
        style: TextStyle(
          color: _hasChanges ? Colors.white : Colors.white.withOpacity(_disabledSaveButtonOpacity),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 사용자명 라벨 구성
  Widget _buildUsernameLabel() {
    return Text(
      _usernameLabel,
      style: TextStyle(
        fontSize: _usernameLabelFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  /// 사용자명 입력 필드 구성
  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        hintText: _usernameHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_textFieldBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _textFieldHorizontalPadding,
          vertical: _textFieldVerticalPadding,
        ),
      ),
      enabled: !_isLoading,
    );
  }

  /// 사용자명 규칙 텍스트 구성
  Widget _buildUsernameRules() {
    return Text(
      _usernameRules,
      style: TextStyle(
        fontSize: _usernameRulesFontSize,
        color: Colors.grey[600],
      ),
    );
  }

  /// 메인 콘텐츠 구성
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _topSpacing),
          _buildUsernameLabel(),
          const SizedBox(height: _labelFieldSpacing),
          _buildUsernameField(),
          const SizedBox(height: _fieldRulesSpacing),
          _buildUsernameRules(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildMainContent(),
    );
  }
}