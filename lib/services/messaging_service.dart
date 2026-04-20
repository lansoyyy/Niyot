import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_constants.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final _firestore = FirebaseFirestore.instance;

  // ─── Conversations ────────────────────────────────────────────────────────

  /// Gets or creates a conversation between two users.
  /// For booking-scoped chats, provide [bookingId] to use a deterministic ID.
  Future<String> getOrCreateConversation({
    required String myId,
    required String myName,
    String? myPhotoUrl,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
    String? bookingId,
  }) async {
    // Deterministic conversation ID prevents duplicates
    final conversationId = bookingId != null
        ? 'booking_$bookingId'
        : _buildConversationId(myId, otherUserId);

    final docRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId);

    final doc = await docRef.get();
    if (!doc.exists) {
      final conversation = ConversationModel(
        id: conversationId,
        participantIds: [myId, otherUserId],
        participantNames: {myId: myName, otherUserId: otherUserName},
        participantPhotoUrls: {
          myId: myPhotoUrl,
          otherUserId: otherUserPhotoUrl,
        },
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCounts: {myId: 0, otherUserId: 0},
        bookingId: bookingId,
      );
      await docRef.set(conversation.toMap());
    }
    return conversationId;
  }

  String _buildConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<ConversationModel>> conversationsStream(String userId) =>
      _firestore
          .collection(FirebaseCollections.conversations)
          .where('participantIds', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => ConversationModel.fromMap(d.id, d.data()))
                .toList(),
          );

  // ─── Messages ─────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> messagesStream(String conversationId) => _firestore
      .collection(FirebaseCollections.conversations)
      .doc(conversationId)
      .collection(FirebaseCollections.messages)
      .orderBy('timestamp')
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => MessageModel.fromMap(d.id, d.data())).toList(),
      );

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && mediaUrl == null) {
      return;
    }

    final preview = trimmedText.isNotEmpty
        ? trimmedText
        : mediaType == 'image'
        ? 'Sent a photo'
        : 'Sent an attachment';

    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': trimmedText,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update conversation summary
    final convRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId);

    // Increment unread count for each participant except sender
    final convDoc = await convRef.get();
    if (convDoc.exists) {
      final data = convDoc.data()!;
      final participants = List<String>.from(
        data['participantIds'] as List? ?? [],
      );
      final currentUnread = Map<String, int>.from(
        (data['unreadCounts'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );

      for (final pid in participants) {
        if (pid != senderId) {
          currentUnread[pid] = (currentUnread[pid] ?? 0) + 1;
        }
      }

      batch.update(convRef, {
        'lastMessage': preview.length > 80
            ? '${preview.substring(0, 80)}…'
            : preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': currentUnread,
      });

      // Notify other participants
      for (final pid in participants) {
        if (pid != senderId) {
          await NotificationService().createNewMessageNotification(
            recipientId: pid,
            senderName: senderName,
            conversationId: conversationId,
            messagePreview: preview.length > 60
                ? '${preview.substring(0, 60)}…'
                : preview,
          );
        }
      }
    }

    await batch.commit();
  }

  // ─── Read Receipts ────────────────────────────────────────────────────────

  Future<void> markConversationRead(
    String conversationId,
    String userId,
  ) async {
    // Reset unread count for this user
    await _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .update({'unreadCounts.$userId': 0});

    // Mark unread messages as read
    final unreadMsgs = await _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMsgs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── Unread Badge ─────────────────────────────────────────────────────────

  Stream<int> totalUnreadStream(String userId) => _firestore
      .collection(FirebaseCollections.conversations)
      .where('participantIds', arrayContains: userId)
      .snapshots()
      .map((snap) {
        int total = 0;
        for (final doc in snap.docs) {
          final counts = (doc.data()['unreadCounts'] as Map? ?? {});
          total += (counts[userId] as num?)?.toInt() ?? 0;
        }
        return total;
      });

  // ─── Custom Offers ────────────────────────────────────────────────────────

  /// Sends a custom offer message. Only photographers should call this.
  Future<void> sendCustomOffer({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String offerName,
    required int offerPrice,
    required DateTime offerDateTime,
  }) async {
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    final preview = 'Custom offer: $offerName – \$$offerPrice';

    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': preview,
      'mediaType': 'custom_offer',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'offerName': offerName,
      'offerPrice': offerPrice,
      'offerDateTime': Timestamp.fromDate(offerDateTime),
      'offerExpiresAt': Timestamp.fromDate(expiresAt),
    });

    final convRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId);

    final convDoc = await convRef.get();
    if (convDoc.exists) {
      final data = convDoc.data()!;
      final participants = List<String>.from(
        data['participantIds'] as List? ?? [],
      );
      final currentUnread = Map<String, int>.from(
        (data['unreadCounts'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );
      for (final pid in participants) {
        if (pid != senderId) {
          currentUnread[pid] = (currentUnread[pid] ?? 0) + 1;
        }
      }
      batch.update(convRef, {
        'lastMessage': preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': currentUnread,
      });
      for (final pid in participants) {
        if (pid != senderId) {
          await NotificationService().createNewMessageNotification(
            recipientId: pid,
            senderName: senderName,
            conversationId: conversationId,
            messagePreview: preview,
          );
        }
      }
    }

    await batch.commit();
  }

  /// Accepts or declines a custom offer. Only the non-sender (client) calls this.
  Future<void> respondToOffer({
    required String conversationId,
    required String messageId,
    required String status, // 'accepted' | 'declined'
  }) async {
    await _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .doc(messageId)
        .update({'offerStatus': status});
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
}
