import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/custom_url_text.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

class SettingRowWidget extends StatelessWidget {

  final bool visibleSwitch, showDivider;
  final String navigateTo;
  final String subtitle, title;
  final Color textColor;
  final  Function? onPressed;
  final double vPadding;

  const SettingRowWidget(
    this.title, {
    Key? key,
    this.navigateTo = "",
    this.subtitle = "",
    this.textColor = Colors.white70,
    this.onPressed,
    this.vPadding = 0,
    this.showDivider = true,
    this.visibleSwitch = true,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding:
              EdgeInsets.symmetric(vertical: vPadding, horizontal: 18),
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            }
            if (navigateTo.isEmpty) {
              return;
            }

            navigateTo != AppRouteConstants.underConstruction ?
              Get.toNamed(navigateTo)
                : AppUtilities.showAlert(context, title, AppTranslationConstants.underConstruction.tr);
          },
          title: UrlText(
                  text: title,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
          subtitle: UrlText(
                  text: subtitle,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w400),
                ),
        ),
        !showDivider ? const SizedBox() : const Divider(height: 0)
      ],
    );
  }
}
