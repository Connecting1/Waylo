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
  // 텍스트 상수들
  static const String _appBarTitle = "Chat";
  static const String _tryAgainButtonText = "Try Again";
  static const String _emptyStateMessage = "No chat rooms available.\nFind friends and start a conversation!";
  static const String _noMessagesText = "No messages";

  // 폰트 크기 상수들
  static const double _appBarTitleFontSize = 16;
  static const double _emptyStateFontSize = 16;
  static const double _unreadBadgeFontSize = 12;

  // 크기 상수들
  static const double _listPaddingLeft = 10.0;
  static const double _listPaddingTop = 0.0;
  static const double _listPaddingRight = 10.0;
  static const double _listPaddingBottom = 10.0;
  static const double _errorStateSpacing = 16;
  static const double _borderWidth = 1;
  static const double _unreadBadgePadding = 6;

  // 텍스트 스타일 상수들
  static const int _subtitleMaxLines = 1;
  static const TextOverflow _subtitleOverflow = TextOverflow.ellipsis;

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
        _appBarTitle,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: _appBarTitleFontSize,
        ),
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
    return const Center(child: CircularProgressIndicator());
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(ChatProvider chatProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(chatProvider.errorMessage),
          const SizedBox(height: _errorStateSpacing),
          ElevatedButton(
            onPressed: () => chatProvider.loadChatRooms(),
            child: const Text(_tryAgainButtonText),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _emptyStateMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: _emptyStateFontSize,
        ),
      ),
    );
  }

  /// 채팅방 목록 위젯
  Widget _buildRoomsList(ChatProvider chatProvider) {
    return RefreshIndicator(
      onRefresh: () => chatProvider.loadChatRooms(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _listPaddingLeft,
          _listPaddingTop,
          _listPaddingRight,
          _listPaddingBottom,
        ),
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
            width: _borderWidth,
          ),
        ),
      ),
      child: ListTile(
        leading: _buildProfileAvatar(room),
        title: Text(room.friendName),
        subtitle: Text(
          room.lastMessage ?? _noMessagesText,
          maxLines: _subtitleMaxLines,
          overflow: _subtitleOverflow,
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
      padding: const EdgeInsets.all(_unreadBadgePadding),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Text(
        room.unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: _unreadBadgeFontSize,
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