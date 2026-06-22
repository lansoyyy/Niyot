import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_constants.dart';
import '../models/report_model.dart';
import 'notification_service.dart';
import 'user_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final _firestore = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String reportedUserId,
    required String reportedUserName,
    required String contentType,
    required String reason,
    String? contentId,
    String? description,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('You must be signed in to report.');

    final reporterName = UserService().cachedUser?.name ?? currentUser.displayName ?? 'User';

    final report = ReportModel(
      id: '',
      reporterId: currentUser.uid,
      reporterName: reporterName,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      contentType: contentType,
      contentId: contentId,
      reason: reason,
      description: description,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirebaseCollections.reports)
        .add(report.toMap());

    await NotificationService().createContentReportedNotification(
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      contentType: contentType,
      reason: reason,
    );
  }

  Future<List<ReportModel>> getReportsForUser(String userId) async {
    final snap = await _firestore
        .collection(FirebaseCollections.reports)
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<bool> hasUserReported({
    required String reportedUserId,
    required String contentType,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final snap = await _firestore
        .collection(FirebaseCollections.reports)
        .where('reporterId', isEqualTo: currentUser.uid)
        .where('reportedUserId', isEqualTo: reportedUserId)
        .where('contentType', isEqualTo: contentType)
        .get();
    return snap.docs.isNotEmpty;
  }
}
