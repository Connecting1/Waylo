// lib/screens/setting/theme_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../styles/app_styles.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text(
              "Theme Settings",
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
                          "App Appearance",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Choose how Waylo looks on your device. You can use the system setting or choose a specific theme.",
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

                // 시스템 테마 옵션
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          "Use Device Settings",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Automatically switch between light and dark themes based on your device settings",
                          style: TextStyle(fontSize: 14),
                        ),
                        value: themeProvider.useSystemTheme,
                        onChanged: (value) {
                          themeProvider.setUseSystemTheme(value);
                        },
                        secondary: Icon(
                          Icons.phone_android,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 수동 테마 선택 옵션
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          "Manual Theme Selection",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      RadioListTile<bool>(
                        title: Text("Light Mode"),
                        subtitle: Text("Light backgrounds with dark text"),
                        value: false,
                        groupValue: themeProvider.isDarkMode,
                        onChanged: themeProvider.useSystemTheme
                            ? null
                            : (value) {
                          if (value != null && themeProvider.isDarkMode) {
                            themeProvider.toggleTheme();
                          }
                        },
                        secondary: Icon(
                          Icons.wb_sunny,
                          color: themeProvider.useSystemTheme
                              ? Colors.grey
                              : Colors.orange,
                        ),
                      ),
                      RadioListTile<bool>(
                        title: Text("Dark Mode"),
                        subtitle: Text("Dark backgrounds with light text"),
                        value: true,
                        groupValue: themeProvider.isDarkMode,
                        onChanged: themeProvider.useSystemTheme
                            ? null
                            : (value) {
                          if (value != null && !themeProvider.isDarkMode) {
                            themeProvider.toggleTheme();
                          }
                        },
                        secondary: Icon(
                          Icons.nights_stay,
                          color: themeProvider.useSystemTheme
                              ? Colors.grey
                              : Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 현재 상태 정보
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
                                themeProvider.useSystemTheme
                                    ? "Using system theme (${themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'})"
                                    : themeProvider.isDarkMode
                                    ? "Using Dark Mode"
                                    : "Using Light Mode",
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

                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}