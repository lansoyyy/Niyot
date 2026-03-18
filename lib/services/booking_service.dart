import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_constants.dart';
import '../models/booking_model.dart';
import '../models/availability_model.dart';
import 'notification_service.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final _firestore = FirebaseFirestore.instance;

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<String> createBooking(BookingModel booking) async {
    final docRef =
        _firestore.collection(FirebaseCollections.bookings).doc();

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
      // Create availability doc with all slots blocked for this time
      final slots = AvailabilityModel.defaultSlots().map((s) {
        if (s.time == time) {
          return s.copyWith(
              isAvailable: false, bookedByBookingId: bookingId);
        }
        return s;
      }).toList();
      await docRef.set(AvailabilityModel(
        photographerId: photographerId,
        date: date,
        slots: slots,
      ).toMap());
    } else {
      final model = AvailabilityModel.fromMap(doc.data()!);
      final updated = model.slots.map((s) {
        if (s.time == time) {
          return s.copyWith(
              isAvailable: false, bookedByBookingId: bookingId);
        }
        return s;
      }).toList();
      await docRef.update({'slots': updated.map((s) => s.toMap()).toList()});
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> clientBookingsStream(String clientId) =>
      _firestore
          .collection(FirebaseCollections.bookings)
          .where('clientId', isEqualTo: clientId)
          .orderBy('scheduledDate', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());

  Stream<List<BookingModel>> photographerBookingsStream(String photographerId) =>
      _firestore
          .collection(FirebaseCollections.bookings)
          .where('photographerId', isEqualTo: photographerId)
          .orderBy('scheduledDate', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());

  Future<BookingModel?> getBookingById(String id) async {
    final doc =
        await _firestore.collection(FirebaseCollections.bookings).doc(id).get();
    if (!doc.exists) return null;
    return BookingModel.fromMap(id, doc.data()!);
  }

  Stream<BookingModel?> bookingStream(String id) =>
      _firestore
          .collection(FirebaseCollections.bookings)
          .doc(id)
          .snapshots()
          .map((d) =>
              d.exists ? BookingModel.fromMap(id, d.data()!) : null);

  // ─── Update Status ────────────────────────────────────────────────────────

  Future<void> updateStatus(String bookingId, BookingStatus status,
      {String? notes}) async {
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
    if (status == BookingStatus.declined ||
        status == BookingStatus.cancelled) {
      await _freeSlot(
        photographerId: booking.photographerId,
        date: booking.scheduledDate,
        time: booking.scheduledTime,
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
  }) async {
    final docId = AvailabilityModel.docId(date);
    final docRef = _firestore
        .collection(FirebaseCollections.photographers)
        .doc(photographerId)
        .collection(FirebaseCollections.availability)
        .doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final model = AvailabilityModel.fromMap(doc.data()!);
    final updated = model.slots.map((s) {
      if (s.time == time) {
        return s.copyWith(isAvailable: true, bookedByBookingId: null);
      }
      return s;
    }).toList();
    await docRef.update({'slots': updated.map((s) => s.toMap()).toList()});
  }
}
