import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_constants.dart';
import '../models/payment_record_model.dart';
import 'notification_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _firestore = FirebaseFirestore.instance;

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<String> createPaymentRecord(PaymentRecordModel record) async {
    final docRef = _firestore
        .collection(FirebaseCollections.paymentRecords)
        .doc();
    await docRef.set(record.toMap());
    return docRef.id;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<PaymentRecordModel?> getPaymentForBooking(String bookingId) async {
    final snap = await _firestore
        .collection(FirebaseCollections.paymentRecords)
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PaymentRecordModel.fromMap(
      snap.docs.first.id,
      snap.docs.first.data(),
    );
  }

  Stream<List<PaymentRecordModel>> payerPaymentsStream(String payerId) =>
      _firestore
          .collection(FirebaseCollections.paymentRecords)
          .where('payerId', isEqualTo: payerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => PaymentRecordModel.fromMap(d.id, d.data()))
                .toList(),
          );

  Stream<List<PaymentRecordModel>> payeePaymentsStream(String payeeId) =>
      _firestore
          .collection(FirebaseCollections.paymentRecords)
          .where('payeeId', isEqualTo: payeeId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => PaymentRecordModel.fromMap(d.id, d.data()))
                .toList(),
          );

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateStatus(
    String paymentId,
    PaymentStatus status, {
    String? proofUrl,
    String? notes,
  }) async {
    final fields = <String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (proofUrl != null) fields['proofUrl'] = proofUrl;
    if (notes != null) fields['notes'] = notes;

    await _firestore
        .collection(FirebaseCollections.paymentRecords)
        .doc(paymentId)
        .update(fields);

    if (status == PaymentStatus.completed) {
      final record = await _getRecordById(paymentId);
      if (record != null) {
        final payerDoc = await _firestore
            .collection(FirebaseCollections.users)
            .doc(record.payerId)
            .get();
        final payerName = payerDoc.data()?['name'] as String? ?? 'A client';
        await NotificationService().createPaymentReceivedNotification(
          photographerId: record.payeeId,
          clientName: payerName,
          amount: record.amount,
          bookingId: record.bookingId,
        );
      }
    }
  }

  Future<PaymentRecordModel?> _getRecordById(String id) async {
    final doc = await _firestore
        .collection(FirebaseCollections.paymentRecords)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return PaymentRecordModel.fromMap(id, doc.data()!);
  }
}
