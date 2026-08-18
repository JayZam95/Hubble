import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../wallet/presentation/providers/payment_provider.dart';
import '../../domain/models/message_model.dart';
import '../../domain/models/chat_room_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_background_view.dart';
import 'video_call_screen.dart';
import '../../../auth/presentation/providers/user_presence_provider.dart';
import '../../../profile/presentation/screens/service_portfolio_screen.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'media_preview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../core/utils/image_utils.dart';
import 'dart:convert';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;
  final bool isReferenceCheck;
  final String? referenceProviderName;
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
    this.isReferenceCheck = false,
    this.referenceProviderName,
  });
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode(); /* Background and Themes*/
  String _bgMode = 'dynamic_gradient';
  String? _customImageUri; /* Typing and Debouncing*/
  Timer? _typingDebounce;
  bool _isMeTyping = false; /* Reply and Edit states*/
  MessageModel? _replyingToMessage;
  MessageModel? _editingMessage; /* Voice Notes*/
  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late AnimationController _pulseController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _audioPath; /* Attachment Menu State*/
  bool _showAttachmentMenu = false;
  @override
  void initState() {
    super.initState();
    _loadBackgroundSettings();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (!(!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadBackgroundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgMode = prefs.getString('bg_mode') ?? 'dynamic_gradient';
      _customImageUri = prefs.getString('custom_bg_uri');
    });
  }

  Future<void> _saveBackgroundSetting(String mode, [String? uri]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_mode', mode);
    if (uri != null) {
      await prefs.setString('custom_bg_uri', uri);
    }
    setState(() {
      _bgMode = mode;
      if (uri != null) {
        _customImageUri = uri;
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  } /* --- Send Standard or Media Message ---*/

  void _handleSend() {
    HapticFeedback.lightImpact();
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final myUser = ref.read(authStateProvider).user;
    if (myUser == null) return;
    _messageController.clear();
    _setTypingState(false);
    if (_editingMessage != null) {
      ref
          .read(chatRepositoryProvider)
          .updateMessage(
            chatId: widget.chatId,
            messageId: _editingMessage!.id,
            newText: text,
          );
      setState(() => _editingMessage = null);
    } else {
      ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chatId: widget.chatId,
            senderId: myUser.uid,
            text: text,
            otherUserId: widget.otherUserId,
            replyToName: _replyingToMessage?.senderId == myUser.uid
                ? 'You'
                : (_replyingToMessage != null ? widget.otherUserName : null),
            replyToContent: _replyingToMessage?.text,
          );
      setState(() => _replyingToMessage = null);
    }
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  } /* --- Media and Attachments ---*/

  Future<void> _pickAndSendImage() async {
    setState(() => _showAttachmentMenu = false);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile == null || !mounted) return;
    final myUser = ref.read(authStateProvider).user;
    if (myUser == null || !context.mounted) return;
    final String? caption = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          file: File(pickedFile.path),
          otherUserName: widget.otherUserName,
        ),
      ),
    );
    if (caption == null || !mounted || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Sending image...')));
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMediaMessage(
            chatId: widget.chatId,
            senderId: myUser.uid,
            file: File(pickedFile.path),
            type: 'image',
            text: caption,
            otherUserId: widget.otherUserId,
            replyToName: _replyingToMessage != null
                ? widget.otherUserName
                : null,
            replyToContent: _replyingToMessage?.text,
          );
      if (mounted) setState(() => _replyingToMessage = null);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _sendMockAttachment(String type, String displayName) {
    setState(() => _showAttachmentMenu = false);
    final myUser = ref.read(authStateProvider).user;
    if (myUser == null) return;
    ref
        .read(chatRepositoryProvider)
        .sendMessage(
          chatId: widget.chatId,
          senderId: myUser.uid,
          text: displayName,
          type: type,
          otherUserId: widget.otherUserId,
        );
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _acceptCustomOffer(
    MessageModel msg,
    double price,
    String description,
  ) async {
    final myUser = ref.read(authStateProvider).user;
    if (myUser == null || !mounted || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Processing payment and booking...')),
    );
    try {
      /* 1. Create Booking*/
      final bookingId = await ref
          .read(bookingRepositoryProvider)
          .createBooking(
            clientId: myUser.uid,
            clientName: myUser.displayName,
            providerId: msg.senderId,
            providerName: widget.otherUserName,
            serviceCategory: 'Custom Service',
            agreedPrice: price,
            jobDescription: description,
            scheduledFor: DateTime.now().add(const Duration(days: 1)),
          ); /* 2. Hold funds in Escrow*/
      await ref
          .read(paymentControllerProvider.notifier)
          .holdInEscrow(
            price,
            bookingId,
          ); /* 3. Mark message as accepted in UI*/
      ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chatId: widget.chatId,
            senderId: myUser.uid,
            text: '✅ Custom Offer Accepted: \$${price.toStringAsFixed(2)}',
            type: 'text',
            otherUserId: widget.otherUserId,
          );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Booking created! Funds held in escrow.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showCustomOfferDialog() {
    setState(() => _showAttachmentMenu = false);
    final priceController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Custom Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (e.g. Plumbing Fix)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (\$)',
                prefixText: '\$',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text) ?? 0.0;
              final desc = descController.text.trim();
              if (price > 0 && desc.isNotEmpty) {
                Navigator.pop(context);
                final myUser = ref.read(authStateProvider).user;
                if (myUser != null) {
                  ref
                      .read(chatRepositoryProvider)
                      .sendMessage(
                        chatId: widget.chatId,
                        senderId: myUser.uid,
                        text: 'Custom Offer: $desc',
                        type: 'custom_offer',
                        metadata: {
                          'price': price,
                          'description': desc,
                          'status': 'PENDING',
                        },
                        otherUserId: widget.otherUserId,
                      );
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    _scrollToBottom,
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  } /* --- Voice Recording ---*/

  Future<void> _startVoiceRecording() async {
    _focusNode.unfocus();
    if (await _audioRecorder.hasPermission()) {
      HapticFeedback.lightImpact();
      final dir = await getApplicationDocumentsDirectory();
      _audioPath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _audioPath!);
      setState(() {
        _isRecordingVoice = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecordingVoice = false;
      _recordingSeconds = 0;
    });
  }

  Future<void> _stopAndSendVoiceRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecordingVoice = false;
      _recordingSeconds = 0;
    });
    if (path != null) {
      final myUser = ref.read(authStateProvider).user;
      if (myUser == null) return;
      HapticFeedback.lightImpact();
      ref
          .read(chatRepositoryProvider)
          .sendMediaMessage(
            chatId: widget.chatId,
            senderId: myUser.uid,
            file: File(path),
            type: 'audio',
            otherUserId: widget.otherUserId,
          );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  } /* --- Typing Indicator ---*/

  void _onTextChanged(String text) {
    setState(() {}); // Rebuild to update send button visibility
    if (text.trim().isNotEmpty) {
      _setTypingState(true);
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        _setTypingState(false);
      });
    } else {
      _setTypingState(false);
    }
  }

  void _setTypingState(bool isTyping) {
    if (_isMeTyping == isTyping) return;
    _isMeTyping = isTyping;
    final myUser = ref.read(authStateProvider).user;
    if (myUser == null) return;
    ref
        .read(chatRepositoryProvider)
        .setTypingStatus(
          chatId: widget.chatId,
          myUserId: myUser.uid,
          isTyping: isTyping,
        );
  } /* --- Read status Batch Confirmation ---*/

  void _syncReadStatus(List<MessageModel> messages, String myUserId) {
    final unreadIncomingIds = messages
        .where((m) => m.senderId != myUserId && m.status < 3)
        .map((m) => m.id)
        .toList();
    if (unreadIncomingIds.isNotEmpty) {
      ref
          .read(chatRepositoryProvider)
          .updateMessageStatus(
            chatId: widget.chatId,
            myUserId: myUserId,
            messageIds: unreadIncomingIds,
          );
    }
  } /* --- Settings Sheet ---*/

  void _showBackgroundSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chat Background',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalize the look of this conversation.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildBackgroundSettingsRow(
                title: 'Dynamic Canvas',
                subtitle: 'Smoothly shifting custom abstract gradients',
                icon: Icons.brush_outlined,
                isSelected: _bgMode == 'dynamic_gradient',
                onClick: () {
                  _saveBackgroundSetting('dynamic_gradient');
                  Navigator.pop(context);
                },
              ),
              _buildBackgroundSettingsRow(
                title: 'Dynamic Wallpapers',
                subtitle: 'Images that cycle based on the current hour',
                icon: Icons.schedule_outlined,
                isSelected: _bgMode == 'dynamic_image',
                onClick: () {
                  _saveBackgroundSetting('dynamic_image');
                  Navigator.pop(context);
                },
              ),
              _buildBackgroundSettingsRow(
                title: 'Custom Gallery Photo',
                subtitle: 'Choose any static image from your album',
                icon: Icons.photo_library_outlined,
                isSelected: _bgMode == 'custom_image',
                onClick: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 50,
                  );
                  if (picked != null) {
                    _saveBackgroundSetting('custom_image', picked.path);
                  }
                  if (mounted && context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundSettingsRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onClick,
  }) {
    return ListTile(
      onTap: onClick,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  } /* --- Message Options Modal ---*/

  void _showMessageOptions(MessageModel message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final myUserId = ref.read(authStateProvider).user?.uid;
                        if (myUserId != null) {
                          await FirebaseFirestore.instance
                              .collection('conversations')
                              .doc(widget.chatId)
                              .collection('messages')
                              .doc(message.id)
                              .set({
                                'metadata': {
                                  'reactions': {
                                    myUserId: emoji
                                  }
                                }
                              }, SetOptions(merge: true));
                        }
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = null;
                    _replyingToMessage = message;
                  });
                  _focusNode.requestFocus();
                },
              ),
              if (message.type == 'text')
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              if (message.type == 'image' && message.mediaUrl != null)
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Downloading...')),
                    );
                    try {
                      final response = await Dio().get(
                        message.mediaUrl!,
                        options: Options(responseType: ResponseType.bytes),
                      );
                      await ImageGallerySaverPlus.saveImage(
                        Uint8List.fromList(response.data),
                        quality: 100,
                        name:
                            "hubble_image_${DateTime.now().millisecondsSinceEpoch}",
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Saved to gallery')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to download: $e')),
                        );
                      }
                    }
                  },
                ),
              if (isMe && message.type == 'text')
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _replyingToMessage = null;
                      _editingMessage = message;
                      _messageController.text = message.text;
                    });
                    _focusNode.requestFocus();
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    ref
                        .read(chatRepositoryProvider)
                        .deleteMessage(
                          chatId: widget.chatId,
                          messageId: message.id,
                        );
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final conversationsAsync = ref.watch(inboxStreamProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final presenceAsync = ref.watch(userPresenceProvider(widget.otherUserId));
    final otherUser = presenceAsync.value;
    final profileImageUrl = otherUser?.personalInfo.profileImageURL ?? '';
    final isOnline = otherUser?.isOnline ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (currentUser == null) {
      return const SizedBox(); /* Trigger read sync when new messages load*/
    }
    messagesAsync.whenData(
      (messages) => _syncReadStatus(messages, currentUser.uid),
    ); /* Resolve if other participant is typing*/
    bool isOtherTyping = false;
    conversationsAsync.whenData((rooms) {
      final activeRoom = rooms.firstWhere(
        (r) => r.id == widget.chatId,
        orElse: () => ChatRoomModel(
          id: '',
          participants: [],
          participantNames: {},
          lastMessage: '',
          lastUpdated: DateTime.now(),
        ),
      );
      if (activeRoom.id.isNotEmpty) {
        isOtherTyping = activeRoom.isOtherUserTyping(currentUser.uid);
      }
    });
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            if (otherUser != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ServicePortfolioScreen(providerUser: otherUser),
                ),
              );
            }
          },
          child: Row(
            children: [
              if (profileImageUrl.isNotEmpty)
                HubbleImage(
                  imagePath: profileImageUrl,
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                )
              else
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isOtherTyping
                        ? 'typing...'
                        : (isOnline ? 'online' : 'offline'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isOtherTyping
                          ? Colors.green
                          : (isOnline ? Colors.green : Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VideoCallScreen(channelName: widget.chatId),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'background') {
                _showBackgroundSettingsSheet();
              } else if (value == 'report') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User reported.')));
              } else if (value == 'block') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User blocked.')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'background',
                child: Text('Chat Background'),
              ),
              const PopupMenuItem(value: 'report', child: Text('Report User')),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          /* 1. Dynamic Wallpaper Background*/ Positioned.fill(
            child: ChatBackgroundView(
              bgMode: _bgMode,
              customImageUri: _customImageUri,
            ),
          ),
          /* 2. Chat UI Column*/ SafeArea(
            child: Column(
              children: [
                if (widget.isReferenceCheck)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are asking about their experience with ${widget.referenceProviderName ?? 'this provider'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: messagesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Start messaging with ${widget.otherUserName}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                      );
                      return ListView.builder(
                        key: const Key('chat_messages_list'),
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == currentUser.uid;
                          bool showDateDivider = false;
                          if (index == 0) {
                            showDateDivider = true;
                          } else {
                            final prevMsg = messages[index - 1];
                            final currentDate = DateTime(
                              msg.timestamp.year,
                              msg.timestamp.month,
                              msg.timestamp.day,
                            );
                            final prevDate = DateTime(
                              prevMsg.timestamp.year,
                              prevMsg.timestamp.month,
                              prevMsg.timestamp.day,
                            );
                            if (currentDate != prevDate) {
                              showDateDivider = true;
                            }
                          }
                          Widget messageWidget = _buildMessageItem(
                            msg,
                            isMe,
                            isDark,
                          );
                          if (showDateDivider) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDateDivider(msg.timestamp, isDark),
                                const SizedBox(height: 8),
                                messageWidget,
                              ],
                            );
                          }
                          return messageWidget;
                        },
                      );
                    },
                  ),
                ),
                /* Live Typing Indicator Row*/ if (isOtherTyping)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgDarkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'typing',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildAnimatedDots(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                /* Attachment Drawer*/ if (_showAttachmentMenu)
                  _buildAttachmentMenuOverlay(isDark),
                /* Quote Banner for Replies/Edits*/ if (_replyingToMessage !=
                        null ||
                    _editingMessage != null)
                  _buildQuoteBanner(isDark),
                /* Bottom Input Control Bar*/ _buildInputBar(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);
    String dateString;
    if (msgDate == today) {
      dateString = 'Today';
    } else if (msgDate == yesterday) {
      dateString = 'Yesterday';
    } else {
      dateString = DateFormat('MMM d, yyyy').format(date);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        dateString,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  } /* --- Message Bubble Widget Builder ---*/

  Widget _buildMessageItem(MessageModel msg, bool isMe, bool isDark) {
    final isCentered = msg.status < 3;
    final alignment = isCentered
        ? Alignment.center
        : (isMe ? Alignment.centerRight : Alignment.centerLeft);
    final Color baseColor = msg.type == 'image'
        ? Colors.transparent
        : (msg.type == 'audio'
              ? (isMe ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
              : (isMe
                    ? AppColors.primary
                    : (isDark ? AppColors.bgDarkCard : Colors.white)));
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Dismissible(
          key: Key(msg.id),
          direction: DismissDirection.startToEnd,
          onDismissed: (_) {},
          confirmDismiss: (direction) async {
            HapticFeedback.lightImpact();
            setState(() {
              _editingMessage = null;
              _replyingToMessage = msg;
            });
            _focusNode.requestFocus();
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: const Icon(Icons.reply, color: Colors.grey),
          ),
          child: GestureDetector(
            onLongPress: () => _showMessageOptions(msg, isMe),
            child: Column(
              crossAxisAlignment: isCentered
                  ? CrossAxisAlignment.center
                  : (isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start),
              children: [
                /* "New Message" header for delivered unread messages*/ if (!isMe &&
                    msg.status == 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'New Message',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe || isCentered ? 20 : 4),
                      bottomRight: Radius.circular(
                        isMe && !isCentered ? 4 : 20,
                      ),
                    ),
                    boxShadow: msg.type == 'image'
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe || isCentered ? 20 : 4),
                      bottomRight: Radius.circular(
                        isMe && !isCentered ? 4 : 20,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: msg.type == 'image'
                              ? Colors.transparent
                              : baseColor.withValues(alpha: isMe ? 0.75 : 0.65),
                          border: msg.type == 'image'
                              ? null
                              : Border.all(
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.8,
                                              )),
                                  width: 1,
                                ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(
                              isMe || isCentered ? 20 : 4,
                            ),
                            bottomRight: Radius.circular(
                              isMe && !isCentered ? 4 : 20,
                            ),
                          ),
                        ),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            left: 16,
                            right: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /* Reply Citation*/ if (msg.replyToContent !=
                                  null) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(
                                      left: BorderSide(
                                        color: isMe
                                            ? Colors.white70
                                            : AppColors.primary,
                                        width: 3.5,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.replyToName ?? 'Reply',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: isMe
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        msg.replyToContent!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMe
                                              ? Colors.white60
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              /* Media Renderers*/ if (msg.type == 'image' &&
                                  msg.mediaUrl != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(
                                      isMe || isCentered ? 20 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isMe && !isCentered ? 4 : 20,
                                    ),
                                  ),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 250,
                                    ),
                                    child: HubbleImage(
                                      imagePath: msg.mediaUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (msg.text.isNotEmpty &&
                                    msg.text != "📷 Image") ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                              ] else if (msg.type == 'audio' &&
                                  msg.mediaUrl != null) ...[
                                AudioPlayerWidget(
                                  audioUrl: msg.mediaUrl!,
                                  isMe: isMe,
                                ),
                              ] else if (msg.type == 'document') ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 28,
                                      color: isMe
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (msg.type == 'contact') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.white12
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_pin,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        msg.text,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (msg.type == 'custom_offer') ...[
                                _buildCustomOfferBubble(msg, isMe, isDark),
                              ] else ...[
                                /* Plain Text*/ Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                /* Timestamp & Status Ticks*/ Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(msg.timestamp),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.grey,
                        ),
                      ),
                      if (msg.isEdited) ...[
                        const Text(
                          ' (edited)',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(msg.status),
                      ],
                    ],
                  ),
                ),
                if (msg.metadata?['reactions'] != null && (msg.metadata!['reactions'] as Map).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Wrap(
                      spacing: 4,
                      children: (msg.metadata!['reactions'] as Map).values.map((emoji) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Text(emoji.toString(), style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(int status) {
    if (status == 3) {
      return const Icon(Icons.done_all, size: 14, color: AppColors.primary);
    } else if (status == 2) {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    } else {
      return const Icon(Icons.done, size: 14, color: Colors.grey);
    }
  } /* --- Quote Banner for Edit/Replies ---*/

  Widget _buildQuoteBanner(bool isDark) {
    final isEditing = _editingMessage != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_outlined : Icons.reply,
            color: isEditing ? Colors.orangeAccent : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing
                      ? 'Editing Message'
                      : 'Replying to ${_replyingToMessage?.senderId == ref.read(authStateProvider).user?.uid ? 'Yourself' : widget.otherUserName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEditing ? Colors.orangeAccent : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEditing ? _editingMessage!.text : _replyingToMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
                _editingMessage = null;
                _messageController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomOfferBubble(MessageModel msg, bool isMe, bool isDark) {
    final metadata = msg.metadata ?? {};
    final price = metadata['price'] ?? 0.0;
    final description = metadata['description'] ?? 'Custom Service';
    final status = metadata['status'] ?? 'PENDING';
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? Colors.white30
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: isMe ? Colors.white : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Offer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isMe
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isMe
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          if (status == 'PENDING' && !isMe)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _acceptCustomOffer(
                  msg,
                  price.toDouble(),
                  description,
                ),
                child: const Text('Accept & Pay'),
              ),
            )
          else if (status == 'PENDING' && isMe)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Waiting for client...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Accepted',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  } /* --- Attachment Menu Widget Overlay ---*/

  Widget _buildAttachmentMenuOverlay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAttachmentIcon(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.green,
            onClick: _pickAndSendImage,
          ),
          _buildAttachmentIcon(
            icon: Icons.description,
            label: 'Document',
            color: Colors.blue,
            onClick: () =>
                _sendMockAttachment('document', '📄 Zambian Contract PDF'),
          ),
          _buildAttachmentIcon(
            icon: Icons.contact_phone,
            label: 'Contact',
            color: Colors.orange,
            onClick: () => _sendMockAttachment(
              'contact',
              '📞 Mwansa Chisha\n📱 +260 971 234567',
            ),
          ),
          _buildAttachmentIcon(
            icon: Icons.local_offer,
            label: 'Offer',
            color: Colors.purple,
            onClick: _showCustomOfferDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onClick,
  }) {
    return GestureDetector(
      onTap: onClick,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  } /* --- Input Bar ---*/

  Widget _buildInputBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                if (!_isRecordingVoice) ...[
                  IconButton(
                    icon: Icon(
                      _showAttachmentMenu ? Icons.close : Icons.add,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() {
                        _showAttachmentMenu = !_showAttachmentMenu;
                      });
                    },
                  ),
                ],
                Expanded(
                  child: _isRecordingVoice
                      ? _buildVoiceRecordingDashboard(isDark)
                      : TextFormField(
                          key: const Key('chat_input_field'),
                          focusNode: _focusNode,
                          controller: _messageController,
                          onChanged: _onTextChanged,
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _editingMessage != null
                                ? 'Edit message...'
                                : 'Message...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black38,
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                ),
                _buildSendOrMicButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceRecordingDashboard(bool isDark) {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: _pulseController.value),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          '$minutes:$seconds',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Recording... Release to send',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _cancelVoiceRecording,
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSendOrMicButton(bool isDark) {
    final showSend = _messageController.text.trim().isNotEmpty;
    if (showSend) {
      return IconButton(
        key: const Key('chat_send_button'),
        onPressed: _handleSend,
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _editingMessage != null
                ? Colors.orangeAccent
                : AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _editingMessage != null ? Icons.check : Icons.send,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onLongPressStart: (_) => _startVoiceRecording(),
        onLongPressEnd: (_) => _stopAndSendVoiceRecording(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.mic,
            color: _isRecordingVoice ? Colors.red : Colors.grey,
            size: 28,
          ),
        ),
      );
    }
  } /* --- Bouncing dots animation simulation for Typing Indicator ---*/

  Widget _buildAnimatedDots(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? Colors.white60 : Colors.black45,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
} /* --- Centered Tail Bubble Shape Clipper (Ported from Cyrcles) --- */

class CenteredTailBubbleClipper extends CustomClipper<Path> {
  final bool isMe;
  final bool isCentered;
  CenteredTailBubbleClipper({required this.isMe, required this.isCentered});
  @override
  Path getClip(Size size) {
    final path = Path();
    const double cr = 18.0; /* corner radius*/
    const double tw = 8.0; /* tail width*/
    const double th = 16.0; /* tail height*/
    final double midY = size.height / 2;
    final double tTop = midY - (th / 2);
    final double tTip = midY;
    final double tBot =
        midY +
        (th /
            2); /* If centered (safeStatus < 3), there is no tail, just a rounded rect!*/
    if (isCentered) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(cr),
        ),
      );
      return path;
    }
    if (isMe) {
      /* Start at top-left*/
      path.moveTo(cr, 0); /* Top line to top-right (before tail area)*/
      path.lineTo(size.width - tw - cr, 0); /* Top-right corner*/
      path.quadraticBezierTo(
        size.width - tw,
        0,
        size.width - tw,
        cr,
      ); /* Right side tail (vertically centered)*/
      path.lineTo(size.width - tw, tTop);
      path.quadraticBezierTo(size.width - tw, tTip - 3, size.width, tTip);
      path.quadraticBezierTo(
        size.width - tw,
        tTip + 3,
        size.width - tw,
        tBot,
      ); /* Bottom-right line*/
      path.lineTo(size.width - tw, size.height - cr); /* Bottom-right corner*/
      path.quadraticBezierTo(
        size.width - tw,
        size.height,
        size.width - tw - cr,
        size.height,
      ); /* Bottom line to bottom-left corner*/
      path.lineTo(cr, size.height); /* Bottom-left corner*/
      path.quadraticBezierTo(
        0,
        size.height,
        0,
        size.height - cr,
      ); /* Left line to top-left corner*/
      path.lineTo(0, cr);
      path.quadraticBezierTo(0, 0, cr, 0);
    } else {
      /* Start at top-left (after tail area)*/
      path.moveTo(tw + cr, 0); /* Top line to top-right*/
      path.lineTo(size.width - cr, 0); /* Top-right corner*/
      path.quadraticBezierTo(
        size.width,
        0,
        size.width,
        cr,
      ); /* Right line to bottom-right*/
      path.lineTo(size.width, size.height - cr); /* Bottom-right corner*/
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - cr,
        size.height,
      ); /* Bottom line to bottom-left (before tail area)*/
      path.lineTo(tw + cr, size.height); /* Bottom-left corner*/
      path.quadraticBezierTo(
        tw,
        size.height,
        tw,
        size.height - cr,
      ); /* Left side tail (vertically centered)*/
      path.lineTo(tw, tBot);
      path.quadraticBezierTo(tw, tTip + 3, 0, tTip);
      path.quadraticBezierTo(tw, tTip - 3, tw, tTop); /* Top-left line*/
      path.lineTo(tw, cr); /* Top-left corner*/
      path.quadraticBezierTo(tw, 0, tw + cr, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
} /* --- Audio Player Widget --- */

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 32,
            color: Colors.white,
          ),
          onPressed: () async {
            if (_isPlaying) {
              await _audioPlayer.pause();
            } else {
              if (ImageUtils.isBase64(widget.audioUrl)) {
                final base64Data = widget.audioUrl.split(',').last;
                final bytes = base64Decode(base64Data);
                await _audioPlayer.play(BytesSource(bytes));
              } else {
                await _audioPlayer.play(UrlSource(widget.audioUrl));
              }
            }
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SliderTheme(
              data: const SliderThemeData(
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 2,
              ),
              child: SizedBox(
                width: 120,
                child: Slider(
                  min: 0,
                  max: _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : 1,
                  value: _position.inSeconds.toDouble().clamp(
                    0,
                    _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1,
                  ),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white54,
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
