import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/chat/domain/models/chat_room_model.dart';
import 'package:hubble/features/chat/presentation/screens/inbox_screen.dart';
import 'package:hubble/features/chat/presentation/providers/chat_provider.dart';
import 'package:hubble/features/auth/presentation/providers/auth_provider.dart';
import 'package:hubble/features/auth/domain/models/user_model.dart';
import '../auth/presentation/auth_provider_test.dart'; // Import FakeAuthRepository

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  Widget createInboxScreen({
    required List<ChatRoomModel> mockRooms,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        inboxStreamProvider.overrideWith((ref) => Stream.value(mockRooms)),
      ],
      child: const MaterialApp(
        home: InboxScreen(),
      ),
    );
  }

  group('InboxScreen Widget Tests', () {
    late UserModel activeUser;

    setUp(() {
      activeUser = createMockUserModel(
        uid: 'my_uid',
        email: 'user@hubble.com',
        displayName: 'My Name',
        role: UserRole.client,
      );
    });

    testWidgets('Renders empty inbox message layout when conversation lists are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createInboxScreen(mockRooms: []));
      
      // Emit user state after listener starts
      fakeRepository.emitUser(activeUser);

      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('No Messages Yet'), findsOneWidget);
      expect(find.text('Your conversations with clients and providers will magically appear here.'), findsOneWidget);
    });

    testWidgets('Renders list of conversation chat rooms correctly', (WidgetTester tester) async {
      final mockRooms = [
        ChatRoomModel(
          id: 'chat_room_1',
          participants: ['my_uid', 'provider_uid_1'],
          participantNames: {
            'my_uid': 'My Name',
            'provider_uid_1': 'Sarah Contractor',
          },
          lastMessage: 'I can start tomorrow morning.',
          lastUpdated: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createInboxScreen(mockRooms: mockRooms));
      
      // Emit user state after listener starts
      fakeRepository.emitUser(activeUser);

      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.byKey(const Key('inbox_list_view')), findsOneWidget);

      expect(find.text('Sarah Contractor'), findsOneWidget);
      expect(find.text('I can start tomorrow morning.'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
    });
  });
}
