import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/chat/domain/models/message_model.dart';
import 'package:hubble/features/chat/presentation/screens/chat_screen.dart';
import 'package:hubble/features/chat/presentation/providers/chat_provider.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hubble/features/chat/domain/models/chat_room_model.dart';
import 'package:hubble/features/chat/data/repositories/chat_repository.dart';
import '../auth/presentation/auth_provider_test.dart'; // Import FakeAuthRepository

void main() {
  Widget createChatScreen({
    required UserModel? mockUser,
    required List<MessageModel> mockMessages,
  }) {
    final fakeRepository = FakeAuthRepository();
    fakeRepository.emitUser(mockUser);

    final fakeFirestore = FakeFirebaseFirestore();

    // Populate conversation document to avoid FakeFirestore error on update()
    fakeFirestore.collection('conversations').doc('dummy_chat_id').set({
      'participants': [mockUser?.uid ?? 'my_uid', 'provider_uid_1'],
      'lastMessage': '',
      'lastUpdated': Timestamp.now(),
    });

    // Populate message documents to avoid FakeFirestore error on update()
    for (var msg in mockMessages) {
      fakeFirestore
          .collection('conversations')
          .doc('dummy_chat_id')
          .collection('messages')
          .doc(msg.id)
          .set(msg.toMap());
    }

    final chatRepository = ChatRepository(firestore: fakeFirestore);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
        chatMessagesStreamProvider('dummy_chat_id').overrideWith((ref) => Stream.value(mockMessages)),
        inboxStreamProvider.overrideWith((ref) => Stream.value(<ChatRoomModel>[])),
      ],
      child: const MaterialApp(
        home: ChatScreen(
          chatId: 'dummy_chat_id',
          otherUserName: 'Sarah Contractor',
          otherUserId: 'provider_uid_1',
        ),
      ),
    );
  }

  group('ChatScreen Widget Tests', () {
    late UserModel activeUser;

    setUp(() {
      activeUser = createMockUserModel(
        uid: 'my_uid',
        email: 'user@hubble.com',
        displayName: 'My Name',
        role: UserRole.client,
      );
    });

    testWidgets('Renders empty list placeholder when messages are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createChatScreen(mockUser: activeUser, mockMessages: []));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Contractor'), findsOneWidget);
      expect(find.text('Start messaging with Sarah Contractor!'), findsOneWidget);
      expect(find.byKey(const Key('chat_input_field')), findsOneWidget);
    });

    testWidgets('Renders message bubbles lists correctly and lets user type text', (WidgetTester tester) async {
      final mockMessages = [
        MessageModel(
          id: 'msg_1',
          senderId: 'provider_uid_1',
          text: 'Hi, when do you need this job done?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        MessageModel(
          id: 'msg_2',
          senderId: 'my_uid',
          text: 'Hi Sarah, tomorrow morning if possible!',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createChatScreen(mockUser: activeUser, mockMessages: mockMessages));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Contractor'), findsOneWidget);
      expect(find.byKey(const Key('chat_messages_list')), findsOneWidget);
      expect(find.text('Hi, when do you need this job done?'), findsOneWidget);
      expect(find.text('Hi Sarah, tomorrow morning if possible!'), findsOneWidget);

      expect(find.byKey(const Key('chat_input_field')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('chat_input_field')), 'Are you free then?');
      await tester.pump();

      expect(find.text('Are you free then?'), findsOneWidget);
      expect(find.byKey(const Key('chat_send_button')), findsOneWidget);
    });
  });
}
