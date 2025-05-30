// lib/models/search_user.dart
import 'package:waylo_flutter/services/api/api_service.dart';

class SearchUser {
  final String id;
  final String username;
  final String profileImage;
  final String accountVisibility;

  SearchUser({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.accountVisibility,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profile_image'] ?? '',
      accountVisibility: json['account_visibility'] ?? 'public',
    );
  }

  // 서버의 상대 경로를 전체 URL로 변환
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