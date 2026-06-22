import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_constants.dart';

class BlockService {
  static final BlockService _instance = BlockService._internal();
  factory BlockService() => _instance;
  BlockService._internal();

  final _firestore = FirebaseFirestore.instance;

  Future<void> blockUser({
    required String blockedUserId,
    required String blockedUserName,
    String? blockReason,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('You must be signed in to block.');

    await _firestore
        .collection(FirebaseCollections.users)
        .doc(currentUser.uid)
        .collection(FirebaseCollections.blockedUsers)
        .doc(blockedUserId)
        .set({
      'blockedUserId': blockedUserId,
      'blockedUserName': blockedUserName,
      'blockedAt': FieldValue.serverTimestamp(),
      if (blockReason != null) 'reason': blockReason,
    });
  }

  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('You must be signed in.');

    await _firestore
        .collection(FirebaseCollections.users)
        .doc(currentUser.uid)
        .collection(FirebaseCollections.blockedUsers)
        .doc(blockedUserId)
        .delete();
  }

  Stream<Set<String>> blockedUserIdsStream(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.blockedUsers)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<Set<String>> getBlockedUserIds(String userId) async {
    final snap = await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.blockedUsers)
        .get();
    return snap.docs.map((doc) => doc.id).toSet();
  }

  Future<bool> isBlocked({
    required String blockerId,
    required String targetUserId,
  }) async {
    final doc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(blockerId)
        .collection(FirebaseCollections.blockedUsers)
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  Stream<Set<String>> blockedByStream(String userId) {
    return _firestore
        .collectionGroup(FirebaseCollections.blockedUsers)
        .where('blockedUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final blockers = <String>{};
      for (final doc in snap.docs) {
        final parentRef = doc.reference.parent.parent;
        if (parentRef != null) {
          blockers.add(parentRef.id);
        }
      }
      return blockers;
    });
  }

  Stream<Map<String, dynamic>?> blockInfoStream({
    required String blockerId,
    required String blockedUserId,
  }) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(blockerId)
        .collection(FirebaseCollections.blockedUsers)
        .doc(blockedUserId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}
