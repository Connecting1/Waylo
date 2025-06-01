import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/screens/map/map_location_picker.dart';
import '../../providers/theme_provider.dart';

class EditFeedScreen extends StatefulWidget {
  final Feed feed;

  const EditFeedScreen({Key? key, required this.feed}) : super(key: key);

  @override
  _EditFeedScreenState createState() => _EditFeedScreenState();
}

class _EditFeedScreenState extends State<EditFeedScreen> {
  // 텍스트 상수들
  static const String _appBarTitle = 'Edit Feed';
  static const String _saveButtonText = 'Save';
  static const String _deleteTooltip = 'Delete Feed';
  static const String _descriptionLabel = 'Description';
  static const String _photoDateTitle = 'Photo Date';
  static const String _locationTitle = 'Location';
  static const String _visibilityTitle = 'Visibility';
  static const String _editCoordinatesTitle = 'Edit Coordinates';
  static const String _latitudeLabel = 'Latitude (-90 to 90)';
  static const String _longitudeLabel = 'Longitude (-180 to 180)';
  static const String _cancelButtonText = 'Cancel';
  static const String _saveCoordinatesButtonText = 'Save';
  static const String _photoDateOptionsTitle = 'Photo Date Options';
  static const String _setDateText = 'Set Date';
  static const String _noDateText = 'No Date';
  static const String _noDateSelectedText = 'No date selected';
  static const String _unknownLocationText = 'Unknown location';
  static const String _editButtonText = 'Edit';
  static const String _onMapButtonText = 'On Map';
  static const String _publicVisibility = 'public';
  static const String _privateVisibility = 'private';
  static const String _publicDisplayText = 'Public';
  static const String _privateDisplayText = 'Private';
  static const String _deleteFeedTitle = 'Delete feed';
  static const String _deleteFeedContent = 'Are you sure you want to delete this feed? This action cannot be undone.';
  static const String _deleteButtonText = 'Delete';

  // 에러 메시지 상수들
  static const String _locationDataMissingError = 'Location data or access token is missing';
  static const String _latitudeRangeError = 'Latitude must be between -90 and 90';
  static const String _longitudeRangeError = 'Longitude must be between -180 and 180';
  static const String _invalidCoordinateError = 'Invalid coordinate format';
  static const String _selectLocationError = 'Please select a location';
  static const String _updateFailedPrefix = 'Update failed: ';
  static const String _deleteFailedPrefix = 'Delete failed: ';
  static const String _errorOccurredPrefix = 'An error occurred: ';

  // 성공 메시지 상수들
  static const String _updateSuccessMessage = 'Feed updated successfully';
  static const String _deleteSuccessMessage = 'Feed has been deleted';

  // API 관련 상수들
  static const String _mapboxGeocodeUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places/';
  static const String _geocodeUrlSuffix = '.json?access_token=';
  static const String _geocodeTypeCountry = '&types=country';
  static const String _featuresKey = 'features';
  static const String _textKey = 'text';
  static const String _propertiesKey = 'properties';
  static const String _shortCodeKey = 'short_code';
  static const String _locationNameKey = 'location_name';
  static const String _errorKey = 'error';
  static const String _accessTokenEnvKey = 'ACCESS_TOKEN';

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 20;
  static const double _sectionTitleFontSize = 16;
  static const double _locationTextFontSize = 16;
  static const double _coordinateTextFontSize = 12;
  static const double _buttonIconSize = 18;

  // 크기 상수들
  static const double _scrollViewPadding = 16.0;
  static const double _sectionSpacing = 20;
  static const double _subsectionSpacing = 8;
  static const double _coordinateSpacing = 4;
  static const double _imagePreviewHeight = 200;
  static const double _imageBorderRadius = 12;
  static const double _containerBorderRadius = 4;
  static const double _containerVerticalPadding = 12;
  static const double _containerHorizontalPadding = 16;
  static const double _buttonVerticalPadding = 8;
  static const double _buttonHorizontalPadding = 12;
  static const double _buttonSpacing = 8;
  static const double _loadingIndicatorSize = 20;
  static const double _loadingIndicatorStroke = 2;
  static const double _fieldSpacing = 10;

  // 폼 필드 상수들
  static const int _descriptionMaxLines = 3;

  // 좌표 관련 상수들
  static const int _coordinateDecimalPlaces = 6;
  static const double _minLatitude = -90;
  static const double _maxLatitude = 90;
  static const double _minLongitude = -180;
  static const double _maxLongitude = 180;
  static const int _longitudeMaxLength = 9;

  // 날짜 관련 상수들
  static const int _minYear = 2000;
  static const String _datePadCharacter = '0';
  static const int _datePadLength = 2;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  String _visibility = _publicVisibility;
  bool _isLoading = false;
  DateTime? _selectedDate;

  double? _latitude;
  double? _longitude;
  String? _locationName;
  String? _countryCode;
  String? _accessToken;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.feed.description);
    _visibility = widget.feed.visibility;
    _selectedDate = widget.feed.photoTakenAt;

    _latitude = widget.feed.latitude;
    _longitude = widget.feed.longitude;
    _locationName = widget.feed.extraData[_locationNameKey];
    _countryCode = widget.feed.countryCode;
    _accessToken = const String.fromEnvironment(_accessTokenEnvKey);
  }

  /// Mapbox API를 통해 좌표에서 위치명 가져오기
  Future<String?> _getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "$_mapboxGeocodeUrl$longitude,$latitude$_geocodeUrlSuffix$_accessToken$_geocodeTypeCountry";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data[_featuresKey].isNotEmpty) {
          return data[_featuresKey][0][_textKey];
        }
      }
    } catch (e) {
      // 위치명 검색 오류는 조용히 처리
    }
    return null;
  }

  /// Mapbox API를 통해 좌표에서 국가 코드 가져오기
  Future<String?> _getCountryCodeFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "$_mapboxGeocodeUrl$longitude,$latitude$_geocodeUrlSuffix$_accessToken$_geocodeTypeCountry";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data[_featuresKey].isNotEmpty) {
          return data[_featuresKey][0][_propertiesKey][_shortCodeKey]?.toUpperCase();
        }
      }
    } catch (e) {
      // 국가 코드 검색 오류는 조용히 처리
    }
    return null;
  }

  /// 지도에서 위치 편집
  void _editLocationOnMap() async {
    if (_latitude == null || _longitude == null || _accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_locationDataMissingError)),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude!,
          initialLongitude: _longitude!,
          accessToken: _accessToken!,
          onLocationSelected: (lat, lng, locationName) async {
            setState(() {
              _latitude = lat;
              _longitude = lng;
              _isLoadingLocation = true;
            });

            await _updateLocationInfo(lat, lng);
          },
        ),
      ),
    );
  }

  /// 좌표 직접 편집 다이얼로그
  void _editCoordinates() {
    final latController = TextEditingController(
      text: _latitude?.toStringAsFixed(_coordinateDecimalPlaces) ?? '',
    );
    final lngController = TextEditingController(
      text: _longitude?.toStringAsFixed(_coordinateDecimalPlaces) ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(_editCoordinatesTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: _latitudeLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              const SizedBox(height: _fieldSpacing),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: _longitudeLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(_cancelButtonText),
            ),
            TextButton(
              onPressed: () => _saveCoordinates(latController.text, lngController.text),
              child: const Text(_saveCoordinatesButtonText),
            ),
          ],
        );
      },
    );
  }

  /// 입력된 좌표 유효성 검사 및 저장
  Future<void> _saveCoordinates(String latText, String lngText) async {
    try {
      double lat = double.parse(latText);
      double lng = double.parse(lngText);

      if (lat < _minLatitude || lat > _maxLatitude) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_latitudeRangeError)),
        );
        return;
      }
      if (lng < _minLongitude || lng > _maxLongitude) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_longitudeRangeError)),
        );
        return;
      }

      Navigator.pop(context);

      setState(() {
        _latitude = lat;
        _longitude = lng;
        _isLoadingLocation = true;
      });

      await _updateLocationInfo(lat, lng);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_invalidCoordinateError)),
      );
    }
  }

  /// 위치 정보 업데이트
  Future<void> _updateLocationInfo(double lat, double lng) async {
    String? name = await _getLocationNameFromCoordinates(lat, lng);
    String? countryCode = await _getCountryCodeFromCoordinates(lat, lng);

    setState(() {
      _locationName = name;
      _countryCode = countryCode;
      _isLoadingLocation = false;
    });
  }

  /// 사진 촬영 날짜 선택 다이얼로그
  void _selectDate(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(_photoDateOptionsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text(_setDateText),
                onTap: () => _showDatePicker(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text(_noDateText),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(_cancelButtonText),
            ),
          ],
        );
      },
    );
  }

  /// 날짜 선택기 표시
  void _showDatePicker() async {
    Navigator.pop(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(_minYear),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  /// 피드 업데이트
  Future<void> _updateFeed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_selectLocationError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double formattedLatitude = double.parse(_latitude!.toStringAsFixed(_coordinateDecimalPlaces));
      double formattedLongitude = _formatLongitude(_longitude!);

      String? photoTakenAtStr = _selectedDate?.toIso8601String();

      Map<String, dynamic> response = await FeedApi.updateFeed(
        feedId: widget.feed.id,
        description: _descriptionController.text,
        visibility: _visibility,
        latitude: formattedLatitude,
        longitude: formattedLongitude,
        countryCode: _countryCode,
        photoTakenAt: photoTakenAtStr,
        extraData: {
          _locationNameKey: _locationName,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey(_errorKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_updateFailedPrefix${response[_errorKey]}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_updateSuccessMessage)),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_errorOccurredPrefix$e')),
      );
    }
  }

  /// 경도 포맷팅 - 9자리 제한
  double _formatLongitude(double longitude) {
    String longStr = longitude.toString();
    if (longStr.replaceAll('.', '').length > _longitudeMaxLength) {
      int integerLength = longStr.split('.')[0].length;
      int decimalPlaces = _longitudeMaxLength - integerLength;
      if (decimalPlaces > 0) {
        return double.parse(longitude.toStringAsFixed(decimalPlaces));
      } else {
        return double.parse(longitude.toStringAsFixed(0));
      }
    } else {
      return longitude;
    }
  }

  /// 피드 삭제
  Future<void> _deleteFeed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_deleteFeedTitle),
        content: const Text(_deleteFeedContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(_cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(_deleteButtonText, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response = await FeedApi.deleteFeed(widget.feed.id);

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey(_errorKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_deleteFailedPrefix${response[_errorKey]}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_deleteSuccessMessage)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_errorOccurredPrefix$e')),
      );
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(_datePadLength, _datePadCharacter)}/${date.month.toString().padLeft(_datePadLength, _datePadCharacter)}/${date.year} ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_scrollViewPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),
              const SizedBox(height: _sectionSpacing),
              _buildDescriptionField(),
              const SizedBox(height: _sectionSpacing),
              _buildDateSection(),
              const SizedBox(height: _sectionSpacing),
              _buildLocationSection(),
              const SizedBox(height: _sectionSpacing),
              _buildVisibilitySection(),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        _appBarTitle,
        style: TextStyle(
          fontSize: _appBarTitleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _deleteFeed,
          icon: const Icon(Icons.delete, color: Colors.white),
          tooltip: _deleteTooltip,
        ),
        TextButton(
          onPressed: _isLoading ? null : _updateFeed,
          child: const Text(
            _saveButtonText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 이미지 미리보기 위젯
  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: _imagePreviewHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_imageBorderRadius),
        image: DecorationImage(
          image: NetworkImage(widget.feed.fullImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 설명 입력 필드
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: _descriptionLabel,
        border: OutlineInputBorder(),
      ),
      maxLines: _descriptionMaxLines,
      validator: (value) => null,
    );
  }

  /// 날짜 선택 섹션
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _photoDateTitle,
          style: TextStyle(
            fontSize: _sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: _subsectionSpacing),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: _containerVerticalPadding,
              horizontal: _containerHorizontalPadding,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(_containerBorderRadius),
            ),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : _noDateSelectedText,
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 위치 정보 섹션
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _locationTitle,
          style: TextStyle(
            fontSize: _sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: _subsectionSpacing),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: _containerVerticalPadding,
            horizontal: _containerHorizontalPadding,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(_containerBorderRadius),
          ),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isLoadingLocation
                  ? const SizedBox(
                height: _loadingIndicatorSize,
                width: _loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: _loadingIndicatorStroke,
                ),
              )
                  : Text(
                _locationName ?? _unknownLocationText,
                style: const TextStyle(fontSize: _locationTextFontSize),
              ),
              const SizedBox(height: _coordinateSpacing),
              Text(
                'Latitude: ${_latitude?.toStringAsFixed(_coordinateDecimalPlaces) ?? 'N/A'}, Longitude: ${_longitude?.toStringAsFixed(_coordinateDecimalPlaces) ?? 'N/A'}',
                style: TextStyle(
                  fontSize: _coordinateTextFontSize,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: _subsectionSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: _buttonIconSize),
                    label: const Text(_editButtonText),
                    onPressed: _editCoordinates,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _buttonHorizontalPadding,
                        vertical: _buttonVerticalPadding,
                      ),
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                  const SizedBox(width: _buttonSpacing),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.map, size: _buttonIconSize),
                    label: const Text(_onMapButtonText),
                    onPressed: _editLocationOnMap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _buttonHorizontalPadding,
                        vertical: _buttonVerticalPadding,
                      ),
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 공개 범위 설정 섹션
  Widget _buildVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _visibilityTitle,
          style: TextStyle(
            fontSize: _sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: _subsectionSpacing),
        DropdownButtonFormField<String>(
          value: _visibility,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: _publicVisibility,
              child: Text(_publicDisplayText),
            ),
            DropdownMenuItem(
              value: _privateVisibility,
              child: Text(_privateDisplayText),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _visibility = value;
              });
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}