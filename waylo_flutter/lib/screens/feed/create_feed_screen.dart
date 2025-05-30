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
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _visibility = 'public';
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
      String countryUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=${widget.accessToken}&types=country";
      final countryResponse = await http.get(Uri.parse(countryUrl));

      if (countryResponse.statusCode == 200) {
        var data = jsonDecode(countryResponse.body);
        if (data["features"].isNotEmpty) {
          setState(() {
            _countryCode = data["features"][0]["properties"]["short_code"]?.toUpperCase() ?? 'UNKNOWN';
            _locationName = data["features"][0]["place_name"] ?? 'Unknown Location';
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
      _countryCode = 'UNKNOWN';
      _locationName = 'Unknown Location';
    });
  }

  /// 지도에서 위치 선택
  void _editLocationOnMap() async {
    if (_latitude == null || _longitude == null || widget.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location data or access token is missing')),
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
      text: _latitude?.toStringAsFixed(6) ?? '',
    );
    final lngController = TextEditingController(
      text: _longitude?.toStringAsFixed(6) ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Coordinates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: InputDecoration(
                  labelText: 'Latitude (-90 to 90)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              SizedBox(height: 10),
              TextField(
                controller: lngController,
                decoration: InputDecoration(
                  labelText: 'Longitude (-180 to 180)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _saveCoordinates(latController.text, lngController.text),
              child: Text('Save'),
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

      if (lat < -90 || lat > 90) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Latitude must be between -90 and 90')),
        );
        return;
      }
      if (lng < -180 || lng > 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Longitude must be between -180 and 180')),
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
        SnackBar(content: Text('Invalid coordinate format')),
      );
    }
  }

  /// 사진 촬영 날짜 선택 다이얼로그
  void _selectDate(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Photo Date Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Set Date'),
                onTap: () => _showDatePicker(),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.clear),
                title: Text('No Date'),
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
      firstDate: DateTime(2000),
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
          SnackBar(content: Text('Please select a location.'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      // 좌표 포맷팅 - 서버 요구사항에 맞게 조정
      double formattedLatitude = double.parse(_latitude!.toStringAsFixed(6));
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
          'location_name': _locationName,
        },
      );

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload post: ${feedProvider.errorMessage}'))
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong while uploading the post: $e'))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 경도 포맷팅 - 9자리 제한
  double _formatLongitude(double longitude) {
    String longStr = longitude.toString();
    if (longStr.replaceAll('.', '').length > 9) {
      int integerLength = longStr.split('.')[0].length;
      int decimalPlaces = 9 - integerLength;
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
          ? Center(child: CircularProgressIndicator())
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
      title: Text(
        'Create Post',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _createFeed,
          child: Text(
            'Post',
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
      height: 300,
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionField(),
          Divider(),
          _buildDateSection(),
          Divider(),
          _buildLocationSection(),
          Divider(),
          _buildVisibilitySection(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 설명 입력 필드
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        hintText: 'Write a caption',
        border: InputBorder.none,
      ),
      maxLines: 5,
      minLines: 3,
      validator: (value) => null,
    );
  }

  /// 촬영 날짜 섹션
  Widget _buildDateSection() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.calendar_today),
      title: Text('Photo Date'),
      subtitle: Text(
        _photoTakenAt != null
            ? DateFormat('yyyy-MM-dd').format(_photoTakenAt!)
            : 'No date information',
      ),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => _selectDate(context),
      ),
    );
  }

  /// 위치 정보 섹션
  Widget _buildLocationSection() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.location_on),
      title: _isLocationLoading
          ? Text('Fetching location')
          : Text(_locationName ?? 'No location selected'),
      subtitle: Text(
        'Latitude: ${_latitude?.toStringAsFixed(6) ?? 'N/A'}, Longitude: ${_longitude?.toStringAsFixed(6) ?? 'N/A'}',
        style: TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editCoordinates,
          ),
          IconButton(
            icon: Icon(Icons.edit_location_alt),
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
      leading: Icon(Icons.visibility),
      title: Text('Who can see this?'),
      trailing: DropdownButton<String>(
        value: _visibility,
        underline: Container(),
        items: [
          DropdownMenuItem(
            value: 'public',
            child: Text('public'),
          ),
          DropdownMenuItem(
            value: 'private',
            child: Text('private'),
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