import 'package:book_app/models/basic/mongol_font_family_model.dart';
import 'package:book_app/core/services/font_service.dart';
import 'package:book_app/widgets/bounded_mongol_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velocity_x/velocity_x.dart';

void showFontFamilyDialogue({
  required Function(MongolFamily) onTap,
  required String selectedFamily,
}) {
  Get.bottomSheet(_FontFamily(
    onTap: onTap,
    selectedFamily: selectedFamily,
  ));
}

class _FontFamily extends StatelessWidget {
  final Function(MongolFamily) onTap;
  final String selectedFamily;
  const _FontFamily({required this.onTap, required this.selectedFamily});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(10, 20, 10, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            20.heightBox,
            // Heading and font names stand upright in vertical
            // columns — never sideways rows.
            Center(
              child: SizedBox(
                width: 200,
                child: BoundedMongolText(
                  "ᢘᡬᡬᡨ ᢔᡭᢑᡬᡪᡪᡳ",
                  maxHeight: 62,
                  maxColumns: 5,
                  style: TextStyle(
                    fontFamily: Get.find<FontService>().fontFamily.value,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            20.heightBox,
            ...MongolFamily.fetchList().map(
              (e) => ListTile(
                onTap: () {
                  onTap(e);
                },
                trailing: selectedFamily == e.familyName
                    ? Icon(
                        Icons.check,
                        color: context.primaryColor,
                      )
                    : null,
                title: BoundedMongolText(
                  e.mongolName,
                  maxHeight: 56,
                  maxColumns: 4,
                  style: TextStyle(
                    fontFamily: e.familyName,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
