import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/service_offers.dart';

/// Red circular camera / video icons shown on creator cards.
class ServiceOfferIcons extends StatelessWidget {
  const ServiceOfferIcons({
    super.key,
    required this.serviceTypes,
    this.size = 28,
    this.iconSize = 14,
    this.spacing = 6,
  });

  final List<String> serviceTypes;
  final double size;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final icons = <Widget>[];
    if (serviceTypes.contains(ServiceOffers.photography)) {
      icons.add(_icon(Icons.camera_alt_rounded));
    }
    if (serviceTypes.contains(ServiceOffers.videography)) {
      icons.add(_icon(Icons.videocam_rounded));
    }
    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < icons.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          icons[i],
        ],
      ],
    );
  }

  Widget _icon(IconData icon) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: AppColors.white),
    );
  }
}
