import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_constants.dart';
import '../models/user_model.dart';

/// Manages the current user's Firestore profile, separate from auth state.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  UserModel? _cachedUser;
  UserModel? get cachedUser => _cachedUser;

  // ─── Profile Fetch ─────────────────────────────────────────────────────────

  Future<UserModel?> fetchCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc =
        await _firestore.collection(FirebaseCollections.users).doc(uid).get();
    if (!doc.exists) return null;
    _cachedUser = UserModel.fromMap(uid, doc.data()!);
    return _cachedUser;
  }

  Stream<UserModel?> userStream(String uid) =>
      _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          _cachedUser = null;
          return null;
        }
        _cachedUser = UserModel.fromMap(uid, doc.data()!);
        return _cachedUser;
      });

  // ─── Profile Update ────────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    fields['lastActiveAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .update(fields);
    // Invalidate cache so next read fetches fresh data
    _cachedUser = null;
  }

  Future<String?> uploadProfilePhoto(String uid, File image) async {
    final ref = _storage.ref(FirebaseStoragePaths.profileImage(uid));
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    // Update both Auth display photo and Firestore
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
    await updateProfile(uid: uid, fields: {'photoUrl': url});
    return url;
  }

  // ─── Notification Preferences ─────────────────────────────────────────────

  Future<void> updateNotificationPreferences(
    String uid,
    Map<String, bool> preferences,
  ) async {
    await updateProfile(
      uid: uid,
      fields: {'notificationPreferences': preferences},
    );
  }

  // ─── Clear Cache ──────────────────────────────────────────────────────────

  void clearCache() => _cachedUser = null;
}
