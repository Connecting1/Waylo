// lib/models/friend_status.dart
enum FriendStatus {
  notFriend,      // 친구가 아님
  requestSent,    // 친구 요청 보냄
  requestReceived,// 친구 요청 받음
  friend          // 이미 친구
}

class FriendStatusHelper {
  static FriendStatus getStatus({
    required List<String> friendIds,
    required List<Map<String, dynamic>> sentRequests,
    required List<Map<String, dynamic>> receivedRequests,
    required String userId,
  }) {
    // 이미 친구인지 확인
    if (friendIds.contains(userId)) {
      return FriendStatus.friend;
    }

    // 보낸 친구 요청이 있는지 확인
    if (sentRequests.any((request) => request['to_user_id'] == userId)) {
      return FriendStatus.requestSent;
    }

    // 받은 친구 요청이 있는지 확인
    if (receivedRequests.any((request) => request['from_user_id'] == userId)) {
      return FriendStatus.requestReceived;
    }

    // 아무 관계 없음
    return FriendStatus.notFriend;
  }
}