import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:waylo_flutter/styles/app_styles.dart';

class MapLocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String accessToken;
  final Function(double, double, String?) onLocationSelected;

  const MapLocationPicker({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.accessToken,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _MapLocationPickerState createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late MapboxMap mapboxMap;
  bool _isMapInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 전체 화면 지도
          MapWidget(
            key: const ValueKey("map"),
            cameraOptions: CameraOptions(
              center: Point(
                  coordinates: Position(
                      widget.initialLongitude,
                      widget.initialLatitude
                  )
              ),
              zoom: 10.0,
            ),
            onMapCreated: _onMapCreated,
          ),

          // 뒤로가기 버튼
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),

          // 중앙 포인터
          Center(
            child: Icon(
              Icons.add,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          // Next 버튼 (우측 하단)
          Positioned(
            bottom: 16,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _confirmLocation,
                child: Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;

    mapboxMap.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: true,
        pinchToZoomEnabled: true,
        scrollEnabled: true,
        doubleTapToZoomInEnabled: true,
      ),
    );

    setState(() {
      _isMapInitialized = true;
    });
  }

  void _confirmLocation() async {
    if (!_isMapInitialized) return;

    try {
      final cameraState = await mapboxMap.getCameraState();
      final center = cameraState.center;

      widget.onLocationSelected(
          center.coordinates.lat.toDouble(),
          center.coordinates.lng.toDouble(),
          null
      );

      Navigator.pop(context);
    } catch (e) {
      print("Location confirmation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to select location.'))
      );
    }
  }
}