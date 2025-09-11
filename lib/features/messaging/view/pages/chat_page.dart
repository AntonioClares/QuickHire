import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/messaging/services/messaging_service.dart';
import 'package:quickhire/features/messaging/models/conversation_model.dart';
import 'package:quickhire/features/messaging/view/widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserProfilePicture;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserProfilePicture,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();

  Timer? _typingTimer;
  bool _isCurrentUserTyping = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _messagingService.markConversationAsRead(widget.conversationId);
    _messagingService.markMessagesAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    if (_isCurrentUserTyping) {
      _messagingService.updateTypingStatus(widget.conversationId, false);
    }
    // Mark conversation as read when leaving the chat
    _messagingService.markConversationAsRead(widget.conversationId);
    super.dispose();
  }

  void _onTyping() {
    if (!_isCurrentUserTyping) {
      _isCurrentUserTyping = true;
      _messagingService.updateTypingStatus(widget.conversationId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isCurrentUserTyping) {
        _isCurrentUserTyping = false;
        _messagingService.updateTypingStatus(widget.conversationId, false);
      }
    });
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    // Stop typing indicator
    if (_isCurrentUserTyping) {
      _isCurrentUserTyping = false;
      _messagingService.updateTypingStatus(widget.conversationId, false);
    }

    await _messagingService.sendMessage(widget.conversationId, messageText);

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF5E616F),
                size: 15,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  widget.otherUserProfilePicture != null
                      ? ClipOval(
                        child: Image.network(
                          widget.otherUserProfilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                        ),
                      )
                      : const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  StreamBuilder<Map<String, bool>>(
                    stream: _messagingService.getTypingStatus(
                      widget.conversationId,
                    ),
                    builder: (context, snapshot) {
                      final typingStatus = snapshot.data ?? {};
                      final isOtherUserTyping =
                          typingStatus.entries
                              .where(
                                (entry) =>
                                    entry.key != _currentUserId && entry.value,
                              )
                              .isNotEmpty;

                      return Text(
                        isOtherUserTyping ? 'typing...' : 'Online',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagingService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: Palette.subtitle),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Palette.subtitle, fontSize: 16),
                    ),
                  );
                }

                return StreamBuilder<Map<String, bool>>(
                  stream: _messagingService.getTypingStatus(
                    widget.conversationId,
                  ),
                  builder: (context, typingSnapshot) {
                    final typingStatus = typingSnapshot.data ?? {};
                    final otherUserTyping =
                        typingStatus.entries
                            .where(
                              (entry) =>
                                  entry.key != _currentUserId && entry.value,
                            )
                            .isNotEmpty;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (otherUserTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show typing indicator at the top (index 0 when reversed)
                        if (otherUserTyping && index == 0) {
                          return TypingIndicator(
                            userName: widget.otherUserName,
                            showUserName: true,
                          );
                        }

                        // Adjust index for messages when typing indicator is present
                        final messageIndex =
                            otherUserTyping ? index - 1 : index;
                        final message = messages[messageIndex];
                        final isCurrentUser =
                            message.senderId == _currentUserId;

                        return _buildMessageBubble(message, isCurrentUser);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Message input with SafeArea for bottom padding
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Palette.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (_) => _onTyping(),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Palette.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment:
                    isCurrentUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                children: [
                  if (!isCurrentUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Palette.primary.withAlpha(30),
                        border: Border.all(color: Palette.primary, width: 1),
                      ),
                      child:
                          widget.otherUserProfilePicture != null
                              ? ClipOval(
                                child: Image.network(
                                  widget.otherUserProfilePicture!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.person,
                                            color: Palette.primary,
                                            size: 16,
                                          ),
                                ),
                              )
                              : const Icon(
                                Icons.person,
                                color: Palette.primary,
                                size: 16,
                              ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Palette.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                          bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(
                              color:
                                  isCurrentUser
                                      ? Colors.white.withAlpha(180)
                                      : Palette.subtitle,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
