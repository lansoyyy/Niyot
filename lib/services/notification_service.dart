import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/firebase_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;

  // ─── FCM Setup ────────────────────────────────────────────────────────────

  Future<void> initFCM() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (token != null && uid != null) {
      await saveFCMToken(uid, token);
    }

    // Refresh token
    _messaging.onTokenRefresh.listen((token) async {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        await saveFCMToken(currentUid, token);
      }
    });

    // Handle foreground messages by creating in-app notification records
    FirebaseMessaging.onMessage.listen((message) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final data = message.data;
      if (data.isEmpty) return;

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .collection(FirebaseCollections.notifications)
          .add({
            'userId': uid,
            'title': message.notification?.title ?? data['title'] ?? '',
            'body': message.notification?.body ?? data['body'] ?? '',
            'type': data['type'] ?? NotificationTypes.system,
            'relatedId': data['relatedId'],
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    });
  }

  Future<void> saveFCMToken(String uid, String token) async {
    await _firestore.collection(FirebaseCollections.users).doc(uid).update({
      'fcmToken': token,
    });
  }

  Future<void> removeFCMToken(String uid) async {
    await _firestore.collection(FirebaseCollections.users).doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
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
  }) => createNotification(
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
  }) => createNotification(
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
  }) => createNotification(
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

  Future<void> createNewMessageNotification({
    required String recipientId,
    required String senderName,
    required String conversationId,
    required String messagePreview,
  }) => createNotification(
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
  }) => createNotification(
    NotificationModel(
      id: '',
      userId: photographerId,
      title: 'Payment Received',
      body: 'You\'ve received a cash payment confirmation from $clientName.',
      type: NotificationType.paymentReceived,
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
  }) => createNotification(
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
