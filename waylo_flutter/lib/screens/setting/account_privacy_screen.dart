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
  // 텍스트 상수들
  static const String _appBarTitle = "Account Privacy";
  static const String _saveButtonText = "Save";
  static const String _accountPrivacySettingsTitle = "Account Privacy Settings";
  static const String _accountPrivacySettingsSubtitle = "Choose who can see your profile and feeds.";
  static const String _publicAccountTitle = "Public Account";
  static const String _publicAccountSubtitle = "Anyone can see your profile, album, and feeds. Your account will appear in search results.";
  static const String _privateAccountTitle = "Private Account";
  static const String _privateAccountSubtitle = "Only your approved friends can see your profile, album, and feeds. Your account won't appear in search results to others.";
  static const String _currentStatusTitle = "Current Status";
  static const String _publicStatusMessage = "Your account is public. Anyone can see your content.";
  static const String _privateStatusMessage = "Your account is private. Only approved friends can see your content.";
  static const String _importantNotesTitle = "Important Notes";
  static const String _privateChangeNote = "Changing to private will hide your content from non-friends immediately.";
  static const String _existingFriendsNote = "Existing friends will still be able to see your content.";
  static const String _individualFeedsNote = "Individual feeds can be set to private regardless of account setting.";

  // 성공 메시지 상수들
  static const String _settingsUpdatedSuccessMessage = "Privacy settings updated successfully";

  // 에러 메시지 상수들
  static const String _userIdTokenNotFoundError = "User ID or Auth Token not found";
  static const String _settingsUpdateFailedError = "Failed to update privacy settings: ";
  static const String _settingsUpdateFailedMessage = "Failed to update privacy settings: ";

  // 계정 가시성 타입 상수들
  static const String _publicVisibility = "public";
  static const String _privateVisibility = "private";

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

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _settingsTitleFontSize = 18;
  static const double _settingsSubtitleFontSize = 14;
  static const double _statusSubtitleFontSize = 14;
  static const double _importantNotesTitleFontSize = 16;
  static const double _infoItemFontSize = 14;

  // 크기 상수들
  static const double _screenPadding = 16;
  static const double _cardInnerPadding = 16;
  static const double _sectionSpacing = 20;
  static const double _titleSubtitleSpacing = 8;
  static const double _statusIconSpacing = 12;
  static const double _statusContentSpacing = 4;
  static const double _importantNotesSpacing = 12;
  static const double _infoItemSpacing = 8;
  static const double _infoItemIconSpacing = 8;
  static const double _progressIndicatorPadding = 10;
  static const double _progressIndicatorStrokeWidth = 2;
  static const double _infoItemIconSize = 20;
  static const double _dividerHeight = 1;

  // 색상 투명도 상수들
  static const double _disabledSaveButtonOpacity = 0.5;

  String _accountVisibility = _publicVisibility;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _handleLoadCurrentSettings();
  }

  /// 현재 설정 로드 처리
  void _handleLoadCurrentSettings() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _accountVisibility = userProvider.accountVisibility;
    });
  }

  /// 가시성 변경 처리
  void _handleVisibilityChanged(String? value) {
    if (value == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _accountVisibility = value;
      _hasChanges = value != userProvider.accountVisibility;
    });
  }

  /// 개인정보 설정 저장 처리
  Future<void> _handleSavePrivacySettings() async {
    if (!_hasChanges) return;

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

      request.fields[_usernameField] = userProvider.username;
      request.fields[_emailField] = userProvider.email;
      request.fields[_genderField] = userProvider.gender;
      request.fields[_phoneNumberField] = userProvider.phoneNumber ?? '';
      request.fields[_accountVisibilityField] = _accountVisibility;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= _httpSuccessMin && response.statusCode < _httpSuccessMax) {
        await userProvider.loadUserInfo(forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_settingsUpdatedSuccessMessage)),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('$_settingsUpdateFailedError${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_settingsUpdateFailedMessage${e.toString()}")),
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

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: Text(
        _appBarTitle,
        style: const TextStyle(
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
      onPressed: _hasChanges ? _handleSavePrivacySettings : null,
      child: Text(
        _saveButtonText,
        style: TextStyle(
          color: _hasChanges ? Colors.white : Colors.white.withOpacity(_disabledSaveButtonOpacity),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 설정 설명 카드 구성
  Widget _buildSettingsDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardInnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _accountPrivacySettingsTitle,
              style: TextStyle(
                fontSize: _settingsTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _titleSubtitleSpacing),
            Text(
              _accountPrivacySettingsSubtitle,
              style: TextStyle(
                fontSize: _settingsSubtitleFontSize,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개인정보 옵션 카드 구성
  Widget _buildPrivacyOptionsCard() {
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text(
              _publicAccountTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _publicAccountSubtitle,
              style: TextStyle(
                fontSize: _settingsSubtitleFontSize,
                color: Colors.grey[600],
              ),
            ),
            value: _publicVisibility,
            groupValue: _accountVisibility,
            onChanged: _isLoading ? null : _handleVisibilityChanged,
            activeColor: AppColors.primary,
          ),
          const Divider(height: _dividerHeight),
          RadioListTile<String>(
            title: const Text(
              _privateAccountTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _privateAccountSubtitle,
              style: TextStyle(
                fontSize: _settingsSubtitleFontSize,
                color: Colors.grey[600],
              ),
            ),
            value: _privateVisibility,
            groupValue: _accountVisibility,
            onChanged: _isLoading ? null : _handleVisibilityChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// 현재 상태 카드 구성
  Widget _buildCurrentStatusCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(_cardInnerPadding),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
            ),
            const SizedBox(width: _statusIconSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStatusTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: _statusContentSpacing),
                  Text(
                    _accountVisibility == _publicVisibility
                        ? _publicStatusMessage
                        : _privateStatusMessage,
                    style: TextStyle(
                      fontSize: _statusSubtitleFontSize,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 중요 정보 카드 구성
  Widget _buildImportantNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardInnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _importantNotesTitle,
              style: TextStyle(
                fontSize: _importantNotesTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _importantNotesSpacing),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: _privateChangeNote,
            ),
            const SizedBox(height: _infoItemSpacing),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: _existingFriendsNote,
            ),
            const SizedBox(height: _infoItemSpacing),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: _individualFeedsNote,
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 아이템 위젯 구성
  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: _infoItemIconSize,
          color: Colors.green,
        ),
        const SizedBox(width: _infoItemIconSpacing),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _infoItemFontSize,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsDescriptionCard(),
            const SizedBox(height: _sectionSpacing),
            _buildPrivacyOptionsCard(),
            const SizedBox(height: _sectionSpacing),
            _buildCurrentStatusCard(),
            const SizedBox(height: _sectionSpacing),
            _buildImportantNotesCard(),
          ],
        ),
      ),
    );
  }
}