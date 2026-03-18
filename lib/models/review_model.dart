import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String photographerId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final double rating;
  final String comment;
  final String? bookingId;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.photographerId,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.rating,
    required this.comment,
    this.bookingId,
    required this.createdAt,
  });

  String get clientInitials {
    final parts = clientName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'photographerId': photographerId,
        'clientId': clientId,
        'clientName': clientName,
        'clientPhotoUrl': clientPhotoUrl,
        'rating': rating,
        'comment': comment,
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) =>
      ReviewModel(
        id: id,
        photographerId: map['photographerId'] as String? ?? '',
        clientId: map['clientId'] as String? ?? '',
        clientName: map['clientName'] as String? ?? '',
        clientPhotoUrl: map['clientPhotoUrl'] as String?,
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        comment: map['comment'] as String? ?? '',
        bookingId: map['bookingId'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
