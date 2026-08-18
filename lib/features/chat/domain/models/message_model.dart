import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final int status; // 1 = Sent, 2 = Delivered, 3 = Read
  final DateTime? readAt;
  final String? replyToName;
  final String? replyToContent;
  final bool isEdited;
  final String type; // 'text', 'image', 'document', 'audio', 'contact', 'custom_offer'
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = 1,
    this.readAt,
    this.replyToName,
    this.replyToContent,
    this.isEdited = false,
    this.type = 'text',
    this.mediaUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
      if (replyToName != null) 'replyToName': replyToName,
      if (replyToContent != null) 'replyToContent': replyToContent,
      'isEdited': isEdited,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as int? ?? 1,
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      replyToName: map['replyToName'] as String?,
      replyToContent: map['replyToContent'] as String?,
      isEdited: map['isEdited'] as bool? ?? false,
      type: map['type'] as String? ?? (map['imageUrl'] != null ? 'image' : 'text'),
      mediaUrl: map['mediaUrl'] as String? ?? map['imageUrl'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
