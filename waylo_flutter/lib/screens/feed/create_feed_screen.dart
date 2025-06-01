import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/feed_provider.dart';
import 'package:waylo_flutter/providers/map_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:waylo_flutter/screens/map/map_location_picker.dart';
import '../../providers/theme_provider.dart';

class FeedCreatePage extends StatefulWidget {
  final File imageFile;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? accessToken;

  const FeedCreatePage({
    Key? key,
    required this.imageFile,
    this.initialLatitude,
    this.initialLongitude,
    this.accessToken,
  }) : super(key: key);

  @override
  _FeedCreatePageState createState() => _FeedCreatePageState();
}

class _FeedCreatePageState extends State<FeedCreatePage> {
  // 텍스트 상수들
  static const String _appBarTitle = 'Create Post';
  static const String _postButtonText = 'Post';
  static const String _captionHintText = 'Write a caption';
  static const String _photoDateTitle = 'Photo Date';
  static const String _fetchingLocationText = 'Fetching location';
  static const String _noLocationSelectedText = 'No location selected';
  static const String _unknownLocationText = 'Unknown Location';
  static const String _editCoordinatesTitle = 'Edit Coordinates';
  static const String _latitudeLabel = 'Latitude (-90 to 90)';
  static const String _longitudeLabel = 'Longitude (-180 to 180)';
  static const String _cancelButtonText = 'Cancel';
  static const String _saveButtonText = 'Save';
  static const String _photoDateOptionsTitle = 'Photo Date Options';
  static const String _setDateText = 'Set Date';
  static const String _noDateText = 'No Date';
  static const String _noDateInfoText = 'No date information';
  static const String _visibilityTitle = 'Who can see this?';
  static const String _publicVisibility = 'public';
  static const String _privateVisibility = 'private';

  // 에러 메시지 상수들
  static const String _locationDataMissingError = 'Location data or access token is missing';
  static const String _latitudeRangeError = 'Latitude must be between -90 and 90';
  static const String _longitudeRangeError = 'Longitude must be between -180 and 180';
  static const String _invalidCoordinateError = 'Invalid coordinate format';
  static const String _selectLocationError = 'Please select a location.';
  static const String _uploadFailedPrefix = 'Failed to upload post: ';
  static const String _uploadErrorPrefix = 'Something went wrong while uploading the post: ';

  // 기본값 상수들
  static const String _unknownCountryCode = 'UNKNOWN';
  static const String _defaultVisibility = 'public';

  // API 관련 상수들
  static const String _mapboxGeocodeUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places/';
  static const String _geocodeUrlSuffix = '.json?access_token=';
  static const String _geocodeTypeCountry = '&types=country';
  static const String _featuresKey = 'features';
  static const String _propertiesKey = 'properties';
  static const String _shortCodeKey = 'short_code';
  static const String _placeNameKey = 'place_name';
  static const String _locationNameKey = 'location_name';

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 16;
  static const double _coordinateSubtitleFontSize = 12;

  // 크기 상수들
  static const double _imagePreviewHeight = 300;
  static const double _formContentPadding = 16.0;
  static const double _bottomSpacing = 40;
  static const double _dateFieldSpacing = 10;

  // 좌표 관련 상수들
  static const int _coordinateDecimalPlaces = 6;
  static const double _minLatitude = -90;
  static const double _maxLatitude = 90;
  static const double _minLongitude = -180;
  static const double _maxLongitude = 180;
  static const int _longitudeMaxLength = 9;

  // 날짜 관련 상수들
  static const String _dateFormat = 'dd/MM/yyyy';
  static const int _minYear = 2000;

  // 폼 필드 상수들
  static const int _descriptionMaxLines = 5;
  static const int _descriptionMinLines = 3;

  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _visibility = _defaultVisibility;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  double? _latitude;
  double? _longitude;
  String? _locationName;
  String? _countryCode;
  DateTime? _photoTakenAt;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _extractPhotoDateFromExif();
  }

  /// EXIF에서 사진 촬영 날짜 추출 시도
  Future<void> _extractPhotoDateFromExif() async {
    try {
      setState(() {
        _photoTakenAt = null;
      });
    } catch (e) {
      // EXIF 데이터 처리 오류는 조용히 처리
    }
  }

  /// 위치 정보 로드 및 초기화
  Future<void> _loadLocationData() async {
    setState(() {
      _isLocationLoading = true;
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
    });

    if (_latitude != null && _longitude != null) {
      await _fetchLocationDetails(_latitude!, _longitude!);
    }

    setState(() {
      _isLocationLoading = false;
    });
  }

  /// Mapbox API를 통해 좌표에서 위치 이름과 국가 코드 가져오기
  Future<void> _fetchLocationDetails(double latitude, double longitude) async {
    if (widget.accessToken == null) return;

    try {
      String countryUrl = "$_mapboxGeocodeUrl$longitude,$latitude$_geocodeUrlSuffix${widget.accessToken}$_geocodeTypeCountry";
      final countryResponse = await http.get(Uri.parse(countryUrl));

      if (countryResponse.statusCode == 200) {
        var data = jsonDecode(countryResponse.body);
        if (data[_featuresKey].isNotEmpty) {
          setState(() {
            _countryCode = data[_featuresKey][0][_propertiesKey][_shortCodeKey]?.toUpperCase() ?? _unknownCountryCode;
            _locationName = data[_featuresKey][0][_placeNameKey] ?? _unknownLocationText;
          });
        } else {
          _setUnknownLocation();
        }
      } else {
        _setUnknownLocation();
      }
    } catch (e) {
      _setUnknownLocation();
    }
  }

  /// 위치 정보를 알 수 없을 때 기본값 설정
  void _setUnknownLocation() {
    setState(() {
      _countryCode = _unknownCountryCode;
      _locationName = _unknownLocationText;
    });
  }

  /// 지도에서 위치 선택
  void _editLocationOnMap() async {
    if (_latitude == null || _longitude == null || widget.accessToken == null) {
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
          accessToken: widget.accessToken!,
          onLocationSelected: (lat, lng, locationName) async {
            setState(() {
              _latitude = lat;
              _longitude = lng;
              _isLocationLoading = true;
              if (locationName != null) {
                _locationName = locationName;
              }
            });

            await _fetchLocationDetails(lat, lng);

            setState(() {
              _isLocationLoading = false;
            });
          },
        ),
      ),
    );
  }

  /// 좌표 직접 입력 다이얼로그
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
              const SizedBox(height: _dateFieldSpacing),
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
              child: const Text(_saveButtonText),
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
        _isLocationLoading = true;
      });

      await _fetchLocationDetails(lat, lng);

      setState(() {
        _isLocationLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_invalidCoordinateError)),
      );
    }
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
                    _photoTakenAt = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 날짜 선택기 표시
  void _showDatePicker() async {
    Navigator.pop(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _photoTakenAt ?? DateTime.now(),
      firstDate: DateTime(_minYear),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _photoTakenAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  /// 피드 생성 및 업로드
  Future<void> _createFeed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_selectLocationError))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      // 좌표 포맷팅 - 서버 요구사항에 맞게 조정
      double formattedLatitude = double.parse(_latitude!.toStringAsFixed(_coordinateDecimalPlaces));
      double formattedLongitude = _formatLongitude(_longitude!);

      String? photoTakenAtStr;
      if (_photoTakenAt != null) {
        photoTakenAtStr = _photoTakenAt!.toIso8601String();
      }

      final success = await feedProvider.createFeed(
        latitude: formattedLatitude,
        longitude: formattedLongitude,
        image: widget.imageFile,
        description: _descriptionController.text,
        visibility: _visibility,
        countryCode: _countryCode,
        photoTakenAt: photoTakenAtStr,
        extraData: {
          _locationNameKey: _locationName,
        },
      );

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$_uploadFailedPrefix${feedProvider.errorMessage}'))
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_uploadErrorPrefix$e'))
      );
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),
              _buildFormContent(),
            ],
          ),
        ),
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
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: _appBarTitleFontSize,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _createFeed,
          child: const Text(
            _postButtonText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      centerTitle: true,
    );
  }

  /// 이미지 미리보기 위젯
  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: _imagePreviewHeight,
      color: Colors.grey[200],
      child: Image.file(
        widget.imageFile,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 폼 내용 위젯
  Widget _buildFormContent() {
    return Padding(
      padding: const EdgeInsets.all(_formContentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionField(),
          const Divider(),
          _buildDateSection(),
          const Divider(),
          _buildLocationSection(),
          const Divider(),
          _buildVisibilitySection(),
          const SizedBox(height: _bottomSpacing),
        ],
      ),
    );
  }

  /// 설명 입력 필드
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        hintText: _captionHintText,
        border: InputBorder.none,
      ),
      maxLines: _descriptionMaxLines,
      minLines: _descriptionMinLines,
      validator: (value) => null,
    );
  }

  /// 촬영 날짜 섹션
  Widget _buildDateSection() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text(_photoDateTitle),
      subtitle: Text(
        _photoTakenAt != null
            ? DateFormat(_dateFormat).format(_photoTakenAt!)
            : _noDateInfoText,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _selectDate(context),
      ),
    );
  }

  /// 위치 정보 섹션
  Widget _buildLocationSection() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on),
      title: _isLocationLoading
          ? const Text(_fetchingLocationText)
          : Text(_locationName ?? _noLocationSelectedText),
      subtitle: Text(
        'Latitude: ${_latitude?.toStringAsFixed(_coordinateDecimalPlaces) ?? 'N/A'}, Longitude: ${_longitude?.toStringAsFixed(_coordinateDecimalPlaces) ?? 'N/A'}',
        style: const TextStyle(fontSize: _coordinateSubtitleFontSize),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCoordinates,
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: _editLocationOnMap,
          ),
        ],
      ),
    );
  }

  /// 공개 범위 설정 섹션
  Widget _buildVisibilitySection() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.visibility),
      title: const Text(_visibilityTitle),
      trailing: DropdownButton<String>(
        value: _visibility,
        underline: Container(),
        items: const [
          DropdownMenuItem(
            value: _publicVisibility,
            child: Text(_publicVisibility),
          ),
          DropdownMenuItem(
            value: _privateVisibility,
            child: Text(_privateVisibility),
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
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}