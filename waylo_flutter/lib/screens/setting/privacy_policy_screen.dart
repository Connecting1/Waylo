// lib/screen/setting/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  // 텍스트 상수들
  static const String _appBarTitle = "Privacy Policy";
  static const String _lastUpdatedText = "Last Updated: May 12, 2025";

  // 섹션 제목 상수들
  static const String _introductionTitle = "Introduction";
  static const String _informationCollectTitle = "Information We Collect";
  static const String _howWeUseTitle = "How We Use Your Information";
  static const String _howWeShareTitle = "How We Share Your Information";
  static const String _dataStorageTitle = "Data Storage and Security";
  static const String _yourChoicesTitle = "Your Choices";
  static const String _childrensPrivacyTitle = "Children's Privacy";
  static const String _changesTitle = "Changes to This Privacy Policy";
  static const String _contactUsTitle = "Contact Us";

  // 섹션 내용 상수들
  static const String _introductionContent = "Waylo (\"we\", \"our\", or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the \"App\").\n\nPlease read this Privacy Policy carefully. By accessing or using the App, you agree to the collection, use, and disclosure of your information as described in this Privacy Policy. If you do not agree with our policies and practices, please do not use our App.";

  static const String _informationCollectContent = "We collect several types of information from and about users of our App, including:\n\n• Personal Information: When you register for an account, we collect your email address, username, and password.\n\n• Profile Information: We collect information you provide in your user profile, such as your name, profile picture, gender, and date of birth.\n\n• Location Information: With your permission, we collect precise location information from your device to display your posts on the map and to enable location-based features.\n\n• Content Information: We collect the content you create, upload, or share on the App, including photos, posts, comments, and other communications.\n\n• Usage Information: We collect information about how you use the App, such as the features you use, the actions you take, and the time, frequency, and duration of your activities.";

  static const String _howWeUseContent = "We use the information we collect about you for various purposes, including to:\n\n• Provide, maintain, and improve our App and services\n• Process your account registration and personalize your experience\n• Fulfill the purposes for which you provided the information\n• Display your posts on the map based on their location\n• Connect you with friends and show their posts on the map\n• Monitor and analyze usage and trends to improve your experience with the App\n• Respond to your comments, questions, and requests\n• Send you technical notices, updates, security alerts, and support messages\n• Detect, prevent, and address technical issues\n• Protect the safety, integrity, and security of our App, databases, and business";

  static const String _howWeShareContent = "We may share your information in the following situations:\n\n• With Other Users: Your profile information, posts, and comments are shared with other users according to your privacy settings.\n\n• With Service Providers: We may share your information with third-party vendors, service providers, contractors, or agents who perform services for us or on our behalf.\n\n• For Legal Purposes: We may disclose your information to comply with applicable laws and regulations, to respond to a subpoena, search warrant, or other lawful request for information, or to otherwise protect our rights.\n\n• With Your Consent: We may share your information with your consent or at your direction.\n\n• Business Transfers: We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.";

  static const String _dataStorageContent = "We use commercially reasonable safeguards to help protect your personal information from unauthorized access, use, or disclosure. However, we cannot guarantee the absolute security of your information. Your information may be stored and processed on servers in various locations, including outside your country of residence.";

  static const String _yourChoicesContent = "You can access and update certain information about you from within the App. You can also:\n\n• Update your account information in the Settings\n• Change your privacy settings to control who can see your posts\n• Choose whether to share your location with the App\n• Delete specific posts or comments\n• Delete your account, which will permanently delete your profile, posts, comments, and other content";

  static const String _childrensPrivacyContent = "Our App is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe we have collected information from your child under 13, please contact us so that we can delete the information.";

  static const String _changesContent = "We may update our Privacy Policy from time to time. If we make material changes, we will notify you by posting the new Privacy Policy on this page and, where appropriate, by sending you a notification. You are advised to review this Privacy Policy periodically for any changes.";

  static const String _contactUsContent = "If you have any questions or concerns about this Privacy Policy, please contact us at:\n\nprivacy@waylo.app";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _lastUpdatedFontSize = 14;
  static const double _sectionTitleFontSize = 18;
  static const double _sectionContentFontSize = 15;

  // 크기 상수들
  static const double _screenPadding = 16;
  static const double _lastUpdatedBottomPadding = 20;
  static const double _sectionTitleVerticalPadding = 12;
  static const double _sectionContentSpacing = 16;
  static const double _dividerHeight = 8;
  static const double _dividerThickness = 1;
  static const double _contentLineHeight = 1.5;
  static const double _finalSpacing = 40;

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

  /// 마지막 업데이트 텍스트 구성
  Widget _buildLastUpdatedText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _lastUpdatedBottomPadding),
      child: Text(
        _lastUpdatedText,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: _lastUpdatedFontSize,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Introduction 섹션 구성
  Widget _buildIntroductionSection() {
    return _buildSection(
      title: _introductionTitle,
      content: _introductionContent,
    );
  }

  /// Information We Collect 섹션 구성
  Widget _buildInformationCollectSection() {
    return _buildSection(
      title: _informationCollectTitle,
      content: _informationCollectContent,
    );
  }

  /// How We Use Your Information 섹션 구성
  Widget _buildHowWeUseSection() {
    return _buildSection(
      title: _howWeUseTitle,
      content: _howWeUseContent,
    );
  }

  /// How We Share Your Information 섹션 구성
  Widget _buildHowWeShareSection() {
    return _buildSection(
      title: _howWeShareTitle,
      content: _howWeShareContent,
    );
  }

  /// Data Storage and Security 섹션 구성
  Widget _buildDataStorageSection() {
    return _buildSection(
      title: _dataStorageTitle,
      content: _dataStorageContent,
    );
  }

  /// Your Choices 섹션 구성
  Widget _buildYourChoicesSection() {
    return _buildSection(
      title: _yourChoicesTitle,
      content: _yourChoicesContent,
    );
  }

  /// Children's Privacy 섹션 구성
  Widget _buildChildrensPrivacySection() {
    return _buildSection(
      title: _childrensPrivacyTitle,
      content: _childrensPrivacyContent,
    );
  }

  /// Changes to This Privacy Policy 섹션 구성
  Widget _buildChangesSection() {
    return _buildSection(
      title: _changesTitle,
      content: _changesContent,
    );
  }

  /// Contact Us 섹션 구성
  Widget _buildContactUsSection() {
    return _buildSection(
      title: _contactUsTitle,
      content: _contactUsContent,
    );
  }

  /// 섹션 위젯 구성
  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: _sectionTitleVerticalPadding),
          child: Text(
            title,
            style: TextStyle(
              fontSize: _sectionTitleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Text(
              content,
              style: TextStyle(
                fontSize: _sectionContentFontSize,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                height: _contentLineHeight,
              ),
            );
          },
        ),
        const SizedBox(height: _sectionContentSpacing),
        const Divider(height: _dividerHeight, thickness: _dividerThickness),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.all(_screenPadding),
        children: [
          _buildLastUpdatedText(),
          _buildIntroductionSection(),
          _buildInformationCollectSection(),
          _buildHowWeUseSection(),
          _buildHowWeShareSection(),
          _buildDataStorageSection(),
          _buildYourChoicesSection(),
          _buildChildrensPrivacySection(),
          _buildChangesSection(),
          _buildContactUsSection(),
          const SizedBox(height: _finalSpacing),
        ],
      ),
    );
  }
}