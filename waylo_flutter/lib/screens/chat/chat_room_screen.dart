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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMessages(widget.roomId);
      chatProvider.startAutoRefresh(widget.roomId);
      _scrollToBottom();
    });
  }

  /// 채팅 스크롤을 맨 아래로 이동
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

  /// 메시지 전송 처리
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildMessageList(),
              _buildMessageInput(userProvider),
            ],
          ),
        );
      },
    );
  }

  /// AppBar 구성
  AppBar _buildAppBar() {
    return AppBar(
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
          Text(
            widget.friendName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? AppColors.darkSurface
          : AppColors.primary,
    );
  }

  /// 메시지 목록 위젯
  Widget _buildMessageList() {
    return Expanded(
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

              // 읽음 표시 구분선 조건: 현재 메시지가 안 읽었고, 이전 메시지는 읽었을 때
              final showUnreadLine = index > 0 &&
                  !message.isRead &&
                  messages[index-1].isRead;

              return _buildMessageItem(message, showUnreadLine);
            },
          );
        },
      ),
    );
  }

  /// 메시지 입력 영역 위젯
  Widget _buildMessageInput(UserProvider userProvider) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.darkSurface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: userProvider.profileImage.isNotEmpty
                  ? NetworkImage(userProvider.profileImage)
                  : null,
              child: userProvider.profileImage.isEmpty
                  ? Icon(
                Icons.person,
                size: 20,
                color: themeProvider.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
              )
                  : null,
              backgroundColor: themeProvider.isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey[300],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: AppColors.primary,
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  /// 개별 메시지 아이템 위젯
  Widget _buildMessageItem(ChatMessage message, bool showUnreadLine) {
    return Column(
      children: [
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

  /// 메시지 정보 다이얼로그 표시
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

  /// 메시지 시간 포맷팅
  String _formatDetailTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate.year == today.year) {
      return DateFormat('d MMMM, HH:mm').format(dateTime);
    } else {
      return DateFormat('d MMMM yyyy, HH:mm').format(dateTime);
    }
  }

  @override
  void dispose() {
    Provider.of<ChatProvider>(context, listen: false).stopAutoRefresh();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}