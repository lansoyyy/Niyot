import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_constants.dart';

/// Centralised file upload helpers. All uploads go through here so paths
/// and content types stay consistent across the app.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File image) async {
    final ref = _storage.ref(FirebaseStoragePaths.profileImage(uid));
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadPortfolioItem(
      String uid, String itemId, File image) async {
    final ref =
        _storage.ref(FirebaseStoragePaths.portfolioItem(uid, itemId));
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadChatAttachment(
      String conversationId, String fileName, File file) async {
    final ref = _storage
        .ref(FirebaseStoragePaths.chatAttachment(conversationId, fileName));
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadVerificationDoc(
      String uid, String docType, File file) async {
    final ref = _storage.ref(FirebaseStoragePaths.verificationDoc(uid, docType));
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadPaymentProof(String paymentId, File image) async {
    final ref = _storage.ref(FirebaseStoragePaths.paymentProof(paymentId));
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may already be deleted — ignore
    }
  }
}
