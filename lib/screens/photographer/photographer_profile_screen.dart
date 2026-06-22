import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_avatar_colors.dart';
import '../../models/photographer_model.dart';
import '../../models/portfolio_item_model.dart';
import '../../models/review_model.dart';
import '../../models/service_package_model.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/currency/peso_price_text.dart';
import '../../services/block_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/report/report_bottom_sheet.dart';
import '../booking/booking_screen.dart';
import '../../widgets/messaging/chat_navigation_helper.dart';
import '../profile/edit_profile_screen.dart';
import 'manage_packages_screen.dart';
import 'manage_portfolio_screen.dart';

class PhotographerProfileScreen extends StatefulWidget {
  const PhotographerProfileScreen({super.key, required this.photographer});

  final PhotographerModel photographer;

  @override
  State<PhotographerProfileScreen> createState() =>
      _PhotographerProfileScreenState();
}

class _PhotographerProfileScreenState extends State<PhotographerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PhotographerModel _photographer;
  List<PortfolioItemModel> _portfolioItems = [];
  List<ReviewModel> _reviews = [];
  bool _isLoadingTabs = true;
  bool _currentUserIsPhotographer = false;
  bool _isOpeningChat = false;

  bool get _isOwnProfile =>
      FirebaseAuth.instance.currentUser?.uid == _photographer.uid;

  /// Clients only — photographers browse in read-only mode.
  bool get _canBookPackages => !_isOwnProfile && !_currentUserIsPhotographer;

  @override
  void initState() {
    super.initState();
    _photographer = widget.photographer;
    _tabController = TabController(length: 3, vsync: this);
    PhotographerService().incrementProfileView(_photographer.uid);
    _loadTabData();
    _detectCurrentUserRole();
  }

  void _detectCurrentUserRole() {
    final cached = UserService().cachedUser;
    if (cached != null) {
      _currentUserIsPhotographer = cached.isPhotographer;
    } else {
      UserService().fetchCurrentUser().then((user) {
        if (mounted && user != null) {
          setState(() => _currentUserIsPhotographer = user.isPhotographer);
        }
      });
    }
  }

  Future<void> _loadTabData() async {
    try {
      final results = await Future.wait([
        PhotographerService().getPortfolio(_photographer.uid),
        PhotographerService().getReviews(_photographer.uid),
      ]);
      if (mounted) {
        setState(() {
          _portfolioItems = results[0] as List<PortfolioItemModel>;
          _reviews = results[1] as List<ReviewModel>;
          _isLoadingTabs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTabs = false);
    }
  }

  Future<void> _blockPhotographer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Block ${_photographer.name}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Are you sure you want to block this photographer? They will no longer appear in your search results, and they will not be able to message you. This action will be reported to our moderation team.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7A7A7A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Block',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BlockService().blockUser(
          blockedUserId: _photographer.uid,
          blockedUserName: _photographer.name,
        );
        await NotificationService().createUserBlockedNotification(
          blockedUserId: _photographer.uid,
          blockedUserName: _photographer.name,
          blockedBy: UserService().cachedUser?.name ?? 'User',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_photographer.name} has been blocked.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to block user. Please try again.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: const Color(0xFFB71C1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photographer = _photographer;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppAvatarColors.profileHeaderBackground,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                actions: [
                  Builder(
                    builder: (context) {
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;
                      if (currentUid == null) {
                        return const SizedBox.shrink();
                      }

                      // Own profile — show edit icon
                      if (currentUid == _photographer.uid) {
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(
                              right: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      }

                      // Another photographer's profile — show favorite toggle + options
                      return Row(
                        children: [
                          StreamBuilder<bool>(
                            stream: UserService().favoriteStatusStream(
                              currentUid,
                              _photographer.uid,
                            ),
                            builder: (context, snapshot) {
                              final isFavorite = snapshot.data ?? false;

                              return GestureDetector(
                                onTap: () async {
                                  try {
                                    final added = await UserService()
                                        .toggleFavoritePhotographer(
                                          uid: currentUid,
                                          photographer: _photographer,
                                        );

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          added
                                              ? 'Added to favorites.'
                                              : 'Removed from favorites.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to update favorites right now.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    right: 4,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavorite
                                        ? Colors.pinkAccent
                                        : Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: Container(
                              margin: const EdgeInsets.only(
                                right: 16,
                                top: 8,
                                bottom: 8,
                              ),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) {
                              if (value == 'report') {
                                showReportBottomSheet(
                                  context: context,
                                  reportedUserId: _photographer.uid,
                                  reportedUserName: _photographer.name,
                                  contentType: 'photographer',
                                );
                              } else if (value == 'block') {
                                _blockPhotographer(context);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.flag_rounded,
                                      size: 18,
                                      color: Color(0xFFC62828),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Report',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'block',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.block_rounded,
                                      size: 18,
                                      color: Color(0xFFC62828),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Block',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      color: AppAvatarColors.profileHeaderBackground,
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: -60,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        // Profile info
                        Positioned(
                          bottom: 24,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: AppProfileAvatar(
                                  displayName: photographer.name,
                                  photoUrl: photographer.photoUrl,
                                  size: 72,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      photographer.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      photographer.primarySpecialty.isNotEmpty
                                          ? photographer.primarySpecialty
                                          : photographer.specialties.isNotEmpty
                                          ? photographer.specialties.first
                                          : '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white70,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          photographer.locationText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (photographer.isVerified) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white54,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.verified_rounded,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Verified',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Stats bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      _StatItem(
                        value: '${photographer.photoCount}',
                        label: 'Photos',
                      ),
                      _divider(),
                      _StatItem(
                        value: photographer.rating.toStringAsFixed(1),
                        label: 'Rating',
                        valueColor: const Color(0xFFC62828),
                      ),
                      _divider(),
                      _StatItem(
                        value: '${photographer.bookingCount}',
                        label: 'Bookings',
                      ),
                      _divider(),
                      _StatItem(
                        value: '${photographer.reviewCount}',
                        label: 'Reviews',
                      ),
                    ],
                  ),
                ),
              ),
              // About section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photographer.bio.isNotEmpty
                            ? photographer.bio
                            : 'Professional photographer specializing in ${photographer.primarySpecialty.isNotEmpty ? photographer.primarySpecialty : 'photography'}. Based in ${photographer.locationText}, available for bookings worldwide.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF7A7A7A),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  ...photographer.specialties.take(5),
                                  if (photographer.specialties.isEmpty)
                                    'Photography',
                                ]
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
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
                    tabs: const [
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Packages'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),
              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPortfolio(),
                    _buildPackages(),
                    _buildReviews(),
                  ],
                ),
              ),
            ],
          ),
          // Bottom bar — contextual for own profile vs. client
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar helpers
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _isOwnProfile
          ? _buildOwnProfileBar()
          : _currentUserIsPhotographer
              ? _buildPhotographerViewBar()
              : _buildClientActionsBar(),
    );
  }

  Widget _buildOwnProfileBar() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ManagePortfolioScreen(photographerId: _photographer.uid),
                ),
              );
              _loadTabData();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC62828)),
              foregroundColor: const Color(0xFFC62828),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.photo_library_rounded, size: 18),
            label: Text(
              'Portfolio',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final updated =
                  await Navigator.of(context).push<List<ServicePackageModel>>(
                MaterialPageRoute(
                  builder: (_) => ManagePackagesScreen(
                    photographerId: _photographer.uid,
                    initialPackages: _photographer.packages,
                  ),
                ),
              );
              if (updated != null && mounted) {
                setState(() {
                  _photographer = _photographer.copyWith(packages: updated);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.inventory_2_rounded, size: 18),
            label: Text(
              'Packages',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotographerViewBar() {
    return Center(
      child: Text(
        'Viewing as photographer',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Widget _buildClientActionsBar() {
    return Row(
      children: [
        // Message button
        OutlinedButton.icon(
          onPressed: _isOpeningChat ? null : _openMessageThread,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFC62828)),
            foregroundColor: const Color(0xFFC62828),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _isOpeningChat
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC62828),
                  ),
                )
              : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(
            'Message',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        // Book Now button
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingScreen(photographer: _photographer),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Starting from',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _photographer.startingPrice.isNotEmpty
                      ? _photographer.startingPrice
                      : 'Book Now',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMessageThread() async {
    if (FirebaseAuth.instance.currentUser?.uid == null) return;
    setState(() => _isOpeningChat = true);
    try {
      await ChatNavigationHelper.openChat(
        context: context,
        otherUserId: _photographer.uid,
        otherUserName: _photographer.name,
        otherUserPhotoUrl: _photographer.photoUrl,
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Tab content builders
  // ---------------------------------------------------------------------------

  Widget _buildPortfolio() {
    if (_isLoadingTabs) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC62828)),
      );
    }
    if (_portfolioItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 8),
            Text(
              'No portfolio items yet.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
              ),
            ),
            if (_isOwnProfile) ...
              [
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManagePortfolioScreen(
                          photographerId: _photographer.uid,
                        ),
                      ),
                    );
                    _loadTabData();
                  },
                  icon: const Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 18,
                    color: Color(0xFFC62828),
                  ),
                  label: Text(
                    'Add your first photo',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _portfolioItems.length,
      itemBuilder: (context, index) {
        final item = _portfolioItems[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => PhotoViewerScreen(
                items: _portfolioItems,
                initialIndex: index,
              ),
            ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.imageUrl.isNotEmpty
                        ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _portfolioPlaceholder(),
                      )
                    : _portfolioPlaceholder(),
                if (item.caption != null && item.caption!.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.72),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        item.caption!,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _portfolioPlaceholder() {
    return Container(
      color: AppAvatarColors.profileHeaderBackground,
      child: Center(
        child: Icon(
          Icons.photo_camera_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPackages() {
    final packages = _photographer.packages;
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 8),
            Text(
              'No packages available.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final isPopular = pkg.isPopular;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPopular
                  ? const Color(0xFFC62828)
                  : const Color(0xFFE5E7EB),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC62828),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Most Popular',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Package name as small-caps label
                    Text(
                      pkg.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E9E9E),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Price — very prominent
                    pkg.price == 0
                        ? Text(
                            'Free',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFC62828),
                              height: 1.1,
                            ),
                          )
                        : PesoPriceText(
                            pkg.price,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFC62828),
                              height: 1.1,
                            ),
                          ),
                    const SizedBox(height: 12),
                    // Duration chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Color(0xFF374151),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pkg.duration,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF0F0F0), height: 1),
                    const SizedBox(height: 14),
                    // Features
                    ...pkg.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEBEE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 11,
                                color: Color(0xFFC62828),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Select button (hidden for own profile / photographer accounts)
                    SizedBox(
                      width: double.infinity,
                      child: _canBookPackages
                          ? (isPopular
                                ? ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BookingScreen(
                                          photographer: _photographer,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC62828),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Select ${pkg.name}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BookingScreen(
                                          photographer: _photographer,
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC62828),
                                      side: const BorderSide(
                                        color: Color(0xFFC62828),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Select ${pkg.name}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _isOwnProfile
                                    ? 'Use the Packages button below to manage pricing.'
                                    : 'Booking is available to client accounts only.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9E9E9E),
                                  height: 1.35,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviews() {
    if (_isLoadingTabs) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC62828)),
      );
    }
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_outline_rounded,
              size: 48,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 8),
            Text(
              'No reviews yet.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppProfileAvatar(
                    displayName: review.clientName,
                    photoUrl: review.clientPhotoUrl,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.clientName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '${_monthName(review.createdAt.month)} ${review.createdAt.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      review.rating.round(),
                      (i) => const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB300),
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                review.comment,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    showReportBottomSheet(
                      context: context,
                      reportedUserId: review.clientId,
                      reportedUserName: review.clientName,
                      contentType: 'review',
                      contentId: review.id,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Report',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
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
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _divider() {
    return Container(width: 1, height: 32, color: const Color(0xFFFFCDD2));
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
