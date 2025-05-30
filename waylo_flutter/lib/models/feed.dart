import 'package:waylo_flutter/services/api/api_service.dart';

class Feed {
  final String id;                        // 피드의 고유 식별자
  final String userId;                    // 작성자의 사용자 ID
  final String username;                  // 작성자의 사용자명
  final String profileImage;             // 작성자의 프로필 이미지 URL
  final double latitude;                  // 위도
  final double longitude;                 // 경도
  final String imageUrl;                  // 원본 이미지 URL
  final String thumbnailUrl;             // 썸네일 이미지 URL
  final String description;              // 피드 설명
  final String visibility;               // 공개 범위 (public, private 등)
  final Map<String, dynamic> extraData;  // 추가 데이터
  final DateTime createdAt;              // 생성 일시
  final DateTime? photoTakenAt;          // 사진 촬영 일시
  final int likesCount;                  // 좋아요 수
  final int bookmarksCount;              // 북마크 수
  final bool isLiked;                    // 현재 사용자의 좋아요 여부
  final bool isBookmarked;               // 현재 사용자의 북마크 여부
  final double? distance;                // 현재 위치로부터의 거리
  final String countryCode;              // 국가 코드

  Feed({
    required this.id,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.visibility,
    required this.extraData,
    required this.createdAt,
    this.photoTakenAt,
    required this.likesCount,
    required this.bookmarksCount,
    required this.isLiked,
    required this.isBookmarked,
    this.distance,
    required this.countryCode,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> extraData = json['extra_data'] ?? {};

    DateTime? photoTakenAt;
    if (json['photo_taken_at'] != null) {
      try {
        photoTakenAt = DateTime.parse(json['photo_taken_at']);
      } catch (e) {
        // 파싱 실패 시 null 유지
      }
    }

    return Feed(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      username: json['user_details']?['username'] ?? '',
      profileImage: json['user_details']?['profile_image'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      description: json['description'] ?? '',
      visibility: json['visibility'] ?? 'public',
      extraData: extraData,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      photoTakenAt: photoTakenAt,
      likesCount: json['likes_count'] ?? 0,
      bookmarksCount: json['bookmarks_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
      countryCode: json['country_code'] ?? '',
    );
  }

  String get fullThumbnailUrl {
    if (thumbnailUrl.isEmpty) return '';

    if (thumbnailUrl.startsWith('http')) return thumbnailUrl;

    if (thumbnailUrl.startsWith('/')) {
      return "${ApiService.baseUrl}$thumbnailUrl";
    }

    return thumbnailUrl;
  }

  String get fullImageUrl {
    if (imageUrl.isEmpty) return '';

    if (imageUrl.startsWith('http')) return imageUrl;

    if (imageUrl.startsWith('/')) {
      return "${ApiService.baseUrl}$imageUrl";
    }

    return imageUrl;
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