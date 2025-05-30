// lib/widget/custom_widgets/profile_image_widget.dart
import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/album_widget.dart';

class ProfileImageWidget extends StatefulWidget {
  final AlbumWidget widget;
  const ProfileImageWidget({Key? key, required this.widget}) : super(key: key);

  @override
  _ProfileImageWidgetState createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  // 이미지 로드 여부를 추적하는 정적 맵
  static Map<String, bool> _loadedImages = {};
  late ImageProvider _imageProvider;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    String imageUrl = widget.widget.extraData['image_url'] ?? '';

    // 이미 로드된 이미지인지 확인
    if (imageUrl.isNotEmpty && !_loadedImages.containsKey(imageUrl)) {
      _imageProvider = NetworkImage(imageUrl);
      _loadedImages[imageUrl] = true;
    } else if (imageUrl.isNotEmpty) {
      _imageProvider = NetworkImage(imageUrl);
      _isLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.widget.extraData['image_url'] ?? '';
    String shape = widget.widget.extraData['shape'] ?? 'circle';
    String borderColor = widget.widget.extraData['border_color'] ?? '#FFFFFF';
    double borderWidth = widget.widget.extraData['border_width']?.toDouble() ?? 2.0;

    // 16진수 색상 코드를 Color 객체로 변환
    Color color;
    try {
      color = Color(int.parse(borderColor.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      color = Colors.white;
    }

    // 이미지 위젯 생성
    Widget imageWidget = imageUrl.isNotEmpty
        ? Image.network(
      imageUrl,
      fit: BoxFit.cover,
      // 첫 로드 시에만 로딩 표시기 보이기
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // 로딩 완료 시
          if (!_isLoaded) {
            Future.microtask(() {
              if (mounted) setState(() {
                _isLoaded = true;
              });
            });
          }
          return child;
        }
        // 이미 로드된 이미지는 로딩 표시기 없이 바로 표시
        if (_isLoaded) {
          return child;
        }
        // 첫 로드 시에만 로딩 표시
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print("[ERROR] 이미지 로드 실패: $imageUrl, 오류: $error");
        return Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Icon(Icons.broken_image, color: Colors.grey.shade700),
          ),
        );
      },
    )
        : Container(color: Colors.grey);

    // 모양에 따라 다른 컨테이너 반환
    if (shape == 'circle') {
      return Container(
        width: widget.widget.width,
        height: widget.widget.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(child: imageWidget),
      );
    } else {
      return Container(
        width: widget.widget.width,
        height: widget.widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageWidget,
        ),
      );
    }
  }
}