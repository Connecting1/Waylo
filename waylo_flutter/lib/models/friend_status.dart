enum FriendStatus {
  notFriend,                            // 친구가 아님
  requestSent,                          // 친구 요청을 보낸 상태
  requestReceived,                      // 친구 요청을 받은 상태
  friend                                // 이미 친구인 상태
}

class FriendStatusHelper {
  /// 사용자의 친구 상태를 확인하여 FriendStatus 반환
  static FriendStatus getStatus({
    required List<String> friendIds,                    // 현재 친구 목록 ID 리스트
    required List<Map<String, dynamic>> sentRequests,   // 보낸 친구 요청 목록
    required List<Map<String, dynamic>> receivedRequests, // 받은 친구 요청 목록
    required String userId,                              // 확인할 사용자 ID
  }) {
    if (friendIds.contains(userId)) {
      return FriendStatus.friend;
    }

    if (sentRequests.any((request) => request['to_user_id'] == userId)) {
      return FriendStatus.requestSent;
    }

    if (receivedRequests.any((request) => request['from_user_id'] == userId)) {
      return FriendStatus.requestReceived;
    }

    return FriendStatus.notFriend;
  }
}