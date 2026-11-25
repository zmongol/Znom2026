import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/font_scale.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/global_controllers/books_ctrl.dart';
import 'package:book_app/models/basic/mongol_font_family_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Component/find_ctrls.dart';
import 'bounded_mongol_text.dart';

/// One-tap reader settings, opened from inside the reading screen:
/// page background (white / sepia / dark), text size, and the bundled
/// Z52 font picker — all in a single sheet, applied live.
///
/// Every Mongolian label in this sheet stands upright in vertical
/// columns (BoundedMongolText). The size and font pickers are rows of
/// tall column tiles — never list rows of sideways text.
void showReaderSettingsSheet() {
  Get.bottomSheet(
    const ReaderSettingsSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  String _family(BookCtrl bookCtrl) => bookCtrl.fontFamily.value.isEmpty
      ? MongolFonts.z52dardastig
      : bookCtrl.fontFamily.value;

  @override
  Widget build(BuildContext context) {
    final bookCtrl = FindCtrl.book;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — Mongolian-first, height-bounded so the
                  // long "settings" word can never run down the sheet.
                  Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Obx(
                          () => BoundedMongolText(
                            UiStrings.settings,
                            maxHeight: 48,
                            maxColumns: 4,
                            style: TextStyle(
                              fontFamily: _family(bookCtrl),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Reading settings',
                        style: TextStyle(fontSize: 13, color: Colors.black45),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Background ────────────────────────────────────
                  _sectionLabel(bookCtrl, UiStrings.background, 'Background'),
                  const SizedBox(height: 8),
                  Obx(
                    () => Row(
                      children: [
                        _bgChip(bookCtrl, 'white', UiStrings.bgWhite, 'White',
                            Colors.white),
                        const SizedBox(width: 10),
                        _bgChip(bookCtrl, 'sepia', UiStrings.bgSepia, 'Sepia',
                            AppColors.readerSepia),
                        const SizedBox(width: 10),
                        _bgChip(bookCtrl, 'dark', UiStrings.bgDark, 'Dark',
                            AppColors.readerDarkBg),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Text size — column tiles at relative sizes ──────
                  _sectionLabel(bookCtrl, UiStrings.fontSize, 'Text size'),
                  const SizedBox(height: 8),
                  Obx(
                    () => SizedBox(
                      height: 126,
                      child: Row(
                        children: [
                          _sizeTile(bookCtrl, FontScale.large, 'ᢘᡭᢎᡳ'),
                          const SizedBox(width: 10),
                          _sizeTile(bookCtrl, FontScale.medium, 'ᢘᡭᢎᢙᡧ'),
                          const SizedBox(width: 10),
                          _sizeTile(bookCtrl, FontScale.regular, 'ᡳᡪᢉᡨ'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Font — horizontally scrolling column tiles ────
                  _sectionLabel(bookCtrl, UiStrings.fontFamily, 'Font'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: Obx(
                      () {
                        // Read the observable HERE, inside the Obx
                        // scope: reading it lazily in itemBuilder is
                        // outside GetX's tracking scope and throws the
                        // "improper use of GetX" error widget.
                        final selectedFamily = bookCtrl.fontFamily.value;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: MongolFamily.fetchList().length,
                          itemBuilder: (context, i) {
                            final e = MongolFamily.fetchList()[i];
                            return _fontTile(
                              bookCtrl,
                              e,
                              selected: e.familyName == selectedFamily,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BookCtrl bookCtrl, String z52, String english) {
    return Row(
      children: [
        SizedBox(
          width: 170,
          child: Obx(
            () => BoundedMongolText(
              z52,
              maxHeight: 42,
              maxColumns: 5,
              style: TextStyle(
                fontFamily: _family(bookCtrl),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          english,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _bgChip(BookCtrl bookCtrl, String value, String z52, String english,
      Color swatch) {
    final selected = bookCtrl.readerBackground.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => bookCtrl.setReaderBackground(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: swatch,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.black26,
              width: selected ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              BoundedMongolText(
                z52,
                maxHeight: 36,
                style: TextStyle(
                  fontFamily: _family(bookCtrl),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == 'dark'
                      ? AppColors.readerDarkText
                      : Colors.black87,
                ),
              ),
              Text(
                english,
                style: TextStyle(
                  fontSize: 11,
                  color: value == 'dark' ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One text-size option: a tall tile whose sample word stands in an
  /// upright column at the option's actual relative size.
  Widget _sizeTile(BookCtrl bookCtrl, double scale, String z52Label) {
    final selected = bookCtrl.fontScale.value == scale;
    return Expanded(
      child: GestureDetector(
        onTap: () => bookCtrl.setFontScaleValue(scale),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : Colors.black26,
              width: selected ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: BoundedMongolText(
                    z52Label,
                    maxHeight: 106,
                    maxColumns: 3,
                    centerVertically: true,
                    style: TextStyle(
                      fontFamily: _family(bookCtrl),
                      // The reader's base size scaled by the option's
                      // own factor — tiles show true relative sizes.
                      fontSize: 11 * scale,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.check, size: 18, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// One font option: a tall narrow tile whose name stands in upright
  /// columns rendered in that very font. [selected] is computed by the
  /// caller inside the Obx scope (see the font picker above).
  Widget _fontTile(BookCtrl bookCtrl, MongolFamily e,
      {required bool selected}) {
    return GestureDetector(
      onTap: () => bookCtrl.setFontFamilyByName(e.familyName),
      child: Container(
        width: 64,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: BoundedMongolText(
                  e.mongolName,
                  maxHeight: 118,
                  maxColumns: 3,
                  centerVertically: true,
                  style: TextStyle(
                    fontFamily: e.familyName,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check, size: 16, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
