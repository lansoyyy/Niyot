import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/favorite_photographer_model.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../photographer/photographer_profile_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
          'Favorite Photographers',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: StreamBuilder<List<FavoritePhotographerModel>>(
        stream: UserService().favoritePhotographersStream(currentUid),
        builder: (context, snapshot) {
          final favorites =
              snapshot.data ?? const <FavoritePhotographerModel>[];

          if (snapshot.connectionState == ConnectionState.waiting &&
              favorites.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828)),
            );
          }

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 56,
                      color: Color(0xFFBDBDBD),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No favorites yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save photographers from their profile to find them quickly later.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return _FavoritePhotographerCard(favorite: favorite);
            },
          );
        },
      ),
    );
  }
}

class _FavoritePhotographerCard extends StatelessWidget {
  const _FavoritePhotographerCard({required this.favorite});

  final FavoritePhotographerModel favorite;

  Future<void> _openPhotographerProfile(BuildContext context) async {
    final photographer = await PhotographerService().getPhotographerById(
      favorite.photographerId,
    );

    if (!context.mounted) return;
    if (photographer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This photographer profile is no longer available.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotographerProfileScreen(photographer: photographer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: () => _openPhotographerProfile(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFFFEBEE),
              backgroundImage:
                  favorite.photoUrl != null && favorite.photoUrl!.isNotEmpty
                  ? NetworkImage(favorite.photoUrl!)
                  : null,
              child: favorite.photoUrl == null || favorite.photoUrl!.isEmpty
                  ? Text(
                      _initials(favorite.name),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC62828),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    favorite.primarySpecialty.isNotEmpty
                        ? favorite.primarySpecialty
                        : 'Photographer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    favorite.locationText.isNotEmpty
                        ? favorite.locationText
                        : 'Location not provided',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await UserService().removeFavoritePhotographer(
                  uid: currentUid,
                  photographerId: favorite.photographerId,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Removed from favorites.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
