import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/message_model.dart';
import '../../../../core/utils/image_utils.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Listen to inbox conversations for a specific user.
  Stream<List<ChatRoomModel>> getConversationsStream(String myUid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Listen to messages in a specific conversation.
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Send a message with optional advanced features (replies, edits, media).
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? otherUserId,
    String type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    String? replyToName,
    String? replyToContent,
  }) async {
    final batch = _firestore.batch();

    final messageRef = _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'text': text,
      'type': type,
      'status': 1, // Sent
      'timestamp': FieldValue.serverTimestamp(),
      'mediaUrl': ?mediaUrl,
      'metadata': ?metadata,
      'replyToName': ?replyToName,
      'replyToContent': ?replyToContent,
      'isEdited': false,
    });

    final conversationRef = _firestore.collection('conversations').doc(chatId);
    final updates = <String, dynamic>{
      'lastMessage': type == 'image'
          ? '📷 Image'
          : (type == 'audio'
              ? '🎤 Voice Note'
              : (type == 'document' ? '📄 Document' : text)),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (otherUserId != null) {
      updates['unreadCount_$otherUserId'] = FieldValue.increment(1);
    }

    batch.update(conversationRef, updates);
    await batch.commit();
  }

  /// Uploads a media file (image, document, audio) to Firebase Storage and sends the message.
  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required File file,
    required String type, // 'image', 'document', 'audio'
    String? text, // Optional caption
    String? otherUserId,
    String? replyToName,
    String? replyToContent,
  }) async {
    String? mediaData;
    
    if (type == 'image') {
      mediaData = await ImageUtils.fileToBase64(file);
    } else {
      // For docs/audio, we just base64 encode the whole file. 
      // Note: This might hit the 1MB Firestore limit quickly.
      final bytes = await file.readAsBytes();
      final base64String = base64.encode(bytes);
      final mime = type == 'audio' ? 'audio/m4a' : 'application/pdf';
      mediaData = 'data:$mime;base64,$base64String';
    }

    if (mediaData == null) throw Exception('Failed to process media file');
    
    await sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: text != null && text.isNotEmpty ? text : (type == 'image' ? '📷 Image' : (type == 'audio' ? '🎤 Voice Note' : '📄 Document')),
      otherUserId: otherUserId,
      type: type,
      mediaUrl: mediaData, // We still use mediaUrl field to store the base64 data
      replyToName: replyToName,
      replyToContent: replyToContent,
    );
  }

  /// Mark messages as read and reset local unread count.
  Future<void> updateMessageStatus({
    required String chatId,
    required String myUserId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    final batch = _firestore.batch();
    final conversationRef = _firestore.collection('conversations').doc(chatId);

    for (var msgId in messageIds) {
      final msgRef = conversationRef.collection('messages').doc(msgId);
      batch.update(msgRef, {
        'status': 3, // Read
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    // Reset unread counts for me
    batch.update(conversationRef, {
      'unreadCount_$myUserId': 0,
    });

    await batch.commit();
  }

  /// Toggles the typing indicator status for the user in the conversation.
  Future<void> setTypingStatus({
    required String chatId,
    required String myUserId,
    required bool isTyping,
  }) async {
    await _firestore.collection('conversations').doc(chatId).update({
      'typing_$myUserId': isTyping,
    });
  }

  /// Update/Edit a previously sent message content.
  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText.trim(),
      'isEdited': true,
    });
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Creates a conversation between two users if it doesn't already exist.
  Future<String> createChatRoom({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
  }) async {
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants'] as List? ?? []);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    final docRef = _firestore.collection('conversations').doc();
    final conversationData = {
      'participants': [myUid, otherUid],
      'participantNames': {
        myUid: myName,
        otherUid: otherName,
      },
      'lastMessage': 'Chat room created',
      'lastUpdated': FieldValue.serverTimestamp(),
      'typing_$myUid': false,
      'typing_$otherUid': false,
      'unreadCount_$myUid': 0,
      'unreadCount_$otherUid': 0,
    };

    await docRef.set(conversationData);
    return docRef.id;
  }
}
