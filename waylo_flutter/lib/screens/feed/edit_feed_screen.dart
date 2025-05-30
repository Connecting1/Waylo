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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  String _visibility = 'public';
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
    _locationName = widget.feed.extraData['location_name'];
    _countryCode = widget.feed.countryCode;
    _accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  }

  /// Mapbox API를 통해 좌표에서 위치명 가져오기
  Future<String?> _getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&types=country";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["text"];
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
      String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&types=country";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          return data["features"][0]["properties"]["short_code"]?.toUpperCase();
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
        _isLoadingLocation = true;
      });

      await _updateLocationInfo(lat, lng);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid coordinate format')),
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
                    _selectedDate = null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
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
      firstDate: DateTime(2000),
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
        SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double formattedLatitude = double.parse(_latitude!.toStringAsFixed(6));
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
          'location_name': _locationName,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response['error']}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feed updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
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

  /// 피드 삭제
  Future<void> _deleteFeed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete feed'),
        content: Text('Are you sure you want to delete this feed? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${response['error']}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feed has been deleted')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),
              SizedBox(height: 20),
              _buildDescriptionField(),
              SizedBox(height: 20),
              _buildDateSection(),
              SizedBox(height: 20),
              _buildLocationSection(),
              SizedBox(height: 20),
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
      title: Text(
        'Edit Feed',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _deleteFeed,
          icon: Icon(Icons.delete, color: Colors.white),
          tooltip: 'Delete Feed',
        ),
        TextButton(
          onPressed: _isLoading ? null : _updateFeed,
          child: Text(
            'Save',
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
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
      decoration: InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      validator: (value) => null,
    );
  }

  /// 날짜 선택 섹션
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'No date selected',
                ),
                Icon(Icons.calendar_today),
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
        Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isLoadingLocation
                  ? Container(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _locationName ?? 'Unknown location',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Latitude: ${_latitude?.toStringAsFixed(6) ?? 'N/A'}, Longitude: ${_longitude?.toStringAsFixed(6) ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Edit'),
                    onPressed: _editCoordinates,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size(0, 0),
                    ),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: Icon(Icons.map, size: 18),
                    label: Text('On Map'),
                    onPressed: _editLocationOnMap,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size(0, 0),
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
        Text(
          'Visibility',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _visibility,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'public',
              child: Text('Public'),
            ),
            DropdownMenuItem(
              value: 'private',
              child: Text('Private'),
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