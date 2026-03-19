import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_constants.dart';
import '../models/verification_submission_model.dart';
import 'storage_service.dart';

class VerificationService {
  static final VerificationService _instance = VerificationService._internal();
  factory VerificationService() => _instance;
  VerificationService._internal();

  final _firestore = FirebaseFirestore.instance;

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<String> submitVerification({
    required String userId,
    required String legalName,
    required String governmentIdNumber,
    required List<PendingDocument> documents,
  }) async {
    final uploaded = <VerificationDocumentModel>[];

    for (final doc in documents) {
      final url = await StorageService().uploadVerificationDoc(
        userId,
        doc.type,
        doc.file,
      );
      uploaded.add(
        VerificationDocumentModel(
          type: doc.type,
          url: url,
          uploadedAt: DateTime.now(),
        ),
      );
    }

    final docRef = _firestore
        .collection(FirebaseCollections.verificationSubmissions)
        .doc();

    final submission = VerificationSubmissionModel(
      id: docRef.id,
      userId: userId,
      legalName: legalName,
      governmentIdNumber: governmentIdNumber,
      documents: uploaded,
      status: VerificationStatuses.pending,
      submittedAt: DateTime.now(),
    );

    await docRef.set(submission.toMap());

    // Update user verification status
    await _firestore.collection(FirebaseCollections.users).doc(userId).update({
      'verificationStatus': VerificationStatuses.pending,
    });
    // Update photographer doc too if applicable
    final photoDoc = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(userId)
        .get();
    if (photoDoc.exists) {
      await photoDoc.reference.update({
        'isVerified': false,
      }); // pending, not yet approved
    }

    return docRef.id;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<VerificationSubmissionModel?> getCurrentSubmission(
    String userId,
  ) async {
    final snap = await _firestore
        .collection(FirebaseCollections.verificationSubmissions)
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return VerificationSubmissionModel.fromMap(
      snap.docs.first.id,
      snap.docs.first.data(),
    );
  }

  Stream<VerificationSubmissionModel?> submissionStream(String userId) =>
      _firestore
          .collection(FirebaseCollections.verificationSubmissions)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .snapshots()
          .map(
            (snap) => snap.docs.isEmpty
                ? null
                : VerificationSubmissionModel.fromMap(
                    snap.docs.first.id,
                    snap.docs.first.data(),
                  ),
          );

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
}

class PendingDocument {
  final String type;
  final File file;

  const PendingDocument({required this.type, required this.file});
}
