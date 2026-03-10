import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/review_model.dart';
import '../services/review_firestore.dart';
import '../utils/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReviewCard — displays a single review row in the detail page review list.
// Extracted from the private `_ReviewCard` inside restroom_detail_page.dart.
// ─────────────────────────────────────────────────────────────────────────────

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isOwnerOrAdmin;
  final bool isHelpful;
  final VoidCallback onHelpfulTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onReadMore;

  const ReviewCard({
    Key? key,
    required this.review,
    required this.isOwnerOrAdmin,
    required this.isHelpful,
    required this.onHelpfulTap,
    required this.onDeleteTap,
    required this.onReadMore,
  }) : super(key: key);

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.pinkLight,
                    AppColors.pink.withOpacity(0.3)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 20, color: AppColors.pink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    _timeAgo(review.timestamp),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            // ── Star badge ──────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orangeAlt.withOpacity(0.18),
                    AppColors.orangeAlt.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded,
                    color: AppColors.orangeAlt, size: 12),
                const SizedBox(width: 2),
                Text(
                  review.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orangeAlt,
                  ),
                ),
              ]),
            ),
            // ── Delete button (owner / admin only) ──────────────
            if (isOwnerOrAdmin) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeleteTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red),
                ),
              ),
            ],
          ]),

          const SizedBox(height: 8),

          // ── Rating badge label ─────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.pinkLight,
                  AppColors.pink.withOpacity(0.2)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ReviewService().getRatingBadge(review.rating),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.pink,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Comment ───────────────────────────────────────────
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMid,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ── Footer row ────────────────────────────────────────
          Row(children: [
            GestureDetector(
              onTap: onHelpfulTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isHelpful
                      ? LinearGradient(
                          colors: [
                            AppColors.pinkLight,
                            AppColors.pink.withOpacity(0.2)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isHelpful
                      ? null
                      : AppColors.divider.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isHelpful
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_outlined,
                    size: 12,
                    color:
                        isHelpful ? AppColors.pink : AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Helpful (${review.helpfulCount + (isHelpful ? 1 : 0)})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isHelpful
                          ? AppColors.pink
                          : AppColors.textLight,
                    ),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onReadMore,
              child: const Text(
                'Read more',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mint,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.mint,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
