import 'dart:io';
import 'api_service.dart';

class FeedApi {
  // 피드 목록 가져오기
  static Future<dynamic> fetchFeeds({int page = 1, int limit = 10}) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/?page=$page&limit=$limit",
      method: "GET",
    );
  }

  // 특정 피드 상세 정보 가져오기
  static Future<Map<String, dynamic>> fetchFeedDetail(String feedId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/",
      method: "GET",
    );
  }

  // 새 피드 생성하기
  static Future<Map<String, dynamic>> createFeed({
    required double latitude,
    required double longitude,
    required File image,
    String? description,
    String? visibility,
    String? countryCode,
    String? photoTakenAt,
    Map<String, dynamic>? extraData,
  }) async {
    Map<String, dynamic> body = {
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
      "description": description,
      "visibility": visibility ?? "public",
    };

    if (countryCode != null) {
      body["country_code"] = countryCode;
    }

    if (photoTakenAt != null) {
      body["photo_taken_at"] = photoTakenAt;
    }

    if (extraData != null) {
      for (var key in extraData.keys) {
        body[key] = extraData[key].toString();
      }
    }

    return await ApiService.sendRequest(
      endpoint: "/api/feeds/create/",
      method: "POST",  // PATCH에서 POST로 변경
      body: body,
      file: image,
    );
  }

  // 피드 수정하기
  static Future<Map<String, dynamic>> updateFeed({
    required String feedId,
    String? description,
    String? visibility,
    double? latitude,
    double? longitude,
    String? countryCode,
    File? image,
    String? photoTakenAt,
    Map<String, dynamic>? extraData,
  }) async {
    Map<String, dynamic> body = {};

    if (description != null) {
      body["description"] = description;
    }

    if (visibility != null) {
      body["visibility"] = visibility;
    }

    if (latitude != null) {
      body["latitude"] = double.parse(latitude.toStringAsFixed(6)).toString();
    }

    if (longitude != null) {
      body["longitude"] = double.parse(longitude.toStringAsFixed(6)).toString();
    }

    if (countryCode != null) {
      body["country_code"] = countryCode;
    }

    if (photoTakenAt != null) {
      body["photo_taken_at"] = photoTakenAt;
    }

    // 중요한 변경: extraData를 개별 필드가 아닌 extra_data 객체로 추가
    if (extraData != null) {
      body["extra_data"] = extraData;
    }

    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/update/",
      method: "PATCH",
      body: body,
      file: image,
    );
  }

  // 피드 삭제하기
  static Future<Map<String, dynamic>> deleteFeed(String feedId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/delete/",
      method: "DELETE",
    );
  }

  // 주변 피드 가져오기
  static Future<dynamic> fetchNearbyFeeds({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 1,
    int limit = 20,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/nearby/?latitude=$latitude&longitude=$longitude&radius=$radius&page=$page&limit=$limit",
      method: "GET",
    );
  }

  // 특정 사용자의 피드 가져오기
  static Future<dynamic> fetchUserFeeds(String userId, {int page = 1, int limit = 100}) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/user/$userId/?page=$page&limit=$limit",
      method: "GET",
    );
  }

  // 북마크한 피드 가져오기
  static Future<dynamic> fetchBookmarkedFeeds({int page = 1, int limit = 10}) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/bookmarked/?page=$page&limit=$limit",
      method: "GET",
    );
  }

  // 피드 좋아요
  static Future<Map<String, dynamic>> likeFeed(String feedId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/like/",
      method: "POST",
    );
  }

  // 피드 좋아요 취소
  static Future<Map<String, dynamic>> unlikeFeed(String feedId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/unlike/",
      method: "POST",
    );
  }

  // 피드 북마크
  static Future<Map<String, dynamic>> bookmarkFeed(String feedId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/bookmark/",
      method: "POST",
    );
  }

  // 피드 북마크 취소
  static Future<Map<String, dynamic>> unbookmarkFeed(String feedId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/unbookmark/",
      method: "POST",
    );
  }

  // 피드 댓글 목록 가져오기
  static Future<dynamic> fetchFeedComments(String feedId, {int page = 1, int limit = 20}) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/comments/?page=$page&limit=$limit",
      method: "GET",
    );
  }

  // 댓글 작성하기
  static Future<Map<String, dynamic>> createComment(String feedId, String content) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/$feedId/comment/",
      method: "POST",
      body: {"content": content},
    );
  }

  // 댓글 삭제하기
  static Future<Map<String, dynamic>> deleteComment(String commentId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/comment/$commentId/delete/",
      method: "DELETE",
    );
  }

  // 댓글 좋아요
  static Future<Map<String, dynamic>> likeComment(String commentId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/comment/$commentId/like/",
      method: "POST",
    );
  }

  // 댓글 좋아요 취소
  static Future<Map<String, dynamic>> unlikeComment(String commentId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/feeds/comment/$commentId/unlike/",
      method: "POST",
    );
  }
}