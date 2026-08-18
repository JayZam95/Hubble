import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastUpdated;
  final Map<String, bool> typingStatus;
  final Map<String, int> unreadCounts;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastUpdated,
    this.typingStatus = const {},
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
    
    typingStatus.forEach((userId, isTyping) {
      map['typing_$userId'] = isTyping;
    });

    unreadCounts.forEach((userId, unreadCount) {
      map['unreadCount_$userId'] = unreadCount;
    });

    return map;
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String docId) {
    final namesMap = map['participantNames'] as Map<dynamic, dynamic>? ?? {};
    final stringNamesMap = namesMap.map((key, value) => MapEntry(key.toString(), value.toString()));

    final typing = <String, bool>{};
    final unread = <String, int>{};

    map.forEach((key, value) {
      if (key.startsWith('typing_') && value is bool) {
        final userId = key.substring(7);
        typing[userId] = value;
      }
      if (key.startsWith('unreadCount_') && value is num) {
        final userId = key.substring(12);
        unread[userId] = value.toInt();
      }
    });

    return ChatRoomModel(
      id: docId,
      participants: List<String>.from(map['participants'] as List? ?? []),
      participantNames: stringNamesMap,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      typingStatus: typing,
      unreadCounts: unread,
    );
  }
  
  bool isOtherUserTyping(String currentUserId) {
    final other = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    if (other.isEmpty) return false;
    return typingStatus[other] ?? false;
  }

  int getMyUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }
}
