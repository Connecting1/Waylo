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
  // 텍스트 상수들
  static const String _appBarTitle = "Location Sharing Settings";
  static const String _locationSharingInfoTitle = "Location Sharing Information";
  static const String _locationSharingInfoContent = "When you enable location sharing, your current location will be displayed on the map. This information is not visible to other users and can only be seen on your map.";
  static const String _enableLocationSharingTitle = "Enable Location Sharing";
  static const String _locationPermissionEnabledSubtitle = "Show my current location on my map";
  static const String _locationPermissionRequiredSubtitle = "Location permission is required";
  static const String _realTimeUpdatesTitle = "Real-time Location Updates";
  static const String _realTimeTrackingTitle = "Real-time Location Tracking";
  static const String _realTimeTrackingSubtitle = "Updates your location on the map in real-time.";
  static const String _updateIntervalLabel = "Location update interval: ";
  static const String _minutesUnit = " minutes";
  static const String _noteTitle = "Note";
  static const String _batteryUsageNote = "Enabling location sharing may increase battery usage. Disabling real-time tracking can help save battery.";
  static const String _openLocationSettingsText = "Open Location Settings";
  static const String _locationPermissionDialogTitle = "Location Permission Required";
  static const String _locationPermissionDialogContent = "Location access permission is required to share your location. Please allow it in your settings.";
  static const String _cancelText = "Cancel";
  static const String _openSettingsText = "Open Settings";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _infoTitleFontSize = 18;
  static const double _infoContentFontSize = 14;
  static const double _realTimeUpdatesTitleFontSize = 16;
  static const double _updateIntervalFontSize = 14;

  // 크기 상수들
  static const double _screenPadding = 16;
  static const double _cardInnerPadding = 16;
  static const double _sectionSpacing = 20;
  static const double _titleContentSpacing = 8;
  static const double _sliderSpacing = 8;
  static const double _iconSpacing = 12;
  static const double _noteContentSpacing = 4;
  static const double _buttonVerticalPadding = 16;
  static const double _buttonHorizontalPadding = 20;
  static const double _buttonInternalVerticalPadding = 12;
  static const double _buttonBorderRadius = 10;

  // 슬라이더 관련 상수들
  static const double _sliderMinValue = 1;
  static const double _sliderMaxValue = 30;
  static const int _sliderDivisions = 29;
  static const int _defaultUpdateInterval = 1;

  // 패딩 상수들
  static const EdgeInsets _realTimeUpdatesPadding = EdgeInsets.fromLTRB(16, 16, 16, 8);
  static const EdgeInsets _updateIntervalPadding = EdgeInsets.all(16);
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(vertical: 16);

  bool _isRealTimeTracking = false;
  int _updateInterval = _defaultUpdateInterval;

  @override
  void initState() {
    super.initState();
    _handleLoadSettings();
  }

  /// 설정 로드 처리
  Future<void> _handleLoadSettings() async {
    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);

    setState(() {
      _isRealTimeTracking = locationProvider.isRealtimeTracking;
      _updateInterval = locationProvider.updateInterval;
    });
  }

  /// 실시간 추적 토글 처리
  Future<void> _handleToggleRealtimeTracking(bool value) async {
    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
    await locationProvider.setRealtimeTracking(value);

    setState(() {
      _isRealTimeTracking = value;
    });
  }

  /// 업데이트 간격 설정 처리
  Future<void> _handleSetUpdateInterval(double value) async {
    final int minutes = value.round();
    final locationProvider = Provider.of<LocationSettingsProvider>(context, listen: false);
    await locationProvider.setUpdateInterval(minutes);

    setState(() {
      _updateInterval = minutes;
    });
  }

  /// 위치 권한 다이얼로그 표시 처리
  void _handleShowLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_locationPermissionDialogTitle),
        content: const Text(_locationPermissionDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(_cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<LocationSettingsProvider>(context, listen: false).openLocationSettings();
            },
            child: const Text(_openSettingsText),
          ),
        ],
      ),
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
    );
  }

  /// 위치 공유 정보 카드 구성
  Widget _buildLocationSharingInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardInnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              _locationSharingInfoTitle,
              style: TextStyle(
                fontSize: _infoTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _titleContentSpacing),
            Text(
              _locationSharingInfoContent,
              style: TextStyle(
                fontSize: _infoContentFontSize,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 위치 공유 토글 카드 구성
  Widget _buildLocationSharingToggleCard(LocationSettingsProvider locationProvider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              _enableLocationSharingTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              locationProvider.isLocationPermissionGranted
                  ? _locationPermissionEnabledSubtitle
                  : _locationPermissionRequiredSubtitle,
            ),
            value: locationProvider.isLocationSharingEnabled,
            onChanged: (value) async {
              await locationProvider.setLocationSharingEnabled(value);
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
    );
  }

  /// 실시간 위치 업데이트 카드 구성
  Widget _buildRealTimeLocationCard(LocationSettingsProvider locationProvider) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: _realTimeUpdatesPadding,
            child: Text(
              _realTimeUpdatesTitle,
              style: TextStyle(
                fontSize: _realTimeUpdatesTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text(_realTimeTrackingTitle),
            subtitle: const Text(_realTimeTrackingSubtitle),
            value: _isRealTimeTracking,
            onChanged: _handleToggleRealtimeTracking,
            secondary: Icon(
              Icons.gps_fixed,
              color: _isRealTimeTracking ? AppColors.primary : Colors.grey,
            ),
          ),
          if (!_isRealTimeTracking) _buildUpdateIntervalSection(),
        ],
      ),
    );
  }

  /// 업데이트 간격 섹션 구성
  Widget _buildUpdateIntervalSection() {
    return Padding(
      padding: _updateIntervalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$_updateIntervalLabel$_updateInterval$_minutesUnit",
            style: const TextStyle(
              fontSize: _updateIntervalFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _sliderSpacing),
          Slider(
            value: _updateInterval.toDouble(),
            min: _sliderMinValue,
            max: _sliderMaxValue,
            divisions: _sliderDivisions,
            label: "$_updateInterval$_minutesUnit",
            onChanged: _handleSetUpdateInterval,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// 배터리 사용량 노트 카드 구성
  Widget _buildBatteryUsageNoteCard() {
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
            const SizedBox(width: _iconSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _noteTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: _noteContentSpacing),
                  Text(
                    _batteryUsageNote,
                    style: TextStyle(
                      fontSize: _infoContentFontSize,
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

  /// 위치 설정 열기 버튼 구성
  Widget _buildOpenLocationSettingsButton(LocationSettingsProvider locationProvider) {
    return Padding(
      padding: _buttonPadding,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.settings),
        label: const Text(_openLocationSettingsText),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: _buttonInternalVerticalPadding,
            horizontal: _buttonHorizontalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonBorderRadius),
          ),
        ),
        onPressed: () {
          locationProvider.openLocationSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<LocationSettingsProvider>(
        builder: (context, locationProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(_screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationSharingInfoCard(),
                const SizedBox(height: _sectionSpacing),
                _buildLocationSharingToggleCard(locationProvider),
                const SizedBox(height: _sectionSpacing),
                if (locationProvider.isLocationSharingEnabled)
                  _buildRealTimeLocationCard(locationProvider),
                const SizedBox(height: _sectionSpacing),
                _buildBatteryUsageNoteCard(),
                const SizedBox(height: _sectionSpacing),
                if (!locationProvider.isLocationPermissionGranted)
                  _buildOpenLocationSettingsButton(locationProvider),
              ],
            ),
          );
        },
      ),
    );
  }
}