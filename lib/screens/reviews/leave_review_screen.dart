import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_service.dart';

class LeaveReviewScreen extends StatefulWidget {
  const LeaveReviewScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to leave a review.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentProfile =
          UserService().cachedUser ?? await UserService().fetchCurrentUser();

      await BookingService().submitReview(
        bookingId: widget.booking.id,
        clientId: currentUser.uid,
        clientName: currentProfile?.name ?? widget.booking.clientName,
        clientPhotoUrl:
            currentProfile?.photoUrl ?? widget.booking.clientPhotoUrl,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Leave a Review',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking.photographerName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.booking.packageName} • ${widget.booking.scheduledTime}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking.location,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your session?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        final selected = _rating >= value;
                        return IconButton(
                          onPressed: _isSubmitting
                              ? null
                              : () =>
                                    setState(() => _rating = value.toDouble()),
                          icon: Icon(
                            selected
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB300),
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rating >= 5
                          ? 'Excellent experience'
                          : _rating >= 4
                          ? 'Great experience'
                          : _rating >= 3
                          ? 'Good experience'
                          : _rating >= 2
                          ? 'Needs improvement'
                          : 'Poor experience',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 5,
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share details about your experience...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFFBDBDBD),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please add a short review.';
                        }
                        if (value.trim().length < 10) {
                          return 'Review must be at least 10 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Submit Review',
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
    );
  }
}
