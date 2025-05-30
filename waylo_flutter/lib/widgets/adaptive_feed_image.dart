// lib/widget/adaptive_feed_image.dart


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:waylo_flutter/models/feed.dart';
//
// class AdaptiveFeedImage extends StatefulWidget {
//   final Feed feed;
//   final BoxFit fit;
//   final double? width;
//   final double? height;
//
//   const AdaptiveFeedImage({
//     Key? key,
//     required this.feed,
//     this.fit = BoxFit.cover,
//     this.width,
//     this.height,
//   }) : super(key: key);
//
//   @override
//   _AdaptiveFeedImageState createState() => _AdaptiveFeedImageState();
// }
//
// class _AdaptiveFeedImageState extends State<AdaptiveFeedImage> {
//   bool _isSpeedTested = false;
//   bool _isImageLoading = true;
//   String _currentImageUrl = '';
//   String _initialImageUrl = '';
//   double _networkSpeed = 0;  // MB/s
//
//   @override
//   void initState() {
//     super.initState();
//
//     // 처음에는 항상 저해상도로 시작
//     _initialImageUrl = widget.feed.fullLowResUrl;
//     _currentImageUrl = _initialImageUrl;
//
//     // 네트워크 속도 측정 시작
//     _measureNetworkSpeed();
//   }
//
//   Future<void> _measureNetworkSpeed() async {
//     try {
//       // 속도 테스트를 위한 작은 파일 다운로드
//       final testUrl = 'https://speed.cloudflare.com/100kb.bin';
//
//       final startTime = DateTime.now();
//       final response = await http.get(Uri.parse(testUrl))
//           .timeout(Duration(seconds: 5));
//       final endTime = DateTime.now();
//
//       // 다운로드 시간 (밀리초)
//       int downloadTime = endTime.difference(startTime).inMilliseconds;
//       if (downloadTime == 0) downloadTime = 1; // 0으로 나누기 방지
//
//       // 다운로드 속도 계산 (MB/s)
//       double fileSize = response.bodyBytes.length / (1024 * 1024); // MB
//       _networkSpeed = fileSize / (downloadTime / 1000); // MB/s
//
//       print('네트워크 속도: $_networkSpeed MB/s');
//
//       // 속도에 따라 이미지 URL 선택
//       _updateImageUrlBasedOnSpeed();
//     } catch (e) {
//       print('속도 측정 오류: $e');
//       // 오류 발생 시 중간 품질 사용
//       if (mounted) {
//         setState(() {
//           _currentImageUrl = widget.feed.fullMediumResUrl;
//           _isSpeedTested = true;
//         });
//       }
//     }
//   }
//
//   void _updateImageUrlBasedOnSpeed() {
//     if (!mounted) return;
//
//     setState(() {
//       if (_networkSpeed < 0.5) {
//         // 느린 연결 - 저해상도
//         _currentImageUrl = widget.feed.fullLowResUrl;
//       } else if (_networkSpeed < 2.0) {
//         // 중간 속도 - 중간 해상도
//         _currentImageUrl = widget.feed.fullMediumResUrl;
//       } else {
//         // 빠른 연결 - 원본 이미지
//         _currentImageUrl = widget.feed.fullImageUrl;
//       }
//
//       _isSpeedTested = true;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // 저해상도 이미지 (항상 표시, 처음에만 보임)
//         CachedNetworkImage(
//           imageUrl: _initialImageUrl,
//           fit: widget.fit,
//           width: widget.width,
//           height: widget.height,
//           placeholder: (context, url) => Container(
//             color: Colors.grey[300],
//             child: Center(child: CircularProgressIndicator()),
//           ),
//           errorWidget: (context, url, error) => Container(
//             color: Colors.grey[300],
//             child: Icon(Icons.broken_image, color: Colors.grey[600]),
//           ),
//         ),
//
//         // 속도에 따른 최적 이미지
//         if (_isSpeedTested && _currentImageUrl != _initialImageUrl)
//           AnimatedOpacity(
//             opacity: _isImageLoading ? 0.0 : 1.0,
//             duration: Duration(milliseconds: 300),
//             child: CachedNetworkImage(
//               imageUrl: _currentImageUrl,
//               fit: widget.fit,
//               width: widget.width,
//               height: widget.height,
//               placeholder: (context, url) => Container(),  // 투명 플레이스홀더
//               errorWidget: (context, url, error) => Container(),  // 투명 에러 위젯
//               imageBuilder: (context, imageProvider) {
//                 // 이미지 로드 완료 시 상태 업데이트
//                 if (_isImageLoading) {
//                   Future.microtask(() {
//                     if (mounted) {
//                       setState(() {
//                         _isImageLoading = false;
//                       });
//                     }
//                   });
//                 }
//                 return Image(image: imageProvider, fit: widget.fit);
//               },
//             ),
//           ),
//       ],
//     );
//   }
// }