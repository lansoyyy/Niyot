/// Custom chat offer expiry copy (24h window, ticks down by hour).
class OfferExpiration {
  OfferExpiration._();

  static String hoursRemainingLabel(DateTime expiresAt) {
    final now = DateTime.now();
    if (!expiresAt.isAfter(now)) return 'This offer has expired';

    final remaining = expiresAt.difference(now);
    final hours = remaining.inHours;
    if (hours <= 0) {
      final minutes = remaining.inMinutes;
      if (minutes <= 0) return 'Expires soon';
      return 'Expires in $minutes min';
    }
    if (hours == 1) return 'Expires in 1 hour';
    return 'Expires in $hours hours';
  }
}
