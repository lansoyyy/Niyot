import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_policy.dart';
import '../../models/booking_model.dart';

/// Contextual copy explaining why reschedule/cancel is allowed or blocked.
class BookingPolicyNotice extends StatelessWidget {
  const BookingPolicyNotice({
    super.key,
    required this.booking,
    this.showRescheduleHint = false,
  });

  final BookingModel booking;
  final bool showRescheduleHint;

  @override
  Widget build(BuildContext context) {
    final message = _messageFor(booking, showRescheduleHint);
    if (message == null) return const SizedBox.shrink();

    final locked = BookingPolicy.isShootDay(booking) &&
        booking.status == BookingStatus.confirmed;
    final grace = showRescheduleHint &&
        BookingPolicy.rescheduleMode(booking) == RescheduleMode.graceImmediate;

    final bg = locked
        ? const Color(0xFFFFEBEE)
        : grace
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFE3F2FD);
    final border = locked
        ? const Color(0xFFFFCDD2)
        : grace
        ? const Color(0xFFC8E6C9)
        : const Color(0xFFBBDEFB);
    final icon = locked
        ? Icons.lock_outline_rounded
        : grace
        ? Icons.schedule_rounded
        : Icons.info_outline_rounded;
    final iconColor = locked
        ? const Color(0xFFC62828)
        : grace
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1976D2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF374151),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _messageFor(BookingModel booking, bool showRescheduleHint) {
    if (BookingPolicy.isShootDay(booking) &&
        booking.status == BookingStatus.confirmed) {
      return BookingPolicy.shootDayLockedHint();
    }
    if (showRescheduleHint) {
      final mode = BookingPolicy.rescheduleMode(booking);
      if (mode == RescheduleMode.graceImmediate) {
        return BookingPolicy.gracePeriodHint();
      }
      if (mode == RescheduleMode.requiresApproval) {
        return BookingPolicy.approvalRescheduleHint();
      }
      if (!BookingPolicy.canReschedule(booking)) {
        return BookingPolicy.rescheduleBlockedMessage(booking);
      }
    }
    if (BookingPolicy.requiresCancellationReason(booking)) {
      return 'Less than 24 hours before the shoot — please provide a reason '
          '(e.g. emergency or weather).';
    }
    if (BookingPolicy.isNotYetAccepted(booking)) {
      return 'This booking is not confirmed yet. You can cancel instantly; '
          'to change the time, cancel and create a new request.';
    }
    return null;
  }
}
