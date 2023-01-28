import 'package:flutter/material.dart';

import 'package:neom_commons/core/ui/widgets/custom_url_text.dart';
import 'package:neom_commons/core/utils/app_color.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  final bool secondHeader;
  const HeaderWidget(this.title,{Key? key, this.secondHeader = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      color: AppColor.mystic.withOpacity(0.05),
      alignment: Alignment.centerLeft,
      child: UrlText(
        text: title,
        style: const TextStyle(
            fontSize: 20,
            color: AppColor.lightGrey,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
