import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_constants.dart';
import '../core/google_sign_in_config.dart';
import 'user_service.dart';

/// Permanently removes a user's account, profile data, and stored media.
class AccountDeletionService {
  static final AccountDeletionService _instance =
      AccountDeletionService._internal();
  factory AccountDeletionService() => _instance;
  AccountDeletionService._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _googleSignIn = createGoogleSignIn();

  Future<void> deleteAccount({required AuthCredential credential}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final uid = user.uid;
    await user.reauthenticateWithCredential(credential);

    await _deleteUserSubcollections(uid);
    await _deletePhotographerData(uid);
    await _deleteVerificationSubmissions(uid);
    await _deletePaymentRecords(uid);
    await _anonymizeBookings(uid);
    await _anonymizeConversations(uid);
    await _deleteClientReviews(uid);
    await _deleteUserStorage(uid);

    await _firestore.collection(FirebaseCollections.users).doc(uid).delete();

    UserService().clearCache();
    await _googleSignIn.signOut();
    await user.delete();
    await _auth.signOut();
  }

  Future<void> _deleteUserSubcollections(String uid) async {
    final userRef = _firestore.collection(FirebaseCollections.users).doc(uid);
    await _deleteSubcollection(userRef, FirebaseCollections.favorites);
    await _deleteSubcollection(userRef, FirebaseCollections.notifications);
    await _deleteSubcollection(userRef, FirebaseCollections.paymentMethods);
  }

  Future<void> _deletePhotographerData(String uid) async {
    final photographerRef = _firestore
        .collection(FirebaseCollections.photographers)
        .doc(uid);
    final photographerDoc = await photographerRef.get();
    if (!photographerDoc.exists) return;

    await _deleteSubcollection(photographerRef, FirebaseCollections.portfolio);
    await _deleteSubcollection(photographerRef, FirebaseCollections.reviews);
    await _deleteSubcollection(photographerRef, FirebaseCollections.availability);
    await photographerRef.delete();
  }

  Future<void> _deleteVerificationSubmissions(String uid) async {
    final snap = await _firestore
        .collection(FirebaseCollections.verificationSubmissions)
        .where('userId', isEqualTo: uid)
        .get();
    await _deleteDocuments(snap.docs.map((doc) => doc.reference).toList());
  }

  Future<void> _deletePaymentRecords(String uid) async {
    final payerSnap = await _firestore
        .collection(FirebaseCollections.paymentRecords)
        .where('payerId', isEqualTo: uid)
        .get();
    await _deleteDocuments(payerSnap.docs.map((doc) => doc.reference).toList());

    final payeeSnap = await _firestore
        .collection(FirebaseCollections.paymentRecords)
        .where('payeeId', isEqualTo: uid)
        .get();
    await _deleteDocuments(payeeSnap.docs.map((doc) => doc.reference).toList());
  }

  Future<void> _anonymizeBookings(String uid) async {
    const deletedLabel = 'Deleted User';

    final asClient = await _firestore
        .collection(FirebaseCollections.bookings)
        .where('clientId', isEqualTo: uid)
        .get();
    for (final doc in asClient.docs) {
      await doc.reference.update({
        'clientName': deletedLabel,
        'clientPhotoUrl': FieldValue.delete(),
      });
    }

    final asPhotographer = await _firestore
        .collection(FirebaseCollections.bookings)
        .where('photographerId', isEqualTo: uid)
        .get();
    for (final doc in asPhotographer.docs) {
      await doc.reference.update({
        'photographerName': deletedLabel,
        'photographerPhotoUrl': FieldValue.delete(),
      });
    }
  }

  Future<void> _anonymizeConversations(String uid) async {
    const deletedLabel = 'Deleted User';
    final snap = await _firestore
        .collection(FirebaseCollections.conversations)
        .where('participantIds', arrayContains: uid)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final names = Map<String, dynamic>.from(
        data['participantNames'] as Map? ?? {},
      );
      final photos = Map<String, dynamic>.from(
        data['participantPhotoUrls'] as Map? ?? {},
      );
      names[uid] = deletedLabel;
      photos.remove(uid);

      await doc.reference.update({
        'participantNames': names,
        'participantPhotoUrls': photos,
      });

      await _deleteSubcollection(
        doc.reference,
        FirebaseCollections.messages,
        senderId: uid,
      );
    }
  }

  Future<void> _deleteClientReviews(String uid) async {
    try {
      final snap = await _firestore
          .collectionGroup(FirebaseCollections.reviews)
          .where('clientId', isEqualTo: uid)
          .get();
      await _deleteDocuments(snap.docs.map((doc) => doc.reference).toList());
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
    }
  }

  Future<void> _deleteUserStorage(String uid) async {
    await _deleteStoragePath(FirebaseStoragePaths.profileImage(uid));
    await _deleteStoragePrefix('portfolio/$uid');
    await _deleteStoragePrefix('verification/$uid');
  }

  Future<void> _deleteSubcollection(
    DocumentReference<Map<String, dynamic>> parentRef,
    String subcollection, {
    String? senderId,
  }) async {
    Query<Map<String, dynamic>> query =
        parentRef.collection(subcollection).limit(500);
    if (senderId != null) {
      query = query.where('senderId', isEqualTo: senderId);
    }

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) return;
      await _deleteDocuments(snap.docs.map((doc) => doc.reference).toList());
      if (snap.docs.length < 500) return;
    }
  }

  Future<void> _deleteDocuments(List<DocumentReference<Map<String, dynamic>>> refs) async {
    if (refs.isEmpty) return;

    for (var i = 0; i < refs.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = refs.skip(i).take(450);
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteStoragePath(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  Future<void> _deleteStoragePrefix(String prefix) async {
    try {
      final listing = await _storage.ref(prefix).listAll();
      for (final item in listing.items) {
        await item.delete();
      }
      for (final folder in listing.prefixes) {
        await _deleteStoragePrefix(folder.fullPath);
      }
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
