import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_constants.dart';
import '../models/booking_model.dart';
import '../models/availability_model.dart';
import '../models/review_model.dart';
import 'notification_service.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final _firestore = FirebaseFirestore.instance;

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<String> createBooking(BookingModel booking) async {
    final docRef = _firestore.collection(FirebaseCollections.bookings).doc();

    final data = booking.toMap();
    await docRef.set(data);

    // Reserve the time slot in photographer's availability
    await _reserveSlot(
      photographerId: booking.photographerId,
      date: booking.scheduledDate,
      time: booking.scheduledTime,
      bookingId: docRef.id,
    );

    // Notify photographer of new booking request
    await NotificationService().createBookingRequestNotification(
      photographerId: booking.photographerId,
      clientName: booking.clientName,
      bookingId: docRef.id,
      scheduledDate: booking.scheduledDate,
    );

    // Increment photographer booking count
    await _firestore
        .collection(FirebaseCollections.photographers)
        .doc(booking.photographerId)
        .update({'bookingCount': FieldValue.increment(1)});

    return docRef.id;
  }

  Future<void> _reserveSlot({
    required String photographerId,
    required DateTime date,
    required String time,
    required String bookingId,
  }) async {
    final docId = AvailabilityModel.docId(date);
    final docRef = _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.availability)
        .doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) {
      final slots = AvailabilityModel.defaultSlots().map((s) {
        if (s.time == time) {
          return s.copyWith(isAvailable: false, bookedByBookingId: bookingId);
        }
        return s;
      }).toList();
      if (!slots.any((slot) => slot.time == time)) {
        throw StateError('Selected time slot is unavailable.');
      }
      await docRef.set(
        AvailabilityModel(
          photographerId: photographerId,
          date: date,
          slots: slots,
        ).toMap(),
      );
    } else {
      final model = AvailabilityModel.fromMap(doc.data()!);
      final targetIndex = model.slots.indexWhere((slot) => slot.time == time);
      if (targetIndex == -1) {
        throw StateError('Selected time slot is unavailable.');
      }

      final targetSlot = model.slots[targetIndex];
      if (!targetSlot.isAvailable &&
          targetSlot.bookedByBookingId != bookingId) {
        throw StateError('Selected time slot is already booked.');
      }

      final updated = model.slots.map((s) {
        if (s.time == time) {
          return s.copyWith(isAvailable: false, bookedByBookingId: bookingId);
        }
        return s;
      }).toList();
      await docRef.update({'slots': updated.map((s) => s.toMap()).toList()});
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> clientBookingsStream(String clientId) => _firestore
      .collection(FirebaseCollections.bookings)
      .where('clientId', isEqualTo: clientId)
      .orderBy('scheduledDate', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList(),
      );

  Stream<List<BookingModel>> photographerBookingsStream(
    String photographerId,
  ) => _firestore
      .collection(FirebaseCollections.bookings)
      .where('photographerId', isEqualTo: photographerId)
      .orderBy('scheduledDate', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList(),
      );

  Future<BookingModel?> getBookingById(String id) async {
    final doc = await _firestore
        .collection(FirebaseCollections.bookings)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return BookingModel.fromMap(id, doc.data()!);
  }

  Stream<BookingModel?> bookingStream(String id) => _firestore
      .collection(FirebaseCollections.bookings)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? BookingModel.fromMap(id, d.data()!) : null);

  Future<String> submitReview({
    required String bookingId,
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    required double rating,
    required String comment,
  }) async {
    final bookingRef = _firestore
        .collection(FirebaseCollections.bookings)
        .doc(bookingId);

    BookingModel? booking;
    late String reviewId;

    await _firestore.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw StateError('Booking not found.');
      }

      booking = BookingModel.fromMap(bookingId, bookingSnap.data()!);
      if (booking!.clientId != clientId) {
        throw StateError('You can only review your own bookings.');
      }
      if (booking!.status != BookingStatus.completed) {
        throw StateError('Only completed bookings can be reviewed.');
      }
      if (booking!.hasReview) {
        throw StateError('This booking has already been reviewed.');
      }

      final photographerRef = _firestore
          .collection(FirebaseCollections.photographers)
          .doc(booking!.photographerId);
      final photographerSnap = await transaction.get(photographerRef);
      if (!photographerSnap.exists) {
        throw StateError('Photographer profile not found.');
      }

      final reviewRef = photographerRef
          .collection(FirebaseCollections.reviews)
          .doc();
      reviewId = reviewRef.id;

      transaction.set(
        reviewRef,
        ReviewModel(
          id: reviewId,
          photographerId: booking!.photographerId,
          clientId: clientId,
          clientName: clientName,
          clientPhotoUrl: clientPhotoUrl,
          rating: rating,
          comment: comment,
          bookingId: bookingId,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      final photographerData = photographerSnap.data()!;
      final currentReviewCount =
          (photographerData['reviewCount'] as num?)?.toInt() ?? 0;
      final currentRating =
          (photographerData['rating'] as num?)?.toDouble() ?? 0.0;
      final nextReviewCount = currentReviewCount + 1;
      final nextRating =
          ((currentRating * currentReviewCount) + rating) / nextReviewCount;

      transaction.update(photographerRef, {
        'reviewCount': nextReviewCount,
        'rating': double.parse(nextRating.toStringAsFixed(1)),
      });

      transaction.update(bookingRef, {
        'reviewId': reviewId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await NotificationService().createReviewNotification(
      photographerId: booking!.photographerId,
      clientName: clientName,
      rating: rating,
      bookingId: bookingId,
    );

    return reviewId;
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? rescheduleNotes,
  }) async {
    final bookingRef = _firestore
        .collection(FirebaseCollections.bookings)
        .doc(bookingId);
    final nextDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final normalizedRescheduleNotes =
        rescheduleNotes != null && rescheduleNotes.trim().isNotEmpty
        ? rescheduleNotes.trim()
        : null;

    await _firestore.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw StateError('Booking not found.');
      }

      final booking = BookingModel.fromMap(bookingId, bookingSnap.data()!);
      if (booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.declined ||
          booking.status == BookingStatus.completed ||
          booking.status == BookingStatus.inProgress) {
        throw StateError('This booking can no longer be rescheduled.');
      }

      final currentDate = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      if (currentDate == nextDate && booking.scheduledTime == scheduledTime) {
        throw StateError('Please choose a different date or time.');
      }

      final currentAvailabilityRef = _availabilityDocRef(
        booking.photographerId,
        currentDate,
      );
      final nextAvailabilityRef = _availabilityDocRef(
        booking.photographerId,
        nextDate,
      );

      final currentAvailabilitySnap = await transaction.get(
        currentAvailabilityRef,
      );
      final nextAvailabilitySnap =
          currentAvailabilityRef.path == nextAvailabilityRef.path
          ? currentAvailabilitySnap
          : await transaction.get(nextAvailabilityRef);

      final currentSlots = currentAvailabilitySnap.exists
          ? AvailabilityModel.fromMap(currentAvailabilitySnap.data()!).slots
          : AvailabilityModel.defaultSlots();

      final releasedCurrentSlots = currentSlots.map((slot) {
        if (slot.time == booking.scheduledTime &&
            (slot.bookedByBookingId == null ||
                slot.bookedByBookingId == booking.id)) {
          return slot.copyWith(isAvailable: true, bookedByBookingId: null);
        }
        return slot;
      }).toList();

      final nextBaseSlots =
          currentAvailabilityRef.path == nextAvailabilityRef.path
          ? releasedCurrentSlots
          : nextAvailabilitySnap.exists
          ? AvailabilityModel.fromMap(nextAvailabilitySnap.data()!).slots
          : AvailabilityModel.defaultSlots();

      final targetIndex = nextBaseSlots.indexWhere(
        (slot) => slot.time == scheduledTime,
      );
      if (targetIndex == -1) {
        throw StateError('Selected time slot is unavailable.');
      }

      final targetSlot = nextBaseSlots[targetIndex];
      if (!targetSlot.isAvailable &&
          targetSlot.bookedByBookingId != booking.id) {
        throw StateError('Selected time slot is already booked.');
      }

      final reservedNextSlots = nextBaseSlots.map((slot) {
        if (slot.time == scheduledTime) {
          return slot.copyWith(
            isAvailable: false,
            bookedByBookingId: booking.id,
          );
        }
        return slot;
      }).toList();

      if (currentAvailabilityRef.path == nextAvailabilityRef.path) {
        transaction.set(
          currentAvailabilityRef,
          AvailabilityModel(
            photographerId: booking.photographerId,
            date: nextDate,
            slots: reservedNextSlots,
          ).toMap(),
        );
      } else {
        if (currentAvailabilitySnap.exists) {
          transaction.set(
            currentAvailabilityRef,
            AvailabilityModel(
              photographerId: booking.photographerId,
              date: currentDate,
              slots: releasedCurrentSlots,
            ).toMap(),
          );
        }

        transaction.set(
          nextAvailabilityRef,
          AvailabilityModel(
            photographerId: booking.photographerId,
            date: nextDate,
            slots: reservedNextSlots,
          ).toMap(),
        );
      }

      transaction.update(bookingRef, {
        'scheduledDate': Timestamp.fromDate(nextDate),
        'scheduledTime': scheduledTime,
        'status': BookingStatus.requested.value,
        'rescheduleNotes': normalizedRescheduleNotes,
        'rescheduledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─── Convenience Status Helpers ──────────────────────────────────────────

  Future<void> acceptBooking(String bookingId) =>
      updateStatus(bookingId, BookingStatus.confirmed);

  Future<void> declineBooking(String bookingId) =>
      updateStatus(bookingId, BookingStatus.declined);

  Future<void> cancelBooking(String bookingId) =>
      updateStatus(bookingId, BookingStatus.cancelled);

  Future<void> markDelivered({
    required String bookingId,
    required String deliveryLink,
    String? deliveryNote,
  }) async {
    await _firestore
        .collection(FirebaseCollections.bookings)
        .doc(bookingId)
        .update({
          'status': BookingStatus.inProgress.value,
          'deliveryLink': deliveryLink.trim(),
          'deliveryNote': deliveryNote?.trim(),
          'deliveredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markCompleted(String bookingId) =>
      updateStatus(bookingId, BookingStatus.completed);

  // ─── Update Status ────────────────────────────────────────────────────────

  Future<void> updateStatus(
    String bookingId,
    BookingStatus status, {
    String? notes,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) return;

    final updateData = <String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (notes != null) updateData['notes'] = notes;

    await _firestore
        .collection(FirebaseCollections.bookings)
        .doc(bookingId)
        .update(updateData);

    // Free the time slot if declining or cancelling
    if (status == BookingStatus.declined || status == BookingStatus.cancelled) {
      await _freeSlot(
        photographerId: booking.photographerId,
        date: booking.scheduledDate,
        time: booking.scheduledTime,
        bookingId: booking.id,
      );
    }

    // Send notifications based on transition
    switch (status) {
      case BookingStatus.confirmed:
        await NotificationService().createBookingConfirmedNotification(
          clientId: booking.clientId,
          photographerName: booking.photographerName,
          bookingId: bookingId,
          scheduledDate: booking.scheduledDate,
        );
        break;
      case BookingStatus.declined:
        await NotificationService().createBookingDeclinedNotification(
          clientId: booking.clientId,
          photographerName: booking.photographerName,
          bookingId: bookingId,
        );
        break;
      default:
        break;
    }
  }

  Future<void> _freeSlot({
    required String photographerId,
    required DateTime date,
    required String time,
    String? bookingId,
  }) async {
    final docRef = _availabilityDocRef(photographerId, date);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final model = AvailabilityModel.fromMap(doc.data()!);
    final updated = model.slots.map((s) {
      if (s.time == time &&
          (bookingId == null || s.bookedByBookingId == bookingId)) {
        return s.copyWith(isAvailable: true, bookedByBookingId: null);
      }
      return s;
    }).toList();
    await docRef.update({'slots': updated.map((s) => s.toMap()).toList()});
  }

  DocumentReference<Map<String, dynamic>> _availabilityDocRef(
    String photographerId,
    DateTime date,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.availability)
        .doc(AvailabilityModel.docId(normalizedDate));
  }
}
