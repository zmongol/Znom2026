import 'package:flutter/material.dart';

/// Unified color palette for Zmongol All-in-One.
///
/// Design principles:
///  • Single cool-blue anchor keeps all screens feeling related.
///  • Module accents are value-matched and desaturated so no tab
///    shouts louder than another.
///  • Warm/hot hues (red, amber, orange) are retired; every accent
///    sits comfortably in the same family.
///  • Backgrounds use near-whites with a faint cool tint for light
///    mode and deep blue-grays for dark mode — never pure black/white.
class AppColors {
  AppColors._();

  // ── Brand primaries ──────────────────────────────────────────────
  /// Primary brand blue — the Zmongol family blue #0073AB (Zmongol2 logo blue).
  static const Color primary = Color(0xFF0073AB);

  /// Darker gradient end / pressed state.
  static const Color primaryDark = Color(0xFF015A87);

  /// Soft gold accent for Pro/premium highlights only.
  static const Color gold = Color(0xFFB8973A);

  // ── Backgrounds ──────────────────────────────────────────────────
  /// Light scaffold — very slightly cool to match the blue anchor.
  static const Color bgLight = Color(0xFFF5F7FB);

  /// Dark scaffold — deep blue-gray, not pure black.
  static const Color bgDark = Color(0xFF0F1B2D);

  /// Card / input fill in light mode.
  static const Color surface = Color(0xFFEDF1FA);

  /// Card background in dark mode.
  static const Color cardDark = Color(0xFF1C2D42);

  // ── Semantics ────────────────────────────────────────────────────
  static const Color error = Color(0xFFD93025);
  static const Color success = Color(0xFF1A7A4A);
  static const Color warning = Color(0xFFB07D1A);

  // ── Module accents (all muted, value-matched) ────────────────────
  /// Editor  — steel-blue, clearly distinct from teal.
  static const Color editorAccent = Color(0xFF2258A8);

  /// Library — muted slate-violet, readable, not neon.
  static const Color libraryAccent = Color(0xFF5B4FCF);

  /// Calendar — cool steel-teal, calm, no harsh warmth.
  static const Color calendarAccent = Color(0xFF2A7C8E);

  /// Learn — dusty sage-teal, soft and encouraging.
  static const Color learnAccent = Color(0xFF1F7A5C);

  /// Translate — soft teal-slate, tonal sibling to calendarAccent.
  static const Color translateAccent = Color(0xFF2A6D8A);

  /// Games — deep purple, energetic and distinct from all other module accents.
  static const Color gamesAccent = Color(0xFF8B35A8);

  // ── Utility ──────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}
