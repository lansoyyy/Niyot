import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../models/photographer_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import '../photographer/photographer_profile_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'favorites_screen.dart';
import 'payment_methods_screen.dart';
import 'verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSigningOut = false;

  Future<void> _updateNotificationPreference(
    UserModel user,
    String key,
    bool value,
  ) async {
    final updated = Map<String, bool>.from(user.notificationPreferences);
    updated[key] = value;
    await UserService().updateNotificationPreferences(_currentUid, updated);
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.parseError(error),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  String _formatMonthYear(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unverified';
    }
  }

  Color _verificationColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFFF8F00);
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _verificationBg(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No signed-in user found')),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: UserService().userStream(_currentUid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828)),
            ),
          );
        }

        final user = userSnapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F8F8),
            body: Center(
              child: Text(
                'Unable to load account settings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }

        if (user.isPhotographer) {
          return StreamBuilder<PhotographerModel?>(
            stream: PhotographerService().photographerStream(_currentUid),
            builder: (context, photographerSnapshot) {
              return _SettingsContent(
                user: user,
                photographer: photographerSnapshot.data,
                onTogglePreference: (key, value) =>
                    _updateNotificationPreference(user, key, value),
                onSignOut: _signOut,
                isSigningOut: _isSigningOut,
                verificationLabel: _verificationLabel(user.verificationStatus),
                verificationColor: _verificationColor(user.verificationStatus),
                verificationBg: _verificationBg(user.verificationStatus),
                memberSince: _formatMonthYear(user.createdAt),
              );
            },
          );
        }

        return StreamBuilder<List<BookingModel>>(
          stream: BookingService().clientBookingsStream(_currentUid),
          builder: (context, bookingsSnapshot) {
            return _SettingsContent(
              user: user,
              clientBookings: bookingsSnapshot.data ?? const <BookingModel>[],
              onTogglePreference: (key, value) =>
                  _updateNotificationPreference(user, key, value),
              onSignOut: _signOut,
              isSigningOut: _isSigningOut,
              verificationLabel: _verificationLabel(user.verificationStatus),
              verificationColor: _verificationColor(user.verificationStatus),
              verificationBg: _verificationBg(user.verificationStatus),
              memberSince: _formatMonthYear(user.createdAt),
            );
          },
        );
      },
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.user,
    required this.onTogglePreference,
    required this.onSignOut,
    required this.isSigningOut,
    required this.verificationLabel,
    required this.verificationColor,
    required this.verificationBg,
    required this.memberSince,
    this.photographer,
    this.clientBookings = const <BookingModel>[],
  });

  final UserModel user;
  final PhotographerModel? photographer;
  final List<BookingModel> clientBookings;
  final Future<void> Function(String key, bool value) onTogglePreference;
  final Future<void> Function() onSignOut;
  final bool isSigningOut;
  final String verificationLabel;
  final Color verificationColor;
  final Color verificationBg;
  final String memberSince;

  @override
  Widget build(BuildContext context) {
    final prefs = user.notificationPreferences;
    final isPhotographer = user.isPhotographer && photographer != null;
    final clientCompleted = clientBookings
        .where((booking) => booking.status == BookingStatus.completed)
        .length;
    final clientUpcoming = clientBookings
        .where((booking) => booking.isUpcoming)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B0000), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage:
                          user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null || user.photoUrl!.isEmpty
                          ? Text(
                              user.initials,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user.email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderBadge(
                          icon: user.isPhotographer
                              ? Icons.camera_alt_rounded
                              : Icons.person_rounded,
                          label: user.isPhotographer
                              ? 'Photographer'
                              : 'Client',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: verificationBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            verificationLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: verificationColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: isPhotographer
                          ? [
                              _ProfileStat(
                                value: '${photographer!.bookingCount}',
                                label: 'Bookings',
                              ),
                              _vDivider(),
                              _ProfileStat(
                                value: photographer!.rating.toStringAsFixed(1),
                                label: 'Rating',
                              ),
                              _vDivider(),
                              _ProfileStat(
                                value: '${photographer!.profileViewCount}',
                                label: 'Views',
                              ),
                              _vDivider(),
                              _ProfileStat(
                                value: '${photographer!.photoCount}',
                                label: 'Photos',
                              ),
                            ]
                          : [
                              _ProfileStat(
                                value: '${clientBookings.length}',
                                label: 'Bookings',
                              ),
                              _vDivider(),
                              _ProfileStat(
                                value: '$clientUpcoming',
                                label: 'Upcoming',
                              ),
                              _vDivider(),
                              _ProfileStat(
                                value: '$clientCompleted',
                                label: 'Completed',
                              ),
                              _vDivider(),
                              _ProfileStat(
                                value: memberSince,
                                label: 'Member Since',
                              ),
                            ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          'Edit Profile',
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
              const SizedBox(height: 12),
              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: user.location ?? 'Manage your profile details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              if (user.isPhotographer)
                _SettingsTile(
                  icon: Icons.badge_outlined,
                  title: 'Professional Profile',
                  subtitle: photographer?.primarySpecialty.isNotEmpty == true
                      ? photographer!.primarySpecialty
                      : 'Portfolio, services, pricing',
                  onTap: () {
                    if (photographer != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhotographerProfileScreen(
                            photographer: photographer!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    }
                  },
                ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Secure your account credentials',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.verified_outlined,
                title: 'Verification',
                subtitle: 'Identity and trust status',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VerificationScreen(),
                    ),
                  );
                },
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: verificationBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    verificationLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: verificationColor,
                    ),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle: 'Manage saved payment options',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Favorite Photographers',
                subtitle: 'Quick access to saved profiles',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Notifications'),
              _SettingsToggle(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                value: prefs['push'] ?? true,
                onChanged: (value) => onTogglePreference('push', value),
              ),
              _SettingsToggle(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                value: prefs['email'] ?? true,
                onChanged: (value) => onTogglePreference('email', value),
              ),
              _SettingsToggle(
                icon: Icons.sms_outlined,
                title: 'SMS Notifications',
                value: prefs['sms'] ?? false,
                onChanged: (value) => onTogglePreference('sms', value),
              ),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Account Info'),
              _InfoCard(
                title: 'Profile Status',
                value: user.isProfileComplete ? 'Complete' : 'Incomplete',
                subtitle: user.bio?.isNotEmpty == true
                    ? user.bio!
                    : 'Add more profile details to complete your account.',
              ),
              _InfoCard(
                title: 'Member Since',
                value: memberSince,
                subtitle: user.isPhotographer
                    ? 'Your public profile is synced with photographer discovery.'
                    : 'Your booking history and notifications are synced to Firebase.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: isSigningOut ? null : onSignOut,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC62828)),
                      foregroundColor: const Color(0xFFC62828),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _vDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF9E9E9E),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF7A7A7A)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFBDBDBD),
                ),
              )
            : null,
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
              size: 20,
            ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF7A7A7A)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFC62828),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
