import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'file'
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.timestamp,
    required this.isRead,
  });

  bool isSentBy(String userId) => senderId == userId;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': isRead,
  };

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) =>
      MessageModel(
        id: id,
        senderId: map['senderId'] as String? ?? '',
        text: map['text'] as String? ?? '',
        mediaUrl: map['mediaUrl'] as String?,
        mediaType: map['mediaType'] as String?,
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: map['isRead'] as bool? ?? false,
      );
}
