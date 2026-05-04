import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'file' | 'custom_offer'
  final String type; // 'text' | 'image' | 'custom_offer'
  final Map<String, dynamic>? offerData;
  final String? offerStatus; // null | 'pending' | 'accepted' | 'declined'
  final DateTime timestamp;
  final bool isRead;
  // Custom offer fields
  final String? offerName;
  final int? offerPrice;
  final DateTime? offerDateTime;
  final DateTime? offerExpiresAt;

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
    this.offerName,
    this.offerPrice,
    this.offerDateTime,
    this.offerExpiresAt,
  });

  bool get isCustomOffer =>
      type == 'custom_offer' || mediaType == 'custom_offer';
  bool get isOfferExpired =>
      isCustomOffer &&
      offerExpiresAt != null &&
      DateTime.now().isAfter(offerExpiresAt!);
  bool get isOfferPending =>
      isCustomOffer && offerStatus == null && !isOfferExpired;

  bool isSentBy(String userId) => senderId == userId;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'type': type,
    if (offerData != null) 'offerData': offerData,
    if (offerStatus != null) 'offerStatus': offerStatus,
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': isRead,
    if (offerName != null) 'offerName': offerName,
    if (offerPrice != null) 'offerPrice': offerPrice,
    if (offerDateTime != null)
      'offerDateTime': Timestamp.fromDate(offerDateTime!),
    if (offerExpiresAt != null)
      'offerExpiresAt': Timestamp.fromDate(offerExpiresAt!),
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
        offerName: map['offerName'] as String?,
        offerPrice: (map['offerPrice'] as num?)?.toInt(),
        offerDateTime: (map['offerDateTime'] as Timestamp?)?.toDate(),
        offerExpiresAt: (map['offerExpiresAt'] as Timestamp?)?.toDate(),
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
    offerName: offerName,
    offerPrice: offerPrice,
    offerDateTime: offerDateTime,
    offerExpiresAt: offerExpiresAt,
  );
}
