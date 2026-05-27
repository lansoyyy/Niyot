import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_expiration.dart';
import '../../models/booking_model.dart';
import '../../screens/bookings/booking_detail_screen.dart';
import '../../widgets/bookings/booking_status_badge.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/home/home_section_header.dart';

/// Client home — next confirmed upcoming session.
class ClientNextShootCard extends StatelessWidget {
  const ClientNextShootCard({
    super.key,
    required this.booking,
    required this.countdown,
  });

  final BookingModel booking;
  final Duration countdown;

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = booking.scheduledDate;
    final dateLabel = '${months[date.month - 1]} ${date.day}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(
            booking: booking,
            isPhotographer: false,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: const Color(0xFF43A047), width: 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppProfileAvatar(
                    displayName: booking.photographerName,
                    photoUrl: booking.photographerPhotoUrl,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.photographerName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.packageName} · ${booking.packageDuration}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  BookingStatusBadge(booking: booking, compact: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.calendar_today_rounded,
                        label: dateLabel,
                      ),
                      _MetaChip(
                        icon: Icons.access_time_rounded,
                        label: booking.scheduledTime,
                      ),
                    ],
                  ),
                  if (booking.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LocationRow(location: booking.location),
                  ],
                  if (booking.isReschedulePending) ...[
                    const SizedBox(height: 6),
                    const RescheduleRequestMark(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Shoot day',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    SessionCountdown.shootDayLabel(booking.scheduledSessionStart),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientNextShootSection extends StatelessWidget {
  const ClientNextShootSection({
    super.key,
    required this.booking,
    required this.countdown,
    required this.onViewAll,
  });

  final BookingModel? booking;
  final Duration countdown;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (booking == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: 'Next shoot',
            actionLabel: 'All bookings →',
            onAction: onViewAll,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ClientNextShootCard(booking: booking!, countdown: countdown),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.location_on_rounded,
              size: 13,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
                height: 1.35,
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
