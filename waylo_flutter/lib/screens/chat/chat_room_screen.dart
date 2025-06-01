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
  // 텍스트 상수들
  static const String _messageInputHint = 'Type a message';
  static const String _readUpToHereText = ' has read up to here';
  static const String _messageInfoTitle = 'Message Info';
  static const String _timePrefix = 'Time: ';
  static const String _statusPrefix = 'Status: ';
  static const String _readStatus = 'Read';
  static const String _unreadStatus = 'Unread';
  static const String _okButtonText = 'OK';

  // 날짜 포맷 상수들
  static const String _todayTimeFormat = 'HH:mm';
  static const String _currentYearFormat = 'd MMMM, HH:mm';
  static const String _fullDateFormat = 'd MMMM yyyy, HH:mm';

  // 크기 상수들
  static const double _appBarProfileRadius = 20;
  static const double _appBarSpacing = 10;
  static const double _messageListPadding = 8;
  static const double _inputAreaPadding = 8;
  static const double _inputProfileRadius = 16;
  static const double _inputProfilePadding = 8.0;
  static const double _inputProfileIconSize = 20;
  static const double _inputHorizontalPadding = 16;
  static const double _inputVerticalPadding = 10;
  static const double _unreadLineMargin = 8;
  static const double _unreadLinePadding = 8;
  static const double _unreadLineFontSize = 12;
  static const double _unreadLineHeight = 1;
  static const double _messageHorizontalMargin = 8;
  static const double _messageVerticalMargin = 4;
  static const double _messageHorizontalPadding = 12;
  static const double _messageVerticalPadding = 8;
  static const double _messageBorderRadius = 12;
  static const double _messageInfoTitleFontSize = 16;
  static const double _messageInfoTextFontSize = 14;
  static const double _messageInfoSpacing = 8;

  // 비율 상수들
  static const double _messageMaxWidthRatio = 0.7;

  // 애니메이션 상수들
  static const int _scrollAnimationDuration = 300;

  // 투명도 상수들
  static const double _darkShadowOpacity = 0.3;
  static const double _lightShadowOpacity = 0.5;

  // 그림자 상수들
  static const double _shadowSpreadRadius = 1;
  static const double _shadowBlurRadius = 5;

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
          duration: const Duration(milliseconds: _scrollAnimationDuration),
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
            radius: _appBarProfileRadius,
          ),
          const SizedBox(width: _appBarSpacing),
          Text(
            widget.friendName,
            style: const TextStyle(
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
            return const Center(child: CircularProgressIndicator());
          }

          final messages = chatProvider.getMessages(widget.roomId);

          return ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            padding: const EdgeInsets.all(_messageListPadding),
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
      padding: const EdgeInsets.all(_inputAreaPadding),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.darkSurface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(_darkShadowOpacity)
                : Colors.grey.withOpacity(_lightShadowOpacity),
            spreadRadius: _shadowSpreadRadius,
            blurRadius: _shadowBlurRadius,
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _inputProfilePadding),
            child: CircleAvatar(
              radius: _inputProfileRadius,
              backgroundImage: userProvider.profileImage.isNotEmpty
                  ? NetworkImage(userProvider.profileImage)
                  : null,
              child: userProvider.profileImage.isEmpty
                  ? Icon(
                Icons.person,
                size: _inputProfileIconSize,
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
                hintText: _messageInputHint,
                hintStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: _inputHorizontalPadding,
                  vertical: _inputVerticalPadding,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(
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
            margin: const EdgeInsets.symmetric(vertical: _unreadLineMargin),
            child: Row(
              children: [
                Expanded(child: Container(height: _unreadLineHeight, color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _unreadLinePadding),
                  child: Text(
                    '${widget.friendName}$_readUpToHereText',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: _unreadLineFontSize,
                    ),
                  ),
                ),
                Expanded(child: Container(height: _unreadLineHeight, color: Colors.grey[300])),
              ],
            ),
          ),
        Align(
          alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () => _showMessageInfo(message),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * _messageMaxWidthRatio,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: _messageHorizontalMargin,
                  vertical: _messageVerticalMargin,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: _messageHorizontalPadding,
                  vertical: _messageVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: message.isMine ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(_messageBorderRadius),
                    topRight: const Radius.circular(_messageBorderRadius),
                    bottomLeft: Radius.circular(message.isMine ? _messageBorderRadius : 0),
                    bottomRight: Radius.circular(message.isMine ? 0 : _messageBorderRadius),
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
            const Text(
              _messageInfoTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _messageInfoTitleFontSize,
              ),
            ),
            const SizedBox(height: _messageInfoSpacing),
            Text(
              '$_timePrefix${_formatDetailTime(message.createdAt)}',
              style: const TextStyle(fontSize: _messageInfoTextFontSize),
            ),
            if (message.isMine)
              Text(
                '$_statusPrefix${message.isRead ? _readStatus : _unreadStatus}',
                style: const TextStyle(fontSize: _messageInfoTextFontSize),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(_okButtonText),
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
      return DateFormat(_todayTimeFormat).format(dateTime);
    } else if (messageDate.year == today.year) {
      return DateFormat(_currentYearFormat).format(dateTime);
    } else {
      return DateFormat(_fullDateFormat).format(dateTime);
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