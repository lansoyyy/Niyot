import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_avatar_colors.dart';
import '../../models/photographer_model.dart';
import '../../models/portfolio_item_model.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/common/service_offer_icons.dart';
import '../../widgets/auth/auth_gate_helper.dart';
import '../../screens/photographer/photographer_profile_screen.dart';

/// Explore list card: portfolio carousel header + creator details (reference UI).
class ExploreCreatorCard extends StatefulWidget {
  const ExploreCreatorCard({super.key, required this.photographer});

  final PhotographerModel photographer;

  @override
  State<ExploreCreatorCard> createState() => _ExploreCreatorCardState();
}

class _ExploreCreatorCardState extends State<ExploreCreatorCard> {
  List<PortfolioItemModel> _portfolio = [];
  bool _loadingPortfolio = true;
  int _carouselIndex = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    try {
      final items =
          await PhotographerService().getPortfolio(widget.photographer.uid);
      if (mounted) {
        setState(() {
          _portfolio = items.where((i) => i.imageUrl.isNotEmpty).toList();
          _loadingPortfolio = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPortfolio = false);
    }
  }

  List<String> get _imageUrls =>
      _portfolio.map((item) => item.imageUrl).toList();

  bool get _hasPortfolio => _imageUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final p = widget.photographer;
    final tags = p.specialties.isNotEmpty
        ? p.specialties.take(3).toList()
        : <String>[
            if (p.primarySpecialty.isNotEmpty) p.primarySpecialty,
          ];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotographerProfileScreen(photographer: p),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaArea(p),
                  if (_hasPortfolio && _imageUrls.length > 1) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _CarouselArrow(
                          icon: Icons.chevron_left_rounded,
                          onTap: _carouselIndex > 0 ? _prevImage : null,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _CarouselArrow(
                          icon: Icons.chevron_right_rounded,
                          onTap: _carouselIndex < _imageUrls.length - 1
                              ? _nextImage
                              : null,
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _FavoriteButton(photographer: p),
                  ),
                  if (p.serviceTypes.isNotEmpty)
                    Positioned(
                      bottom: _hasPortfolio ? 40 : 12,
                      right: 12,
                      child: ServiceOfferIcons(
                        serviceTypes: p.serviceTypes,
                        size: 28,
                        iconSize: 14,
                      ),
                    ),
                  if (_hasPortfolio)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_carouselIndex + 1} / ${_imageUrls.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppProfileAvatar(
                        displayName: p.name,
                        photoUrl: p.photoUrl,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    p.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: Color(0xFFC62828),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    p.locationText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${p.rating.toStringAsFixed(1)} (${p.reviewCount})',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.startingPrice.isEmpty
                              ? 'View packages'
                              : '${p.startingPrice} starting',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: p.isAvailable
                                  ? const Color(0xFF43A047)
                                  : const Color(0xFFBDBDBD),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.isAvailable
                                ? 'Available this week'
                                : 'Fully booked',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
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

  Widget _buildMediaArea(PhotographerModel p) {
    if (_loadingPortfolio) {
      return Container(
        color: AppAvatarColors.profileHeaderBackground,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white54,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!_hasPortfolio) {
      return Container(
        color: p.gradientColors.first,
        alignment: Alignment.center,
        child: Text(
          'no portfolio yet',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _imageUrls.length,
      onPageChanged: (i) => setState(() => _carouselIndex = i),
      itemBuilder: (context, index) {
        return Image.network(
          _imageUrls[index],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppAvatarColors.profileHeaderBackground,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
        );
      },
    );
  }

  void _prevImage() {
    if (_carouselIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _nextImage() {
    if (_carouselIndex >= _imageUrls.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.photographer});

  final PhotographerModel photographer;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == photographer.uid) {
      return const SizedBox.shrink();
    }

    if (uid == null) {
      return Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            final ok = await AuthGateHelper.requireAuth(
              context,
              message: 'Sign in to save favorites',
            );
            if (!ok || !context.mounted) return;
            try {
              await UserService().toggleFavoritePhotographer(
                uid: FirebaseAuth.instance.currentUser!.uid,
                photographer: photographer,
              );
            } catch (_) {}
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color: Color(0xFF374151),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: UserService().favoriteStatusStream(uid, photographer.uid),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return Material(
          color: Colors.white.withValues(alpha: 0.92),
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
              padding: const EdgeInsets.all(8),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: isFavorite ? Colors.pinkAccent : const Color(0xFF374151),
              ),
            ),
          ),
        );
      },
    );
  }
}
