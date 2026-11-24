import 'package:book_app/Component/font_scale.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/global_controllers/books_ctrl.dart';
import 'package:book_app/models/basic/mongol_font_family_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/find_ctrls.dart';

/// One-tap reader settings, opened from inside the reading screen:
/// page background (white / sepia / dark), text size, and the bundled
/// Z52 font picker — all in a single sheet, applied live.
void showReaderSettingsSheet() {
  Get.bottomSheet(
    const ReaderSettingsSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

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
          height: MediaQuery.of(context).size.height * 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — Mongolian-first.
                Row(
                  children: [
                    SizedBox(
                      height: 46,
                      child: Obx(
                        () => MongolText(
                          UiStrings.settings,
                          style: TextStyle(
                            fontFamily: bookCtrl.fontFamily.value.isEmpty
                                ? null
                                : bookCtrl.fontFamily.value,
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
                const SizedBox(height: 8),

                // ── Background ──────────────────────────────────────
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

                // ── Text size ───────────────────────────────────────
                _sectionLabel(bookCtrl, UiStrings.fontSize, 'Text size'),
                const SizedBox(height: 4),
                Obx(
                  () => Column(
                    children: [
                      _sizeTile(bookCtrl, FontScale.large, 'ᢘᡭᢎᡳ'),
                      _sizeTile(bookCtrl, FontScale.medium, 'ᢘᡭᢎᢙᡧ'),
                      _sizeTile(bookCtrl, FontScale.regular, 'ᡳᡪᢉᡨ'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Font ────────────────────────────────────────────
                _sectionLabel(bookCtrl, UiStrings.fontFamily, 'Font'),
                const SizedBox(height: 4),
                Expanded(
                  child: Obx(
                    () => ListView(
                      children: MongolFamily.fetchList()
                          .map(
                            (e) => ListTile(
                              dense: true,
                              onTap: () =>
                                  bookCtrl.setFontFamilyByName(e.familyName),
                              trailing:
                                  bookCtrl.fontFamily.value == e.familyName
                                      ? const Icon(Icons.check,
                                          color: AppColors.primary)
                                      : null,
                              title: Text(
                                e.mongolName,
                                style: TextStyle(
                                  fontFamily: e.familyName,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
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
          height: 38,
          child: Obx(
            () => MongolText(
              z52,
              style: TextStyle(
                fontFamily: bookCtrl.fontFamily.value.isEmpty
                    ? null
                    : bookCtrl.fontFamily.value,
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

  Widget _bgChip(BookCtrl bookCtrl, String value, String z52,
      String english, Color swatch) {
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
              SizedBox(
                height: 34,
                child: MongolText(
                  z52,
                  style: TextStyle(
                    fontFamily: bookCtrl.fontFamily.value.isEmpty
                        ? null
                        : bookCtrl.fontFamily.value,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value == 'dark'
                        ? AppColors.readerDarkText
                        : Colors.black87,
                  ),
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

  Widget _sizeTile(BookCtrl bookCtrl, double scale, String z52Label) {
    final selected = bookCtrl.fontScale.value == scale;
    return ListTile(
      dense: true,
      onTap: () => bookCtrl.setFontScaleValue(scale),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      title: Text(
        z52Label,
        style: TextStyle(
          fontFamily: bookCtrl.fontFamily.value.isEmpty
              ? null
              : bookCtrl.fontFamily.value,
          fontSize: 16,
        ),
      ),
    );
  }
}
