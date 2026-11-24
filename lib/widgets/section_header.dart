import 'package:book_app/Component/MongolFonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/find_ctrls.dart';

/// Mongolian-first section header: the Z52 label as the main text
/// (vertical Mongolian, wrapping into columns) with the small English
/// caption beneath it — the pattern approved for the app's chrome.
class SectionHeader extends StatelessWidget {
  final String z52;
  final String english;
  const SectionHeader({super.key, required this.z52, required this.english});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookCtrl = FindCtrl.book;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 86,
          child: Obx(
            () => MongolText(
              z52,
              style: TextStyle(
                fontFamily: bookCtrl.fontFamily.value.isEmpty
                    ? MongolFonts.z52dardastig
                    : bookCtrl.fontFamily.value,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white.withOpacity(0.95)
                    : const Color(0xFF2D3436),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          english,
          style: TextStyle(
            fontSize: 12.5,
            letterSpacing: 0.4,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}
