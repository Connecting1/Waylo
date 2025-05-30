import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/chat_api.dart';
import 'dart:async';
import '../services/api/api_service.dart';

class ChatRoom {
  final String id;                        // 채팅방의 고유 식별자
  final String friendId;                  // 친구의 사용자 ID
  final String friendName;                // 친구의 사용자명
  final String friendProfileImage;       // 친구의 프로필 이미지 URL
  final String? lastMessage;             // 마지막 메시지 내용
  final DateTime? lastMessageTime;       // 마지막 메시지 시간
  final int unreadCount;                 // 읽지 않은 메시지 수

  ChatRoom({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.friendProfileImage,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    DateTime? lastMessageTime;
    if (json['last_message_time'] != null) {
      try {
        lastMessageTime = DateTime.parse(json['last_message_time']);
      } catch (e) {
        // 파싱 실패 시 null 유지
      }
    }

    return ChatRoom(
      id: json['id'] ?? '',
      friendId: json['friend_id'] ?? '',
      friendName: json['friend_name'] ?? '',
      friendProfileImage: json['friend_profile_image'] ?? '',
      lastMessage: json['last_message'],
      lastMessageTime: lastMessageTime,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  String get fullFriendProfileImageUrl {
    if (friendProfileImage.isEmpty) return '';

    if (friendProfileImage.startsWith('http')) return friendProfileImage;

    if (friendProfileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$friendProfileImage";
    }

    return friendProfileImage;
  }
}

class ChatMessage {
  final String id;                        // 메시지의 고유 식별자
  final String content;                   // 메시지 내용
  final DateTime createdAt;              // 생성 일시
  final bool isMine;                     // 내가 보낸 메시지 여부
  final bool isRead;                     // 읽음 여부

  ChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isMine,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isMine: json['is_mine'] ?? false,
      isRead: json['is_read'] ?? false,
    );
  }
}

/// 채팅방과 메시지를 관리하는 Provider
class ChatProvider with ChangeNotifier {
  List<ChatRoom> _rooms = [];                           // 채팅방 목록
  Map<String, List<ChatMessage>> _messages = {};        // 채팅방별 메시지 목록
  bool _isLoading = false;                              // 채팅방 목록 로딩 상태
  bool _isLoadingMessages = false;                      // 메시지 로딩 상태
  String _errorMessage = '';                            // 에러 메시지
  Timer? _refreshTimer;                                 // 자동 새로고침 타이머

  List<ChatRoom> get rooms => _rooms;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String get errorMessage => _errorMessage;

  /// 특정 채팅방의 메시지 목록 반환
  List<ChatMessage> getMessages(String roomId) {
    return _messages[roomId] ?? [];
  }

  /// 채팅방 목록 로드
  Future<void> loadChatRooms() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await ChatApi.getChatRooms();

      if (!response.containsKey('error')) {
        List<dynamic> roomsData = response['rooms'] ?? [];
        _rooms = roomsData.map((data) => ChatRoom.fromJson(data)).toList();
      } else {
        _errorMessage = response['error'] ?? '채팅방 목록을 불러오는데 실패했습니다';
      }
    } catch (e) {
      _errorMessage = '채팅방 목록을 불러오는 중 오류가 발생했습니다';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 채팅방 생성
  Future<String?> createChatRoom(String friendId) async {
    try {
      final response = await ChatApi.createChatRoom(friendId: friendId);

      if (!response.containsKey('error')) {
        await loadChatRooms();
        return response['room_id'];
      } else {
        _errorMessage = response['error'] ?? '채팅방을 생성하는데 실패했습니다';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '채팅방을 생성하는 중 오류가 발생했습니다';
      notifyListeners();
      return null;
    }
  }

  /// 채팅 메시지 로드
  Future<void> loadMessages(String roomId) async {
    if (_isLoadingMessages) return;

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final response = await ChatApi.getChatMessages(roomId: roomId);

      if (!response.containsKey('error')) {
        List<dynamic> messagesData = response['messages'] ?? [];
        List<ChatMessage> messages = messagesData
            .map((data) => ChatMessage.fromJson(data))
            .toList();

        _messages[roomId] = messages;
      } else {
        _errorMessage = response['error'] ?? '메시지를 불러오는데 실패했습니다';
      }
    } catch (e) {
      _errorMessage = '메시지를 불러오는 중 오류가 발생했습니다';
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// 메시지 전송
  Future<bool> sendMessage(String roomId, String content) async {
    if (content.isEmpty) return false;

    try {
      final response = await ChatApi.sendMessage(
        roomId: roomId,
        content: content,
      );

      if (!response.containsKey('error')) {
        final messageData = response['message'];
        if (messageData != null) {
          final newMessage = ChatMessage.fromJson(messageData);

          if (!_messages.containsKey(roomId)) {
            _messages[roomId] = [];
          }
          _messages[roomId]!.add(newMessage);

          notifyListeners();
          return true;
        }
      } else {
        _errorMessage = response['error'] ?? '메시지 전송에 실패했습니다';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '메시지 전송 중 오류가 발생했습니다';
      notifyListeners();
    }

    return false;
  }

  /// 자동 메시지 새로고침 시작
  void startAutoRefresh(String roomId, {Duration duration = const Duration(seconds: 10)}) {
    stopAutoRefresh();

    _refreshTimer = Timer.periodic(duration, (timer) {
      loadMessages(roomId);
    });
  }

  /// 자동 메시지 새로고침 중지
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}