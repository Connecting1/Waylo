// lib/services/api/chat_api.dart
import 'api_service.dart';

class ChatApi {
  // 채팅방 목록 조회
  static Future<Map<String, dynamic>> getChatRooms() async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/chats/rooms/",
        method: "GET",
      );
    } catch (e) {
      print("[ERROR] 채팅방 목록 조회 중 오류 발생: $e");
      return {"error": "서버 오류가 발생했습니다."};
    }
  }

  // 채팅방 생성 (친구와의 1:1 채팅)
  static Future<Map<String, dynamic>> createChatRoom({
    required String friendId,
  }) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/chats/rooms/create/",
        method: "POST",
        body: {"friend_id": friendId},
      );
    } catch (e) {
      print("[ERROR] 채팅방 생성 중 오류 발생: $e");
      return {"error": "서버 오류가 발생했습니다."};
    }
  }

  // 채팅 메시지 목록 조회
  static Future<Map<String, dynamic>> getChatMessages({
    required String roomId,
    String? lastMessageId,
  }) async {
    try {
      String endpoint = "/api/chats/rooms/$roomId/messages/";
      if (lastMessageId != null) {
        endpoint += "?last_message_id=$lastMessageId";
      }

      return await ApiService.sendRequest(
        endpoint: endpoint,
        method: "GET",
      );
    } catch (e) {
      print("[ERROR] 채팅 메시지 목록 조회 중 오류 발생: $e");
      return {"error": "서버 오류가 발생했습니다."};
    }
  }

  // 채팅 메시지 전송
  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
  }) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/chats/rooms/$roomId/messages/",
        method: "POST",
        body: {"content": content},
      );
    } catch (e) {
      print("[ERROR] 채팅 메시지 전송 중 오류 발생: $e");
      return {"error": "서버 오류가 발생했습니다."};
    }
  }
}