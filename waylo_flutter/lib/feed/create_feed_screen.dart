import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/feed_provider.dart';
import 'package:waylo_flutter/providers/map_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:waylo_flutter/screens/map/map_location_picker.dart'; // Import the new component

class FeedCreatePage extends StatefulWidget {
  final File imageFile;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? accessToken; // Mapbox 액세스 토큰

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
  DateTime? _photoTakenAt; // 사진 촬영 날짜 추가

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _extractPhotoDateFromExif(); // EXIF에서 날짜 추출 시도
  }

  // EXIF에서 날짜 추출 시도 (Flutter 단에서 가능한 경우)
  Future<void> _extractPhotoDateFromExif() async {
    try {
      setState(() {
        _photoTakenAt = null;
      });
    } catch (e) {
      print("EXIF 날짜 추출 오류: $e");
    }
  }

  // 위치 정보 로드
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

  // 좌표에서 위치 이름과 국가 코드 가져오기
  Future<void> _fetchLocationDetails(double latitude, double longitude) async {
    if (widget.accessToken == null) return;

    try {
      // 국가 코드 가져오기 (우선순위)
      String countryUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=${widget.accessToken}&types=country";
      final countryResponse = await http.get(Uri.parse(countryUrl));

      print("🌍 국가 코드 API 응답: ${countryResponse.statusCode}");
      print("🌍 국가 코드 응답 본문: ${countryResponse.body}");

      if (countryResponse.statusCode == 200) {
        var data = jsonDecode(countryResponse.body);
        if (data["features"].isNotEmpty) {
          setState(() {
            _countryCode = data["features"][0]["properties"]["short_code"]?.toUpperCase() ?? 'UNKNOWN';
            _locationName = data["features"][0]["place_name"] ?? 'Unknown Location';
          });
        } else {
          setState(() {
            _countryCode = 'UNKNOWN';
            _locationName = 'Unknown Location';
          });
        }
      } else {
        setState(() {
          _countryCode = 'UNKNOWN';
          _locationName = 'Unknown Location';
        });
      }
    } catch (e) {
      print("위치 정보 가져오기 오류: $e");
      setState(() {
        _countryCode = 'UNKNOWN';
        _locationName = 'Unknown Location';
      });
    }
  }

  // 위치 수정 - 새로운 지도 인터페이스 사용
  void _editLocationOnMap() async {
    if (_latitude == null || _longitude == null || widget.accessToken == null) {
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

            // Fetch additional location details if needed
            await _fetchLocationDetails(lat, lng);

            setState(() {
              _isLocationLoading = false;
            });
          },
        ),
      ),
    );
  }

  void _editCoordinates() {
    // 텍스트 컨트롤러 초기화
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

                  // 유효성 검사
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

                  // 새 좌표의 위치 정보 가져오기
                  await _fetchLocationDetails(lat, lng);

                  setState(() {
                    _isLocationLoading = false;
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
                  Navigator.pop(context);
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _photoTakenAt ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      // Set date only without time
                      _photoTakenAt = DateTime(
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

  // 피드 생성
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

      // 위도와 경도 포맷팅 - 서버 요구사항을 충족하도록
      double formattedLatitude = double.parse(_latitude!.toStringAsFixed(6)); // 소수점 6자리로 제한
      double formattedLongitude;

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

      // 날짜 정보가 ISO 형식으로 변환
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
        photoTakenAt: photoTakenAtStr, // 사진 촬영 날짜 추가
        extraData: {
          'location_name': _locationName,
        },
      );

      if (success) {
        Navigator.pop(context, true); // 성공 결과와 함께 이전 화면으로 돌아가기
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 미리보기
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[200],
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.cover,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 설명 입력
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Write a caption',
                        border: InputBorder.none,
                      ),
                      maxLines: 5,
                      minLines: 3,
                      validator: (value) {
                        // 설명은 선택 사항이므로 validation 없음
                        return null;
                      },
                    ),

                    Divider(),

                    // 촬영 날짜 설정
                    ListTile(
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
                    ),

                    Divider(),

                    // 위치 정보
                    // 위치 정보
                    ListTile(
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
                          // 숫자로 좌표 수정 버튼
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: _editCoordinates,  // 새로운 함수
                          ),
                          // 지도에서 위치 선택 버튼
                          IconButton(
                            icon: Icon(Icons.edit_location_alt),
                            onPressed: _editLocationOnMap,  // 기존 함수 이름 변경
                          ),
                        ],
                      ),
                    ),

                    Divider(),

                    // 공개 범위 설정
                    ListTile(
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
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}