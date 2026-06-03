import '../core/booking_policy.dart';
import '../models/booking_model.dart';
import '../services/booking_view_tracker.dart';

/// Actionable booking counts for My Bookings summary cards.
class BookingAttentionCounts {
  const BookingAttentionCounts({
    this.bookingRequest = 0,
    this.reschedule = 0,
    this.cancel = 0,
    this.pending = 0,
    this.delivered = 0,
  });

  final int bookingRequest;
  final int reschedule;
  final int cancel;
  final int pending;
  final int delivered;

  bool get hasPhotographerActions =>
      bookingRequest > 0 || reschedule > 0 || cancel > 0;

  bool get hasClientActions => pending > 0 || reschedule > 0 || delivered > 0;

  factory BookingAttentionCounts.forPhotographer(
    List<BookingModel> all,
    String userId,
  ) {
    final tracker = BookingViewTracker.instance;
    var bookingRequest = 0;
    var reschedule = 0;
    var cancel = 0;

    for (final b in all) {
      if (b.status == BookingStatus.requested && !b.isReschedulePending) {
        bookingRequest++;
      } else if (BookingPolicy.canRespondToReschedule(b, userId)) {
        reschedule++;
      } else if (b.status == BookingStatus.cancelled &&
          b.cancelledBy == 'client' &&
          !tracker.isViewed(b.id)) {
        cancel++;
      }
    }

    return BookingAttentionCounts(
      bookingRequest: bookingRequest,
      reschedule: reschedule,
      cancel: cancel,
    );
  }

  factory BookingAttentionCounts.forClient(
    List<BookingModel> all,
    String userId,
  ) {
    final tracker = BookingViewTracker.instance;
    var pending = 0;
    var reschedule = 0;
    var delivered = 0;

    for (final b in all) {
      if (b.status == BookingStatus.paymentPending) {
        pending++;
      } else if (b.status == BookingStatus.requested && !b.isReschedulePending) {
        pending++;
      } else if (BookingPolicy.canRespondToReschedule(b, userId)) {
        reschedule++;
      } else if (b.status == BookingStatus.inProgress &&
          b.deliveryLink != null &&
          b.deliveryLink!.isNotEmpty &&
          !tracker.isViewed(b.id)) {
        delivered++;
      }
    }

    return BookingAttentionCounts(
      pending: pending,
      reschedule: reschedule,
      delivered: delivered,
    );
  }
}
