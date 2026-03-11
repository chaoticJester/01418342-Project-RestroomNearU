import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RatingBreakdown
// The big avg-rating number + per-star bar chart used in restroom_detail_page.
// ─────────────────────────────────────────────────────────────────────────────
class RatingBreakdown extends StatelessWidget {
  final double avgRating;
  final int totalReviews;
  final Map<int, int> starDistribution;

  const RatingBreakdown({
    super.key,
    required this.avgRating,
    required this.totalReviews,
    required this.starDistribution,
  });

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Column(children: [
            Icon(Icons.star_border_rounded, size: 32, color: AppColors.textLight),
            SizedBox(height: 6),
            Text('No ratings yet',
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ]),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big number + stars
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                if (i < avgRating.floor()) {
                  return const Icon(Icons.star_rounded, size: 14, color: AppColors.orange);
                } else if (i < avgRating && (avgRating - avgRating.floor()) >= 0.5) {
                  return const Icon(Icons.star_half_rounded, size: 14, color: AppColors.orange);
                } else {
                  return const Icon(Icons.star_outline_rounded,
                      size: 14, color: AppColors.textLight);
                }
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalReviews review${totalReviews == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Container(width: 1, height: 90, color: AppColors.divider),
        const SizedBox(width: 16),
        // Per-star bars
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count    = starDistribution[star] ?? 0;
              final fraction = totalReviews > 0 ? count / totalReviews : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Text('$star',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.textMid)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 11, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 7,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          star >= 4
                              ? AppColors.mint
                              : star == 3
                                  ? AppColors.orange
                                  : AppColors.pink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 24,
                    child: Text('$count',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textLight)),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CategoryRatingRow
// Icon + label + progress bar used in the "Category Ratings" section.
// ─────────────────────────────────────────────────────────────────────────────
class CategoryRatingRow extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;

  const CategoryRatingRow({
    super.key,
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ),
        Text(score.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const Text('/5.0',
            style: TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: score / 5.0,
          minHeight: 6,
          backgroundColor: AppColors.divider.withOpacity(0.5),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }
}
