// lib/screen/setting/help_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: const Text(
          "Help Center",
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
          _buildHelpSection(
            title: "Getting Started",
            items: [
              _HelpItem(
                  title: "How to create an account",
                  content: "To create an account, open the app and click on 'Sign up for free'. Follow the steps to enter your email, password, and personal information to complete the signup process."
              ),
              _HelpItem(
                  title: "How to log in",
                  content: "If you already have an account, simply tap 'Log in' on the welcome screen and enter your email and password to access your account."
              ),
              _HelpItem(
                  title: "How to set up your profile",
                  content: "After creating your account, you can personalize your profile by going to the Settings screen and tapping on 'Change Profile Picture' or 'Change Username'."
              ),
            ],
          ),

          _buildHelpSection(
            title: "Using the Map",
            items: [
              _HelpItem(
                  title: "How to navigate the map",
                  content: "Use pinch gestures to zoom in and out, and drag to move around the map. The app will show your posts and your friends' posts on the map based on their location."
              ),
              _HelpItem(
                  title: "How to add a post to the map",
                  content: "Tap the '+' button while on the Map tab to add a new post. Choose an image from your gallery, and the app will detect the location or allow you to specify one."
              ),
              _HelpItem(
                  title: "Understanding map icons",
                  content: "On the map, country flags represent grouped posts in a specific country when zoomed out. Individual post markers appear when zoomed in closer."
              ),
            ],
          ),

          _buildHelpSection(
            title: "Album Features",
            items: [
              _HelpItem(
                  title: "How to customize your album",
                  content: "In the Album tab, tap the '+' button and select 'Change Canvas Background' to modify the color and pattern of your album background."
              ),
              _HelpItem(
                  title: "Adding widgets to your album",
                  content: "Tap the '+' button in the Album tab and select the type of widget you want to add, such as Profile Image, Checklist, or Text Box."
              ),
              _HelpItem(
                  title: "Editing and moving widgets",
                  content: "Tap and hold a widget to edit its properties. To move a widget, simply drag it to the desired position on your album."
              ),
            ],
          ),

          _buildHelpSection(
            title: "Friends and Chat",
            items: [
              _HelpItem(
                  title: "How to find friends",
                  content: "Go to the Search tab and type a username to search for friends. You can send friend requests to users you want to connect with."
              ),
              _HelpItem(
                  title: "Managing friend requests",
                  content: "You can view and manage your friend requests in the Friends tab. Accept or decline requests from other users."
              ),
              _HelpItem(
                  title: "Starting a chat",
                  content: "To start a conversation with a friend, go to their profile or find them in your friends list and tap the chat icon."
              ),
            ],
          ),

          _buildHelpSection(
            title: "Account Settings",
            items: [
              _HelpItem(
                  title: "Privacy settings",
                  content: "Control who can see your content by updating your account privacy settings in the Settings tab."
              ),
              _HelpItem(
                  title: "Notification preferences",
                  content: "Manage what notifications you receive in the Settings tab under Notification Settings."
              ),
              _HelpItem(
                  title: "How to log out",
                  content: "To log out of your account, go to the Settings tab and scroll to the bottom to find the 'Logout' button."
              ),
            ],
          ),

          _buildHelpSection(
            title: "Troubleshooting",
            items: [
              _HelpItem(
                  title: "App crashes or freezes",
                  content: "If the app crashes or freezes, try closing and reopening it. If the issue persists, try clearing the app cache or reinstalling the app."
              ),
              _HelpItem(
                  title: "Login issues",
                  content: "If you're having trouble logging in, make sure your internet connection is stable. You can also try resetting your password."
              ),
              _HelpItem(
                  title: "Contact support",
                  content: "For any other issues or questions, please contact our support team at support@waylo.app."
              ),
            ],
          ),

          SizedBox(height: 30),

          Center(
            child: Text(
              "App Version: 1.0.0",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required List<_HelpItem> items,
  }) {
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
        ...items.map((item) => _buildHelpItem(item)),
        Divider(height: 32, thickness: 1),
      ],
    );
  }

  Widget _buildHelpItem(_HelpItem item) {
    return ExpansionTile(
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _HelpItem {
  final String title;
  final String content;

  _HelpItem({
    required this.title,
    required this.content,
  });
}