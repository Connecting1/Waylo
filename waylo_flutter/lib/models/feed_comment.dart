import 'package:waylo_flutter/services/api/api_service.dart';

class FeedComment {
  final String id;                        // 댓글의 고유 식별자
  final String feedId;                    // 피드 ID
  final String userId;                    // 작성자의 사용자 ID
  final String username;                  // 작성자의 사용자명
  final String profileImage;             // 작성자의 프로필 이미지 URL
  final String content;                   // 댓글 내용
  final DateTime createdAt;              // 생성 일시
  final int likesCount;                  // 좋아요 수
  final bool isLiked;                    // 현재 사용자의 좋아요 여부
  final String? parentId;                // 부모 댓글 ID (대댓글인 경우)
  final List<FeedComment> replies;       // 대댓글 목록

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
    this.parentId,
    this.replies = const [],
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
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
      parentId: json['parent'],
      replies: parsedReplies,
    );
  }

  String get fullProfileImageUrl {
    if (profileImage.isEmpty) return '';

    if (profileImage.startsWith('http')) return profileImage;

    if (profileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$profileImage";
    }

    return profileImage;
  }
}