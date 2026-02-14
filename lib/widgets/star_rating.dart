import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Reusable star rating widget
class StarRating extends StatelessWidget {
  final double rating;
  final Function(double)? onRatingChanged;
  final double size;
  final bool readOnly;
  final Color activeColor;
  final Color inactiveColor;

  const StarRating({
    Key? key,
    required this.rating,
    this.onRatingChanged,
    this.size = 32,
    this.readOnly = false,
    this.activeColor = Colors.orange,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: readOnly || onRatingChanged == null
              ? null
              : () {
                  onRatingChanged!((index + 1).toDouble());
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              size: size,
              color: index < rating ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

/// Compact star rating with number (for list items)
class CompactStarRating extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double iconSize;
  final double fontSize;

  const CompactStarRating({
    Key? key,
    required this.rating,
    this.reviewCount,
    this.iconSize = 16,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.orange, size: iconSize),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: fontSize - 2,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
