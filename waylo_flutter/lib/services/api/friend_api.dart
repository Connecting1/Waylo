import 'api_service.dart';

class FriendApi {
  // 친구 요청 보내기
  static Future<Map<String, dynamic>> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {

    try {
      final response = await ApiService.sendRequest(
        endpoint: "/api/friends/request/",
        method: "POST",
        body: {
          "from_user": fromUserId,
          "to_user": toUserId,
        },
      );
      return response;
    } catch (e) {
      print("[ERROR][ERROR] 친구 요청 전송 예외: $e");
      return {"error": "요청 처리 중 오류 발생"};
    }
  }

  // 받은 친구 요청 목록 조회
  static Future<dynamic> getFriendRequests() async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/friends/requests/",
        method: "GET",
      );
    } catch (e) {
      print("[ERROR] 친구 요청 목록 조회 예외: $e");
      return {"error": "요청 처리 중 오류 발생"};
    }
  }

  // 보낸 친구 요청 목록 조회
  static Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    try {
      final response = await ApiService.sendRequest(
        endpoint: "/api/friends/sent-requests/",
        method: "GET",
      );

      if (response is Map && response.containsKey('requests')) {
        return List<Map<String, dynamic>>.from(response['requests']);
      }
      return [];
    } catch (e) {
      print("[ERROR] 보낸 친구 요청 목록 조회 예외: $e");
      return [];
    }
  }

  // 친구 요청 수락
  static Future<Map<String, dynamic>> acceptFriendRequest({
    required String requestId,
  }) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/friends/accept/",
        method: "POST",
        body: {
          "request_id": requestId,
        },
      );
    } catch (e) {
      print("[ERROR] 친구 요청 수락 예외: $e");
      return {"error": "요청 처리 중 오류 발생"};
    }
  }

  // 친구 요청 거절
  static Future<Map<String, dynamic>> rejectFriendRequest({
    required String requestId,
  }) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/friends/reject/",
        method: "POST",
        body: {
          "request_id": requestId,
        },
      );
    } catch (e) {
      print("[ERROR] 친구 요청 거절 예외: $e");
      return {"error": "요청 처리 중 오류 발생"};
    }
  }

  // 특정 사용자의 친구 목록 조회
  static Future<dynamic> getFriends(String userId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/friends/$userId/",
        method: "GET",
      );
    } catch (e) {
      print("[ERROR] 친구 목록 조회 예외: $e");
      return {"error": "요청 처리 중 오류 발생"};
    }
  }
}