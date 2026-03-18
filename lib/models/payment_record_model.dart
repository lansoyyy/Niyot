import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';

enum PaymentStatus {
  pending,
  completed,
  refunded,
  failed,
}

extension PaymentStatusX on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return PaymentStatuses.pending;
      case PaymentStatus.completed:
        return PaymentStatuses.completed;
      case PaymentStatus.refunded:
        return PaymentStatuses.refunded;
      case PaymentStatus.failed:
        return PaymentStatuses.failed;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  static PaymentStatus fromValue(String value) {
    switch (value) {
      case PaymentStatuses.completed:
        return PaymentStatus.completed;
      case PaymentStatuses.refunded:
        return PaymentStatus.refunded;
      case PaymentStatuses.failed:
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

class PaymentRecordModel {
  final String id;
  final String bookingId;
  final String payerId;
  final String payeeId;
  final int amount; // in USD
  final String currency;
  final String paymentMethodLabel;
  final String? proofUrl;
  final PaymentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentRecordModel({
    required this.id,
    required this.bookingId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    this.currency = 'USD',
    required this.paymentMethodLabel,
    this.proofUrl,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'payerId': payerId,
        'payeeId': payeeId,
        'amount': amount,
        'currency': currency,
        'paymentMethodLabel': paymentMethodLabel,
        'proofUrl': proofUrl,
        'status': status.value,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory PaymentRecordModel.fromMap(String id, Map<String, dynamic> map) =>
      PaymentRecordModel(
        id: id,
        bookingId: map['bookingId'] as String? ?? '',
        payerId: map['payerId'] as String? ?? '',
        payeeId: map['payeeId'] as String? ?? '',
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        currency: map['currency'] as String? ?? 'USD',
        paymentMethodLabel: map['paymentMethodLabel'] as String? ?? '',
        proofUrl: map['proofUrl'] as String?,
        status: PaymentStatusX.fromValue(map['status'] as String? ?? ''),
        notes: map['notes'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
