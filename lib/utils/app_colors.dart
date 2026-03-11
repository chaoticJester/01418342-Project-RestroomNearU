import 'package:flutter/material.dart';

/// Unified design tokens for the entire app.
/// Replaces all the private `_C` classes scattered across pages.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color bg        = Color(0xFFF5F1E8);
  static const Color bgAlt     = Color(0xFFFCF9EA); // slightly cooler bg used in some pages
  static const Color card      = Color(0xFFFFFDFA);
  static const Color cardAlt   = Color(0xFFF7F4E6);
  static const Color fieldFill = Color(0xFFFFFBF5);
  static const Color searchFill= Color(0xFFEEEBDA);
  static const Color sheet     = Color(0xFFFAF7E8);

  // ── Brand / Accent ───────────────────────────────────────────
  static const Color mint      = Color(0xFFA8D5D5); // teal on detail page
  static const Color mintLight = Color(0xFFBADFDB); // teal on homepage
  static const Color mintDark  = Color(0xFF88B5B5); // tealDark on detail
  static const Color teal      = Color(0xFF9BCFCA); // general teal accent
  static const Color tealDark  = Color(0xFF7BBFBA); // tealDark on homepage
  static const Color pink      = Color(0xFFEC9B9B);
  static const Color pinkLight = Color(0xFFF5D4D4);
  static const Color orange    = Color(0xFFF5A162); // detail page orange
  static const Color orangeAlt = Color(0xFFE8753D); // homepage / write-review orange

  // ── Status ───────────────────────────────────────────────────
  static const Color green     = Color(0xFF7CB87C);
  static const Color greenAlt  = Color(0xFF34A853); // brighter green (homepage)
  static const Color red       = Color(0xFFD77A7A);
  static const Color redAlt    = Color(0xFFB3261E); // darker red (profile / write-review)

  // ── Text ─────────────────────────────────────────────────────
  static const Color textDark  = Color(0xFF2C2C2C);
  static const Color textDarkAlt = Color(0xFF1C1B1F); // homepage variant
  static const Color textMid   = Color(0xFF6B6B6B);
  static const Color textMidAlt= Color(0xFF6B6874);
  static const Color textLight = Color(0xFFA5A5A5);
  static const Color textLightAlt = Color(0xFFAEABB8);

  // ── Dividers / Borders ───────────────────────────────────────
  static const Color divider   = Color(0xFFE8E4DB);
  static const Color dividerAlt= Color(0xFFECE9DA);
  static const Color pill      = Color(0xFFD8D4C4);
}
