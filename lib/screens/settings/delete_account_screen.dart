import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../core/google_sign_in_config.dart';
import '../../services/account_deletion_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_button.dart';
import '../auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isDeleting = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _usesPasswordAuth {
    final providers =
        _user?.providerData.map((item) => item.providerId).toSet() ?? {};
    return providers.contains('password');
  }

  bool get _usesGoogleAuth {
    final providers =
        _user?.providerData.map((item) => item.providerId).toSet() ?? {};
    return providers.contains('google.com');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<AuthCredential?> _buildCredential() async {
    final user = _user;
    if (user == null) return null;

    if (_usesPasswordAuth) {
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        _showError('Please enter your password to confirm deletion.');
        return null;
      }
      if (user.email == null || user.email!.isEmpty) {
        _showError('Unable to verify your account email.');
        return null;
      }
      return EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
    }

    if (_usesGoogleAuth) {
      final googleUser = await createGoogleSignIn().signIn();
      if (googleUser == null) {
        _showError('Google sign-in was cancelled.');
        return null;
      }
      final googleAuth = await googleUser.authentication;
      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }

    _showError('This account cannot be verified for deletion.');
    return null;
  }

  Future<void> _deleteAccount() async {
    if (_confirmController.text.trim().toUpperCase() != 'DELETE') {
      _showError('Type DELETE to confirm account removal.');
      return;
    }

    final credential = await _buildCredential();
    if (credential == null) return;

    setState(() => _isDeleting = true);
    try {
      await AccountDeletionService().deleteAccount(credential: credential);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your account has been permanently deleted.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(AuthService.parseError(error));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.gray700,
            ),
          ),
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.deleteAccountConfirmation,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What will be removed',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _DeletionItem(text: 'Your profile, favorites, and notifications'),
            _DeletionItem(text: 'Saved payment methods and verification documents'),
            _DeletionItem(text: 'Portfolio photos and profile images'),
            _DeletionItem(
              text: 'Your messages (booking records are kept but anonymized)',
            ),
            const SizedBox(height: 24),
            Text(
              'Confirm deletion',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              enabled: !_isDeleting,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type DELETE',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            if (_usesPasswordAuth) ...[
              const SizedBox(height: 20),
              Text(
                'Current password',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                enabled: !_isDeleting,
                obscureText: _obscurePassword,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
            if (_usesGoogleAuth && !_usesPasswordAuth) ...[
              const SizedBox(height: 12),
              Text(
                'You will be asked to sign in with Google again to confirm.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 28),
            AppButton(
              text: 'Permanently Delete Account',
              onPressed: _isDeleting ? null : _deleteAccount,
              isFullWidth: true,
              isLoading: _isDeleting,
              size: AppButtonSize.large,
              variant: AppButtonVariant.primary,
              icon: Icons.delete_forever_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletionItem extends StatelessWidget {
  const _DeletionItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
