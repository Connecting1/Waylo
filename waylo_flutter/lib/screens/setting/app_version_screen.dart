import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import '../../providers/theme_provider.dart';

class AppVersionScreen extends StatelessWidget {
  const AppVersionScreen({Key? key}) : super(key: key);

  // 텍스트 상수들
  static const String _appBarTitle = "App Info";
  static const String _appName = "Waylo";
  static const String _appVersion = "Version 1.0.0";
  static const String _appSlogan = "Waylo - Share Your Journey";
  static const String _appDescription = "A social platform to share and document your travel experiences. Mark your journey moments on the map anywhere in the world, connect with friends, and customize your memories like an album.";
  static const String _developerTitle = "Developer";
  static const String _developerName = "Jihun Cho";
  static const String _contactTitle = "Contact";
  static const String _contactEmail = "jihuntomars@gmail.com";
  static const String _copyrightTitle = "Copyright";
  static const String _specialThanksTitle = "Special Thanks";
  static const String _specialThanksContent = "Flutter Team, Mapbox, and all the open-source contributors that made this app possible.";
  static const String _madeInKoreaText = "Made with in Korea";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _appNameFontSize = 24;
  static const double _appVersionFontSize = 16;
  static const double _appSloganFontSize = 18;
  static const double _appDescriptionFontSize = 14;
  static const double _sectionTitleFontSize = 18;
  static const double _infoTitleFontSize = 14;
  static const double _infoContentFontSize = 16;
  static const double _madeInKoreaFontSize = 14;

  // 크기 상수들
  static const double _screenPadding = 20;
  static const double _logoSize = 200;
  static const double _sectionSpacing = 30;
  static const double _titleContentSpacing = 10;
  static const double _infoSectionVerticalPadding = 8;
  static const double _infoIconSpacing = 12;
  static const double _infoIconSize = 20;
  static const double _bottomSpacing = 40;
  static const double _finalSpacing = 20;

  // 파일 경로 상수들
  static const String _logoAssetPath = "assets/logos/logo3.png";

  /// 년도 문자열 생성
  String _getCopyrightText() {
    return "© ${DateTime.now().year} $_developerName. All rights reserved.";
  }

  /// AppBar 구성
  AppBar _buildAppBar(BuildContext context) {
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

  /// 앱 로고 위젯 구성
  Widget _buildAppLogo() {
    return Container(
      width: _logoSize,
      height: _logoSize,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_logoAssetPath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 앱 이름 위젯 구성
  Widget _buildAppName() {
    return Text(
      _appName,
      style: TextStyle(
        fontSize: _appNameFontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  /// 앱 버전 위젯 구성
  Widget _buildAppVersion() {
    return Text(
      _appVersion,
      style: TextStyle(
        fontSize: _appVersionFontSize,
        color: Colors.grey[600],
      ),
    );
  }

  /// 앱 슬로건 위젯 구성
  Widget _buildAppSlogan() {
    return const Text(
      _appSlogan,
      style: TextStyle(
        fontSize: _appSloganFontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 앱 설명 위젯 구성
  Widget _buildAppDescription() {
    return Text(
      _appDescription,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: _appDescriptionFontSize,
        color: Colors.grey[700],
      ),
    );
  }

  /// 개발자 정보 섹션 구성
  Widget _buildDeveloperSection() {
    return _buildInfoSection(
      title: _developerTitle,
      content: _developerName,
      icon: Icons.code,
    );
  }

  /// 연락처 정보 섹션 구성
  Widget _buildContactSection() {
    return _buildInfoSection(
      title: _contactTitle,
      content: _contactEmail,
      icon: Icons.email,
    );
  }

  /// 저작권 정보 섹션 구성
  Widget _buildCopyrightSection() {
    return _buildInfoSection(
      title: _copyrightTitle,
      content: _getCopyrightText(),
      icon: Icons.copyright,
    );
  }

  /// 감사의 글 제목 위젯 구성
  Widget _buildSpecialThanksTitle() {
    return const Text(
      _specialThanksTitle,
      style: TextStyle(
        fontSize: _sectionTitleFontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 감사의 글 내용 위젯 구성
  Widget _buildSpecialThanksContent() {
    return Text(
      _specialThanksContent,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: _appDescriptionFontSize,
        color: Colors.grey[700],
      ),
    );
  }

  /// 한국 제작 표시 위젯 구성
  Widget _buildMadeInKorea() {
    return Text(
      _madeInKoreaText,
      style: TextStyle(
        fontSize: _madeInKoreaFontSize,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// 정보 섹션 위젯 구성
  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _infoSectionVerticalPadding),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: _infoIconSize),
          const SizedBox(width: _infoIconSpacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: _infoTitleFontSize,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                content,
                style: const TextStyle(
                  fontSize: _infoContentFontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAppLogo(),
            _buildAppName(),
            _buildAppVersion(),
            const SizedBox(height: _sectionSpacing),
            _buildAppSlogan(),
            const SizedBox(height: _titleContentSpacing),
            _buildAppDescription(),
            const SizedBox(height: _sectionSpacing),
            _buildDeveloperSection(),
            _buildContactSection(),
            _buildCopyrightSection(),
            const SizedBox(height: _sectionSpacing),
            _buildSpecialThanksTitle(),
            const SizedBox(height: _titleContentSpacing),
            _buildSpecialThanksContent(),
            const SizedBox(height: _bottomSpacing),
            _buildMadeInKorea(),
            const SizedBox(height: _finalSpacing),
          ],
        ),
      ),
    );
  }
}