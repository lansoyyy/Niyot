import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../models/photographer_model.dart';
import '../../services/booking_service.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../notifications/notifications_screen.dart';
import '../photographer/manage_packages_screen.dart';
import '../photographer/manage_portfolio_screen.dart';
import '../photographer/photographer_profile_screen.dart';
import '../settings/settings_screen.dart';

class PhotographerDashboardScreen extends StatefulWidget {
  const PhotographerDashboardScreen({super.key});

  @override
  State<PhotographerDashboardScreen> createState() =>
      _PhotographerDashboardScreenState();
}

class _PhotographerDashboardScreenState
    extends State<PhotographerDashboardScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTicker();
  }

  void _startCountdownTicker() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Duration _timeUntil(DateTime target) {
    final diff = target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }

  List<BookingModel> _upcomingConfirmed(List<BookingModel> all) => all
      .where(
        (b) =>
            b.status == BookingStatus.confirmed &&
            b.scheduledDate.isAfter(DateTime.now()),
      )
      .toList()
    ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

  int _pendingCount(List<BookingModel> all) =>
      all.where((b) => b.status == BookingStatus.requested).length;

  int _shootsThisWeek(List<BookingModel> all) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return all
        .where(
          (b) =>
              b.status == BookingStatus.confirmed &&
              b.scheduledDate.isAfter(weekStart) &&
              b.scheduledDate.isBefore(weekEnd),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: StreamBuilder<PhotographerModel?>(
          stream: PhotographerService().photographerStream(_uid),
          builder: (context, photographerSnap) {
            final photographer = photographerSnap.data;
            return StreamBuilder<List<BookingModel>>(
              stream: BookingService().photographerBookingsStream(_uid),
              builder: (context, bookingsSnap) {
                final allBookings = bookingsSnap.data ?? const <BookingModel>[];
                final upcoming = _upcomingConfirmed(allBookings);
                final nextShoot = upcoming.isNotEmpty ? upcoming.first : null;
                final pendingCount = _pendingCount(allBookings);
                final shootsThisWeek = _shootsThisWeek(allBookings);
                final views = photographer?.profileViewCount ?? 0;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context, photographer),
                    ),
                    if (nextShoot != null)
                      SliverToBoxAdapter(
                        child: _buildNextShootCard(nextShoot),
                      ),
                    if (upcoming.length > 1)
                      SliverToBoxAdapter(
                        child: _buildComingUpRow(upcoming.skip(1).take(3).toList()),
                      ),
                    SliverToBoxAdapter(
                      child: _buildThisWeekStats(
                        pendingCount,
                        shootsThisWeek,
                        views,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(context, photographer),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, PhotographerModel? photographer) {
    final userName =
        UserService().cachedUser?.name ?? 'Photographer';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B0000), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName.split(' ').first,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                child: _headerIconBtn(Icons.settings_rounded),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: _headerIconBtn(Icons.notifications_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      );

  // ── Next Shoot Card ────────────────────────────────────────────────────────

  Widget _buildNextShootCard(BookingModel nextShoot) {
    final countdown = _timeUntil(nextShoot.scheduledDate);
    final days = countdown.inDays;
    final hours = countdown.inHours % 24;
    final minutes = countdown.inMinutes % 60;

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = nextShoot.scheduledDate;
    final dateStr =
        '${months[date.month - 1]} ${date.day}  •  ${nextShoot.scheduledTime}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Label
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC62828),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'NEXT SHOOT',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC62828),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Countdown
            Row(
              children: [
                _countdownUnit('$days', 'DAYS'),
                const SizedBox(width: 14),
                _countdownUnit(_twoDigit(hours), 'HOURS'),
                const SizedBox(width: 14),
                _countdownUnit(_twoDigit(minutes), 'MIN'),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F1F1)),
            // Client info
            Row(
              children: [
                _clientAvatar(nextShoot.clientName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextShoot.clientName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF7A7A7A),
                            ),
                          ),
                        ],
                      ),
                      if (nextShoot.location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                nextShoot.location,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7A7A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${nextShoot.packageName}  •  \$${nextShoot.packagePrice}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countdownUnit(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientAvatar(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length == 1
        ? parts[0][0].toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    const colors = [
      [Color(0xFF1A237E), Color(0xFF3949AB)],
      [Color(0xFF1B5E20), Color(0xFF388E3C)],
      [Color(0xFF004D40), Color(0xFF00897B)],
      [Color(0xFFC62828), Color(0xFF6B0000)],
    ];
    final idx = name.codeUnits.fold(0, (s, c) => s + c) % colors.length;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors[idx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Coming Up Row ──────────────────────────────────────────────────────────

  Widget _buildComingUpRow(List<BookingModel> bookings) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Text(
            'Coming up: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: bookings.map((b) {
                  final parts = b.clientName.trim().split(' ');
                  final initials = parts.length == 1
                      ? parts[0][0].toUpperCase()
                      : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
                  final date = b.scheduledDate;
                  final label =
                      '${months[date.month - 1]} ${date.day}  •  ${b.packageName}';
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFEBEE),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── This Week Stats ────────────────────────────────────────────────────────

  Widget _buildThisWeekStats(int pending, int shoots, int views) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9E9E9E),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  '$pending',
                  'PENDING',
                  const Color(0xFFF59E0B),
                  Icons.inbox_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  '$shoots',
                  'SHOOTS',
                  const Color(0xFF059669),
                  Icons.camera_alt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  '$views',
                  'VIEWS',
                  const Color(0xFF3B82F6),
                  Icons.remove_red_eye_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(
      BuildContext context, PhotographerModel? photographer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9E9E9E),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(
                  icon: Icons.add_photo_alternate_rounded,
                  label: 'Upload Photos',
                  color: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFC62828),
                  onTap: () {
                    if (_uid.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ManagePortfolioScreen(photographerId: _uid),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Edit Packages',
                  color: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFFF8F00),
                  onTap: () {
                    if (_uid.isNotEmpty && photographer != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManagePackagesScreen(
                            photographerId: _uid,
                            initialPackages: photographer.packages,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(
                  icon: Icons.person_rounded,
                  label: 'View Profile',
                  color: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  onTap: () {
                    if (photographer != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhotographerProfileScreen(
                            photographer: photographer,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF7B1FA2),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
