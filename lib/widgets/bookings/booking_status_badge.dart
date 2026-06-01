import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/booking_model.dart';

/// Status pill for booking cards and detail headers.
class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({
    super.key,
    required this.booking,
    this.compact = false,
    this.onDarkBackground = false,
  });

  final BookingModel booking;
  final bool compact;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final label = booking.statusBadgeLabel;
    final colors = _colorsFor(booking);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: onDarkBackground ? colors.background.withValues(alpha: 0.95) : colors.background,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: booking.isReschedulePending
            ? Border.all(color: colors.foreground.withValues(alpha: 0.35))
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }

  _BadgeColors _colorsFor(BookingModel booking) {
    if (booking.isReschedulePending) {
      return const _BadgeColors(
        foreground: Color(0xFF1565C0),
        background: Color(0xFFE3F2FD),
      );
    }

    switch (booking.status) {
      case BookingStatus.confirmed:
        return const _BadgeColors(
          foreground: Color(0xFF2E7D32),
          background: Color(0xFFE8F5E9),
        );
      case BookingStatus.requested:
        return const _BadgeColors(
          foreground: AppColors.warning,
          background: Color(0xFFFFF3E0),
        );
      case BookingStatus.paymentPending:
        return const _BadgeColors(
          foreground: Color(0xFFFB8C00),
          background: Color(0xFFFFF8E1),
        );
      case BookingStatus.inProgress:
        if (booking.deliveryLink != null && booking.deliveryLink!.isNotEmpty) {
          return const _BadgeColors(
            foreground: Color(0xFF2E7D32),
            background: Color(0xFFE8F5E9),
          );
        }
        return const _BadgeColors(
          foreground: Color(0xFF1565C0),
          background: Color(0xFFE3F2FD),
        );
      case BookingStatus.completed:
        return const _BadgeColors(
          foreground: AppColors.gray500,
          background: AppColors.gray100,
        );
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return const _BadgeColors(
          foreground: AppColors.primary,
          background: AppColors.primarySurface,
        );
    }
  }
}

class _BadgeColors {
  const _BadgeColors({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

/// Secondary label shown on booking list cards during reschedule approval.
class RescheduleRequestMark extends StatelessWidget {
  const RescheduleRequestMark({this.onDarkBackground = false, super.key});

  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    return Text(
      '(reschedule request)',
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: onDarkBackground
            ? Colors.white.withValues(alpha: 0.9)
            : const Color(0xFF1565C0),
      ),
    );
  }
}
