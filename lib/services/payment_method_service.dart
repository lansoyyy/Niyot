import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_constants.dart';
import '../models/payment_method_model.dart';

class PaymentMethodService {
  static final PaymentMethodService _instance = PaymentMethodService._internal();
  factory PaymentMethodService() => _instance;
  PaymentMethodService._internal();

  final _firestore = FirebaseFirestore.instance;

  Stream<List<PaymentMethodModel>> paymentMethodsStream(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.paymentMethods)
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PaymentMethodModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addCardMethod({
    required String userId,
    required String brand,
    required String last4,
    required String expiry,
    required String holderName,
    required bool isDefault,
  }) async {
    final collection = _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.paymentMethods);

    final existing = await collection.get();
    final batch = _firestore.batch();
    if (isDefault) {
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    final docRef = collection.doc();
    batch.set(
      docRef,
      PaymentMethodModel(
        id: docRef.id,
        userId: userId,
        provider: 'card',
        label: brand,
        holderName: holderName,
        last4: last4,
        expiry: expiry,
        isDefault: isDefault || existing.docs.isEmpty,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    await batch.commit();
  }

  Future<void> addWalletMethod({
    required String userId,
    required String provider,
    required String label,
    bool isDefault = false,
  }) async {
    final collection = _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.paymentMethods);

    final existing = await collection.get();
    final batch = _firestore.batch();
    if (isDefault) {
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    final docRef = collection.doc();
    batch.set(
      docRef,
      PaymentMethodModel(
        id: docRef.id,
        userId: userId,
        provider: provider,
        label: label,
        isDefault: isDefault || existing.docs.isEmpty,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    await batch.commit();
  }

  Future<void> setDefaultMethod(String userId, String methodId) async {
    final collection = _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.paymentMethods);

    final existing = await collection.get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == methodId});
    }
    await batch.commit();
  }

  Future<void> deleteMethod(String userId, String methodId) async {
    final collection = _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.paymentMethods);

    final docRef = collection.doc(methodId);
    final doc = await docRef.get();
    final wasDefault = doc.data()?['isDefault'] as bool? ?? false;
    await docRef.delete();

    if (wasDefault) {
      final remaining = await collection.orderBy('createdAt').limit(1).get();
      if (remaining.docs.isNotEmpty) {
        await remaining.docs.first.reference.update({'isDefault': true});
      }
    }
  }

  String inferCardBrand(String number) {
    final normalized = number.replaceAll(RegExp(r'\s+'), '');
    if (normalized.startsWith('4')) return 'Visa';
    if (normalized.startsWith('5')) return 'Mastercard';
    if (normalized.startsWith('34') || normalized.startsWith('37')) {
      return 'American Express';
    }
    return 'Card';
  }
}
