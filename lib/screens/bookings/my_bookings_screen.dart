import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_service.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stream<List<BookingModel>>? _bookingsStream;
  bool _isPhotographer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initStream();
  }

  void _initStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final cached = UserService().cachedUser;
    if (cached != null) {
      _isPhotographer = cached.isPhotographer;
      _setStream(uid, cached);
    } else {
      UserService().fetchCurrentUser().then((user) {
        if (!mounted || user == null) return;
        setState(() {
          _isPhotographer = user.isPhotographer;
          _setStream(uid, user);
        });
      });
    }
  }

  void _setStream(String uid, UserModel user) {
    _bookingsStream = user.isPhotographer
        ? BookingService().photographerBookingsStream(uid)
        : BookingService().clientBookingsStream(uid);
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

        final requested = all
            .where((b) => b.status == BookingStatus.requested)
            .toList();
        final upcoming = all.where((b) => b.isUpcoming).toList();
        final active = all.where((b) => b.isActive).toList();
        final past = all.where((b) => b.isPast).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  tabController: _tabController,
                  requestedCount: requested.length,
                  upcomingCount: upcoming.length,
                  activeCount: active.length,
                  pastCount: past.length,
                ),
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
                            _TabList(
                              bookings: requested,
                              emptyLabel: 'No pending requests',
                              emptyIcon: Icons.hourglass_empty_rounded,
                              isPhotographer: _isPhotographer,
                            ),
                            _TabList(
                              bookings: upcoming,
                              emptyLabel: 'No upcoming sessions',
                              emptyIcon: Icons.event_outlined,
                              isPhotographer: _isPhotographer,
                            ),
                            _TabList(
                              bookings: active,
                              emptyLabel: 'No active sessions',
                              emptyIcon: Icons.camera_enhance_outlined,
                              isPhotographer: _isPhotographer,
                            ),
                            _TabList(
                              bookings: past,
                              emptyLabel: 'No past bookings',
                              emptyIcon: Icons.history_rounded,
                              isPhotographer: _isPhotographer,
                            ),
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
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.tabController,
    required this.requestedCount,
    required this.upcomingCount,
    required this.activeCount,
    required this.pastCount,
  });

  final TabController tabController;
  final int requestedCount;
  final int upcomingCount;
  final int activeCount;
  final int pastCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                value: requestedCount,
                label: 'Pending',
                color: const Color(0xFFFF6D00),
                bg: const Color(0xFFFFF3E0),
              ),
              const SizedBox(width: 8),
              _StatPill(
                value: upcomingCount,
                label: 'Upcoming',
                color: const Color(0xFFC62828),
                bg: const Color(0xFFFFEBEE),
              ),
              const SizedBox(width: 8),
              _StatPill(
                value: activeCount,
                label: 'Active',
                color: const Color(0xFF1565C0),
                bg: const Color(0xFFE3F2FD),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
              Tab(text: 'Requested ($requestedCount)'),
              Tab(text: 'Upcoming ($upcomingCount)'),
              Tab(text: 'Active ($activeCount)'),
              Tab(text: 'Past ($pastCount)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  final int value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab List ────────────────────────────────────────────────────────────────

class _TabList extends StatelessWidget {
  const _TabList({
    required this.bookings,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.isPhotographer,
  });

  final List<BookingModel> bookings;
  final String emptyLabel;
  final IconData emptyIcon;
  final bool isPhotographer;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
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
      itemBuilder: (context, index) => _BookingCard(
        booking: bookings[index],
        isPhotographer: isPhotographer,
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.booking, required this.isPhotographer});

  final BookingModel booking;
  final bool isPhotographer;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _isLoading = false;

  List<Color> _gradient(String id) {
    const pairs = [
      [Color(0xFF6B0000), Color(0xFFC62828)],
      [Color(0xFF4A0000), Color(0xFF880E0E)],
      [Color(0xFF1A237E), Color(0xFF3949AB)],
      [Color(0xFF1B5E20), Color(0xFF388E3C)],
      [Color(0xFF004D40), Color(0xFF00897B)],
      [Color(0xFFBF360C), Color(0xFFE64A19)],
      [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    ];
    final index =
        id.codeUnits.fold<int>(0, (sum, c) => sum + c) % pairs.length;
    return pairs[index].cast<Color>();
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}';
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return const Color(0xFF2E7D32);
      case BookingStatus.requested:
        return const Color(0xFFFF6D00);
      case BookingStatus.inProgress:
        return const Color(0xFF1565C0);
      case BookingStatus.completed:
        return const Color(0xFF6B7280);
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _statusBg(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return const Color(0xFFE8F5E9);
      case BookingStatus.requested:
        return const Color(0xFFFFF3E0);
      case BookingStatus.inProgress:
        return const Color(0xFFE3F2FD);
      case BookingStatus.completed:
        return const Color(0xFFF3F4F6);
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPhotographer = widget.isPhotographer;
    final otherName = isPhotographer
        ? booking.clientName
        : booking.photographerName;
    final otherInitials = isPhotographer
        ? booking.clientInitials
        : booking.photographerInitials;
    final gradientId = isPhotographer
        ? booking.clientId
        : booking.photographerId;
    final status = booking.status;
    final isRequested = status == BookingStatus.requested;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(
            booking: booking,
            isPhotographer: isPhotographer,
          ),
        ),
      ),
      child: Container(
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
            // ── Header gradient ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradient(gradientId),
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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      otherInitials,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Info row ──
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
                        icon: Icons.attach_money_rounded,
                        text: '\$${booking.packagePrice}',
                        color: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Chip(
                        icon: Icons.location_on_rounded,
                        text: booking.location,
                        expand: true,
                      ),
                    ],
                  ),
                  // ── Photographer quick-action buttons for requested ──
                  if (isPhotographer && isRequested) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _decline,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFC62828),
                              ),
                              foregroundColor: const Color(0xFFC62828),
                              padding: const EdgeInsets.symmetric(vertical: 9),
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
                                      color: Color(0xFFC62828),
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
                              padding: const EdgeInsets.symmetric(vertical: 9),
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
    );
  }
}

// ─── Small chip widget ────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    this.color,
    this.expand = false,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? const Color(0xFF9E9E9E)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color ?? const Color(0xFF7A7A7A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (expand) {
      return Expanded(child: chip);
    }
    return chip;
  }
}
