import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'file'
  final String type; // 'text' | 'image' | 'custom_offer'
  final Map<String, dynamic>? offerData;
  final String? offerStatus; // 'pending' | 'accepted' | 'declined'
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.type = 'text',
    this.offerData,
    this.offerStatus,
    required this.timestamp,
    required this.isRead,
  });

  bool get isCustomOffer => type == 'custom_offer';
  bool isSentBy(String userId) => senderId == userId;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'type': type,
    'offerData': offerData,
    'offerStatus': offerStatus,
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
        type: map['type'] as String? ?? 'text',
        offerData: map['offerData'] as Map<String, dynamic>?,
        offerStatus: map['offerStatus'] as String?,
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: map['isRead'] as bool? ?? false,
      );

  MessageModel copyWith({String? offerStatus}) => MessageModel(
    id: id,
    senderId: senderId,
    text: text,
    mediaUrl: mediaUrl,
    mediaType: mediaType,
    type: type,
    offerData: offerData,
    offerStatus: offerStatus ?? this.offerStatus,
    timestamp: timestamp,
    isRead: isRead,
  );
}
