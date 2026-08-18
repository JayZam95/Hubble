import 'package:flutter_test/flutter_test.dart';
import 'package:hubble/features/chat/domain/models/chat_room_model.dart';
import 'package:hubble/features/chat/domain/models/message_model.dart';
import 'dart:async';

// Mock stream provider for Unit Testing chat repository queries
class MockFirestoreStream {
  final _inboxController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _messagesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<ChatRoomModel>> getConversationsStream(String myUid) {
    return _inboxController.stream.map((rawList) {
      return rawList.map((data) => ChatRoomModel.fromMap(data, data['id'] as String)).toList();
    });
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _messagesController.stream.map((rawList) {
      return rawList.map((data) => MessageModel.fromMap(data, data['id'] as String)).toList();
    });
  }

  void emitInbox(List<Map<String, dynamic>> rawInbox) {
    _inboxController.add(rawInbox);
  }

  void emitMessages(List<Map<String, dynamic>> rawMessages) {
    _messagesController.add(rawMessages);
  }

  void dispose() {
    _inboxController.close();
    _messagesController.close();
  }
}

void main() {
  group('ChatRepository Real-Time Stream Mocks', () {
    late MockFirestoreStream mockFirestoreStream;

    setUp(() {
      mockFirestoreStream = MockFirestoreStream();
    });

    tearDown(() {
      mockFirestoreStream.dispose();
    });

    test('getConversationsStream real-time stream returns correct parsed rooms list', () async {
      final stream = mockFirestoreStream.getConversationsStream('my_uid');
      
      final completer = Completer<List<ChatRoomModel>>();
      stream.listen((rooms) {
        if (!completer.isCompleted) completer.complete(rooms);
      });

      // Emit mock raw Firestore items
      mockFirestoreStream.emitInbox([
        {
          'id': 'chat_1',
          'participants': ['my_uid', 'other_uid_1'],
          'participantNames': {
            'my_uid': 'My Name',
            'other_uid_1': 'Sarah M.',
          },
          'lastMessage': 'Hello there!',
          'lastUpdated': null, // fallback in fromMap
        }
      ]);

      final result = await completer.future;
      expect(result.length, 1);
      expect(result.first.id, 'chat_1');
      expect(result.first.lastMessage, 'Hello there!');
      expect(result.first.participantNames['other_uid_1'], 'Sarah M.');
    });

    test('getMessagesStream real-time stream returns correct message list', () async {
      final stream = mockFirestoreStream.getMessagesStream('chat_1');
      
      final completer = Completer<List<MessageModel>>();
      stream.listen((messages) {
        if (!completer.isCompleted) completer.complete(messages);
      });

      // Emit mock raw message structures
      mockFirestoreStream.emitMessages([
        {
          'id': 'msg_1',
          'senderId': 'other_uid_1',
          'text': 'How are you?',
          'timestamp': null,
        },
        {
          'id': 'msg_2',
          'senderId': 'my_uid',
          'text': 'I am fine, thanks!',
          'timestamp': null,
        }
      ]);

      final result = await completer.future;
      expect(result.length, 2);
      expect(result.first.id, 'msg_1');
      expect(result.first.text, 'How are you?');
      expect(result.last.id, 'msg_2');
      expect(result.last.senderId, 'my_uid');
    });
  });
}
