import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

/// Interactive star rating row.
/// Replaces both the private `_StarRating` in write_review_page.dart
/// AND the existing `star_rating.dart` widget (which was not being used).
class AppStarRating extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<double>? onChanged; // null → read-only
  final Color activeColor;
  final Color inactiveColor;
  final MainAxisAlignment alignment;

  const AppStarRating({
    Key? key,
    required this.rating,
    this.size = 28,
    this.onChanged,
    this.activeColor = AppColors.orangeAlt,
    this.inactiveColor = AppColors.textLight,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        final halfFilled = !filled && i < rating && (rating - rating.floor()) >= 0.5;
        IconData iconData;
        if (filled) {
          iconData = Icons.star_rounded;
        } else if (halfFilled) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_outline_rounded;
        }

        final star = Icon(
          iconData,
          size: size,
          color: filled || halfFilled ? activeColor : inactiveColor,
        );

        if (onChanged == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: star,
          );
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged!((i + 1).toDouble());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: star,
          ),
        );
      }),
    );
  }
}
