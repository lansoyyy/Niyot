import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/booking_service.dart';
import '../../services/booking_view_tracker.dart';
import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';
import '../home/photographer_dashboard_screen.dart';
import '../explore/explore_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../messages/messages_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isPhotographer = false;

  StreamController<int>? _bookingsBadgeController;
  StreamSubscription<int>? _bookingsBadgeSub;
  int _lastBookingsCount = 0;

  @override
  void initState() {
    super.initState();
    _detectRole();
  }

  @override
  void dispose() {
    _bookingsBadgeSub?.cancel();
    _bookingsBadgeController?.close();
    super.dispose();
  }

  void _detectRole() {
    final cached = UserService().cachedUser;
    if (cached != null) {
      setState(() => _isPhotographer = cached.isPhotographer);
      _initBookingsBadge();
    } else {
      UserService().fetchCurrentUser().then((user) {
        if (!mounted || user == null) return;
        setState(() => _isPhotographer = user.isPhotographer);
        _restartBookingsBadge();
      });
    }
  }

  void _restartBookingsBadge() {
    _bookingsBadgeSub?.cancel();
    _bookingsBadgeController?.close();
    _lastBookingsCount = 0;
    _initBookingsBadge();
  }

  void _initBookingsBadge() {
    if (_currentUid.isEmpty) return;
    BookingViewTracker.instance.init(_currentUid);
    _bookingsBadgeController = StreamController<int>.broadcast();
    _bookingsBadgeSub = BookingService()
        .pendingActionCountStream(
          _currentUid,
          isPhotographer: _isPhotographer,
        )
        .listen((count) {
      _lastBookingsCount = count;
      if (_currentIndex != 2) {
        _bookingsBadgeController?.add(count);
      }
    });
  }

  void _updateIndex(int index) {
    final wasBookings = _currentIndex == 2;
    setState(() => _currentIndex = index);
    if (index == 2) {
      _bookingsBadgeController?.add(0);
    } else if (wasBookings) {
      _bookingsBadgeController?.add(_lastBookingsCount);
    }
  }

  List<Widget> get _screens => [
    _isPhotographer ? const PhotographerDashboardScreen() : const HomeScreen(),
    const ExploreScreen(),
    const MyBookingsScreen(),
    const MessagesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: _currentIndex == 0,
                    onTap: () => _updateIndex(0),
                  ),
                  _NavItem(
                    icon: Icons.explore_rounded,
                    label: 'Explore',
                    isSelected: _currentIndex == 1,
                    onTap: () => _updateIndex(1),
                  ),
                  _NavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Bookings',
                    isSelected: _currentIndex == 2,
                    badgeStream: _bookingsBadgeController?.stream,
                    onTap: () => _updateIndex(2),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    isSelected: _currentIndex == 3,
                    badgeStream: _currentUid.isEmpty
                        ? null
                        : MessagingService().totalUnreadStream(_currentUid),
                    onTap: () => _updateIndex(3),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: _currentIndex == 4,
                    onTap: () => _updateIndex(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeStream,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Stream<int>? badgeStream;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? const Color(0xFFC62828)
                        : const Color(0xFFBDBDBD),
                  ),
                  if (badgeStream != null)
                    StreamBuilder<int>(
                      stream: badgeStream,
                      initialData: 0,
                      builder: (context, snapshot) {
                        final badge = snapshot.data ?? 0;
                        if (badge <= 0) return const SizedBox.shrink();
                        final label = badge > 9 ? '9+' : '$badge';
                        return Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC62828),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFFC62828)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
