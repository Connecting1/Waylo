import 'api_service.dart';

class ChatApi {
  /// 채팅방 목록 조회
  static Future<Map<String, dynamic>> getChatRooms() async {
    return await ApiService.sendRequest(
      endpoint: "/api/chats/rooms/",
      method: "GET",
    );
  }

  /// 채팅방 생성 (친구와의 1:1 채팅)
  static Future<Map<String, dynamic>> createChatRoom({
    required String friendId,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/chats/rooms/create/",
      method: "POST",
      body: {"friend_id": friendId},
    );
  }

  /// 채팅 메시지 목록 조회
  static Future<Map<String, dynamic>> getChatMessages({
    required String roomId,
    String? lastMessageId,
  }) async {
    String endpoint = "/api/chats/rooms/$roomId/messages/";
    if (lastMessageId != null) {
      endpoint += "?last_message_id=$lastMessageId";
    }

    return await ApiService.sendRequest(
      endpoint: endpoint,
      method: "GET",
    );
  }

  /// 채팅 메시지 전송
  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/chats/rooms/$roomId/messages/",
      method: "POST",
      body: {"content": content},
    );
  }
}