import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/firebase_constants.dart';
import '../../models/verification_submission_model.dart';
import '../../services/user_service.dart';
import '../../services/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final Map<String, File> _selectedDocuments = {};

  bool _isSubmitting = false;
  bool _didPrefill = false;

  String get _currentUid => VerificationService().currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await UserService().fetchCurrentUser();
    if (!mounted) return;
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = user?.name ?? '';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String type) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() {
      _selectedDocuments[type] = File(file.path);
    });
  }

  String _maskId(String value) {
    if (value.length <= 4) return value;
    final visible = value.substring(value.length - 4);
    return '••••$visible';
  }

  Color _statusColor(String status) {
    switch (status) {
      case VerificationStatuses.verified:
        return const Color(0xFF2E7D32);
      case VerificationStatuses.pending:
        return const Color(0xFFFF8F00);
      case VerificationStatuses.rejected:
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case VerificationStatuses.verified:
        return const Color(0xFFE8F5E9);
      case VerificationStatuses.pending:
        return const Color(0xFFFFF8E1);
      case VerificationStatuses.rejected:
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case VerificationStatuses.verified:
        return 'Verified';
      case VerificationStatuses.pending:
        return 'Pending Review';
      case VerificationStatuses.rejected:
        return 'Needs Attention';
      default:
        return 'Not Submitted';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDocuments.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload all required documents.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await VerificationService().submitVerification(
        userId: _currentUid,
        legalName: _nameController.text.trim(),
        governmentIdNumber: _idController.text.trim(),
        documents: [
          PendingDocument(type: 'front', file: _selectedDocuments['front']!),
          PendingDocument(type: 'back', file: _selectedDocuments['back']!),
          PendingDocument(type: 'selfie', file: _selectedDocuments['selfie']!),
        ],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification submitted successfully.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _selectedDocuments.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit verification: $error',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VerificationSubmissionModel?>(
      stream: VerificationService().submissionStream(_currentUid),
      builder: (context, snapshot) {
        final submission = snapshot.data;
        if (!_didPrefill && submission != null) {
          _didPrefill = true;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = submission.legalName;
          }
          if (_idController.text.trim().isEmpty) {
            _idController.text = submission.governmentIdNumber;
          }
        }

        final isLocked =
            submission != null &&
            (submission.isPending || submission.isVerified);

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
              'Identity Verification',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submission != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusBg(submission.status),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(submission.status),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(submission.status),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${submission.documents.length} documents',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _StatusRow(
                          label: 'Legal Name',
                          value: submission.legalName,
                        ),
                        const SizedBox(height: 10),
                        _StatusRow(
                          label: 'Government ID',
                          value: _maskId(submission.governmentIdNumber),
                        ),
                        if (submission.rejectionReason != null &&
                            submission.rejectionReason!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              submission.rejectionReason!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (submission != null) const SizedBox(height: 16),
                if (isLocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      submission.isVerified
                          ? 'Your account has already been verified. No further action is required.'
                          : 'Your submission is currently under review. You can update it again if support requests changes.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Submit your legal identity details and three clear images so the review team can verify your account.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF1A1A1A),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Full Legal Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Enter your full legal name',
                          icon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your legal name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Government ID Number'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _idController,
                          hint: 'Enter your ID number',
                          icon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your ID number';
                            }
                            if (value.trim().length < 5) {
                              return 'Please enter a valid ID number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Required Documents',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DocumentUploadCard(
                          title: 'Front of ID',
                          subtitle: _selectedDocuments['front'] != null
                              ? _selectedDocuments['front']!.path
                                    .split(Platform.pathSeparator)
                                    .last
                              : 'Upload a clear image of the front side',
                          isUploaded: _selectedDocuments['front'] != null,
                          onTap: () => _pickDocument('front'),
                        ),
                        const SizedBox(height: 12),
                        _DocumentUploadCard(
                          title: 'Back of ID',
                          subtitle: _selectedDocuments['back'] != null
                              ? _selectedDocuments['back']!.path
                                    .split(Platform.pathSeparator)
                                    .last
                              : 'Upload a clear image of the back side',
                          isUploaded: _selectedDocuments['back'] != null,
                          onTap: () => _pickDocument('back'),
                        ),
                        const SizedBox(height: 12),
                        _DocumentUploadCard(
                          title: 'Selfie with ID',
                          subtitle: _selectedDocuments['selfie'] != null
                              ? _selectedDocuments['selfie']!.path
                                    .split(Platform.pathSeparator)
                                    .last
                              : 'Upload a selfie while holding your ID',
                          isUploaded: _selectedDocuments['selfie'] != null,
                          onTap: () => _pickDocument('selfie'),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tips',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...[
                                'Use good lighting',
                                'Keep all text readable',
                                'Avoid glare or blur',
                                'Upload uncropped originals',
                              ].map(
                                (tip) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '• $tip',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
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
                                    submission?.isRejected == true
                                        ? 'Resubmit Verification'
                                        : 'Submit Verification',
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFFBDBDBD),
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

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
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isUploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isUploaded
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUploaded ? Icons.check_rounded : Icons.upload_file_rounded,
                color: isUploaded
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}
