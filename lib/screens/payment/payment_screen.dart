import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/booking_model.dart';
import '../../models/payment_method_model.dart';
import '../../models/payment_record_model.dart';
import '../../services/booking_service.dart';
import '../../services/payment_method_service.dart';
import '../../services/payment_service.dart';
import '../../services/storage_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _picker = ImagePicker();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _paymentReferenceController = TextEditingController();
  final _paymentNotesController = TextEditingController();

  bool _isProcessing = false;
  bool _saveCard = false;
  String _selectedMethodKey = 'new_card';
  File? _paymentProofFile;

  static const _otherMethods = [
    _OtherMethodConfig(
      key: 'new_card',
      icon: Icons.credit_card_rounded,
      label: 'Credit/Debit Card',
      color: Color(0xFF1976D2),
    ),
    _OtherMethodConfig(
      key: 'paypal',
      icon: Icons.account_balance_wallet_rounded,
      label: 'PayPal',
      color: Color(0xFF0070BA),
    ),
    _OtherMethodConfig(
      key: 'apple_pay',
      icon: Icons.apple_rounded,
      label: 'Apple Pay',
      color: Color(0xFF000000),
    ),
    _OtherMethodConfig(
      key: 'google_pay',
      icon: Icons.g_mobiledata_rounded,
      label: 'Google Pay',
      color: Color(0xFF4285F4),
    ),
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _paymentReferenceController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(
    BookingModel booking,
    List<PaymentMethodModel> savedMethods,
  ) async {
    if (_isProcessing) return;

    final existingPayment = await PaymentService().getPaymentForBooking(
      booking.id,
    );
    if (!mounted) return;
    if (existingPayment != null &&
        existingPayment.status != PaymentStatus.failed &&
        existingPayment.status != PaymentStatus.refunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A payment record already exists for this booking.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    PaymentMethodModel? selectedSavedMethod;
    for (final method in savedMethods) {
      if (method.id == _selectedMethodKey) {
        selectedSavedMethod = method;
        break;
      }
    }

    String? normalizedCardNumber;
    if (selectedSavedMethod == null && _selectedMethodKey == 'new_card') {
      normalizedCardNumber = _cardNumberController.text.replaceAll(
        RegExp(r'\s+'),
        '',
      );
      if (normalizedCardNumber.length < 12 ||
          _cardHolderController.text.trim().isEmpty ||
          _expiryController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please complete your card metadata',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    }

    final paymentLabel = selectedSavedMethod != null
        ? selectedSavedMethod.isCard
              ? '${selectedSavedMethod.label} ending in ${selectedSavedMethod.last4}'
              : selectedSavedMethod.label
        : _selectedMethodKey == 'new_card'
        ? '${PaymentMethodService().inferCardBrand(normalizedCardNumber!)} ending in ${normalizedCardNumber.substring(normalizedCardNumber.length - 4)}'
        : _otherMethods
              .firstWhere((method) => method.key == _selectedMethodKey)
              .label;

    setState(() => _isProcessing = true);
    try {
      String? proofUrl;
      if (_paymentProofFile != null) {
        final paymentProofId =
            '${booking.id}_${DateTime.now().millisecondsSinceEpoch}';
        proofUrl = await StorageService().uploadPaymentProof(
          paymentProofId,
          _paymentProofFile!,
        );
      }

      final noteParts = <String>[
        'Submitted from the app for manual confirmation.',
      ];
      final reference = _paymentReferenceController.text.trim();
      if (reference.isNotEmpty) {
        noteParts.add('Reference: $reference');
      }
      final userNotes = _paymentNotesController.text.trim();
      if (userNotes.isNotEmpty) {
        noteParts.add(userNotes);
      }

      final record = PaymentRecordModel(
        id: '',
        bookingId: booking.id,
        payerId: _currentUid,
        payeeId: booking.photographerId,
        amount: booking.packagePrice,
        paymentMethodLabel: paymentLabel,
        proofUrl: proofUrl,
        status: PaymentStatus.pending,
        notes: noteParts.join(' '),
        createdAt: DateTime.now(),
      );

      await PaymentService().createPaymentRecord(record);

      if (_selectedMethodKey == 'new_card' &&
          _saveCard &&
          normalizedCardNumber != null) {
        await PaymentMethodService().addCardMethod(
          userId: _currentUid,
          brand: PaymentMethodService().inferCardBrand(normalizedCardNumber),
          last4: normalizedCardNumber.substring(
            normalizedCardNumber.length - 4,
          ),
          expiry: _expiryController.text.trim(),
          holderName: _cardHolderController.text.trim(),
          isDefault: savedMethods.isEmpty,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              booking: booking,
              amount: booking.packagePrice,
              paymentMethodLabel: paymentLabel,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickPaymentProof() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null || !mounted) return;
    setState(() => _paymentProofFile = File(pickedFile.path));
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<Color> _gradientForId(String id) {
    const gradients = [
      [Color(0xFF6B0000), Color(0xFFC62828)],
      [Color(0xFF4A0000), Color(0xFF880E0E)],
      [Color(0xFF1A237E), Color(0xFF3949AB)],
      [Color(0xFF1B5E20), Color(0xFF388E3C)],
      [Color(0xFF004D40), Color(0xFF00897B)],
      [Color(0xFFBF360C), Color(0xFFE64A19)],
      [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    ];
    final index =
        id.codeUnits.fold<int>(0, (sum, code) => sum + code) % gradients.length;
    return gradients[index].cast<Color>();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFFBDBDBD),
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFFBDBDBD)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookingModel?>(
      future: BookingService().getBookingById(widget.bookingId),
      builder: (context, bookingSnapshot) {
        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828)),
            ),
          );
        }

        final booking = bookingSnapshot.data;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white),
            body: Center(
              child: Text(
                'Booking not found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
          );
        }

        final total = booking.packagePrice;
        final serviceFee = (total * 0.1).round();
        final subtotal = total - serviceFee;

        return StreamBuilder<List<PaymentMethodModel>>(
          stream: PaymentMethodService().paymentMethodsStream(_currentUid),
          builder: (context, methodsSnapshot) {
            final savedMethods =
                methodsSnapshot.data ?? const <PaymentMethodModel>[];

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
                  'Submit Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _gradientForId(
                                      booking.photographerId,
                                    ),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    booking.photographerInitials,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
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
                                      booking.photographerName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    Text(
                                      booking.packageName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Service Package',
                            value: booking.packageName,
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Date',
                            value: _formatDate(booking.scheduledDate),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Time',
                            value: booking.scheduledTime,
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Duration',
                            value: booking.packageDuration,
                          ),
                          const Divider(height: 24),
                          _SummaryRow(label: 'Subtotal', value: '\$$subtotal'),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Service Fee (10%)',
                            value: '\$$serviceFee',
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                '\$$total',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFC62828),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (savedMethods.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Saved Methods',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...savedMethods.map(
                              (method) => _SelectablePaymentMethodCard(
                                label: method.isCard
                                    ? '${method.label} •••• ${method.last4}'
                                    : method.label,
                                subtitle: method.isCard
                                    ? 'Expires ${method.expiry}'
                                    : 'Saved payment method',
                                icon: method.isCard
                                    ? Icons.credit_card_rounded
                                    : _walletIcon(method.provider),
                                color: method.isCard
                                    ? const Color(0xFF1976D2)
                                    : _walletColor(method.provider),
                                isSelected: _selectedMethodKey == method.id,
                                onTap: () => setState(
                                  () => _selectedMethodKey = method.id,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            'Other Methods',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._otherMethods.map(
                            (method) => _SelectablePaymentMethodCard(
                              label: method.label,
                              subtitle: method.key == 'new_card'
                                  ? 'Record a card payment method'
                                  : 'Record a payment made via ${method.label}',
                              icon: method.icon,
                              color: method.color,
                              isSelected: _selectedMethodKey == method.key,
                              onTap: () => setState(
                                () => _selectedMethodKey = method.key,
                              ),
                            ),
                          ),
                          if (_selectedMethodKey == 'new_card') ...[
                            const SizedBox(height: 20),
                            Text(
                              'Card Metadata',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _cardNumberController,
                              hint: 'Card Number (last 4 used for records)',
                              icon: Icons.credit_card_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _cardHolderController,
                                    hint: 'Card Holder',
                                    icon: Icons.person_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _expiryController,
                                    hint: 'MM/YY',
                                    icon: Icons.calendar_today_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  child: _buildTextField(
                                    controller: _paymentReferenceController,
                                    hint: 'Reference',
                                    icon: Icons.receipt_long_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _saveCard,
                                  onChanged: (value) {
                                    setState(() => _saveCard = value ?? false);
                                  },
                                  activeColor: const Color(0xFFC62828),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Save card metadata for future payments',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Reference & Proof',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_selectedMethodKey != 'new_card')
                            _buildTextField(
                              controller: _paymentReferenceController,
                              hint: 'Payment reference (optional)',
                              icon: Icons.receipt_long_rounded,
                            ),
                          if (_selectedMethodKey != 'new_card')
                            const SizedBox(height: 12),
                          TextField(
                            controller: _paymentNotesController,
                            maxLines: 4,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF1A1A1A),
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Add payment notes for the photographer (optional)',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFFBDBDBD),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickPaymentProof,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: const BorderSide(color: Color(0xFFC62828)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: Text(
                              _paymentProofFile == null
                                  ? 'Attach Payment Proof'
                                  : 'Proof Attached',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_paymentProofFile != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _paymentProofFile!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Proof image ready to upload',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _paymentProofFile = null,
                                    ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Firebase-backed Payment Record',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  'This screen records payment details, references, and proof in Firebase. Real card charging is not processed in-app.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              bottomSheet: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            '\$$total',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _processPayment(booking, savedMethods),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Submit Payment Record',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
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
          },
        );
      },
    );
  }

  static IconData _walletIcon(String provider) {
    switch (provider) {
      case 'paypal':
        return Icons.account_balance_wallet_rounded;
      case 'apple_pay':
        return Icons.apple_rounded;
      case 'google_pay':
        return Icons.g_mobiledata_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static Color _walletColor(String provider) {
    switch (provider) {
      case 'paypal':
        return const Color(0xFF0070BA);
      case 'apple_pay':
        return const Color(0xFF000000);
      case 'google_pay':
        return const Color(0xFF4285F4);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _SelectablePaymentMethodCard extends StatelessWidget {
  const _SelectablePaymentMethodCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC62828) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? const Color(0xFFC62828)
                  : const Color(0xFFBDBDBD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.booking,
    required this.amount,
    required this.paymentMethodLabel,
  });

  final BookingModel booking;
  final int amount;
  final String paymentMethodLabel;

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Payment Submitted',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment record has been saved with pending status.\n${booking.photographerName} can review the payment details from bookings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _SuccessDetailRow(
                      icon: Icons.person_rounded,
                      label: 'Photographer',
                      value: booking.photographerName,
                    ),
                    const SizedBox(height: 12),
                    _SuccessDetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: _formatDate(booking.scheduledDate),
                    ),
                    const SizedBox(height: 12),
                    _SuccessDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: booking.scheduledTime,
                    ),
                    const SizedBox(height: 12),
                    _SuccessDetailRow(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Package',
                      value: booking.packageName,
                    ),
                    const SizedBox(height: 12),
                    _SuccessDetailRow(
                      icon: Icons.credit_card_rounded,
                      label: 'Method',
                      value: paymentMethodLabel,
                    ),
                    const SizedBox(height: 12),
                    const _SuccessDetailRow(
                      icon: Icons.pending_actions_rounded,
                      label: 'Status',
                      value: 'Pending Confirmation',
                      valueColor: Color(0xFFFF9800),
                    ),
                    const SizedBox(height: 12),
                    _SuccessDetailRow(
                      icon: Icons.payments_rounded,
                      label: 'Recorded Amount',
                      value: '\$$amount',
                      valueColor: const Color(0xFFC62828),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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

class _SuccessDetailRow extends StatelessWidget {
  const _SuccessDetailRow({
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
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _OtherMethodConfig {
  const _OtherMethodConfig({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final String key;
  final IconData icon;
  final String label;
  final Color color;
}
