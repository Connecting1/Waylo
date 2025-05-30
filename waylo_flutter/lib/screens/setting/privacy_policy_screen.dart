// lib/screen/setting/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: const Text(
          "Privacy Policy",
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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildLastUpdatedText(),
          _buildSection(
              title: "Introduction",
              content: "Waylo (\"we\", \"our\", or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the \"App\").\n\nPlease read this Privacy Policy carefully. By accessing or using the App, you agree to the collection, use, and disclosure of your information as described in this Privacy Policy. If you do not agree with our policies and practices, please do not use our App."
          ),

          _buildSection(
              title: "Information We Collect",
              content: "We collect several types of information from and about users of our App, including:\n\n• Personal Information: When you register for an account, we collect your email address, username, and password.\n\n• Profile Information: We collect information you provide in your user profile, such as your name, profile picture, gender, and date of birth.\n\n• Location Information: With your permission, we collect precise location information from your device to display your posts on the map and to enable location-based features.\n\n• Content Information: We collect the content you create, upload, or share on the App, including photos, posts, comments, and other communications.\n\n• Usage Information: We collect information about how you use the App, such as the features you use, the actions you take, and the time, frequency, and duration of your activities."
          ),

          _buildSection(
              title: "How We Use Your Information",
              content: "We use the information we collect about you for various purposes, including to:\n\n• Provide, maintain, and improve our App and services\n• Process your account registration and personalize your experience\n• Fulfill the purposes for which you provided the information\n• Display your posts on the map based on their location\n• Connect you with friends and show their posts on the map\n• Monitor and analyze usage and trends to improve your experience with the App\n• Respond to your comments, questions, and requests\n• Send you technical notices, updates, security alerts, and support messages\n• Detect, prevent, and address technical issues\n• Protect the safety, integrity, and security of our App, databases, and business"
          ),

          _buildSection(
              title: "How We Share Your Information",
              content: "We may share your information in the following situations:\n\n• With Other Users: Your profile information, posts, and comments are shared with other users according to your privacy settings.\n\n• With Service Providers: We may share your information with third-party vendors, service providers, contractors, or agents who perform services for us or on our behalf.\n\n• For Legal Purposes: We may disclose your information to comply with applicable laws and regulations, to respond to a subpoena, search warrant, or other lawful request for information, or to otherwise protect our rights.\n\n• With Your Consent: We may share your information with your consent or at your direction.\n\n• Business Transfers: We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company."
          ),

          _buildSection(
              title: "Data Storage and Security",
              content: "We use commercially reasonable safeguards to help protect your personal information from unauthorized access, use, or disclosure. However, we cannot guarantee the absolute security of your information. Your information may be stored and processed on servers in various locations, including outside your country of residence."
          ),

          _buildSection(
              title: "Your Choices",
              content: "You can access and update certain information about you from within the App. You can also:\n\n• Update your account information in the Settings\n• Change your privacy settings to control who can see your posts\n• Choose whether to share your location with the App\n• Delete specific posts or comments\n• Delete your account, which will permanently delete your profile, posts, comments, and other content"
          ),

          _buildSection(
              title: "Children's Privacy",
              content: "Our App is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe we have collected information from your child under 13, please contact us so that we can delete the information."
          ),

          _buildSection(
              title: "Changes to This Privacy Policy",
              content: "We may update our Privacy Policy from time to time. If we make material changes, we will notify you by posting the new Privacy Policy on this page and, where appropriate, by sending you a notification. You are advised to review this Privacy Policy periodically for any changes."
          ),

          _buildSection(
              title: "Contact Us",
              content: "If you have any questions or concerns about this Privacy Policy, please contact us at:\n\nprivacy@waylo.app"
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Text(
        "Last Updated: May 12, 2025",
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16),
        Divider(height: 8, thickness: 1),
      ],
    );
  }
}