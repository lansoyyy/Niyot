import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../messages/chat_screen.dart';
import '../reviews/leave_review_screen.dart';
import 'booking_actions_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.isPhotographer,
  });

  final BookingModel booking;
  final bool isPhotographer;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLoading = false;
  final _deliveryLinkCtrl = TextEditingController();
  final _deliveryNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.booking.deliveryLink != null) {
      _deliveryLinkCtrl.text = widget.booking.deliveryLink!;
    }
    if (widget.booking.deliveryNote != null) {
      _deliveryNoteCtrl.text = widget.booking.deliveryNote!;
    }
  }

  @override
  void dispose() {
    _deliveryLinkCtrl.dispose();
    _deliveryNoteCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final wd = weekdays[d.weekday - 1];
    return '$wd, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Duration _countdown(DateTime target) {
    final now = DateTime.now();
    return target.isAfter(now) ? target.difference(now) : Duration.zero;
  }

  String _countdownText(Duration dur) {
    if (dur == Duration.zero) return 'Today';
    final days = dur.inDays;
    final hours = dur.inHours.remainder(24);
    if (days > 0) return '$days day${days == 1 ? '' : 's'} $hours hr';
    return '$hours hr ${dur.inMinutes.remainder(60)} min';
  }

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
    final index = id.codeUnits.fold<int>(0, (s, c) => s + c) % pairs.length;
    return pairs[index].cast<Color>();
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      await BookingService().acceptBooking(widget.booking.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Decline booking?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will notify the client that their request was declined.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Decline', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await BookingService().declineBooking(widget.booking.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Cancel booking?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this booking?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Yes, cancel', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await BookingService().cancelBooking(widget.booking.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deliverPhotos() async {
    final link = _deliveryLinkCtrl.text.trim();
    if (link.isEmpty) {
      _showError('Please enter a delivery link.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await BookingService().markDelivered(
        bookingId: widget.booking.id,
        deliveryLink: link,
        deliveryNote: _deliveryNoteCtrl.text.trim().isEmpty
            ? null
            : _deliveryNoteCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos delivered successfully!')),
      );
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markComplete() async {
    setState(() => _isLoading = true);
    try {
      await BookingService().markCompleted(widget.booking.id);
      if (!mounted) return;
      // Prompt to leave review
      final left = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => LeaveReviewScreen(booking: widget.booking),
        ),
      );
      if (!mounted) return;
      if (left == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking completed and review submitted!')),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;
    final booking = widget.booking;
    final userProfile =
        UserService().cachedUser ?? await UserService().fetchCurrentUser();

    final otherUserId = widget.isPhotographer ? booking.clientId : booking.photographerId;
    final otherUserName = widget.isPhotographer ? booking.clientName : booking.photographerName;
    final otherUserPhoto = widget.isPhotographer
        ? booking.clientPhotoUrl
        : booking.photographerPhotoUrl;

    final convId = await MessagingService().getOrCreateConversation(
      myId: currentUser.uid,
      myName: userProfile?.name ?? currentUser.displayName ?? 'User',
      myPhotoUrl: userProfile?.photoUrl,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhotoUrl: otherUserPhoto,
      bookingId: booking.id,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFC62828),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPhotographer = widget.isPhotographer;
    final status = booking.status;

    final otherName = isPhotographer ? booking.clientName : booking.photographerName;
    final otherInitials = isPhotographer ? booking.clientInitials : booking.photographerInitials;
    final gradientId = isPhotographer ? booking.clientId : booking.photographerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
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
          'Booking Details',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (!booking.isPast)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF374151)),
              onPressed: _openChat,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Other party card ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradient(gradientId),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      otherInitials,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isPhotographer ? 'Client' : 'Photographer',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Countdown (upcoming only) ─────────────────────────────────
            if (status == BookingStatus.confirmed && booking.isUpcoming) ...[
              Builder(builder: (_) {
                final dur = _countdown(booking.scheduledDate);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR SHOOT IS IN',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              _countdownText(dur),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // ── Delivery card (inProgress – client view) ──────────────────
            if (status == BookingStatus.inProgress &&
                !isPhotographer &&
                booking.deliveryLink != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            color: Color(0xFF1565C0), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Photos Delivered!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: booking.deliveryLink!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.deliveryLink!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF1565C0),
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded,
                                size: 16, color: Color(0xFF1565C0)),
                          ],
                        ),
                      ),
                    ),
                    if (booking.deliveryNote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        booking.deliveryNote!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Booking details card ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Package',
                    value: booking.packageName,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formatDate(booking.scheduledDate),
                  ),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: booking.scheduledTime,
                  ),
                  _DetailRow(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Duration',
                    value: booking.packageDuration,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: booking.location,
                  ),
                  _DetailRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Total',
                    value: '\$${booking.packagePrice}',
                    valueColor: const Color(0xFF2E7D32),
                  ),
                  if (booking.notes != null && booking.notes!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: booking.notes!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status-specific action sections ───────────────────────────
            if (status == BookingStatus.requested) ...[
              if (isPhotographer) ...[
                // Photographer: accept / decline
                _ActionSection(
                  title: 'Respond to Request',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _decline,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC62828)),
                            foregroundColor: const Color(0xFFC62828),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? _Spinner(color: const Color(0xFFC62828))
                              : Text(
                                  'Decline',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _accept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const _Spinner(color: Colors.white)
                              : Text(
                                  'Accept',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Client: cancel pending request
                _ActionSection(
                  title: 'Waiting for Response',
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_empty_rounded,
                                color: Color(0xFFFF6D00), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your request is awaiting photographer confirmation.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _cancelBooking,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC62828)),
                            foregroundColor: const Color(0xFFC62828),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel Request',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            if (status == BookingStatus.confirmed && booking.isUpcoming) ...[
              _ActionSection(
                title: 'Manage Session',
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18),
                        label: Text(
                          'Message',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingActionsScreen(
                              booking: widget.booking,
                              actionType: 'reschedule',
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: const Color(0xFF374151),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_calendar_outlined,
                            size: 18),
                        label: Text(
                          'Reschedule',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _cancelBooking,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC62828)),
                          foregroundColor: const Color(0xFFC62828),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel Booking',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (booking.isActive) ...[
              if (isPhotographer) ...[
                // Photographer: deliver photos
                _ActionSection(
                  title: 'Deliver Photos',
                  child: Column(
                    children: [
                      TextField(
                        controller: _deliveryLinkCtrl,
                        decoration: InputDecoration(
                          labelText: 'Gallery / Download link',
                          labelStyle: GoogleFonts.poppins(fontSize: 13),
                          hintText: 'https://...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFC62828)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _deliveryNoteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          labelStyle: GoogleFonts.poppins(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFC62828)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _deliverPhotos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const _Spinner(color: Colors.white)
                              : const Icon(Icons.upload_rounded, size: 18),
                          label: Text(
                            booking.deliveryLink != null
                                ? 'Update Delivery'
                                : 'Send Photos',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Client: mark complete if photos delivered
                _ActionSection(
                  title: 'Session Complete?',
                  child: Column(
                    children: [
                      if (booking.deliveryLink == null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded,
                                  color: Color(0xFF9E9E9E), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Awaiting photo delivery from photographer.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _markComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isLoading
                                ? const _Spinner(color: Colors.white)
                                : const Icon(Icons.check_circle_outline_rounded,
                                    size: 18),
                            label: Text(
                              'Mark Complete & Review',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],

            // ── Past / completed actions ──────────────────────────────────
            if (status == BookingStatus.completed) ...[
              _ActionSection(
                title: 'Session Summary',
                child: Column(
                  children: [
                    if (!booking.hasReview)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final left = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LeaveReviewScreen(booking: widget.booking),
                              ),
                            );
                            if (!context.mounted || left != true) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Review submitted!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.star_outline_rounded,
                              size: 18),
                          label: Text(
                            'Leave a Review',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Review already submitted',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF2E7D32),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final BookingStatus status;

  Color get _color {
    switch (status) {
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

  Color get _bg {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
