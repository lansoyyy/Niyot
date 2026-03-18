import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String id;
  final String userId;
  final String provider;
  final String label;
  final String? holderName;
  final String? last4;
  final String? expiry;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.label,
    this.holderName,
    this.last4,
    this.expiry,
    required this.isDefault,
    required this.createdAt,
  });

  bool get isCard => provider == 'card';

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'provider': provider,
        'label': label,
        'holderName': holderName,
        'last4': last4,
        'expiry': expiry,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory PaymentMethodModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      provider: map['provider'] as String? ?? 'card',
      label: map['label'] as String? ?? '',
      holderName: map['holderName'] as String?,
      last4: map['last4'] as String?,
      expiry: map['expiry'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
