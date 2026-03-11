import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../booking/booking_screen.dart';

class PhotographerProfileScreen extends StatefulWidget {
  const PhotographerProfileScreen({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<PhotographerProfileScreen> createState() =>
      _PhotographerProfileScreenState();
}

class _PhotographerProfileScreenState extends State<PhotographerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  static const List<Map<String, dynamic>> _portfolioItems = [
    {'gradient': [Color(0xFF8E0000), Color(0xFFC62828)]},
    {'gradient': [Color(0xFF880E4F), Color(0xFFAD1457)]},
    {'gradient': [Color(0xFF4A0000), Color(0xFFBF360C)]},
    {'gradient': [Color(0xFF1A237E), Color(0xFFC62828)]},
    {'gradient': [Color(0xFF6B0000), Color(0xFF880E4F)]},
    {'gradient': [Color(0xFF3D0000), Color(0xFF8E0000)]},
    {'gradient': [Color(0xFF560027), Color(0xFFC62828)]},
    {'gradient': [Color(0xFFBF360C), Color(0xFF6B0000)]},
    {'gradient': [Color(0xFF880E0E), Color(0xFF4A0000)]},
  ];

  static const List<Map<String, dynamic>> _packages = [
    {
      'name': 'Starter',
      'duration': '2 hours',
      'price': '\$280',
      'features': ['50 edited photos', 'Online gallery', '1 location'],
    },
    {
      'name': 'Standard',
      'duration': '4 hours',
      'price': '\$450',
      'features': ['120 edited photos', 'Online gallery', '2 locations', 'Prints included'],
    },
    {
      'name': 'Premium',
      'duration': 'Full day',
      'price': '\$750',
      'features': ['250+ edited photos', 'Online gallery', 'Unlimited locations', 'Prints + album', 'Rush delivery'],
      'popular': true,
    },
  ];

  static const List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Emily Watson',
      'initials': 'EW',
      'rating': 5,
      'date': 'Jan 2026',
      'comment': 'Absolutely stunning photos! Professional, punctual, and creative. Would hire again without hesitation.',
    },
    {
      'name': 'James Rodriguez',
      'initials': 'JR',
      'rating': 5,
      'date': 'Dec 2025',
      'comment': 'Captured our wedding day beautifully. Every shot felt natural and emotional. Truly talented.',
    },
    {
      'name': 'Sarah Kim',
      'initials': 'SK',
      'rating': 4,
      'date': 'Nov 2025',
      'comment': 'Great work overall! Very responsive and easy to work with. Photos came out gorgeous.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final List<Color> gradient = List<Color>.from(data['gradient'] as List);

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
                backgroundColor: gradient[0],
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
                  GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite ? Colors.pinkAccent : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                              color:
                                  Colors.white.withValues(alpha: 0.07),
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
                              color:
                                  Colors.white.withValues(alpha: 0.05),
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
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    data['initials'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      data['specialty'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
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
                                          data['location'] as String,
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
                      _StatItem(value: '420+', label: 'Photos'),
                      _divider(),
                      _StatItem(
                        value: '${data['rating']}',
                        label: 'Rating',
                        valueColor: const Color(0xFFC62828),
                      ),
                      _divider(),
                      _StatItem(value: '180+', label: 'Bookings'),
                      _divider(),
                      _StatItem(value: '5yr', label: 'Experience'),
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
                        'I\'m a professional photographer with over 5 years of experience specializing in ${data['specialty']}. I believe every moment tells a story, and my mission is to capture yours with authenticity and artistry. Based in ${data['location']}, I\'m available for travel worldwide.',
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
                        children: [
                          data['specialty'] as String,
                          'Portrait',
                          'Editorial',
                          'Natural Light',
                          'Studio'
                        ].map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                        )).toList(),
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
                    unselectedLabelStyle:
                        GoogleFonts.poppins(fontSize: 13),
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
                    _buildPackages(data),
                    _buildReviews(),
                  ],
                ),
              ),
            ],
          ),
          // Book Now button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Starting from',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                        Text(
                          data['price'] != null
                              ? '${data['price']}/hr'
                              : '\$280/hr',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingScreen(photographerData: data),
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
                      child: Text(
                        'Book Now',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolio() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _portfolioItems.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: List<Color>.from(_portfolioItems[index]['gradient'] as List),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              Icons.photo_camera_rounded,
              color: Colors.white.withValues(alpha: 0.35),
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackages(Map<String, dynamic> data) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        final isPopular = pkg['popular'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
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
            children: [
              if (isPopular)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg['name'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              pkg['duration'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          pkg['price'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(pkg['features'] as List<String>).map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFC62828),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            f,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingScreen(photographerData: data),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPopular
                              ? const Color(0xFFC62828)
                              : Colors.white,
                          foregroundColor: isPopular
                              ? Colors.white
                              : const Color(0xFFC62828),
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: isPopular
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color(0xFFC62828)),
                          ),
                        ),
                        child: Text(
                          'Select Package',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8E0000), Color(0xFFC62828)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        review['initials'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          review['date'] as String,
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
                      review['rating'] as int,
                      (i) => const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                review['comment'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
