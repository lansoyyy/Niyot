import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_avatar_colors.dart';
import '../../data/philippines_locations.dart';
import '../../models/booking_model.dart';
import '../../models/photographer_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/currency/peso_price_text.dart';
import '../../widgets/location/ph_location_dropdowns.dart';
import 'booking_confirmation_screen.dart';
import '../calendar/calendar_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.photographer});

  final PhotographerModel photographer;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  int _selectedTimeSlot = 1;
  int _selectedService = 0;
  bool _isSubmitting = false;
  /// When set, this screen is read-only (self-booking or photographer account).
  String? _bookingBlockedReason;
  String _selectedEventType = 'Wedding';
  final _notesController = TextEditingController();
  final _venueController = TextEditingController();
  String _country = PhilippinesLocations.countryName;
  String _province = '';
  String _city = '';

  // Must match AvailabilityModel.defaultSlots so reservations resolve cleanly.
  final List<String> _timeSlots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _evaluateBookingEligibility();
  }

  Future<void> _evaluateBookingEligibility() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (uid == widget.photographer.uid) {
      if (mounted) {
        setState(() => _bookingBlockedReason = 'self');
      }
      return;
    }
    final cached = UserService().cachedUser;
    final user = cached ?? await UserService().fetchCurrentUser();
    if (!mounted) return;
    if (user?.isPhotographer == true) {
      setState(() => _bookingBlockedReason = 'photographer');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photographer = widget.photographer;
    final packages = photographer.packages.isNotEmpty
        ? photographer.packages
        : [
            // Fallback if no packages loaded
          ];
    if (packages.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF374151),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Book a Session',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        body: const Center(
          child: Text('No packages available for this photographer.'),
        ),
      );
    }

    if (_bookingBlockedReason != null) {
      final message = _bookingBlockedReason == 'self'
          ? 'You cannot book a session with your own photographer profile.'
          : 'Client accounts can book photographers. Switch to a client profile or use a separate client account to place a booking.';
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF374151),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Book a Session',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF374151),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Book a Session',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photographer summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppAvatarColors.profileHeaderBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: AppProfileAvatar(
                      displayName: photographer.name,
                      photoUrl: photographer.photoUrl,
                      size: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photographer.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          photographer.primarySpecialty.isNotEmpty
                              ? photographer.primarySpecialty
                              : photographer.specialties.isNotEmpty
                              ? photographer.specialties.first
                              : '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB300),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photographer.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Package selection
            _sectionTitle('Select Package'),
            const SizedBox(height: 12),
            ...List.generate(
              packages.length,
              (index) => GestureDetector(
                onTap: () => setState(() => _selectedService = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedService == index
                        ? const Color(0xFFFFEBEE)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedService == index
                          ? const Color(0xFFC62828)
                          : const Color(0xFFE5E7EB),
                      width: _selectedService == index ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedService == index
                              ? const Color(0xFFC62828)
                              : Colors.transparent,
                          border: Border.all(
                            color: _selectedService == index
                                ? const Color(0xFFC62828)
                                : const Color(0xFFBDBDBD),
                            width: 2,
                          ),
                        ),
                        child: _selectedService == index
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              packages[index].name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              packages[index].duration,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PesoPriceText(
                        packages[index].price,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _selectedService == index
                              ? const Color(0xFFC62828)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selected package details card
            if (packages.isNotEmpty) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _buildSelectedPackageCard(
                  packages[_selectedService.clamp(0, packages.length - 1)],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Date section with calendar link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Select Date'),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CalendarScreen(photographer: widget.photographer),
                      ),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        _selectedDate = result['date'] as DateTime;
                        _selectedTimeSlot = _timeSlots.indexOf(
                          result['time'] as String,
                        );
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Color(0xFFC62828),
                  ),
                  label: Text(
                    'View Full Calendar',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCalendar(),
            const SizedBox(height: 24),
            // Time slots
            _sectionTitle('Select Time'),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final selected = _selectedTimeSlot == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeSlot = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFC62828)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFC62828)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _timeSlots[index],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF7A7A7A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Event type
            _sectionTitle('Event Type'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  prefixIcon: Icon(
                    Icons.event_rounded,
                    color: Color(0xFF9E9E9E),
                    size: 20,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
                items:
                    [
                          'Wedding',
                          'Portrait',
                          'Event',
                          'Commercial',
                          'Fashion',
                          'Product',
                          'Other',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedEventType = v);
                },
                dropdownColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Location (country / province / city dropdowns; exact address typed)
            _sectionTitle('Location'),
            const SizedBox(height: 12),
            PhLocationDropdowns(
              country: _country,
              province: _province,
              city: _city,
              dense: true,
              onCountryChanged: (c) => setState(() => _country = c),
              onProvinceChanged: (p) => setState(() {
                _province = p;
                _city = '';
              }),
              onCityChanged: (c) => setState(() => _city = c),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Exact address or venue'),
            const SizedBox(height: 8),
            VenueAddressField(
              controller: _venueController,
              hint: 'Street, building, barangay, landmark…',
            ),
            const SizedBox(height: 24),
            // Notes
            _sectionTitle('Additional Notes'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Any special requirements, locations, or style preferences...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFBDBDBD),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom summary bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                    'Total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  packages.isNotEmpty
                      ? PesoPriceText(
                          packages[_selectedService.clamp(
                            0,
                            packages.length - 1,
                          )].price,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC62828),
                          ),
                        )
                      : Text(
                          '—',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Confirm Booking',
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
    );
  }

  Future<void> _submitBooking() async {
    final photographer = widget.photographer;
    final packages = photographer.packages;
    if (packages.isEmpty) return;
    final pkg = packages[_selectedService.clamp(0, packages.length - 1)];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_bookingBlockedReason != null ||
        currentUser.uid == photographer.uid) {
      return;
    }
    final gateUser =
        UserService().cachedUser ?? await UserService().fetchCurrentUser();
    if (!mounted) return;
    if (gateUser?.isPhotographer == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photographer accounts cannot place bookings.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      return;
    }

    final venue = _venueController.text.trim();

    if (_province.isEmpty || _city.isEmpty || venue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select province and city, and enter the exact address.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final scheduledTime = _timeSlots[_selectedTimeSlot];
      final slotFree = await BookingService().isTimeSlotAvailable(
        photographerId: photographer.uid,
        scheduledDate: _selectedDate,
        scheduledTime: scheduledTime,
      );
      if (!slotFree) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'That time slot is no longer available. Please choose another date or time.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final user = await UserService().fetchCurrentUser();
      final booking = BookingModel(
        id: '',
        clientId: currentUser.uid,
        clientName: user?.name ?? currentUser.displayName ?? 'Client',
        clientPhotoUrl: user?.photoUrl,
        photographerId: photographer.uid,
        photographerName: photographer.name,
        photographerPhotoUrl: photographer.photoUrl,
        packageName: pkg.name,
        packagePrice: pkg.price,
        packageDuration: pkg.duration,
        scheduledDate: _selectedDate,
        scheduledTime: scheduledTime,
        location: _buildClientLocation(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: BookingStatus.paymentPending,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => BookingConfirmationScreen(pendingBooking: booking),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not continue: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _buildClientLocation() {
    final base = PhilippinesLocations.composeLocation(
      city: _city,
      province: _province,
      country: _country,
    );
    final v = _venueController.text.trim();
    if (v.isEmpty) return base;
    return '$base — $v';
  }

  Widget _buildSelectedPackageCard(dynamic pkg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pkg.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              PesoPriceText(
                pkg.price as int,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 4),
              Text(
                pkg.duration as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          if ((pkg.features as List).isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFFFE0E0), height: 1),
            const SizedBox(height: 8),
            ...(pkg.features as List<String>).map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFFC62828),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay = now;
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7; // 0=Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthName(now.month)} ${now.year}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => SizedBox(
                    width: 32,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
            ),
            itemCount: daysInMonth + firstWeekday,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = index - firstWeekday + 1;
              final date = DateTime(now.year, now.month, day);
              final isSelected =
                  _selectedDate.day == day && _selectedDate.month == now.month;
              final isPast = date.isBefore(firstDay) && date.day < now.day;
              final isToday = date.day == now.day;

              return GestureDetector(
                onTap: isPast
                    ? null
                    : () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFC62828)
                        : isToday
                        ? const Color(0xFFFFEBEE)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isPast
                            ? const Color(0xFFE0E0E0)
                            : isToday
                            ? const Color(0xFFC62828)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
