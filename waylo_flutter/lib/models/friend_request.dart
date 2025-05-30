// lib/models/friend_request.dart
import 'package:waylo_flutter/services/api/api_service.dart';

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserProfileImage;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserProfileImage,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      fromUserId: json['from_user_id'] ?? '',
      fromUserName: json['from_user_name'] ?? '',
      fromUserProfileImage: json['from_user_profile_image'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // 서버의 상대 경로를 전체 URL로 변환
  String get fullProfileImageUrl {
    if (fromUserProfileImage.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (fromUserProfileImage.startsWith('http')) return fromUserProfileImage;

    // 상대 경로를 전체 URL로 변환 - ApiService.baseUrl 사용
    if (fromUserProfileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$fromUserProfileImage";
    }

    return fromUserProfileImage;
  }
}