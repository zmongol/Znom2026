import 'package:book_app/Component/font_scale.dart';
import 'package:book_app/core/services/font_service.dart';
import 'package:book_app/widgets/bounded_mongol_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velocity_x/velocity_x.dart';

void showFontSizeDialogue({
  required Function(double) onTap,
  required double selectedScale,
}) {
  Get.bottomSheet(_FontSize(
    onTap: onTap,
    selectedScale: selectedScale,
  ));
}

class _FontSize extends StatelessWidget {
  final Function(double) onTap;
  final double selectedScale;
  const _FontSize({required this.onTap, required this.selectedScale});

  @override
  Widget build(BuildContext context) {
    final family = Get.find<FontService>().fontFamily.value;
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          20.heightBox,
          // Heading and samples stand upright in vertical columns —
          // never sideways rows.
          Center(
            child: SizedBox(
              width: 260,
              child: BoundedMongolText(
                "ᡥᡭᡬᢔᡭᡬᡨ ᡭᡧ ᢊᡪᢎᢛᡬᡫᡨ ᢔᡭᡪᢊᡱᡱᡭᡪᡪᡳ",
                maxHeight: 62,
                maxColumns: 6,
                style: TextStyle(
                  fontFamily: family,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          20.heightBox,
          _tile(context, family, FontScale.large, "ᢘᡭᢎᡳ"),
          _tile(context, family, FontScale.medium, "ᢘᡭᢎᢙᡧ"),
          _tile(context, family, FontScale.regular, "ᡳᡪᢉᡨ"),
          20.heightBox,
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, String family, double scale, String label) {
    return ListTile(
      onTap: () => onTap(scale),
      trailing: selectedScale == scale
          ? Icon(
              Icons.check,
              color: context.primaryColor,
            )
          : null,
      title: BoundedMongolText(
        label,
        maxHeight: 54,
        maxColumns: 3,
        style: TextStyle(fontFamily: family, fontSize: 16),
      ),
    );
  }
}
