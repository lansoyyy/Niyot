import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_constants.dart';
import '../models/notification_model.dart';
import 'local_notification_helper.dart';

/// In-app Firestore notifications + local system banners (foreground/background).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _local = LocalNotificationHelper.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _watchSub;
  StreamSubscription<User?>? _authSub;
  final Set<String> _knownIds = {};
  bool _seeded = false;
  bool _started = false;

  /// Initializes local notifications, requests permission, and watches Firestore.
  Future<void> init() async {
    await _local.init();
    await _local.requestPermission();

    if (_started) {
      await _restartWatchForCurrentUser();
      return;
    }
    _started = true;

    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        await _stopWatch();
      } else {
        await _startWatch(user.uid);
      }
    });

    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      await _startWatch(current.uid);
    }
  }

  Future<void> _restartWatchForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await _stopWatch();
      return;
    }
    await _startWatch(uid);
  }

  Future<void> _stopWatch() async {
    await _watchSub?.cancel();
    _watchSub = null;
    _knownIds.clear();
    _seeded = false;
  }

  Future<void> _startWatch(String userId) async {
    await _watchSub?.cancel();
    _knownIds.clear();
    _seeded = false;

    _watchSub = _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.notifications)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .listen((snap) async {
      if (!_seeded) {
        for (final doc in snap.docs) {
          _knownIds.add(doc.id);
        }
        _seeded = true;
        return;
      }

      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final doc = change.doc;
        if (_knownIds.contains(doc.id)) continue;
        _knownIds.add(doc.id);

        final data = doc.data();
        if (data == null) continue;
        final notification = NotificationModel.fromMap(doc.id, data);
        if (notification.isRead) continue;
        await _local.showFromModel(notification);
        if (notification.type == NotificationType.bookingConfirmed &&
            notification.relatedId != null) {
          await _maybeScheduleReminderFromBooking(notification);
        }
      }
    }, onError: (_) {});
  }

  Future<void> _maybeScheduleReminderFromBooking(
    NotificationModel notification,
  ) async {
    try {
      final snap = await _firestore
          .collection(FirebaseCollections.bookings)
          .doc(notification.relatedId)
          .get();
      if (!snap.exists) return;
      final data = snap.data()!;
      final date = (data['scheduledDate'] as Timestamp?)?.toDate();
      if (date == null) return;
      final time = data['scheduledTime'] as String? ?? '09:00';
      final parts = time.split(':');
      final hour = int.tryParse(parts.first) ?? 9;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final sessionStart = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final otherName = uid == (data['clientId'] as String? ?? '')
          ? (data['photographerName'] as String? ?? 'your creator')
          : (data['clientName'] as String? ?? 'your client');
      await _local.scheduleShootReminder(
        bookingId: '${notification.relatedId}_$uid',
        otherPartyName: otherName,
        sessionStart: sessionStart,
      );
    } catch (_) {}
  }

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
  }) async {
    await createNotification(
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
  }

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

  Future<void> createCustomOfferNotification({
    required String clientId,
    required String photographerName,
    required String conversationId,
    required String offerName,
    required int offerPrice,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: clientId,
          title: 'Custom offer from $photographerName',
          body: '$offerName – PHP $offerPrice',
          type: NotificationType.customOffer,
          relatedId: conversationId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createOfferAcceptedNotification({
    required String photographerId,
    required String clientName,
    required String conversationId,
    required String offerName,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: photographerId,
          title: 'Offer accepted',
          body: '$clientName accepted your offer: $offerName',
          type: NotificationType.offerAccepted,
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
  }) async {
    await createNotification(
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
    await _local.cancelShootReminder(bookingId);
    await _local.cancelShootReminder('${bookingId}_client');
    await _local.cancelShootReminder('${bookingId}_photographer');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _local.cancelShootReminder('${bookingId}_$uid');
    }
    if (recipientId.isNotEmpty) {
      await _local.cancelShootReminder('${bookingId}_$recipientId');
    }
  }

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

  Future<void> createRescheduleDeclinedNotification({
    required String recipientId,
    required String bookingId,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: recipientId,
          title: 'Reschedule Declined',
          body:
              'Your reschedule request was declined. The original date and time were kept.',
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

  Future<void> createContentReportedNotification({
    required String reportedUserId,
    required String reportedUserName,
    required String contentType,
    required String reason,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: reportedUserId,
          title: 'Content Reported',
          body:
              'Your $contentType has been reported for: $reason. Our moderation team will review this.',
          type: NotificationType.contentReported,
          relatedId: reportedUserId,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> createUserBlockedNotification({
    required String blockedUserId,
    required String blockedUserName,
    required String blockedBy,
  }) =>
      createNotification(
        NotificationModel(
          id: '',
          userId: blockedUserId,
          title: 'Account Action',
          body:
              'Your account has been reported by another user. Our moderation team will review this.',
          type: NotificationType.userBlocked,
          relatedId: blockedUserId,
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

  /// Optional day-before shoot reminder for [forUserId] on this device.
  Future<void> scheduleShootReminders({
    required String bookingId,
    required String clientName,
    required String photographerName,
    required DateTime sessionStart,
    required String forUserId,
    required String otherPartyName,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != forUserId) return;

    await _local.scheduleShootReminder(
      bookingId: '${bookingId}_$forUserId',
      otherPartyName: otherPartyName,
      sessionStart: sessionStart,
    );
  }

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
