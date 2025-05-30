import 'package:waylo_flutter/services/api/api_service.dart';

class SearchUser {
  final String id;                        // 사용자의 고유 식별자
  final String username;                  // 사용자명
  final String profileImage;             // 프로필 이미지 URL
  final String accountVisibility;        // 계정 공개 설정 (public, private)

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

  String get fullProfileImageUrl {
    if (profileImage.isEmpty) return '';

    if (profileImage.startsWith('http')) return profileImage;

    if (profileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$profileImage";
    }

    return profileImage;
  }
}