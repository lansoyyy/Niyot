import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/booking_expiration.dart';
import '../core/booking_policy.dart';
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

  static const _slotBlockingStatuses = {
    BookingStatuses.paymentPending,
    BookingStatuses.requested,
    BookingStatuses.confirmed,
    BookingStatuses.inProgress,
  };

  /// Whether the photographer has no other active booking at this date/time.
  Future<bool> isTimeSlotAvailable({
    required String photographerId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? excludeBookingId,
  }) async {
    if (await hasConflictingActiveBooking(
      photographerId: photographerId,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      excludeBookingId: excludeBookingId,
    )) {
      return false;
    }

    final day = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final docRef = _availabilityDocRef(photographerId, day);
    final doc = await docRef.get();
    if (!doc.exists) return true;

    final model = AvailabilityModel.fromMap(doc.data()!);
    final index = model.slots.indexWhere((s) => s.time == scheduledTime);
    if (index == -1) return false;
    final timeSlot = model.slots[index];
    if (timeSlot.isAvailable) return true;
    return excludeBookingId != null &&
        timeSlot.bookedByBookingId == excludeBookingId;
  }

  Future<bool> hasConflictingActiveBooking({
    required String photographerId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? excludeBookingId,
  }) async {
    final day = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final snap = await _firestore
        .collection(FirebaseCollections.bookings)
        .where('photographerId', isEqualTo: photographerId)
        .get();

    for (final doc in snap.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      if (!_slotBlockingStatuses.contains(status)) continue;

      final bookingDay = (data['scheduledDate'] as Timestamp?)?.toDate();
      if (bookingDay == null) continue;
      final normalized = DateTime(
        bookingDay.year,
        bookingDay.month,
        bookingDay.day,
      );
      if (normalized != day) continue;
      if ((data['scheduledTime'] as String? ?? '') == scheduledTime) {
        return true;
      }
    }
    return false;
  }

  /// Creates a booking and reserves the slot atomically. Photographer is notified
  /// only after cash payment ([promoteBookingAfterCashConfirmation]).
  Future<String> createBooking(BookingModel booking) async {
    await cancelDuplicatePendingForSlot(
      clientId: booking.clientId,
      photographerId: booking.photographerId,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
    );

    final available = await isTimeSlotAvailable(
      photographerId: booking.photographerId,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
    );
    if (!available) {
      throw StateError('Selected time slot is already booked.');
    }

    final docRef = _firestore.collection(FirebaseCollections.bookings).doc();
    final bookingId = docRef.id;
    final data = _mapWithExpiration(booking);

    await _firestore.runTransaction((transaction) async {
      await _applySlotReservation(
        transaction: transaction,
        photographerId: booking.photographerId,
        date: booking.scheduledDate,
        time: booking.scheduledTime,
        bookingId: bookingId,
      );
      transaction.set(docRef, data);
    });

    return bookingId;
  }

  Map<String, dynamic> _mapWithExpiration(BookingModel booking) {
    final data = booking.toMap();
    data['expiresAt'] = Timestamp.fromDate(BookingExpiration.expiresAtFor(booking));
    return data;
  }

  /// Cancels other pending bookings for the same client, photographer, and slot.
  Future<void> cancelDuplicatePendingForSlot({
    required String clientId,
    required String photographerId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? keepBookingId,
  }) async {
    final day = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final snap = await _firestore
        .collection(FirebaseCollections.bookings)
        .where('photographerId', isEqualTo: photographerId)
        .where('clientId', isEqualTo: clientId)
        .get();

    for (final doc in snap.docs) {
      if (keepBookingId != null && doc.id == keepBookingId) continue;
      final b = BookingModel.fromMap(doc.id, doc.data());
      if (!BookingExpiration.isPendingStatus(b.status)) continue;
      final bDay = DateTime(
        b.scheduledDate.year,
        b.scheduledDate.month,
        b.scheduledDate.day,
      );
      if (bDay != day || b.scheduledTime != scheduledTime) continue;
      await updateStatus(doc.id, BookingStatus.cancelled);
    }
  }

  Future<void> expireBookingIfNeeded(BookingModel booking) async {
    if (!BookingExpiration.hasExpired(booking)) return;

    await updateStatus(
      booking.id,
      BookingStatus.cancelled,
      notes: 'Request expired',
    );

    try {
      await NotificationService().createBookingExpiredNotification(
        userId: booking.clientId,
        bookingId: booking.id,
        isPhotographer: false,
      );
      await NotificationService().createBookingExpiredNotification(
        userId: booking.photographerId,
        bookingId: booking.id,
        isPhotographer: true,
      );
    } catch (_) {}
  }

  Future<List<BookingModel>> _syncExpirations(List<BookingModel> list) async {
    final active = <BookingModel>[];
    for (final b in list) {
      if (BookingExpiration.hasExpired(b)) {
        unawaited(expireBookingIfNeeded(b));
        continue;
      }
      active.add(b);
    }
    return active;
  }

  /// Call after the client confirms cash payment. Moves [payment_pending] →
  /// [requested], notifies the photographer, and increments booking count.
  Future<void> promoteBookingAfterCashConfirmation(String bookingId) async {
    final bookingRef = _firestore
        .collection(FirebaseCollections.bookings)
        .doc(bookingId);
    final snap = await bookingRef.get();
    if (!snap.exists) return;

    final booking = BookingModel.fromMap(bookingId, snap.data()!);
    if (booking.status != BookingStatus.paymentPending) return;

    await bookingRef.update({
      'status': BookingStatuses.requested,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await NotificationService().createBookingRequestNotification(
        photographerId: booking.photographerId,
        clientName: booking.clientName,
        bookingId: bookingId,
        scheduledDate: booking.scheduledDate,
      );
    } catch (_) {
      // Notification failure must not block status promotion.
    }

    await _bumpPhotographerBookingCount(booking.photographerId);
  }

  /// After the client accepts a custom chat offer: creates a [requested]
  /// booking (same queue as post–cash‑payment package bookings), reserves the
  /// time slot, notifies the photographer, and increments booking count.
  Future<String> createBookingFromAcceptedOffer(BookingModel booking) async {
    if (booking.status != BookingStatus.requested) {
      throw ArgumentError(
        'createBookingFromAcceptedOffer expects status requested, '
        'got ${booking.status}',
      );
    }

    await cancelDuplicatePendingForSlot(
      clientId: booking.clientId,
      photographerId: booking.photographerId,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
    );

    final available = await isTimeSlotAvailable(
      photographerId: booking.photographerId,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
    );
    if (!available) {
      throw StateError('Selected time slot is already booked.');
    }

    final docRef = _firestore.collection(FirebaseCollections.bookings).doc();
    final bookingId = docRef.id;
    final data = _mapWithExpiration(booking);

    await _firestore.runTransaction((transaction) async {
      await _applySlotReservation(
        transaction: transaction,
        photographerId: booking.photographerId,
        date: booking.scheduledDate,
        time: booking.scheduledTime,
        bookingId: bookingId,
      );
      transaction.set(docRef, data);
    });

    try {
      await NotificationService().createBookingRequestNotification(
        photographerId: booking.photographerId,
        clientName: booking.clientName,
        bookingId: bookingId,
        scheduledDate: booking.scheduledDate,
      );
    } catch (_) {
      // Notification failure must not block offer acceptance.
    }

    await _bumpPhotographerBookingCount(booking.photographerId);

    return bookingId;
  }

  /// Increments the photographer's bookingCount, creating the field if the
  /// photographer doc is missing or doesn't yet have the field. Failures here
  /// are swallowed so they don't break the booking flow.
  Future<void> _bumpPhotographerBookingCount(String photographerId) async {
    final ref = _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId);
    try {
      await ref.set({
        'bookingCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal: leave the counter as-is rather than break the user flow.
    }
  }

  Future<void> _applySlotReservation({
    required Transaction transaction,
    required String photographerId,
    required DateTime date,
    required String time,
    required String bookingId,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final docRef = _availabilityDocRef(photographerId, normalizedDate);
    final doc = await transaction.get(docRef);

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
      transaction.set(
        docRef,
        AvailabilityModel(
          photographerId: photographerId,
          date: normalizedDate,
          slots: slots,
        ).toMap(),
      );
      return;
    }

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
    transaction.update(
      docRef,
      {'slots': updated.map((s) => s.toMap()).toList()},
    );
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> clientBookingsStream(String clientId) =>
      _firestore
          .collection(FirebaseCollections.bookings)
          .where('clientId', isEqualTo: clientId)
          .snapshots()
          .asyncMap((snap) async {
            final list = snap.docs
                .map((d) => BookingModel.fromMap(d.id, d.data()))
                .toList();
            list.sort(
              (a, b) =>
                  a.scheduledSessionStart.compareTo(b.scheduledSessionStart),
            );
            return _syncExpirations(list);
          });

  /// Bookings that need the user's attention (badge on bottom nav).
  Stream<int> pendingActionCountStream(
    String userId, {
    required bool isPhotographer,
  }) {
    final source = isPhotographer
        ? photographerBookingsStream(userId)
        : clientBookingsStream(userId);
    return source.map((bookings) {
      if (isPhotographer) {
        return bookings
            .where(
              (b) =>
                  (b.status == BookingStatus.requested &&
                      !b.isReschedulePending) ||
                  b.status == BookingStatus.paymentPending,
            )
            .length;
      }
      return bookings.where((b) {
        if (b.status == BookingStatus.paymentPending) return true;
        return BookingPolicy.canRespondToReschedule(b, userId);
      }).length;
    });
  }

  Stream<List<BookingModel>> photographerBookingsStream(
    String photographerId,
  ) =>
      _firestore
          .collection(FirebaseCollections.bookings)
          .where('photographerId', isEqualTo: photographerId)
          .snapshots()
          .asyncMap((snap) async {
            final list = snap.docs
                .map((d) => BookingModel.fromMap(d.id, d.data()))
                .toList();
            list.sort(
              (a, b) =>
                  a.scheduledSessionStart.compareTo(b.scheduledSessionStart),
            );
            return _syncExpirations(list);
          });

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
    required String requestedBy,
    String? rescheduleNotes,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw StateError('Booking not found.');
    }

    final mode = BookingPolicy.rescheduleMode(existing);
    if (mode == RescheduleMode.disabled) {
      throw StateError(BookingPolicy.rescheduleBlockedMessage(existing));
    }

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
    final graceImmediate = mode == RescheduleMode.graceImmediate;

    await _firestore.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw StateError('Booking not found.');
      }

      final booking = BookingModel.fromMap(bookingId, bookingSnap.data()!);
      if (booking.status != BookingStatus.confirmed) {
        throw StateError('Only confirmed bookings can be rescheduled.');
      }

      final currentDate = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      if (currentDate == nextDate && booking.scheduledTime == scheduledTime) {
        throw StateError('Please choose a different date or time.');
      }

      await _applySlotChangeInTransaction(
        transaction: transaction,
        booking: booking,
        fromDate: currentDate,
        fromTime: booking.scheduledTime,
        toDate: nextDate,
        toTime: scheduledTime,
      );

      final updateData = <String, dynamic>{
        'scheduledDate': Timestamp.fromDate(nextDate),
        'scheduledTime': scheduledTime,
        'rescheduleNotes': normalizedRescheduleNotes,
        'rescheduledAt': FieldValue.serverTimestamp(),
        'rescheduleRequestedBy': requestedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (graceImmediate) {
        updateData['status'] = BookingStatus.confirmed.value;
        updateData['previousScheduledDate'] = FieldValue.delete();
        updateData['previousScheduledTime'] = FieldValue.delete();
      } else {
        updateData['status'] = BookingStatus.requested.value;
        updateData['previousScheduledDate'] = Timestamp.fromDate(currentDate);
        updateData['previousScheduledTime'] = booking.scheduledTime;
      }

      transaction.update(bookingRef, updateData);
    });

    final updated = await getBookingById(bookingId);
    if (updated == null) return;

    try {
      final recipientId = requestedBy == 'client'
          ? updated.photographerId
          : updated.clientId;
      final requesterName = requestedBy == 'client'
          ? updated.clientName
          : updated.photographerName;

      if (graceImmediate) {
        await NotificationService().createRescheduleConfirmedNotification(
          recipientId: recipientId,
          changerName: requesterName,
          bookingId: bookingId,
          scheduledDate: updated.scheduledDate,
          scheduledTime: updated.scheduledTime,
        );
      } else {
        await NotificationService().createRescheduleRequestNotification(
          recipientId: recipientId,
          requesterName: requesterName,
          bookingId: bookingId,
          scheduledDate: updated.scheduledDate,
          scheduledTime: updated.scheduledTime,
        );
      }
    } catch (_) {}
  }

  Future<void> rejectRescheduleRequest(String bookingId) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) return;

    final bookingRef = _firestore
        .collection(FirebaseCollections.bookings)
        .doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw StateError('Booking not found.');
      }

      final booking = BookingModel.fromMap(bookingId, bookingSnap.data()!);
      if (!BookingPolicy.isReschedulePending(booking)) {
        throw StateError('This booking is not waiting for reschedule approval.');
      }

      final previousDate = booking.previousScheduledDate;
      final previousTime = booking.previousScheduledTime;
      if (previousDate == null || previousTime == null) {
        throw StateError('Unable to restore the previous schedule.');
      }

      final currentDate = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      final restoreDate = DateTime(
        previousDate.year,
        previousDate.month,
        previousDate.day,
      );

      await _applySlotChangeInTransaction(
        transaction: transaction,
        booking: booking,
        fromDate: currentDate,
        fromTime: booking.scheduledTime,
        toDate: restoreDate,
        toTime: previousTime,
      );

      transaction.update(bookingRef, {
        'scheduledDate': Timestamp.fromDate(restoreDate),
        'scheduledTime': previousTime,
        'status': BookingStatus.confirmed.value,
        'rescheduleNotes': FieldValue.delete(),
        'rescheduledAt': FieldValue.delete(),
        'rescheduleRequestedBy': FieldValue.delete(),
        'previousScheduledDate': FieldValue.delete(),
        'previousScheduledTime': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (!BookingPolicy.isReschedulePending(existing)) return;

    final recipientId = existing.rescheduleRequestedBy == 'client'
        ? existing.clientId
        : existing.photographerId;
    try {
      await NotificationService().createRescheduleDeclinedNotification(
        recipientId: recipientId,
        bookingId: bookingId,
      );
    } catch (_) {}
  }

  Future<void> _applySlotChangeInTransaction({
    required Transaction transaction,
    required BookingModel booking,
    required DateTime fromDate,
    required String fromTime,
    required DateTime toDate,
    required String toTime,
  }) async {
    final currentAvailabilityRef = _availabilityDocRef(
      booking.photographerId,
      fromDate,
    );
    final nextAvailabilityRef = _availabilityDocRef(
      booking.photographerId,
      toDate,
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
      if (slot.time == fromTime &&
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

    final targetIndex = nextBaseSlots.indexWhere((slot) => slot.time == toTime);
    if (targetIndex == -1) {
      throw StateError('Selected time slot is unavailable.');
    }

    final targetSlot = nextBaseSlots[targetIndex];
    if (!targetSlot.isAvailable && targetSlot.bookedByBookingId != booking.id) {
      throw StateError('Selected time slot is already booked.');
    }

    final reservedNextSlots = nextBaseSlots.map((slot) {
      if (slot.time == toTime) {
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
          date: toDate,
          slots: reservedNextSlots,
        ).toMap(),
      );
    } else {
      if (currentAvailabilitySnap.exists) {
        transaction.set(
          currentAvailabilityRef,
          AvailabilityModel(
            photographerId: booking.photographerId,
            date: fromDate,
            slots: releasedCurrentSlots,
          ).toMap(),
        );
      }

      transaction.set(
        nextAvailabilityRef,
        AvailabilityModel(
          photographerId: booking.photographerId,
          date: toDate,
          slots: reservedNextSlots,
        ).toMap(),
      );
    }
  }

  // ─── Convenience Status Helpers ──────────────────────────────────────────

  Future<void> acceptBooking(String bookingId) =>
      updateStatus(bookingId, BookingStatus.confirmed);

  Future<void> declineBooking(String bookingId) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) return;
    if (BookingPolicy.isReschedulePending(booking)) {
      await rejectRescheduleRequest(bookingId);
      return;
    }
    await updateStatus(bookingId, BookingStatus.declined);
  }

  Future<void> cancelBooking(
    String bookingId, {
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) return;

    if (!BookingPolicy.canCancel(booking)) {
      throw StateError(BookingPolicy.cancelBlockedMessage(booking));
    }

    if (BookingPolicy.requiresCancellationReason(booking) &&
        (cancellationReason == null || cancellationReason.trim().isEmpty)) {
      throw StateError('Please provide a cancellation reason.');
    }

    await updateStatus(
      bookingId,
      BookingStatus.cancelled,
      cancelledBy: cancelledBy,
      cancellationReason: cancellationReason?.trim(),
    );
  }

  Future<void> markDelivered({
    required String bookingId,
    required String deliveryLink,
    String? deliveryNote,
  }) async {
    final booking = await getBookingById(bookingId);

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

    if (booking != null) {
      try {
        await NotificationService().createPhotosDeliveredNotification(
          clientId: booking.clientId,
          photographerName: booking.photographerName,
          bookingId: bookingId,
        );
      } catch (_) {}
    }
  }

  Future<void> markCompleted(String bookingId) =>
      updateStatus(bookingId, BookingStatus.completed);

  // ─── Update Status ────────────────────────────────────────────────────────

  Future<void> updateStatus(
    String bookingId,
    BookingStatus status, {
    String? notes,
    String? cancelledBy,
    String? cancellationReason,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) return;

    final updateData = <String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (notes != null) updateData['notes'] = notes;

    if (status == BookingStatus.confirmed) {
      updateData['confirmedAt'] = FieldValue.serverTimestamp();
      updateData['rescheduleNotes'] = FieldValue.delete();
      updateData['rescheduledAt'] = FieldValue.delete();
      updateData['rescheduleRequestedBy'] = FieldValue.delete();
      updateData['previousScheduledDate'] = FieldValue.delete();
      updateData['previousScheduledTime'] = FieldValue.delete();
    }

    if (status == BookingStatus.cancelled) {
      if (cancelledBy != null) updateData['cancelledBy'] = cancelledBy;
      if (cancellationReason != null && cancellationReason.isNotEmpty) {
        updateData['cancellationReason'] = cancellationReason;
      }
    }

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
      case BookingStatus.cancelled:
        if (cancelledBy != null && notes != 'Request expired') {
          final recipientId = cancelledBy == 'photographer'
              ? booking.clientId
              : booking.photographerId;
          try {
            await NotificationService().createBookingCancelledNotification(
              recipientId: recipientId,
              bookingId: bookingId,
              cancelledByPhotographer: cancelledBy == 'photographer',
              reason: cancellationReason,
            );
          } catch (_) {}
        }
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
