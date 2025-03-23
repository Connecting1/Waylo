import 'package:waylo_flutter/services/api/api_service.dart';

// 피드 댓글을 표현하는 클래스
class FeedComment {
  final String id;
  final String feedId;
  final String userId;
  final String username;
  final String profileImage;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;

  FeedComment({
    required this.id,
    required this.feedId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.content,
    required this.createdAt,
    required this.likesCount,
    required this.isLiked,
  });

  // JSON 데이터에서 FeedComment 객체 생성
  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] ?? '',
      feedId: json['feed'] ?? '',
      userId: json['user'] ?? '',
      username: json['user_details']?['username'] ?? '',
      profileImage: json['user_details']?['profile_image'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  // 프로필 이미지의 전체 URL을 반환
  // 상대 경로인 경우 ApiService.baseUrl과 결합
  String get fullProfileImageUrl {
    if (profileImage.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (profileImage.startsWith('http')) return profileImage;

    // 상대 경로를 전체 URL로 변환 - ApiService.baseUrl 사용
    if (profileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$profileImage";
    }

    return profileImage;
  }
}