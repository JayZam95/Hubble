import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final inboxStreamProvider = StreamProvider.autoDispose<List<ChatRoomModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) {
    return Stream.value(<ChatRoomModel>[]);
  }
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getConversationsStream(user.uid);
});

final chatMessagesStreamProvider = StreamProvider.family.autoDispose<List<MessageModel>, String>((ref, chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessagesStream(chatId);
});
