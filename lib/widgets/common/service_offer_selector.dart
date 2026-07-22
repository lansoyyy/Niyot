import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../constants/service_offers.dart';

/// Multi-select cards for Photography / Videography offers.
class ServiceOfferSelector extends StatelessWidget {
  const ServiceOfferSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OfferCard(
          icon: Icons.camera_alt_rounded,
          title: ServiceOffers.photography,
          subtitle: 'Photo shoots & sessions',
          isSelected: selected.contains(ServiceOffers.photography),
          onTap: () => _toggle(ServiceOffers.photography),
        ),
        const SizedBox(height: 14),
        _OfferCard(
          icon: Icons.videocam_rounded,
          title: ServiceOffers.videography,
          subtitle: 'Video coverage & films',
          isSelected: selected.contains(ServiceOffers.videography),
          onTap: () => _toggle(ServiceOffers.videography),
        ),
      ],
    );
  }

  void _toggle(String offer) {
    final next = Set<String>.from(selected);
    if (next.contains(offer)) {
      next.remove(offer);
    } else {
      next.add(offer);
    }
    onChanged(next);
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.gray200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.gray400,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
