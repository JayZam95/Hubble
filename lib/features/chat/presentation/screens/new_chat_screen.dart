import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _performSearch(''));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      final results = await repo.searchAllUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _startChat(UserModel otherUser) async {
    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final chatRepo = ref.read(chatRepositoryProvider);
      final chatId = await chatRepo.createChatRoom(
        myUid: currentUser.uid,
        myName: currentUser.displayName,
        otherUid: otherUser.uid,
        otherName: otherUser.displayName,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: otherUser.uid,
              otherUserName: otherUser.displayName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Chat'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for users by name or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppColors.bgDarkCard : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (val) {
                // simple debounce or run immediately
                _performSearch(val);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final isProvider = user.role == UserRole.provider;
                          final hasImage = user.personalInfo.profileImageURL.isNotEmpty;

                          final subtitleText = isProvider 
                              ? (user.providerProfile.professionTitle.isNotEmpty 
                                  ? user.providerProfile.professionTitle 
                                  : 'Service Provider')
                              : 'Client Account';

                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white10 : Colors.grey[200],
                              ),
                              child: hasImage
                                  ? HubbleImage(
                                      imagePath: user.personalInfo.profileImageURL,
                                      width: 50,
                                      height: 50,
                                      borderRadius: BorderRadius.circular(25),
                                    )
                                  : Center(
                                      child: Text(
                                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ),
                            title: Row(
                              children: [
                                Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (user.personalInfo.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Colors.blue, size: 14),
                                ],
                              ],
                            ),
                            subtitle: Text(subtitleText),
                            onTap: () => _startChat(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
