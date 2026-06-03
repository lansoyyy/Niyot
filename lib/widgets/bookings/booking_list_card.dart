import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../core/booking_policy.dart';
import '../../models/booking_model.dart';
import '../../screens/bookings/booking_detail_screen.dart';
import '../../services/booking_service.dart';
import '../../services/booking_view_tracker.dart';
import '../../widgets/bookings/booking_status_badge.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/currency/peso_price_text.dart';

/// Tappable booking row with unread (dark) / read (light) styling and press feedback.
class BookingListCard extends StatefulWidget {
  const BookingListCard({
    super.key,
    required this.booking,
    required this.isPhotographer,
  });

  final BookingModel booking;
  final bool isPhotographer;

  @override
  State<BookingListCard> createState() => _BookingListCardState();
}

class _BookingListCardState extends State<BookingListCard> {
  bool _isLoading = false;

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}';
  }

  Future<void> _openDetail() async {
    await BookingViewTracker.instance.markViewed(widget.booking.id);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailScreen(
          booking: widget.booking,
          isPhotographer: widget.isPhotographer,
        ),
      ),
    );
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      await BookingService().acceptBooking(widget.booking.id);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _isLoading = true);
    try {
      await BookingService().declineBooking(widget.booking.id);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelFromCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel booking?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'The other party will be notified.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Go back', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Cancel booking', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await BookingService().cancelBooking(
        widget.booking.id,
        cancelledBy: widget.isPhotographer ? 'photographer' : 'client',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPhotographer = widget.isPhotographer;
    final isViewed = BookingViewTracker.instance.isViewed(booking.id);
    final otherName =
        isPhotographer ? booking.clientName : booking.photographerName;
    final otherPhotoUrl = isPhotographer
        ? booking.clientPhotoUrl
        : booking.photographerPhotoUrl;
    final status = booking.status;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isNewRequest =
        status == BookingStatus.requested && !booking.isReschedulePending;
    final canRespondReschedule =
        BookingPolicy.canRespondToReschedule(booking, uid);

    final headerColor = isViewed
        ? const Color(0xFFB71C1C)
        : AppColors.primaryDark;
    final bodyColor = isViewed ? AppColors.white : AppColors.gray100;
    final outerColor = isViewed ? AppColors.gray200 : AppColors.gray300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: outerColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        elevation: isViewed ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        child: Material(
          color: bodyColor,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openDetail,
            splashColor: AppColors.primary.withValues(alpha: 0.18),
            highlightColor: AppColors.gray800.withValues(alpha: 0.1),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: isViewed
                        ? null
                        : const Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      AppProfileAvatar(
                        displayName: otherName,
                        photoUrl: otherPhotoUrl,
                        size: 44,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              booking.packageName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isViewed)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                          BookingStatusBadge(
                            booking: booking,
                            compact: true,
                            onDarkBackground: true,
                          ),
                          if (booking.isReschedulePending) ...[
                            const SizedBox(height: 4),
                            const RescheduleRequestMark(
                              onDarkBackground: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _Chip(
                            icon: Icons.calendar_today_rounded,
                            text: _formatDate(booking.scheduledDate),
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            icon: Icons.access_time_rounded,
                            text: booking.scheduledTime,
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            icon: Icons.payments_rounded,
                            text: booking.packagePrice <= 0
                                ? 'Free'
                                : 'PHP ${PesoPriceText.formatDigits(booking.packagePrice)}',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _LocationChip(location: booking.location),
                      if (canRespondReschedule) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Reschedule request — choose an action',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _cancelFromCard,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancel booking',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _accept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Accept',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isPhotographer && isNewRequest) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _decline,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Text(
                                        'Decline',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _accept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Accept',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.location_on_rounded,
              size: 14,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? AppColors.gray400),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.gray500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
