import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_avatar_colors.dart';
import '../../core/profile_initials.dart';

/// Network profile photo with unified placeholder: light disc + two-letter initials.
class AppProfileAvatar extends StatelessWidget {
  const AppProfileAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    required this.size,
  });

  final String displayName;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(
            displayName: displayName,
            size: size,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _Placeholder(displayName: displayName, size: size);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.displayName,
    required this.size,
  });

  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = ProfileInitials.fromName(displayName);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppAvatarColors.placeholderFill,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: AppAvatarColors.placeholderText,
        ),
        maxLines: 1,
      ),
    );
  }
}
