import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';

/// Prompts guests to sign in / register before gated actions.
class AuthGateHelper {
  AuthGateHelper._();

  static bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Returns true if the user is already signed in, or signs in via the gate.
  ///
  /// Opens Login/Register with [popOnSuccess] so the underlying screen
  /// (e.g. creator profile) stays on the stack and is restored after auth.
  static Future<bool> requireAuth(
    BuildContext context, {
    String message = 'Sign in to continue',
  }) async {
    if (isSignedIn) return true;
    if (!context.mounted) return false;

    final choice = await showModalBottomSheet<_AuthChoice>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AuthGateSheet(message: message),
    );

    if (choice == null || !context.mounted) return false;

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => choice == _AuthChoice.register
            ? const RegisterScreen(popOnSuccess: true)
            : const LoginScreen(popOnSuccess: true),
      ),
    );

    if (ok == true) {
      await UserService().fetchCurrentUser();
      await NotificationService().init();
    }

    return isSignedIn;
  }
}

enum _AuthChoice { login, register }

class _AuthGateSheet extends StatelessWidget {
  const _AuthGateSheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account or log in to book, message, and save creators.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(_AuthChoice.register),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(_AuthChoice.login),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Log In',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
}
