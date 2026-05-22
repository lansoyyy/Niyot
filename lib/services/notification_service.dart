import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_constants.dart';
import '../models/notification_model.dart';

/// In-app notifications stored under `users/{uid}/notifications` (Firestore only).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// No FCM — notifications are created in Firestore when app events occur.
  Future<void> init() async {}

  // ─── Notification Stream ──────────────────────────────────────────────────

  Stream<List<NotificationModel>> notificationsStream(String userId) =>
      _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.notifications)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => NotificationModel.fromMap(d.id, d.data()))
                .toList(),
          );

  Stream<int> unreadCountStream(String userId) => _firestore
      .collection(FirebaseCollections.users)
      .doc(userId)
      .collection(FirebaseCollections.notifications)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> createNotification(NotificationModel notification) async {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(notification.userId)
        .collection(FirebaseCollections.notifications)
        .add(notification.toMap());
  }

  Future<void> markRead(String userId, String notificationId) async {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.notifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllRead(String userId) async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.notifications)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── Convenience Creators ─────────────────────────────────────────────────

  Future<void> createBookingRequestNotification({
    required String photographerId,
    required String clientName,
    required String bookingId,
    required DateTime scheduledDate,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: photographerId,
          title: 'New Booking Request',
          body:
              '$clientName wants to book a session on ${_formatDate(scheduledDate)}.',
          type: NotificationType.bookingRequest,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createBookingConfirmedNotification({
    required String clientId,
    required String photographerName,
    required String bookingId,
    required DateTime scheduledDate,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: clientId,
          title: 'Booking Confirmed!',
          body:
              '$photographerName has confirmed your session on ${_formatDate(scheduledDate)}.',
          type: NotificationType.bookingConfirmed,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createBookingDeclinedNotification({
    required String clientId,
    required String photographerName,
    required String bookingId,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: clientId,
          title: 'Booking Declined',
          body: '$photographerName is unavailable for your requested session.',
          type: NotificationType.bookingDeclined,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createBookingExpiredNotification({
    required String userId,
    required String bookingId,
    required bool isPhotographer,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: userId,
          title: 'Booking Request Expired',
          body: isPhotographer
              ? 'A pending booking request has expired.'
              : 'Your booking request has expired.',
          type: NotificationType.bookingExpired,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createNewMessageNotification({
    required String recipientId,
    required String senderName,
    required String conversationId,
    required String messagePreview,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: recipientId,
          title: 'New Message from $senderName',
          body: messagePreview,
          type: NotificationType.newMessage,
          relatedId: conversationId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createPaymentReceivedNotification({
    required String photographerId,
    required String clientName,
    required int amount,
    required String bookingId,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: photographerId,
          title: 'Payment Received',
          body:
              'You\'ve received a cash payment confirmation from $clientName.',
          type: NotificationType.paymentReceived,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createPhotosDeliveredNotification({
    required String clientId,
    required String photographerName,
    required String bookingId,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: clientId,
          title: 'Photos Delivered',
          body:
              '$photographerName sent your session photos. Tap to view the gallery link.',
          type: NotificationType.photosDelivered,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createBookingCancelledNotification({
    required String recipientId,
    required String bookingId,
    required bool cancelledByPhotographer,
    String? reason,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: recipientId,
          title: cancelledByPhotographer
              ? 'Cancelled by photographer'
              : 'Cancelled by client',
          body: cancelledByPhotographer
              ? 'The photographer cancelled your booking.${reason != null && reason.isNotEmpty ? ' Reason: $reason' : ''}'
              : 'The client cancelled this booking.${reason != null && reason.isNotEmpty ? ' Reason: $reason' : ''}',
          type: NotificationType.bookingCancelled,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createRescheduleRequestNotification({
    required String recipientId,
    required String requesterName,
    required String bookingId,
    required DateTime scheduledDate,
    required String scheduledTime,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: recipientId,
          title: 'Reschedule Request',
          body:
              '$requesterName requested a new time: ${_formatDate(scheduledDate)} at $scheduledTime. Tap to review.',
          type: NotificationType.rescheduleRequest,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createRescheduleConfirmedNotification({
    required String recipientId,
    required String changerName,
    required String bookingId,
    required DateTime scheduledDate,
    required String scheduledTime,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: recipientId,
          title: 'Booking Rescheduled',
          body:
              '$changerName updated the session to ${_formatDate(scheduledDate)} at $scheduledTime.',
          type: NotificationType.rescheduleConfirmed,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createReviewNotification({
    required String photographerId,
    required String clientName,
    required double rating,
    required String bookingId,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: photographerId,
          title: 'New Review!',
          body: '$clientName left a ${rating.toStringAsFixed(1)}-star review.',
          type: NotificationType.reviewLeft,
          relatedId: bookingId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
