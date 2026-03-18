import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_constants.dart';
import '../models/photographer_model.dart';
import '../models/portfolio_item_model.dart';
import '../models/review_model.dart';
import '../models/availability_model.dart';
import '../models/service_package_model.dart';

class PhotographerService {
  static final PhotographerService _instance = PhotographerService._internal();
  factory PhotographerService() => _instance;
  PhotographerService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ─── Discovery ────────────────────────────────────────────────────────────

  Future<List<PhotographerModel>> getFeaturedPhotographers(
      {int limit = 5}) async {
    final snap = await _firestore
        .collection(FirebaseCollections.photographers)
        .where('isFeatured', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => PhotographerModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<PhotographerModel>> getPhotographers({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(FirebaseCollections.photographers);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('specialties', arrayContains: category);
    }

    query = query.orderBy('rating', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    var results = snap.docs
        .map((d) => PhotographerModel.fromMap(d.id, d.data()))
        .toList();

    // Client-side search filter (Firestore doesn't support full-text search)
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.locationText.toLowerCase().contains(q) ||
              p.specialties.any((s) => s.toLowerCase().contains(q)))
          .toList();
    }

    return results;
  }

  // ─── Single Photographer ──────────────────────────────────────────────────

  Future<PhotographerModel?> getPhotographerById(String uid) async {
    final doc = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return PhotographerModel.fromMap(uid, doc.data()!);
  }

  Stream<PhotographerModel?> photographerStream(String uid) =>
      _firestore
          .collection(FirebaseCollections.photographers)
          .doc(uid)
          .snapshots()
          .map((d) =>
              d.exists ? PhotographerModel.fromMap(uid, d.data()!) : null);

  // ─── Portfolio ────────────────────────────────────────────────────────────

  Future<List<PortfolioItemModel>> getPortfolio(String photographerId) async {
    final snap = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.portfolio)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => PortfolioItemModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<PortfolioItemModel> addPortfolioItem(
    String photographerId,
    File image, {
    String? caption,
    List<String> tags = const [],
  }) async {
    final ref = _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.portfolio)
        .doc();

    final storageRef = _storage
        .ref(FirebaseStoragePaths.portfolioItem(photographerId, ref.id));
    await storageRef.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    final imageUrl = await storageRef.getDownloadURL();

    final item = PortfolioItemModel(
      id: ref.id,
      photographerId: photographerId,
      imageUrl: imageUrl,
      caption: caption,
      tags: tags,
      createdAt: DateTime.now(),
    );
    await ref.set(item.toMap());

    // Increment photoCount
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .update({'photoCount': FieldValue.increment(1)});

    return item;
  }

  Future<void> deletePortfolioItem(
      String photographerId, String itemId) async {
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.portfolio)
        .doc(itemId)
        .delete();
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .update({'photoCount': FieldValue.increment(-1)});
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────

  Future<List<ReviewModel>> getReviews(String photographerId) async {
    final snap = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.reviews)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => ReviewModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> addReview(ReviewModel review) async {
    final docRef = _firestore
        .collection(FirebaseCollections.photographers)
        .doc(review.photographerId)
        .collection(FirebaseCollections.reviews)
        .doc();

    await docRef.set(review.toMap());

    // Recalculate average rating
    await _recalculateRating(review.photographerId);
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(review.photographerId)
        .update({'reviewCount': FieldValue.increment(1)});
  }

  Future<void> _recalculateRating(String photographerId) async {
    final snap = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.reviews)
        .get();

    if (snap.docs.isEmpty) return;
    final total = snap.docs
        .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a + b);
    final avg = total / snap.docs.length;

    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .update({'rating': double.parse(avg.toStringAsFixed(1))});
  }

  // ─── Availability ─────────────────────────────────────────────────────────

  Future<AvailabilityModel?> getAvailability(
      String photographerId, DateTime date) async {
    final docId = AvailabilityModel.docId(date);
    final doc = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.availability)
        .doc(docId)
        .get();

    if (!doc.exists) return null;
    return AvailabilityModel.fromMap(doc.data()!);
  }

  /// Returns a set of dates in [month] that have at least one available slot.
  Future<Set<DateTime>> getAvailableDatesInMonth(
    String photographerId,
    DateTime month,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final snap = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.availability)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final available = <DateTime>{};
    for (final doc in snap.docs) {
      final model = AvailabilityModel.fromMap(doc.data());
      if (model.slots.any((s) => s.isAvailable)) {
        available.add(DateTime(
            model.date.year, model.date.month, model.date.day));
      }
    }
    return available;
  }

  /// Returns a set of booked/unavailable dates in [month].
  Future<Set<DateTime>> getBookedDatesInMonth(
    String photographerId,
    DateTime month,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final snap = await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.availability)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final booked = <DateTime>{};
    for (final doc in snap.docs) {
      final model = AvailabilityModel.fromMap(doc.data());
      final hasAllBooked = model.slots.every((s) => !s.isAvailable);
      if (hasAllBooked && model.slots.isNotEmpty) {
        booked.add(DateTime(
            model.date.year, model.date.month, model.date.day));
      }
    }
    return booked;
  }

  Future<void> setAvailability(AvailabilityModel availability) async {
    final docId = AvailabilityModel.docId(availability.date);
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(availability.photographerId)
        .collection(FirebaseCollections.availability)
        .doc(docId)
        .set(availability.toMap());
  }

  // ─── Profile Update ────────────────────────────────────────────────────────

  Future<void> createOrUpdatePhotographerProfile(
      PhotographerModel model) async {
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(model.uid)
        .set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> updatePackages(
      String uid, List<ServicePackageModel> packages) async {
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(uid)
        .update({'packages': packages.map((p) => p.toMap()).toList()});
  }

  Future<void> updateAvailabilityStatus(String uid, bool isAvailable) async {
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(uid)
        .update({'isAvailable': isAvailable});
  }

  // ─── Increment Profile Views ──────────────────────────────────────────────

  Future<void> incrementProfileView(String photographerId) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    // Don't count own views
    if (currentUid == photographerId) return;
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .update({'profileViewCount': FieldValue.increment(1)});
  }
}
