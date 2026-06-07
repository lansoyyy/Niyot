import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/photographer_model.dart';
import '../../screens/photographer/photographer_profile_screen.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
/// Compact horizontal card for client home "Near You" row.
class NearYouCard extends StatelessWidget {
  const NearYouCard({super.key, required this.photographer});

  final PhotographerModel photographer;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final tags = photographer.specialties.take(2).toList();
    final city = photographer.locationText.contains(',')
        ? photographer.locationText.split(',').first.trim()
        : photographer.locationText;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotographerProfileScreen(photographer: photographer),
        ),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: photographer.gradientColors.first,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  if (photographer.isAvailable)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF43A047),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Available',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (uid != null && uid != photographer.uid)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _FavoriteHeart(photographer: photographer),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AppProfileAvatar(
                        displayName: photographer.name,
                        photoUrl: photographer.photoUrl,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                photographer.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (photographer.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xFFC62828),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: Color(0xFFBDBDBD),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          city,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF9E9E9E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (photographer.startingPrice.isNotEmpty)
                    Text(
                      '${photographer.startingPrice} starting',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC62828),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'View packages',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        photographer.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.photographer});

  final PhotographerModel photographer;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<bool>(
      stream: UserService().favoriteStatusStream(uid, photographer.uid),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              try {
                await UserService().toggleFavoritePhotographer(
                  uid: uid,
                  photographer: photographer,
                );
              } catch (_) {}
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: isFavorite ? Colors.pinkAccent : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      },
    );
  }
}
