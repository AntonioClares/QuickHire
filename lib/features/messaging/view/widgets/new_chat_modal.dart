import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/features/messaging/services/user_search_service.dart';
import 'package:quickhire/features/messaging/services/messaging_service.dart';
import 'package:quickhire/features/messaging/view/pages/chat_page.dart';

class NewChatModal extends StatefulWidget {
  const NewChatModal({super.key});

  @override
  State<NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<NewChatModal> {
  final TextEditingController _searchController = TextEditingController();
  final UserSearchService _userSearchService = UserSearchService();
  final MessagingService _messagingService = MessagingService();

  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    final results = await _userSearchService.searchUsers(query);

    // Only update if the search query hasn't changed
    if (_searchQuery == query && mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _startConversation(UserProfile user) async {
    Navigator.pop(context); // Close the modal first

    await LoadingService.runWithLoading(context, () async {
      try {
        final conversationId = await _messagingService.createOrGetConversation(
          user.id,
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatPage(
                    conversationId: conversationId,
                    otherUserName: user.name,
                    otherUserProfilePicture: user.profilePicture,
                  ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          CustomDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to start conversation: ${e.toString()}',
            icon: Icons.error_outline,
            iconColor: Colors.red,
            buttonText: 'OK',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Palette.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Palette.subtitle.withAlpha(100),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Palette.subtitle.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.close, size: 20, color: Palette.subtitle),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.primary.withAlpha(50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search users by name...',
                  hintStyle: TextStyle(color: Palette.subtitle),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Palette.primary),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Search results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Palette.subtitle.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users to start a conversation',
              style: TextStyle(color: Palette.subtitle, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Palette.subtitle.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: Palette.subtitle,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Palette.subtitle, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(user),
        );
      },
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return GestureDetector(
      onTap: () => _startConversation(user),
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
                  user.profilePicture != null
                      ? ClipOval(
                        child: Image.network(
                          user.profilePicture!,
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

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.role != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.role!,
                      style: TextStyle(fontSize: 14, color: Palette.subtitle),
                    ),
                  ],
                ],
              ),
            ),

            // Chat icon
            Icon(Icons.chat_bubble_outline, color: Palette.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
