import 'package:flutter/material.dart';
import 'package:waylo_flutter/services/api/chat_api.dart';
import 'dart:async';

import '../services/api/api_service.dart';

class ChatRoom {
  final String id;
  final String friendId;
  final String friendName;
  final String friendProfileImage;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

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
        print("[ERROR] 메시지 시간 파싱 오류: $e");
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

  // 프로필 이미지 URL 변환 (기존 패턴과 일치)
  String get fullFriendProfileImageUrl {
    if (friendProfileImage.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (friendProfileImage.startsWith('http')) return friendProfileImage;

    // 상대 경로를 전체 URL로 변환 - ApiService.baseUrl 사용
    if (friendProfileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$friendProfileImage";
    }

    return friendProfileImage;
  }
}

class ChatMessage {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final bool isRead;

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

class ChatProvider with ChangeNotifier {
  List<ChatRoom> _rooms = [];
  Map<String, List<ChatMessage>> _messages = {}; // 채팅방별 메시지
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String _errorMessage = '';
  Timer? _refreshTimer;

  // 상태 getter
  List<ChatRoom> get rooms => _rooms;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String get errorMessage => _errorMessage;

  // 채팅방의 메시지 가져오기
  List<ChatMessage> getMessages(String roomId) {
    return _messages[roomId] ?? [];
  }

  // 채팅방 목록 로드
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
      print("[ERROR] 채팅방 목록 로드 중 오류: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 채팅방 생성
  Future<String?> createChatRoom(String friendId) async {
    try {
      final response = await ChatApi.createChatRoom(friendId: friendId);

      if (!response.containsKey('error')) {
        // 채팅방 생성 성공 후 목록 새로고침
        await loadChatRooms();
        return response['room_id'];
      } else {
        _errorMessage = response['error'] ?? '채팅방을 생성하는데 실패했습니다';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '채팅방을 생성하는 중 오류가 발생했습니다';
      print("[ERROR] 채팅방 생성 중 오류: $e");
      notifyListeners();
      return null;
    }
  }

  // 채팅 메시지 로드
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
      print("[ERROR] 메시지 로드 중 오류: $e");
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // 메시지 전송
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

          // 메시지 목록에 추가
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
      print("[ERROR] 메시지 전송 중 오류: $e");
      notifyListeners();
    }

    return false;
  }

  // 자동 주기적 메시지 로드 시작
  void startAutoRefresh(String roomId, {Duration duration = const Duration(seconds: 10)}) {
    stopAutoRefresh(); // 이전 타이머 중지

    _refreshTimer = Timer.periodic(duration, (timer) {
      loadMessages(roomId);
    });
  }

  // 자동 메시지 로드 중지
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // 에러 메시지 초기화
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