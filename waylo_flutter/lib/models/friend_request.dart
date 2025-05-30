import 'package:waylo_flutter/services/api/api_service.dart';

class FriendRequest {
  final String id;                        // 친구 요청의 고유 식별자
  final String fromUserId;               // 요청을 보낸 사용자 ID
  final String fromUserName;             // 요청을 보낸 사용자명
  final String fromUserProfileImage;     // 요청을 보낸 사용자의 프로필 이미지 URL
  final DateTime createdAt;              // 생성 일시

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

  String get fullProfileImageUrl {
    if (fromUserProfileImage.isEmpty) return '';

    if (fromUserProfileImage.startsWith('http')) return fromUserProfileImage;

    if (fromUserProfileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$fromUserProfileImage";
    }

    return fromUserProfileImage;
  }
}