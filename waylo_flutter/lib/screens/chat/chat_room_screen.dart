// lib/screen/chat/chat_room_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/providers/chat_provider.dart';
import 'package:waylo_flutter/styles/app_styles.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../services/api/api_service.dart';
import 'package:waylo_flutter/providers/user_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String friendName;
  final String friendProfileImage;

  const ChatRoomScreen({
    Key? key,
    required this.roomId,
    required this.friendName,
    required this.friendProfileImage,
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 메시지 로드 및 자동 새로고침 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMessages(widget.roomId);
      chatProvider.startAutoRefresh(widget.roomId);

      // 메시지 로드 후 스크롤을 맨 아래로 이동
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.sendMessage(widget.roomId, message);

    if (success) {
      _scrollToBottom();
    }
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.friendProfileImage.isNotEmpty
                      ? NetworkImage(_getFullProfileImageUrl(widget.friendProfileImage))
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: widget.friendProfileImage.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[600])
                      : null,
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(widget.friendName, style: TextStyle(color: Colors.white),),
              ],
            ),
            backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
                ? AppColors.darkSurface
                : AppColors.primary,
          ),
          body: Column(
            children: [
              // 메시지 목록
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.isLoadingMessages && chatProvider.getMessages(widget.roomId).isEmpty) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final messages = chatProvider.getMessages(widget.roomId);

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      padding: EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        // 현재 메시지가 안 읽었고, 이전 메시지는 읽었을 때만 구분선을 표시
                        final showUnreadLine = index > 0 &&
                            !message.isRead &&
                            messages[index-1].isRead;

                        return _buildMessageItem(message, showUnreadLine);
                      },
                    );
                  },
                ),
              ),

              // 메시지 입력 영역
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 현재 사용자 프로필 이미지
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: userProvider.profileImage.isNotEmpty
                            ? NetworkImage(userProvider.profileImage)
                            : null,
                        child: userProvider.profileImage.isEmpty
                            ? Icon(Icons.person, size: 20)
                            : null,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    // 메시지 입력 필드
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: AppColors.primary),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message, bool showUnreadLine) {
    return Column(
      children: [
        // 읽음 표시 구분선
        if (showUnreadLine)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.grey[300])),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${widget.friendName} has read up to here',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                Expanded(child: Container(height: 1, color: Colors.grey[300])),
              ],
            ),
          ),

        // 메시지 버블
        Align(
          alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () => _showMessageInfo(message),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: message.isMine ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(message.isMine ? 12 : 0),
                    bottomRight: Radius.circular(message.isMine ? 0 : 12),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: message.isMine ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMessageInfo(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Time: ${_formatDetailTime(message.createdAt)}',
              style: TextStyle(fontSize: 14),
            ),
            if (message.isMine)
              Text(
                'Status: ${message.isRead ? 'Read' : 'Unread'}',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDetailTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // 오늘 보낸 메시지는 시간만 표시
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate.year == today.year) {
      // 올해 보낸 메시지는 영국식 일/월 시:분
      return DateFormat('d MMMM, HH:mm').format(dateTime);
    } else {
      // 작년 이전 메시지는 영국식 일/월/연 시:분
      return DateFormat('d MMMM yyyy, HH:mm').format(dateTime);
    }
  }

  @override
  void dispose() {
    // 화면 나갈 때 자동 새로고침 중지
    Provider.of<ChatProvider>(context, listen: false).stopAutoRefresh();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}