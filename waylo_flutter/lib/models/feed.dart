// lib/models/feed.dart
import 'package:waylo_flutter/services/api/api_service.dart';

class Feed {
  final String id;
  final String userId;
  final String username;
  final String profileImage;
  final double latitude;
  final double longitude;
  final String imageUrl;
  // final String? mediumResUrl;
  // final String? lowResUrl;
  final String thumbnailUrl;
  final String description;
  final String visibility;
  final Map<String, dynamic> extraData;
  final DateTime createdAt;
  final DateTime? photoTakenAt;
  final int likesCount;
  final int bookmarksCount;
  final bool isLiked;
  final bool isBookmarked;
  final double? distance;
  final String countryCode; // 추가된 필드

  Feed({
    required this.id,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    // this.mediumResUrl,
    // this.lowResUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.visibility,
    required this.extraData,
    required this.createdAt, this.photoTakenAt,
    required this.likesCount,
    required this.bookmarksCount,
    required this.isLiked,
    required this.isBookmarked,
    this.distance,
    required this.countryCode, // 추가
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> extraData = json['extra_data'] ?? {};

    // 촬영 날짜 파싱
    DateTime? photoTakenAt;
    if (json['photo_taken_at'] != null) {
      try {
        photoTakenAt = DateTime.parse(json['photo_taken_at']);
      } catch (e) {
        print("[ERROR] photo_taken_at 파싱 오류: $e");
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
      // mediumResUrl: json['medium_res_url'],
      // lowResUrl: json['low_res_url'],
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
      countryCode: json['country_code'] ?? '', // 직접 JSON에서 가져옴
    );
  }

  // String get fullMediumResUrl {
  //   if (mediumResUrl == null || mediumResUrl!.isEmpty) return fullImageUrl;
  //   if (mediumResUrl!.startsWith('http')) return mediumResUrl!;
  //   if (mediumResUrl!.startsWith('/')) {
  //     return "${ApiService.baseUrl}$mediumResUrl";
  //   }
  //   return mediumResUrl!;
  // }
  //
  // String get fullLowResUrl {
  //   if (lowResUrl == null || lowResUrl!.isEmpty) return fullThumbnailUrl;
  //   if (lowResUrl!.startsWith('http')) return lowResUrl!;
  //   if (lowResUrl!.startsWith('/')) {
  //     return "${ApiService.baseUrl}$lowResUrl";
  //   }
  //   return lowResUrl!;
  // }

  String get fullThumbnailUrl {
    if (thumbnailUrl.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (thumbnailUrl.startsWith('http')) return thumbnailUrl;

    // 상대 경로를 전체 URL로 변환
    if (thumbnailUrl.startsWith('/')) {
      return "${ApiService.baseUrl}$thumbnailUrl";
    }

    return thumbnailUrl;
  }

  // 서버의 상대 경로를 전체 URL로 변환
  String get fullImageUrl {
    if (imageUrl.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (imageUrl.startsWith('http')) return imageUrl;

    // 상대 경로를 전체 URL로 변환 - ApiService.baseUrl 사용
    if (imageUrl.startsWith('/')) {
      return "${ApiService.baseUrl}$imageUrl";
    }

    return imageUrl;
  }

  // 프로필 이미지 URL 변환
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