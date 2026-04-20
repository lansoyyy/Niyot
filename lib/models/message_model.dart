import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'file' | 'custom_offer'
  final DateTime timestamp;
  final bool isRead;
  // Custom offer fields (only set when mediaType == 'custom_offer')
  final String? offerName;
  final int? offerPrice;
  final DateTime? offerDateTime;
  final String? offerStatus; // null | 'accepted' | 'declined'
  final DateTime? offerExpiresAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.timestamp,
    required this.isRead,
    this.offerName,
    this.offerPrice,
    this.offerDateTime,
    this.offerStatus,
    this.offerExpiresAt,
  });

  bool get isCustomOffer => mediaType == 'custom_offer';
  bool get isOfferExpired =>
      isCustomOffer && offerExpiresAt != null && DateTime.now().isAfter(offerExpiresAt!);
  bool get isOfferPending => isCustomOffer && offerStatus == null && !isOfferExpired;

  bool isSentBy(String userId) => senderId == userId;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': isRead,
    if (offerName != null) 'offerName': offerName,
    if (offerPrice != null) 'offerPrice': offerPrice,
    if (offerDateTime != null) 'offerDateTime': Timestamp.fromDate(offerDateTime!),
    if (offerStatus != null) 'offerStatus': offerStatus,
    if (offerExpiresAt != null) 'offerExpiresAt': Timestamp.fromDate(offerExpiresAt!),
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
        offerName: map['offerName'] as String?,
        offerPrice: (map['offerPrice'] as num?)?.toInt(),
        offerDateTime: (map['offerDateTime'] as Timestamp?)?.toDate(),
        offerStatus: map['offerStatus'] as String?,
        offerExpiresAt: (map['offerExpiresAt'] as Timestamp?)?.toDate(),
      );

  MessageModel copyWith({String? offerStatus}) => MessageModel(
        id: id,
        senderId: senderId,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        timestamp: timestamp,
        isRead: isRead,
        offerName: offerName,
        offerPrice: offerPrice,
        offerDateTime: offerDateTime,
        offerStatus: offerStatus ?? this.offerStatus,
        offerExpiresAt: offerExpiresAt,
      );
}
