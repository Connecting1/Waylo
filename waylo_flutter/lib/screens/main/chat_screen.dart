import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/chat_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import '../../providers/theme_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadChatRooms();
    });
  }

  /// 프로필 이미지 URL 변환
  String _getFullProfileImageUrl(String profileImage) {
    if (profileImage.isEmpty) return '';

    if (profileImage.startsWith('http')) return profileImage;

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
          appBar: _buildAppBar(),
          body: _buildChatRoomsList(chatProvider),
        );
      },
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
      title: const Text(
        "Chat",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  /// 채팅방 목록 위젯
  Widget _buildChatRoomsList(ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return _buildLoadingState();
    }

    if (chatProvider.errorMessage.isNotEmpty) {
      return _buildErrorState(chatProvider);
    }

    if (chatProvider.rooms.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRoomsList(chatProvider);
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(ChatProvider chatProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(chatProvider.errorMessage),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => chatProvider.loadChatRooms(),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
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

  /// 채팅방 목록 위젯
  Widget _buildRoomsList(ChatProvider chatProvider) {
    return RefreshIndicator(
      onRefresh: () => chatProvider.loadChatRooms(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
        child: ListView.builder(
          itemCount: chatProvider.rooms.length,
          itemBuilder: (context, index) {
            final room = chatProvider.rooms[index];
            return _buildChatRoomItem(room, chatProvider);
          },
        ),
      ),
    );
  }

  /// 개별 채팅방 아이템 위젯
  Widget _buildChatRoomItem(dynamic room, ChatProvider chatProvider) {
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
        leading: _buildProfileAvatar(room),
        title: Text(room.friendName),
        subtitle: Text(
          room.lastMessage ?? 'No messages',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildUnreadBadge(room),
        onTap: () => _navigateToChatRoom(room, chatProvider),
      ),
    );
  }

  /// 프로필 아바타 위젯
  Widget _buildProfileAvatar(dynamic room) {
    return CircleAvatar(
      backgroundImage: room.friendProfileImage.isNotEmpty
          ? NetworkImage(_getFullProfileImageUrl(room.friendProfileImage))
          : null,
      backgroundColor: Colors.grey[300],
      child: room.friendProfileImage.isEmpty
          ? Icon(Icons.person, color: Colors.grey[600])
          : null,
    );
  }

  /// 읽지 않은 메시지 배지 위젯
  Widget? _buildUnreadBadge(dynamic room) {
    if (room.unreadCount <= 0) return null;

    return Container(
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
    );
  }

  /// 채팅방으로 이동
  void _navigateToChatRoom(dynamic room, ChatProvider chatProvider) {
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
      chatProvider.loadChatRooms();
    });
  }
}