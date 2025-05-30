// lib/screen/setting/location_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/location_settings_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import '../../providers/theme_provider.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({Key? key}) : super(key: key);

  @override
  _LocationSettingsScreenState createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _isRealTimeTracking = false;
  int _updateInterval = 1; // 업데이트 간격 (분 단위)

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);

    setState(() {
      _isRealTimeTracking = locationProvider.isRealtimeTracking;
      _updateInterval = locationProvider.updateInterval;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? AppColors.darkSurface
            : AppColors.primary,
        title: Text(
          "Location Sharing Settings",
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
      body: Consumer<LocationSettingsProvider>(
        builder: (context, locationProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 설명 카드
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Location Sharing Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "When you enable location sharing, your current location will be displayed on the map. This information is not visible to other users and can only be seen on your map.",
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

                // 위치 공유 토글
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          "Enable Location Sharing",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          locationProvider.isLocationPermissionGranted
                              ? "Show my current location on my map"
                              : "Location permission is required",
                        ),
                        value: locationProvider.isLocationSharingEnabled,
                        onChanged: (value) async {
                          await locationProvider.setLocationSharingEnabled(value);
                          // setState 호출 없음 - notifyListeners()가 UI 업데이트 처리
                        },
                        secondary: Icon(
                          Icons.location_on,
                          color: locationProvider.isLocationSharingEnabled
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 실시간 추적 설정 (위치 공유가 활성화된 경우에만)
                if (locationProvider.isLocationSharingEnabled)
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            "Real-time Location Updates",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SwitchListTile(
                          title: Text("Real-time Location Tracking"),
                          subtitle: Text(
                              "Updates your location on the map in real-time."
                          ),
                          value: _isRealTimeTracking,
                          onChanged: (value) async {
                            final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
                            await locationProvider.setRealtimeTracking(value);

                            setState(() {
                              _isRealTimeTracking = value;
                            });
                          },
                          secondary: Icon(
                            Icons.gps_fixed,
                            color: _isRealTimeTracking ? AppColors.primary : Colors.grey,
                          ),
                        ),

                        // 위치 업데이트 간격 (실시간이 아닌 경우)
                        if (!_isRealTimeTracking)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Location update interval: $_updateInterval minutes",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Slider(
                                  value: _updateInterval.toDouble(),
                                  min: 1,
                                  max: 30,
                                  divisions: 29,
                                  label: "$_updateInterval minutes",
                                  onChanged: (value) async {
                                    final int minutes = value.round();
                                    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
                                    await locationProvider.setUpdateInterval(minutes);

                                    setState(() {
                                      _updateInterval = minutes;
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                SizedBox(height: 20),

                // 위치 공유에 관한 추가 정보
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
                                "Note",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Enabling location sharing may increase battery usage. Disabling real-time tracking can help save battery.",
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

                // 위치 권한 관련 버튼
                if (!locationProvider.isLocationPermissionGranted)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.settings),
                      label: Text("Open Location Settings"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        locationProvider.openLocationSettings();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Permission Required"),
        content: Text("Location access permission is required to share your location. Please allow it in your settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<LocationSettingsProvider>(context, listen: false).openLocationSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _toggleRealtimeTracking(bool value) async {
    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
    await locationProvider.setRealtimeTracking(value);

    setState(() {
      _isRealTimeTracking = value;
    });
  }

  void _setUpdateInterval(double value) async {
    final int minutes = value.round();
    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
    await locationProvider.setUpdateInterval(minutes);

    setState(() {
      _updateInterval = minutes;
    });
  }


}