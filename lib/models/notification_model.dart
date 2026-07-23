import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';

enum NotificationType {
  bookingConfirmed,
  bookingDeclined,
  bookingRequest,
  bookingExpired,
  bookingCancelled,
  rescheduleRequest,
  rescheduleConfirmed,
  newMessage,
  customOffer,
  offerAccepted,
  paymentReceived,
  photosDelivered,
  reviewLeft,
  profileView,
  system,
  contentReported,
  userBlocked,
}

extension NotificationTypeX on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.bookingConfirmed:
        return NotificationTypes.bookingConfirmed;
      case NotificationType.bookingDeclined:
        return NotificationTypes.bookingDeclined;
      case NotificationType.bookingRequest:
        return NotificationTypes.bookingRequest;
      case NotificationType.newMessage:
        return NotificationTypes.newMessage;
      case NotificationType.customOffer:
        return NotificationTypes.customOffer;
      case NotificationType.offerAccepted:
        return NotificationTypes.offerAccepted;
      case NotificationType.paymentReceived:
        return NotificationTypes.paymentReceived;
      case NotificationType.bookingExpired:
        return NotificationTypes.bookingExpired;
      case NotificationType.bookingCancelled:
        return NotificationTypes.bookingCancelled;
      case NotificationType.rescheduleRequest:
        return NotificationTypes.rescheduleRequest;
      case NotificationType.rescheduleConfirmed:
        return NotificationTypes.rescheduleConfirmed;
      case NotificationType.reviewLeft:
        return NotificationTypes.reviewLeft;
      case NotificationType.profileView:
        return NotificationTypes.profileView;
      case NotificationType.photosDelivered:
        return NotificationTypes.photosDelivered;
      case NotificationType.system:
        return NotificationTypes.system;
      case NotificationType.contentReported:
        return NotificationTypes.contentReported;
      case NotificationType.userBlocked:
        return NotificationTypes.userBlocked;
    }
  }

  static NotificationType fromValue(String value) {
    switch (value) {
      case NotificationTypes.bookingConfirmed:
        return NotificationType.bookingConfirmed;
      case NotificationTypes.bookingDeclined:
        return NotificationType.bookingDeclined;
      case NotificationTypes.bookingRequest:
        return NotificationType.bookingRequest;
      case NotificationTypes.bookingExpired:
        return NotificationType.bookingExpired;
      case NotificationTypes.bookingCancelled:
        return NotificationType.bookingCancelled;
      case NotificationTypes.rescheduleRequest:
        return NotificationType.rescheduleRequest;
      case NotificationTypes.rescheduleConfirmed:
        return NotificationType.rescheduleConfirmed;
      case NotificationTypes.newMessage:
        return NotificationType.newMessage;
      case NotificationTypes.customOffer:
        return NotificationType.customOffer;
      case NotificationTypes.offerAccepted:
        return NotificationType.offerAccepted;
      case NotificationTypes.paymentReceived:
        return NotificationType.paymentReceived;
      case NotificationTypes.photosDelivered:
        return NotificationType.photosDelivered;
      case NotificationTypes.reviewLeft:
        return NotificationType.reviewLeft;
      case NotificationTypes.profileView:
        return NotificationType.profileView;
      case NotificationTypes.contentReported:
        return NotificationType.contentReported;
      case NotificationTypes.userBlocked:
        return NotificationType.userBlocked;
      default:
        return NotificationType.system;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.bookingConfirmed:
        return Icons.check_circle_rounded;
      case NotificationType.bookingDeclined:
        return Icons.cancel_rounded;
      case NotificationType.bookingRequest:
        return Icons.calendar_today_rounded;
      case NotificationType.bookingExpired:
        return Icons.timer_off_rounded;
      case NotificationType.bookingCancelled:
        return Icons.event_busy_rounded;
      case NotificationType.rescheduleRequest:
        return Icons.edit_calendar_rounded;
      case NotificationType.rescheduleConfirmed:
        return Icons.event_available_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.customOffer:
        return Icons.local_offer_rounded;
      case NotificationType.offerAccepted:
        return Icons.handshake_rounded;
      case NotificationType.paymentReceived:
        return Icons.payments_rounded;
      case NotificationType.photosDelivered:
        return Icons.photo_library_rounded;
      case NotificationType.reviewLeft:
        return Icons.star_rounded;
      case NotificationType.profileView:
        return Icons.visibility_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      case NotificationType.contentReported:
        return Icons.flag_rounded;
      case NotificationType.userBlocked:
        return Icons.block_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.bookingConfirmed:
        return const Color(0xFF56AB2F);
      case NotificationType.bookingDeclined:
        return const Color(0xFFC62828);
      case NotificationType.bookingRequest:
        return const Color(0xFFFF6D00);
      case NotificationType.bookingExpired:
        return const Color(0xFF9E9E9E);
      case NotificationType.bookingCancelled:
        return const Color(0xFFC62828);
      case NotificationType.rescheduleRequest:
        return const Color(0xFF1976D2);
      case NotificationType.rescheduleConfirmed:
        return const Color(0xFF2E7D32);
      case NotificationType.newMessage:
        return const Color(0xFFC62828);
      case NotificationType.customOffer:
        return const Color(0xFF6A1B9A);
      case NotificationType.offerAccepted:
        return const Color(0xFF2E7D32);
      case NotificationType.paymentReceived:
        return const Color(0xFF2E7D32);
      case NotificationType.photosDelivered:
        return const Color(0xFF1565C0);
      case NotificationType.reviewLeft:
        return const Color(0xFFFFB300);
      case NotificationType.profileView:
        return const Color(0xFF1565C0);
      case NotificationType.system:
        return const Color(0xFF880E4F);
      case NotificationType.contentReported:
        return const Color(0xFFFF6D00);
      case NotificationType.userBlocked:
        return const Color(0xFFC62828);
    }
  }

  Color get bgColor {
    switch (this) {
      case NotificationType.bookingConfirmed:
        return const Color(0xFFE8F5E9);
      case NotificationType.bookingDeclined:
        return const Color(0xFFFFEBEE);
      case NotificationType.bookingRequest:
        return const Color(0xFFFFF3E0);
      case NotificationType.bookingExpired:
        return const Color(0xFFF5F5F5);
      case NotificationType.bookingCancelled:
        return const Color(0xFFFFEBEE);
      case NotificationType.rescheduleRequest:
        return const Color(0xFFE3F2FD);
      case NotificationType.rescheduleConfirmed:
        return const Color(0xFFE8F5E9);
      case NotificationType.newMessage:
        return const Color(0xFFFFEBEE);
      case NotificationType.customOffer:
        return const Color(0xFFF3E5F5);
      case NotificationType.offerAccepted:
        return const Color(0xFFE8F5E9);
      case NotificationType.paymentReceived:
        return const Color(0xFFE8F5E9);
      case NotificationType.photosDelivered:
        return const Color(0xFFE3F2FD);
      case NotificationType.reviewLeft:
        return const Color(0xFFFFF8E1);
      case NotificationType.profileView:
        return const Color(0xFFE3F2FD);
      case NotificationType.system:
        return const Color(0xFFFCE4EC);
      case NotificationType.contentReported:
        return const Color(0xFFFFF3E0);
      case NotificationType.userBlocked:
        return const Color(0xFFFFEBEE);
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId; // bookingId, conversationId, etc.
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.value,
    'relatedId': relatedId,
    'isRead': isRead,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) =>
      NotificationModel(
        id: id,
        userId: map['userId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: NotificationTypeX.fromValue(map['type'] as String? ?? ''),
        relatedId: map['relatedId'] as String?,
        isRead: map['isRead'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    body: body,
    type: type,
    relatedId: relatedId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
