import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/animated_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_presence_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _searchQuery = '';
  final Set<String> _hiddenRoomIds = {};

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.month}/${dt.day}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inboxAsync = ref.watch(inboxStreamProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        centerTitle: false,
        title: Text(
          'Messages',
          style: AppTextStyles.heading1.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkCard : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.edit_note, color: isDark ? Colors.white : Colors.black, size: 24),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NewChatScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
              onRefresh: () async {
                ref.invalidate(inboxStreamProvider);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: inboxAsync.when(
                loading: () => const ShimmerListLoading(),
                error: (err, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    alignment: Alignment.center,
                    child: Text(
                      'Failed to load messages\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                data: (allRooms) {
                  if (allRooms.isEmpty || currentUser == null) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        alignment: Alignment.center,
                        child: _buildEmptyState(isDark),
                      ),
                    );
                  }

                  final rooms = allRooms.where((room) {
                    if (_hiddenRoomIds.contains(room.id)) return false;
                    if (_searchQuery.isEmpty) return true;
                    final myUid = currentUser.uid;
                    final otherUserId = room.participants.firstWhere(
                      (id) => id != myUid,
                      orElse: () => 'UnknownID',
                    );
                    final otherUserName = room.participantNames[otherUserId] ?? 'Hubble User';
                    return otherUserName.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (rooms.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        alignment: Alignment.center,
                        child: Text(
                          'No matches found.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    key: const Key('inbox_list_view'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 40),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final myUid = currentUser.uid;
                      final otherUserId = room.participants.firstWhere(
                        (id) => id != myUid,
                        orElse: () => 'UnknownID',
                      );
                      final otherUserName = room.participantNames[otherUserId] ?? 'Hubble User';
                      final unreadCount = room.getMyUnreadCount(myUid);

                      return Consumer(
                        builder: (context, ref, child) {
                          final presenceAsync = ref.watch(userPresenceProvider(otherUserId));
                          final userModel = presenceAsync.value;
                          final isOnline = userModel?.isOnline ?? false;
                          final profileImageUrl = userModel?.personalInfo.profileImageURL ?? '';

                          return Dismissible(
                            key: Key('dismiss_${room.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red.shade400,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                _hiddenRoomIds.add(room.id);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Conversation hidden')),
                              );
                            },
                            child: InkWell(
                              key: Key('chat_room_tile_${room.id}'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: room.id,
                                      otherUserName: otherUserName,
                                      otherUserId: otherUserId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        if (profileImageUrl.isNotEmpty)
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(profileImageUrl),
                                          )
                                        else
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: AppColors.primaryGradient,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'H',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isOnline)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: Colors.greenAccent.shade400,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  otherUserName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    _formatDateTime(room.lastUpdated),
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      fontSize: 12,
                                                      color: isDark ? Colors.white54 : Colors.black54,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (unreadCount > 0)
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 4),
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.greenAccent.shade400,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        '$unreadCount New',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  room.lastMessage,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTextStyles.bodyMedium.copyWith(
                                                    color: unreadCount > 0 
                                                      ? (isDark ? Colors.white : Colors.black)
                                                      : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 16,
                                                color: isDark ? Colors.white30 : Colors.black26,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return const AnimatedEmptyState(
      icon: Icons.forum_rounded,
      title: 'No Messages Yet',
      subtitle: 'Your conversations with clients and providers will magically appear here.',
    );
  }
}
