import '../models/booking_model.dart';

enum RescheduleMode {
  disabled,
  /// Within 4 hours of acceptance — new date applies immediately.
  graceImmediate,
  /// More than 24 hours before shoot — other party must approve.
  requiresApproval,
}

/// Reschedule / cancel rules shared by UI and [BookingService].
class BookingPolicy {
  BookingPolicy._();

  static const Duration gracePeriodAfterConfirm = Duration(hours: 4);
  static const Duration rescheduleCutoff = Duration(hours: 24);

  static Duration timeUntilShoot(BookingModel booking) {
    final diff = booking.scheduledSessionStart.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static bool isShootDay(BookingModel booking) {
    final now = DateTime.now();
    final day = booking.scheduledDay;
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  static bool isNotYetAccepted(BookingModel booking) =>
      booking.status == BookingStatus.paymentPending ||
      (booking.status == BookingStatus.requested &&
          !isReschedulePending(booking));

  static bool isWithinGracePeriod(BookingModel booking) {
    final confirmedAt = booking.confirmedAt;
    if (confirmedAt == null) return false;
    return DateTime.now().difference(confirmedAt) <= gracePeriodAfterConfirm;
  }

  static bool isReschedulePending(BookingModel booking) =>
      booking.isReschedulePending;

  /// Who must respond to a pending reschedule request.
  static String? rescheduleResponderId(BookingModel booking) {
    if (!isReschedulePending(booking)) return null;
    final by = booking.rescheduleRequestedBy;
    if (by == 'client') return booking.photographerId;
    if (by == 'photographer') return booking.clientId;
    return booking.photographerId;
  }

  static bool canRespondToReschedule(
    BookingModel booking,
    String currentUserId,
  ) =>
      rescheduleResponderId(booking) == currentUserId;

  static bool canCancel(BookingModel booking) {
    if (booking.isPast) return false;
    if (booking.status == BookingStatus.inProgress) return false;
    if (isShootDay(booking)) return false;
    if (isNotYetAccepted(booking)) return true;
    if (isReschedulePending(booking)) return true;
    if (booking.status == BookingStatus.confirmed) return true;
    return false;
  }

  static bool requiresCancellationReason(BookingModel booking) {
    if (!canCancel(booking)) return false;
    if (isNotYetAccepted(booking)) return false;
    if (booking.status != BookingStatus.confirmed &&
        !isReschedulePending(booking)) {
      return false;
    }
    final until = timeUntilShoot(booking);
    return until <= rescheduleCutoff;
  }

  static bool canReschedule(BookingModel booking) {
    if (isReschedulePending(booking)) return false;
    if (booking.status != BookingStatus.confirmed) return false;
    if (isShootDay(booking)) return false;
    // Prevent immediate re-rescheduling after a recent reschedule
    final rescheduledAt = booking.rescheduledAt;
    if (rescheduledAt != null) {
      final diff = DateTime.now().difference(rescheduledAt);
      if (diff < const Duration(hours: 1)) return false;
    }
    if (isWithinGracePeriod(booking)) return true;
    return timeUntilShoot(booking) > rescheduleCutoff;
  }

  static RescheduleMode rescheduleMode(BookingModel booking) {
    if (!canReschedule(booking)) return RescheduleMode.disabled;
    if (isWithinGracePeriod(booking)) return RescheduleMode.graceImmediate;
    return RescheduleMode.requiresApproval;
  }

  static String cancelBlockedMessage(BookingModel booking) {
    if (isShootDay(booking)) {
      return 'Bookings cannot be cancelled on shoot day. Please contact support if you need help.';
    }
    return 'This booking can no longer be cancelled.';
  }

  static String rescheduleBlockedMessage(BookingModel booking) {
    if (isShootDay(booking)) {
      return 'Rescheduling is locked on shoot day. Please contact support if you need help.';
    }
    if (booking.status == BookingStatus.confirmed &&
        timeUntilShoot(booking) <= rescheduleCutoff &&
        !isWithinGracePeriod(booking)) {
      return 'Rescheduling is disabled within 24 hours of the shoot. You can still cancel with a reason.';
    }
    return 'This booking can no longer be rescheduled.';
  }

  static String gracePeriodHint() =>
      'You are within the 4-hour grace window after acceptance. '
      'The new date applies immediately.';

  static String approvalRescheduleHint() =>
      'The other party must approve the new date and time.';

  static String shootDayLockedHint() =>
      'Shoot day — reschedule and cancel are locked. Contact support for disputes.';
}
