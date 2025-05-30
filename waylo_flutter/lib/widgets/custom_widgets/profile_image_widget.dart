import 'package:flutter/material.dart';
import 'package:waylo_flutter/models/album_widget.dart';

/// 프로필 이미지를 표시하는 위젯 (원형 또는 사각형)
class ProfileImageWidget extends StatefulWidget {
  final AlbumWidget widget;
  const ProfileImageWidget({Key? key, required this.widget}) : super(key: key);

  @override
  _ProfileImageWidgetState createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  static Map<String, bool> _loadedImages = {};
  late ImageProvider _imageProvider;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    String imageUrl = widget.widget.extraData['image_url'] ?? '';

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

    Color color;
    try {
      color = Color(int.parse(borderColor.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      color = Colors.white;
    }

    Widget imageWidget = imageUrl.isNotEmpty
        ? Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (!_isLoaded) {
            Future.microtask(() {
              if (mounted) setState(() {
                _isLoaded = true;
              });
            });
          }
          return child;
        }
        if (_isLoaded) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Icon(Icons.broken_image, color: Colors.grey.shade700),
          ),
        );
      },
    )
        : Container(color: Colors.grey);

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