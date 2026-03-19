import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';

enum NotificationType {
  bookingConfirmed,
  bookingDeclined,
  bookingRequest,
  newMessage,
  paymentReceived,
  reviewLeft,
  profileView,
  system,
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
      case NotificationType.paymentReceived:
        return NotificationTypes.paymentReceived;
      case NotificationType.reviewLeft:
        return NotificationTypes.reviewLeft;
      case NotificationType.profileView:
        return NotificationTypes.profileView;
      case NotificationType.system:
        return NotificationTypes.system;
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
      case NotificationTypes.newMessage:
        return NotificationType.newMessage;
      case NotificationTypes.paymentReceived:
        return NotificationType.paymentReceived;
      case NotificationTypes.reviewLeft:
        return NotificationType.reviewLeft;
      case NotificationTypes.profileView:
        return NotificationType.profileView;
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
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.paymentReceived:
        return Icons.payments_rounded;
      case NotificationType.reviewLeft:
        return Icons.star_rounded;
      case NotificationType.profileView:
        return Icons.visibility_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
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
      case NotificationType.newMessage:
        return const Color(0xFFC62828);
      case NotificationType.paymentReceived:
        return const Color(0xFF2E7D32);
      case NotificationType.reviewLeft:
        return const Color(0xFFFFB300);
      case NotificationType.profileView:
        return const Color(0xFF1565C0);
      case NotificationType.system:
        return const Color(0xFF880E4F);
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
      case NotificationType.newMessage:
        return const Color(0xFFFFEBEE);
      case NotificationType.paymentReceived:
        return const Color(0xFFE8F5E9);
      case NotificationType.reviewLeft:
        return const Color(0xFFFFF8E1);
      case NotificationType.profileView:
        return const Color(0xFFE3F2FD);
      case NotificationType.system:
        return const Color(0xFFFCE4EC);
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
