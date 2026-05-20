import '../models/booking_model.dart';

/// Rules for how long a [requested] / [payment_pending] booking stays open.
class BookingExpiration {
  BookingExpiration._();

  static const Duration requestWindow = Duration(hours: 72);

  /// Expires at the earlier of 72 hours after creation or the shoot start time.
  static DateTime expiresAtFor(BookingModel booking) => expiresAtForTimes(
        createdAt: booking.createdAt,
        scheduledSessionStart: booking.scheduledSessionStart,
      );

  static DateTime expiresAtForTimes({
    required DateTime createdAt,
    required DateTime scheduledSessionStart,
  }) {
    final windowEnd = createdAt.add(requestWindow);
    return scheduledSessionStart.isBefore(windowEnd)
        ? scheduledSessionStart
        : windowEnd;
  }

  static bool isPendingStatus(BookingStatus status) =>
      status == BookingStatus.requested ||
      status == BookingStatus.paymentPending;

  static bool hasExpired(BookingModel booking) {
    if (!isPendingStatus(booking.status)) return false;
    final expiresAt =
        booking.expiresAt ?? expiresAtFor(booking);
    return DateTime.now().isAfter(expiresAt);
  }
}

/// Countdown until a session starts (shared by home, dashboard, booking detail).
class SessionCountdown {
  SessionCountdown._();

  static Duration until(DateTime sessionStart) {
    final diff = sessionStart.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static String compactLabel(Duration d) {
    if (d == Duration.zero) return 'Today';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} $hours hr';
    }
    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }

  static String shootDayLabel(Duration d) {
    if (d == Duration.zero) return 'Today';
    final days = d.inDays;
    if (days == 0) return 'Today';
    return 'in $days day${days == 1 ? '' : 's'}';
  }
}
