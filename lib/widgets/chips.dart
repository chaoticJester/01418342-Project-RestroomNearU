import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Small icon + label chip used across the restroom cards and popups.
/// Replaces the private `_MiniChip` in user_homepage and restroom_detail_page.
class MiniChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? backgroundColor;

  const MiniChip({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.searchFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Open / Closed badge.
/// Replaces the private `_StatusBadge` in user_homepage.
class StatusBadge extends StatelessWidget {
  final bool isOpen;

  const StatusBadge({Key? key, required this.isOpen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.greenAlt : AppColors.redAlt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
