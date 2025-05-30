// lib/widget/draggable_widget.dart

import 'package:flutter/material.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:waylo_flutter/widgets/custom_widgets/textbox_widget.dart';

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
  final String? widgetType; // 추가: 위젯 타입 정보
  final ResizeMode resizeMode; // 리사이징 모드 추가

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
    this.widgetType, // 위젯 타입 매개변수 추가
    this.resizeMode = ResizeMode.aspectRatio, // 기본값은 종횡비 유지
  }) : super(key: key);

  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  late double x;
  late double y;
  late double width;
  late double height;
  late double _aspectRatio; // 비율 저장 변수
  bool _isSelected = false;
  bool _isResizing = false;

  // 위젯 타입별 최소 가로 크기 정의
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

  // 위젯 타입별 최소 세로 크기 정의
  double get _minHeight {
    switch (widget.widgetType) {
      case "checklist":
        return 161.2;
      case "text_box":
        return 60.0; // 텍스트 박스는 세로로 더 작게 할 수 있음
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
    _aspectRatio = width / height; // 초기 비율 저장
    print(
        "🔄 DraggableWidget 초기화: 타입=${widget.widgetType}, 최소 가로 크기=$_minWidth, 최소 세로 크기=$_minHeight");
  }

  @override
  void didUpdateWidget(DraggableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 위젯의 속성이 외부에서 변경되었을 때 상태 업데이트
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      width = widget.width;
      height = widget.height;

      // 최소 크기 제약 적용
      if (width < _minWidth) width = _minWidth;
      if (height < _minHeight) height = _minHeight;

      _aspectRatio = width / height; // 비율 업데이트
    }

    if (oldWidget.initialX != widget.initialX ||
        oldWidget.initialY != widget.initialY) {
      x = widget.initialX;
      y = widget.initialY;
    }
  }

  // TextBoxWidget의 경우 isSelected 상태를 전달하기 위한 클론 처리
  Widget _buildChildWithSelectedState() {
    // text_box 타입인 경우만 특별 처리
    if (widget.widgetType == "text_box") {
      final originalWidget = widget.child;

      if (originalWidget is TextBoxWidget) {
        // TextBoxWidget이면 isSelected를 전달하는 새 인스턴스 생성
        return TextBoxWidget(
          widget: originalWidget.widget,
          isSelected: _isSelected,
        );
      }
    }

    // 다른 타입은 그대로 반환
    return widget.child;
  }

  @override
  Widget build(BuildContext context) {
    // 텍스트 박스인 경우 선택 상태를 전달하기 위한 처리
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
          // 리사이징 중이면 이동하지 않음
          if (_isResizing) return;

          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
        },
        onPanEnd: (_) {
          // 드래그가 끝났을 때 위치 업데이트
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
              // 위젯 내용
              Positioned.fill(child: widget.child),

              // 리사이징 핸들 (선택된 경우와 onSizeChanged가 제공된 경우에만 표시)
              if (_isSelected && widget.onSizeChanged != null)
                _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

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
            // 현재 크기를 저장
            double oldWidth = width;
            double oldHeight = height;

            // 리사이징 모드에 따라 다른 로직 적용
            switch (widget.resizeMode) {
              case ResizeMode.free:
              // 가로/세로 독립적으로 크기 조절 (각각 다른 최소 크기 적용)
                double newWidth = (width + details.delta.dx)
                    .clamp(_minWidth, double.infinity);
                double newHeight = (height + details.delta.dy)
                    .clamp(_minHeight, double.infinity);

                width = newWidth;
                height = newHeight;
                break;

              case ResizeMode.aspectRatio:
              default:
              // 종횡비 유지 로직 (기존 코드)
                double deltaX = details.delta.dx;
                double rawNewWidth = width + deltaX;
                double newWidth = rawNewWidth.clamp(_minWidth, double.infinity);
                double newHeight = newWidth / _aspectRatio;

                if (newHeight < _minHeight) {
                  newHeight = _minHeight;
                  newWidth = newHeight * _aspectRatio;
                }

                // 가로 크기가 최소 너비보다 작아질 수 있는지 한번 더 검사
                if (newWidth < _minWidth) {
                  newWidth = _minWidth;
                  // 이 경우 종횡비를 완벽히 유지할 수 없음을 로그로 남길 수 있음
                  print("⚠️ 종횡비를 완벽히 유지할 수 없음: 최소 가로/세로 크기 제약으로 인해");
                }

                width = newWidth;
                height = newHeight;
                break;
            }

            // 디버깅용 로그
            if (width != oldWidth || height != oldHeight) {
              print(
                  "🔄 크기 조절: ${widget.widgetType ?? "unknown"} - $oldWidth x $oldHeight → $width x $height");
            }
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isResizing = false;
          });
          // 크기 조절이 끝났을 때 크기 업데이트
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

enum ResizeMode {
  aspectRatio, // 종횡비 유지
  free // 가로/세로 독립적으로
}
