import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/chat_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import '../../services/api/api_service.dart';
import '../chat/chat_room_screen.dart';

class ChatScreenPage extends StatefulWidget {
  @override
  _ChatScreenPageState createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  @override
  void initState() {
    super.initState();
    // 화면이 생성될 때 채팅방 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadChatRooms();
    });
  }

  String _getFullProfileImageUrl(String profileImage) {
    if (profileImage.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (profileImage.startsWith('http')) return profileImage;

    // 상대 경로를 전체 URL로 변환 - ApiService.baseUrl 사용
    if (profileImage.startsWith('/')) {
      return "${ApiService.baseUrl}$profileImage";
    }

    return profileImage;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            title: const Text(
              "Chat",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true, // Chat 문구를 중앙으로 정렬
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.grey[200],
              ),
            ),
          ),
          body: _buildChatRoomsList(chatProvider),
        );
      },
    );
  }

  Widget _buildChatRoomsList(ChatProvider chatProvider) {
    // 로딩 중
    if (chatProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // 오류 발생
    if (chatProvider.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(chatProvider.errorMessage),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                chatProvider.loadChatRooms();
              },
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // 채팅방 없음
    if (chatProvider.rooms.isEmpty) {
      return Center(
        child: Text(
          'No chat rooms available.\nFind friends and start a conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    // 채팅방 목록
    return RefreshIndicator(
      onRefresh: () => chatProvider.loadChatRooms(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
        child: ListView.builder(
          itemCount: chatProvider.rooms.length,
          itemBuilder: (context, index) {
            final room = chatProvider.rooms[index];
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: room.friendProfileImage.isNotEmpty
                      ? NetworkImage(_getFullProfileImageUrl(room.friendProfileImage))
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: room.friendProfileImage.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[600])
                      : null,
                ),
                title: Text(room.friendName),
                subtitle: Text(
                  room.lastMessage ?? 'No messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: room.unreadCount > 0
                    ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    room.unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                )
                    : null,
                onTap: () {
                  // 채팅방 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        roomId: room.id,
                        friendName: room.friendName,
                        friendProfileImage: room.friendProfileImage,
                      ),
                    ),
                  ).then((_) {
                    // 뒤로 왔을 때 목록 새로고침
                    chatProvider.loadChatRooms();
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}