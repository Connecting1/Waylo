// lib/screen/setting/app_version_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';

import '../../providers/theme_provider.dart';

class AppVersionScreen extends StatelessWidget {
  const AppVersionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: Text(
          "App Info",
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 로고
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/logos/logo3.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 앱 이름
            Text(
              "Waylo",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            // 앱 버전
            Text(
              "Version 1.0.0",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 30),

            // 앱 설명
            Text(
              "Waylo - Share Your Journey",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "A social platform to share and document your travel experiences. Mark your journey moments on the map anywhere in the world, connect with friends, and customize your memories like an album.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 30),

            // 개발자 정보
            _buildInfoSection(
              title: "Developer",
              content: "Jihun Cho",
              icon: Icons.code,
            ),

            // 연락처 정보
            _buildInfoSection(
              title: "Contact",
              content: "jihuntomars@gmail.com",
              icon: Icons.email,
            ),

            // 저작권 정보
            _buildInfoSection(
              title: "Copyright",
              content: "© ${DateTime.now().year} Jihun Cho. All rights reserved.",
              icon: Icons.copyright,
            ),

            SizedBox(height: 30),

            // 감사의 글
            Text(
              "Special Thanks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Flutter Team, Mapbox, and all the open-source contributors that made this app possible.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 40),

            Text(
              "Made with in Korea",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}