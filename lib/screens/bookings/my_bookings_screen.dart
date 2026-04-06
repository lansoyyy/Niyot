import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../messages/chat_screen.dart';
import '../reviews/leave_review_screen.dart';
import 'booking_actions_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Stream<List<BookingModel>>? _bookingsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService().clientBookingsStream(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final upcoming = all.where((b) => b.isUpcoming).toList();
        final requested = all
            .where((b) => b.status == BookingStatus.requested)
            .toList();
        final past = all.where((b) => b.isPast).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookings',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        children: [
                          _StatCard(
                            value: '${upcoming.length}',
                            label: 'Upcoming',
                            color: const Color(0xFFC62828),
                            bgColor: const Color(0xFFFFEBEE),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            value: '${requested.length}',
                            label: 'Pending',
                            color: const Color(0xFFFF6D00),
                            bgColor: const Color(0xFFFFF3E0),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            value:
                                '${past.where((b) => b.status == BookingStatus.completed).length}',
                            label: 'Completed',
                            color: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tab bar
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFFC62828),
                        unselectedLabelColor: const Color(0xFF9E9E9E),
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                        indicatorColor: const Color(0xFFC62828),
                        indicatorWeight: 2.5,
                        tabs: [
                          Tab(text: 'Upcoming (${upcoming.length})'),
                          Tab(text: 'Requested (${requested.length})'),
                          Tab(text: 'Past (${past.length})'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC62828),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBookingList(upcoming),
                            _buildBookingList(requested),
                            _buildBookingList(past),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingModel booking;

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.requested:
        return const Color(0xFFFF6D00);
      case BookingStatus.cancelled:
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFFE8F5E9);
      case BookingStatus.requested:
        return const Color(0xFFFFF3E0);
      case BookingStatus.cancelled:
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static const _gradients = [
    [Color(0xFF6B0000), Color(0xFFC62828)],
    [Color(0xFF4A0000), Color(0xFF880E0E)],
    [Color(0xFF1A237E), Color(0xFF3949AB)],
    [Color(0xFF1B5E20), Color(0xFF388E3C)],
    [Color(0xFF004D40), Color(0xFF00897B)],
    [Color(0xFFBF360C), Color(0xFFE64A19)],
    [Color(0xFF4A148C), Color(0xFF7B1FA2)],
  ];

  List<Color> _photographerGradient(String photographerId) {
    final index =
        photographerId.codeUnits.fold<int>(0, (sum, c) => sum + c) %
        _gradients.length;
    return _gradients[index].cast<Color>();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _photographerGradient(booking.photographerId),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      booking.photographerInitials,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.photographerName,
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
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      text: _formatDate(booking.scheduledDate),
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      text: booking.scheduledTime,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.location_on_rounded,
                      text: booking.location,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.payments_rounded,
                      text: 'Free',
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                if (booking.isUpcoming ||
                    booking.status == BookingStatus.requested) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;

                            final currentProfile =
                                UserService().cachedUser ??
                                await UserService().fetchCurrentUser();
                            final conversationId = await MessagingService()
                                .getOrCreateConversation(
                                  myId: currentUser.uid,
                                  myName:
                                      currentProfile?.name ??
                                      currentUser.displayName ??
                                      'Client',
                                  myPhotoUrl: currentProfile?.photoUrl,
                                  otherUserId: booking.photographerId,
                                  otherUserName: booking.photographerName,
                                  otherUserPhotoUrl:
                                      booking.photographerPhotoUrl,
                                  bookingId: booking.id,
                                );

                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: conversationId,
                                  otherUserId: booking.photographerId,
                                  otherUserName: booking.photographerName,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: const Color(0xFF7A7A7A),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Message',
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
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookingActionsScreen(
                                  booking: booking,
                                  actionType:
                                      booking.status == BookingStatus.requested
                                      ? 'cancel'
                                      : 'reschedule',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            booking.status == BookingStatus.requested
                                ? 'Cancel'
                                : 'View Details',
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
                if (booking.status == BookingStatus.completed) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: booking.hasReview
                          ? null
                          : () async {
                              final created = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LeaveReviewScreen(booking: booking),
                                    ),
                                  );

                              if (!context.mounted || created != true) {
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Review submitted successfully.',
                                  ),
                                ),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: booking.hasReview
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFFC62828),
                        ),
                        foregroundColor: booking.hasReview
                            ? const Color(0xFF9E9E9E)
                            : const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        booking.hasReview
                            ? Icons.check_circle_outline_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        booking.hasReview
                            ? 'Review Submitted'
                            : 'Leave a Review',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

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
          Icon(icon, size: 13, color: color ?? const Color(0xFF9E9E9E)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color ?? const Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String value;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
