import 'api_service.dart';

class FriendApi {
  /// 친구 요청 보내기
  static Future<Map<String, dynamic>> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/friends/request/",
      method: "POST",
      body: {
        "from_user": fromUserId,
        "to_user": toUserId,
      },
    );
  }

  /// 받은 친구 요청 목록 조회
  static Future<dynamic> getFriendRequests() async {
    return await ApiService.sendRequest(
      endpoint: "/api/friends/requests/",
      method: "GET",
    );
  }

  /// 보낸 친구 요청 목록 조회
  static Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    final response = await ApiService.sendRequest(
      endpoint: "/api/friends/sent-requests/",
      method: "GET",
    );

    if (response is Map && response.containsKey('requests')) {
      return List<Map<String, dynamic>>.from(response['requests']);
    }
    return [];
  }

  /// 친구 요청 수락
  static Future<Map<String, dynamic>> acceptFriendRequest({
    required String requestId,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/friends/accept/",
      method: "POST",
      body: {
        "request_id": requestId,
      },
    );
  }

  /// 친구 요청 거절
  static Future<Map<String, dynamic>> rejectFriendRequest({
    required String requestId,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/friends/reject/",
      method: "POST",
      body: {
        "request_id": requestId,
      },
    );
  }

  /// 특정 사용자의 친구 목록 조회
  static Future<dynamic> getFriends(String userId) async {
    return await ApiService.sendRequest(
      endpoint: "/api/friends/$userId/",
      method: "GET",
    );
  }
}