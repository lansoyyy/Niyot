import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_avatar_colors.dart';
import '../../core/booking_expiration.dart';
import '../../models/booking_model.dart';
import '../../models/photographer_model.dart';
import '../../models/user_model.dart';
import '../../services/booking_service.dart';
import '../../services/photographer_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../services/user_service.dart';
import '../../widgets/home/client_next_shoot_card.dart';
import '../../widgets/home/near_you_card.dart';
import '../explore/explore_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../photographer/photographer_profile_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _clientUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _countdownTimer;
  int _selectedCategory = 0;
  List<PhotographerModel> _featured = [];
  List<PhotographerModel> _photographers = [];
  bool _isLoading = true;
  String? _error;
  String _headerLocation = 'Discover nearby creators';

  final List<String> _categories = [
    'All',
    'Portrait',
    'Wedding',
    'Event',
    'Commercial',
    'Fashion',
    'Travel',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  BookingModel? _nextClientShoot(List<BookingModel> bookings) {
    final upcoming = bookings.where((b) => b.isUpcoming).toList()
      ..sort(
        (a, b) => a.scheduledSessionStart.compareTo(b.scheduledSessionStart),
      );
    return upcoming.isEmpty ? null : upcoming.first;
  }

  void _openAllBookings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final category = _selectedCategory == 0
          ? null
          : _categories[_selectedCategory];
      final results = await Future.wait<Object?>([
        PhotographerService().getFeaturedPhotographers(),
        PhotographerService().getPhotographers(category: category),
        UserService().fetchCurrentUser(),
      ]);
      final featured = results[0]! as List<PhotographerModel>;
      final photographers = results[1]! as List<PhotographerModel>;
      final user = results[2] as UserModel?;
      final userLocation = user?.location;
      final prioritizedPhotographers = _prioritizeNearbyPhotographers(
        photographers,
        userLocation,
      );
      if (mounted) {
        setState(() {
          _featured = featured;
          _photographers = prioritizedPhotographers;
          _headerLocation = _resolveHeaderLocation(
            userLocation,
            prioritizedPhotographers,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load photographers. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildSearchBar(),
              ),
            ),
            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildCategoryChips(),
              ),
            ),
            // Next shoot (client)
            if (_clientUid.isNotEmpty)
              SliverToBoxAdapter(
                child: StreamBuilder<List<BookingModel>>(
                  stream: BookingService().clientBookingsStream(_clientUid),
                  builder: (context, snap) {
                    final next = _nextClientShoot(snap.data ?? const []);
                    if (next == null) return const SizedBox.shrink();
                    final countdown =
                        SessionCountdown.until(next.scheduledSessionStart);
                    return ClientNextShootSection(
                      booking: next,
                      countdown: countdown,
                      onViewAll: _openAllBookings,
                    );
                  },
                ),
              ),
            // Featured creators
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 0, 12),
                child: Text(
                  'Featured Creators',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildFeaturedCarousel()),
            // Near you
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Near You',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    TextButton(
                      onPressed: _openExplore,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'See all →',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFC62828)),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_photographers.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No photographers found.',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _photographers.length.clamp(0, 12),
                    itemBuilder: (context, index) =>
                        NearYouCard(photographer: _photographers[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _headerLocation,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Find Your\nPerfect Creator',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.transparent, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openExplore,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(
                Icons.search_rounded,
                color: Color(0xFFBDBDBD),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search photographers, videographers...',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(6),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFFC62828),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PhotographerModel> _prioritizeNearbyPhotographers(
    List<PhotographerModel> photographers,
    String? userLocation,
  ) {
    if (!_hasMeaningfulLocation(userLocation)) {
      return photographers;
    }

    final sorted = List<PhotographerModel>.from(photographers)
      ..sort((a, b) {
        final aMatches = _locationsMatch(a.locationText, userLocation!);
        final bMatches = _locationsMatch(b.locationText, userLocation);
        if (aMatches == bMatches) {
          return 0;
        }
        return aMatches ? -1 : 1;
      });
    return sorted;
  }

  String _resolveHeaderLocation(
    String? userLocation,
    List<PhotographerModel> photographers,
  ) {
    if (_hasMeaningfulLocation(userLocation)) {
      return userLocation!.trim();
    }
    if (photographers.isNotEmpty &&
        photographers.first.locationText.isNotEmpty) {
      return photographers.first.locationText;
    }
    return 'Discover nearby creators';
  }

  bool _hasMeaningfulLocation(String? value) =>
      value != null && value.trim().isNotEmpty;

  bool _locationsMatch(String left, String right) {
    final normalizedLeft = _normalizeLocation(left);
    final normalizedRight = _normalizeLocation(right);
    if (normalizedLeft == null || normalizedRight == null) {
      return false;
    }

    final leftParts = normalizedLeft.split(',').map((part) => part.trim());
    final rightParts = normalizedRight.split(',').map((part) => part.trim());
    return leftParts.any(
          (part) => part.isNotEmpty && normalizedRight.contains(part),
        ) ||
        rightParts.any(
          (part) => part.isNotEmpty && normalizedLeft.contains(part),
        );
  }

  String? _normalizeLocation(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9,\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _openExplore() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExploreScreen(
          initialCategory: _selectedCategory == 0
              ? null
              : _categories[_selectedCategory],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = index);
              _loadData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFC62828) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFC62828)
                      : const Color(0xFFE5E7EB),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFC62828).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _categories[index],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF7A7A7A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFC62828)),
        ),
      );
    }
    if (_featured.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No featured photographers yet.',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _featured.length,
        itemBuilder: (context, index) {
          final item = _featured[index];
          return GestureDetector(
            onTap: () => _openProfile(context, item),
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: AppAvatarColors.profileHeaderBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -10,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppProfileAvatar(
                              displayName: item.name,
                              photoUrl: item.photoUrl,
                              size: 48,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    item.primarySpecialty.isNotEmpty
                                        ? item.primarySpecialty
                                        : item.specialties.isNotEmpty
                                        ? item.specialties.first
                                        : '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.startingPrice.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.startingPrice,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.yellowAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.rating.toStringAsFixed(1)} (${item.reviewCount} reviews)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.locationText,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openProfile(BuildContext context, PhotographerModel photographer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotographerProfileScreen(photographer: photographer),
      ),
    );
  }
}

