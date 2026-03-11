import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, dynamic>> _upcoming = [
    {
      'photographer': 'Sofia Reyes',
      'initials': 'SR',
      'service': 'Standard Package',
      'date': 'Mar 18, 2026',
      'time': '10:00 AM',
      'location': 'New York, NY',
      'price': '\$450',
      'status': 'Confirmed',
      'gradient': [Color(0xFF8E0000), Color(0xFFC62828)],
    },
    {
      'photographer': 'Marcus Chen',
      'initials': 'MC',
      'service': 'Premium Package',
      'date': 'Mar 25, 2026',
      'time': '9:00 AM',
      'location': 'Brooklyn, NY',
      'price': '\$750',
      'status': 'Confirmed',
      'gradient': [Color(0xFF4A0000), Color(0xFF880E0E)],
    },
  ];

  static const List<Map<String, dynamic>> _requested = [
    {
      'photographer': 'Ava Thompson',
      'initials': 'AT',
      'service': 'Starter Package',
      'date': 'Apr 5, 2026',
      'time': '2:00 PM',
      'location': 'Chicago, IL',
      'price': '\$280',
      'status': 'Pending',
      'gradient': [Color(0xFF880E4F), Color(0xFFAD1457)],
    },
  ];

  static const List<Map<String, dynamic>> _past = [
    {
      'photographer': 'Isabella Cruz',
      'initials': 'IC',
      'service': 'Standard Package',
      'date': 'Feb 14, 2026',
      'time': '11:00 AM',
      'location': 'Austin, TX',
      'price': '\$450',
      'status': 'Completed',
      'gradient': [Color(0xFFAD1457), Color(0xFF560027)],
    },
    {
      'photographer': 'Liam Park',
      'initials': 'LP',
      'service': 'Starter Package',
      'date': 'Jan 22, 2026',
      'time': '3:00 PM',
      'location': 'Miami, FL',
      'price': '\$280',
      'status': 'Completed',
      'gradient': [Color(0xFFC62828), Color(0xFF6B0000)],
    },
    {
      'photographer': 'Noah Williams',
      'initials': 'NW',
      'service': 'Premium Package',
      'date': 'Dec 30, 2025',
      'time': '9:00 AM',
      'location': 'Seattle, WA',
      'price': '\$750',
      'status': 'Cancelled',
      'gradient': [Color(0xFF880E0E), Color(0xFF3D0000)],
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
                        value: '2',
                        label: 'Upcoming',
                        color: const Color(0xFFC62828),
                        bgColor: const Color(0xFFFFEBEE),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: '1',
                        label: 'Pending',
                        color: const Color(0xFFFF6D00),
                        bgColor: const Color(0xFFFFF3E0),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: '8',
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
                    unselectedLabelStyle:
                        GoogleFonts.poppins(fontSize: 13),
                    indicatorColor: const Color(0xFFC62828),
                    indicatorWeight: 2.5,
                    tabs: [
                      Tab(
                          text:
                              'Upcoming (${_upcoming.length})'),
                      Tab(
                          text:
                              'Requested (${_requested.length})'),
                      Tab(text: 'Past (${_past.length})'),
                    ],
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(_upcoming),
                  _buildBookingList(_requested),
                  _buildBookingList(_past),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> bookings) {
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
      itemBuilder: (context, index) =>
          _BookingCard(booking: bookings[index]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final Map<String, dynamic> booking;

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return const Color(0xFFFF6D00);
      case 'Cancelled':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFFE8F5E9);
      case 'Pending':
        return const Color(0xFFFFF3E0);
      case 'Cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String;
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
                colors:
                    List<Color>.from(booking['gradient'] as List),
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
                        width: 2),
                  ),
                  child: Center(
                    child: Text(
                      booking['initials'] as String,
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
                        booking['photographer'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        booking['service'] as String,
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
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
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
                      text: booking['date'] as String,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      text: booking['time'] as String,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.location_on_rounded,
                      text: booking['location'] as String,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.attach_money_rounded,
                      text: booking['price'] as String,
                      color: const Color(0xFFC62828),
                    ),
                  ],
                ),
                if (status == 'Confirmed' || status == 'Pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            foregroundColor:
                                const Color(0xFF7A7A7A),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Message',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            status == 'Pending'
                                ? 'Cancel'
                                : 'View Details',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'Completed') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFC62828)),
                        foregroundColor: const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.star_outline_rounded,
                          size: 16),
                      label: Text(
                        'Leave a Review',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
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
