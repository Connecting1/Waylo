// lib/models/feed_comment.dart
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
  final String? parentId; // 추가: 부모 댓글 ID
  final List<FeedComment> replies; // 추가: 대댓글 목록

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
    this.parentId, // 추가
    this.replies = const [], // 추가: 기본값은 빈 배열
  });

  // JSON 데이터에서 FeedComment 객체 생성
  factory FeedComment.fromJson(Map<String, dynamic> json) {
    // 대댓글 목록 파싱
    List<FeedComment> parsedReplies = [];
    if (json['replies'] != null) {
      parsedReplies = (json['replies'] as List)
          .map((replyJson) => FeedComment.fromJson(replyJson))
          .toList();
    }

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
      parentId: json['parent'], // 부모 댓글 ID 추가
      replies: parsedReplies, // 대댓글 목록 추가
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