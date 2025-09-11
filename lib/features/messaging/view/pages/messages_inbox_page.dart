import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/messaging/services/messaging_service.dart';
import 'package:quickhire/features/messaging/models/conversation_model.dart';
import 'package:quickhire/features/messaging/view/pages/chat_page.dart';
import 'package:quickhire/features/messaging/view/widgets/new_chat_modal.dart';

class MessagesInboxPage extends StatefulWidget {
  const MessagesInboxPage({super.key});

  @override
  State<MessagesInboxPage> createState() => _MessagesInboxPageState();
}

class _MessagesInboxPageState extends State<MessagesInboxPage> {
  double _headerHeight = 0;
  final double searchBarHeight = 74.0;
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Update UI for clear button visibility
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredConversations = _allConversations;
      } else {
        _filteredConversations =
            _allConversations.where((conversation) {
              final name = conversation.name?.toLowerCase() ?? '';
              final lastMessage = conversation.lastMessage.toLowerCase();
              return name.contains(_searchQuery) ||
                  lastMessage.contains(_searchQuery);
            }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredConversations = _allConversations;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  @override
  Widget build(BuildContext context) {
    _headerHeight = MediaQuery.of(context).size.height * 0.235;

    return Scaffold(
      backgroundColor: Palette.background,
      body: Stack(
        children: [
          // Background color split
          Container(
            height: _headerHeight,
            width: double.infinity,
            color: Palette.primary,
          ),
          // Main content with padding for header and search bar
          Padding(
            padding: EdgeInsets.only(
              top: _headerHeight + searchBarHeight / 2 + 5,
            ),
            child: _buildMessagesList(),
          ),
          // Fixed header content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Messages",
                        style: TextStyle(
                          fontSize: 32,
                          color: Palette.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const NewChatModal(),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Palette.white.withAlpha(60),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.add, color: Palette.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search bar at intersection
          Positioned(
            top: _headerHeight - searchBarHeight / 2,
            left: 24,
            right: 24,
            child: Container(
              height: searchBarHeight,
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Palette.imagePlaceholder.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Palette.subtitle, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          color: Palette.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search conversations...",
                          hintStyle: TextStyle(
                            color: Palette.subtitle,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.clear,
                            color: Palette.subtitle,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Unread count text positioned outside container
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0),
      child: StreamBuilder<List<Conversation>>(
        stream: _messagingService.getConversations(),
        builder: (context, snapshot) {
          // Check if user is authenticated
          if (FirebaseAuth.instance.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Palette.subtitle),
                  const SizedBox(height: 16),
                  Text(
                    'Please log in to view messages',
                    style: TextStyle(color: Palette.subtitle, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Palette.subtitle),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading conversations',
                    style: TextStyle(color: Palette.subtitle, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Palette.subtitle, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          // Update the conversations lists when data changes
          if (_allConversations != conversations) {
            _allConversations = conversations;
            // Apply current search filter
            if (_searchQuery.isEmpty) {
              _filteredConversations = _allConversations;
            } else {
              _filteredConversations =
                  _allConversations.where((conversation) {
                    final name = conversation.name?.toLowerCase() ?? '';
                    final lastMessage = conversation.lastMessage.toLowerCase();
                    return name.contains(_searchQuery) ||
                        lastMessage.contains(_searchQuery);
                  }).toList();
            }
          }

          // Use filtered conversations for display
          final displayConversations = _filteredConversations;

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Palette.subtitle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: Palette.subtitle,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button above to start a new conversation!',
                    style: TextStyle(color: Palette.subtitle, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const NewChatModal(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.primary.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Palette.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Start New Chat',
                            style: TextStyle(
                              color: Palette.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

          // Show "No results found" when search returns empty but conversations exist
          if (displayConversations.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Palette.subtitle),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations found',
                    style: TextStyle(
                      color: Palette.subtitle,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with a different name or keyword',
                    style: TextStyle(color: Palette.subtitle, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: displayConversations.length,
            itemBuilder: (context, index) {
              final conversation = displayConversations[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildConversationCard(conversation),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    return GestureDetector(
      onTap: () async {
        await LoadingService.runWithLoading(context, () async {
          // Brief loading delay for better UX
          await Future.delayed(const Duration(milliseconds: 300));
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatPage(
                    conversationId: conversation.id,
                    otherUserName: conversation.name ?? 'Unknown User',
                    otherUserProfilePicture: conversation.profilePicture,
                  ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.primary.withAlpha(50), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.primary.withAlpha(30),
                border: Border.all(color: Palette.primary, width: 2),
              ),
              child:
                  conversation.profilePicture != null
                      ? ClipOval(
                        child: Image.network(
                          conversation.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 25,
                                color: Palette.primary,
                              ),
                        ),
                      )
                      : const Icon(
                        Icons.person,
                        size: 25,
                        color: Palette.primary,
                      ),
            ),
            const SizedBox(width: 12),

            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                conversation.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(conversation.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              !conversation.isRead
                                  ? Palette.primary
                                  : Palette.subtitle,
                          fontWeight:
                              !conversation.isRead
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                !conversation.isRead
                                    ? Colors.black87
                                    : Palette.subtitle,
                            fontWeight:
                                !conversation.isRead
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!conversation.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Palette.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
