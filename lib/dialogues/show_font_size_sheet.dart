import 'package:book_app/Component/font_scale.dart';
import 'package:book_app/core/services/font_service.dart';
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
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          20.heightBox,
          Text(
            "ᡥᡭᡬᢔᡭᡬᡨ ᡭᡧ ᢊᡪᢎᢛᡬᡫᡨ ᢔᡭᡪᢊᡱᡱᡭᡪᡪᡳ",
            style: TextStyle(
              fontFamily: Get.find<FontService>().fontFamily.value,
              fontSize: 18,
            ),
          ).centered(),
          20.heightBox,
          ListTile(
            onTap: () {
              onTap(FontScale.large);
            },
            trailing: selectedScale == FontScale.large
                ? Icon(
                    Icons.check,
                    color: context.primaryColor,
                  )
                : null,
            title: Text(
              "ᢘᡭᢎᡳ",
              style: TextStyle(
                  fontFamily: Get.find<FontService>().fontFamily.value,
                  fontSize: 16),
            ),
          ),
          ListTile(
            onTap: () {
              onTap(FontScale.medium);
            },
            trailing: selectedScale == FontScale.medium
                ? Icon(
                    Icons.check,
                    color: context.primaryColor,
                  )
                : null,
            title: Text(
              "ᢘᡭᢎᢙᡧ",
              style: TextStyle(
                  fontFamily: Get.find<FontService>().fontFamily.value,
                  fontSize: 16),
            ),
          ),
          ListTile(
            onTap: () {
              onTap(FontScale.regular);
            },
            trailing: selectedScale == FontScale.regular
                ? Icon(
                    Icons.check,
                    color: context.primaryColor,
                  )
                : null,
            title: Text(
              "ᡳᡪᢉᡨ",
              style: TextStyle(
                  fontFamily: Get.find<FontService>().fontFamily.value,
                  fontSize: 16),
            ),
          ),
          20.heightBox,
        ],
      ),
    );
  }
}
