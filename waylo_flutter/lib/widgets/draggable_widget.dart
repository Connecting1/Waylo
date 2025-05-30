import 'package:flutter/material.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/widgets/custom_widgets/textbox_widget.dart';

/// 드래그 가능하고 크기 조절이 가능한 위젯
class DraggableWidget extends StatefulWidget {
  final Widget child;
  final double initialX;
  final double initialY;
  final double width;
  final double height;
  final Function(double, double) onPositionChanged;
  final Function(double, double)? onSizeChanged;
  final Function() onTap;
  final Function() onLongPress;
  final String? widgetType;
  final ResizeMode resizeMode;

  const DraggableWidget({
    Key? key,
    required this.child,
    required this.initialX,
    required this.initialY,
    required this.width,
    required this.height,
    required this.onPositionChanged,
    this.onSizeChanged,
    required this.onTap,
    required this.onLongPress,
    this.widgetType,
    this.resizeMode = ResizeMode.aspectRatio,
  }) : super(key: key);

  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  late double x;
  late double y;
  late double width;
  late double height;
  late double _aspectRatio;
  bool _isSelected = false;
  bool _isResizing = false;

  double get _minWidth {
    switch (widget.widgetType) {
      case "checklist":
        return 161.2;
      case "text_box":
        return 100.0;
      case "profile_image":
        return 40.0;
      default:
        return 120.0;
    }
  }

  double get _minHeight {
    switch (widget.widgetType) {
      case "checklist":
        return 161.2;
      case "text_box":
        return 60.0;
      case "profile_image":
        return 60.0;
      default:
        return 120.0;
    }
  }

  @override
  void initState() {
    super.initState();
    x = widget.initialX;
    y = widget.initialY;
    width = widget.width;
    height = widget.height;
    _aspectRatio = width / height;
  }

  @override
  void didUpdateWidget(DraggableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      width = widget.width;
      height = widget.height;

      if (width < _minWidth) width = _minWidth;
      if (height < _minHeight) height = _minHeight;

      _aspectRatio = width / height;
    }

    if (oldWidget.initialX != widget.initialX ||
        oldWidget.initialY != widget.initialY) {
      x = widget.initialX;
      y = widget.initialY;
    }
  }

  /// TextBoxWidget의 선택 상태 전달을 위한 처리
  Widget _buildChildWithSelectedState() {
    if (widget.widgetType == "text_box") {
      final originalWidget = widget.child;

      if (originalWidget is TextBoxWidget) {
        return TextBoxWidget(
          widget: originalWidget.widget,
          isSelected: _isSelected,
        );
      }
    }

    return widget.child;
  }

  @override
  Widget build(BuildContext context) {
    final childWithState = _buildChildWithSelectedState();

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
          });
          widget.onTap();
        },
        onLongPress: widget.onLongPress,
        onPanUpdate: (details) {
          if (_isResizing) return;

          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
        },
        onPanEnd: (_) {
          if (!_isResizing) {
            widget.onPositionChanged(x, y);
          }
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: _isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),

              if (_isSelected && widget.onSizeChanged != null)
                _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

  /// 크기 조절 핸들 구성
  Widget _buildResizeHandle() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isResizing = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            double oldWidth = width;
            double oldHeight = height;

            switch (widget.resizeMode) {
              case ResizeMode.free:
                double newWidth = (width + details.delta.dx)
                    .clamp(_minWidth, double.infinity);
                double newHeight = (height + details.delta.dy)
                    .clamp(_minHeight, double.infinity);

                width = newWidth;
                height = newHeight;
                break;

              case ResizeMode.aspectRatio:
              default:
                double deltaX = details.delta.dx;
                double rawNewWidth = width + deltaX;
                double newWidth = rawNewWidth.clamp(_minWidth, double.infinity);
                double newHeight = newWidth / _aspectRatio;

                if (newHeight < _minHeight) {
                  newHeight = _minHeight;
                  newWidth = newHeight * _aspectRatio;
                }

                if (newWidth < _minWidth) {
                  newWidth = _minWidth;
                }

                width = newWidth;
                height = newHeight;
                break;
            }
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isResizing = false;
          });
          widget.onSizeChanged?.call(width, height);
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.open_with,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// 크기 조절 모드
enum ResizeMode {
  aspectRatio,                                          // 종횡비 유지
  free                                                  // 가로/세로 독립적으로
}