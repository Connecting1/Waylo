import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waylo_flutter/models/feed.dart';
import 'package:waylo_flutter/services/api/feed_api.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/screens/map/map_location_picker.dart';

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

  // Location related variables
  double? _latitude;
  double? _longitude;
  String? _locationName;
  String? _countryCode;  // Added country code variable
  String? _accessToken;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.feed.description);
    _visibility = widget.feed.visibility;
    _selectedDate = widget.feed.photoTakenAt;

    // Initialize location data from feed
    _latitude = widget.feed.latitude;
    _longitude = widget.feed.longitude;
    _locationName = widget.feed.extraData['location_name'];
    _countryCode = widget.feed.countryCode;
    _accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 위치명 가져오기 메서드 추가
  Future<String?> _getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&types=country";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["features"].isNotEmpty) {
          // 국가 이름만 반환
          return data["features"][0]["text"];
        }
      }
    } catch (e) {
      print("[ERROR] 위치명 검색 오류: $e");
    }
    return null;
  }

  // Get country code from coordinates - EXACTLY like CreateFeedScreen
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
      print("[ERROR] 국가 코드 검색 오류: $e");
    }
    return null;
  }

  // Edit location on map
  void _editLocationOnMap() async {
    if (_latitude == null || _longitude == null || _accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location data or access token is missing')),
      );
      return;
    }

    // Navigate to the map location picker
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

            // 위치 이름 직접 가져오기 추가
            String? name = await _getLocationNameFromCoordinates(lat, lng);

            // Get country code - EXACTLY like CreateFeedScreen
            String? countryCode = await _getCountryCodeFromCoordinates(lat, lng);

            setState(() {
              _locationName = name; // 위치 이름 업데이트 추가
              _countryCode = countryCode;
              _isLoadingLocation = false;
            });
          },
        ),
      ),
    );
  }

  // Edit coordinates directly
  void _editCoordinates() {
    // Initialize text controllers with current values
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
              onPressed: () async {
                try {
                  double lat = double.parse(latController.text);
                  double lng = double.parse(lngController.text);

                  // Validation
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

                  // 위치 이름 직접 가져오기 추가
                  String? name = await _getLocationNameFromCoordinates(lat, lng);

                  // Get country code - EXACTLY like CreateFeedScreen
                  String? countryCode = await _getCountryCodeFromCoordinates(lat, lng);

                  setState(() {
                    _locationName = name; // 위치 이름 업데이트 추가
                    _countryCode = countryCode;
                    _isLoadingLocation = false;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid coordinate format')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 날짜 선택 다이얼로그 표시
  void _selectDate(BuildContext context) async {
    // 팝업 메뉴 표시
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
                onTap: () async {
                  Navigator.pop(context); // 다이얼로그 닫기

                  // 날짜 선택기 표시
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      // 시간 정보 없이 날짜만 설정
                      _selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                    });
                  }
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.clear),
                title: Text('No Date'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = null; // 날짜 정보 제거
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

  // 피드 업데이트
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
      print("🔥 업데이트 시작: ${widget.feed.id}");

      // 위도와 경도 포맷팅 - CreateFeedScreen 방식을 그대로 따름
      double formattedLatitude = double.parse(_latitude!.toStringAsFixed(6)); // 소수점 6자리로 제한
      double formattedLongitude = double.parse(_longitude!.toStringAsFixed(6));

      // 경도가 9자리를 초과하지 않도록 포맷팅
      String longStr = _longitude!.toString();
      if (longStr.replaceAll('.', '').length > 9) {
        // 총 자릿수가 9자리가 되도록 소수점 부분 조정
        int integerLength = longStr.split('.')[0].length;
        int decimalPlaces = 9 - integerLength;
        if (decimalPlaces > 0) {
          formattedLongitude = double.parse(_longitude!.toStringAsFixed(decimalPlaces));
        } else {
          // 정수 부분만으로 9자리를 넘으면 정수 부분만 사용
          formattedLongitude = double.parse(_longitude!.toStringAsFixed(0));
        }
      } else {
        formattedLongitude = _longitude!;
      }

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

      print("🔥 응답 받음: $response");
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

      Navigator.pop(context, true); // 성공 결과와 함께 이전 화면으로 돌아가기
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      print("🔥🔥🔥 업데이트 오류: $e");
      print("🔥🔥🔥 스택 트레이스: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _deleteFeed() async {
    // 삭제 확인 다이얼로그 표시
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

      // 결과와 함께 화면 닫기 (삭제 성공 시 true 반환)
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

  // 날짜 포맷팅 (DD/MM/YYYY)
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // toolbarHeight: 40,
        title: Text(
          'Edit Feed',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 미리보기
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(widget.feed.fullImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // 설명 입력
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  // 설명은 선택 사항이므로 validation 없음
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 날짜 선택
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
              SizedBox(height: 20),

              // Location section - Simplified to match CreateFeedScreen
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
                        // Edit coordinates directly button
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
                        // Edit on map button
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
              SizedBox(height: 20),

              // 공개 범위 설정
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
          ),
        ),
      ),
    );
  }
}