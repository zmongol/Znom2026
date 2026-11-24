import 'package:flutter/material.dart';

/// Znom brand palette — sampled from the app logo (the orange book-stack
/// with the green dot / green pages on a pale-pink ground), 24 Nov 2026.
///
/// Sampled logo colours:
///   • Logo orange  #EB6119 — the book-stack outline (dominant brand colour)
///   • Logo green   #5AB631 — the dot and the green book
///   • Logo pink    #FBEBEE — the icon's background ground
///
/// White text on the raw logo orange only reaches 3.36:1 contrast, so the
/// primary used behind white text is the same orange darkened one step:
/// #BC4E14 reaches 4.96:1 (WCAG AA for normal text). The vivid logo orange
/// stays as [brandOrange] for graphics and large fills. The logo green is
/// the secondary/accent; [secondaryDark] (#3F7F22, 4.92:1 with white) is
/// its text-safe shade.
class AppColors {
  AppColors._();

  // ── Brand primaries ──────────────────────────────────────────────
  /// Primary — darkened logo orange; white text on it passes AA (4.96:1).
  static const Color primary = Color(0xFFBC4E14);

  /// Darker shade — gradient end / pressed states (white text ≈ 7.3:1).
  static const Color primaryDark = Color(0xFF8F3A0E);

  /// The vivid logo orange #EB6119 — graphics, large fills, icons.
  static const Color brandOrange = Color(0xFFEB6119);

  /// Secondary — the logo green #5AB631 (accent; pair with dark text).
  static const Color secondary = Color(0xFF5AB631);

  /// Text-safe shade of the logo green (white text 4.92:1).
  static const Color secondaryDark = Color(0xFF3F7F22);

  /// Mid green for accents (white text 4.38:1).
  static const Color secondaryMid = Color(0xFF448825);

  /// The logo's pale-pink ground — placeholder / soft surface tint.
  static const Color logoPink = Color(0xFFFBEBEE);

  /// Soft gold accent for premium highlights only.
  static const Color gold = Color(0xFFB8973A);

  // ── Backgrounds ──────────────────────────────────────────────────
  /// Light scaffold — warm off-white from the logo pink family.
  static const Color bgLight = Color(0xFFFFFBF6);

  /// Dark scaffold — warm near-black, not pure black.
  static const Color bgDark = Color(0xFF14100C);

  /// Card / input fill in light mode.
  static const Color surface = Color(0xFFFBEFE6);

  /// Card background in dark mode.
  static const Color cardDark = Color(0xFF241B12);

  // ── Reader page backgrounds ──────────────────────────────────────
  static const Color readerSepia = Color(0xFFF6ECD9);
  static const Color readerSepiaText = Color(0xFF3E2F23);
  static const Color readerDarkBg = Color(0xFF14100C);
  static const Color readerDarkText = Color(0xFFEDE6DA);

  /// Search-match highlight — light amber (replaces pure yellow).
  static const Color highlightAmber = Color(0xFFFBE7A1);

  // ── Search result card palette ───────────────────────────────────
  /// Header accents for search result cards — all derived from the two
  /// logo colours (darkened shades), never random pastels.
  static const List<Color> cardAccents = [
    Color(0xFFBC4E14), // primary orange
    Color(0xFF3F7F22), // dark logo green
    Color(0xFF8F3A0E), // deep orange
    Color(0xFF448825), // mid logo green
    Color(0xFFD45716), // bright logo orange (large/bold text only)
  ];

  // ── Semantics ────────────────────────────────────────────────────
  static const Color error = Color(0xFFD93025);
  static const Color success = Color(0xFF3F7F22);
  static const Color warning = Color(0xFFB07D1A);

  // ── Module accents (kept for compatibility; brand-derived) ──────
  static const Color editorAccent = Color(0xFFBC4E14);
  static const Color libraryAccent = Color(0xFF3F7F22);
  static const Color calendarAccent = Color(0xFF448825);
  static const Color learnAccent = Color(0xFF5AB631);
  static const Color translateAccent = Color(0xFFD45716);
  static const Color gamesAccent = Color(0xFF8F3A0E);

  // ── Utility ──────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}
