import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App-wide utility functions for UI.
class AppUI {
  AppUI._();

  // ── SnackBar ─────────────────────────────────────────────────

  /// Show a floating snack-bar.
  /// [isError] switches the colour to red; default is teal (success).
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.redAlt : AppColors.tealDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Hide the current snack-bar then show a new one.
  static void replaceSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showSnackBar(context, message, isError: isError, icon: icon);
  }

  // ── Navigation ───────────────────────────────────────────────

  /// Slide + fade page route (right-to-left, used throughout the app).
  static Route<T> smoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
