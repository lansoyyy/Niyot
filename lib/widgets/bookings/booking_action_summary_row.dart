import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

/// Horizontal notification-style counters (photographer or client).
class BookingActionSummaryRow extends StatelessWidget {
  const BookingActionSummaryRow({super.key, required this.items});

  final List<BookingActionSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _SummaryCard(item: items[index]),
      ),
    );
  }
}

class BookingActionSummaryItem {
  const BookingActionSummaryItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.count,
    required this.label,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final int count;
  final String label;
  final bool highlighted;
  final VoidCallback? onTap;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final BookingActionSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final countColor =
        item.highlighted ? AppColors.primary : AppColors.textPrimary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.gray800.withValues(alpha: 0.06),
        child: Container(
          width: 118,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.highlighted
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.gray200,
              width: item.highlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: item.iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${item.count}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: countColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
