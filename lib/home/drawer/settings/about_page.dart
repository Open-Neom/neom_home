import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/settings_row_widget.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/url_constants.dart';
import 'app_settings_controller.dart';

class AboutPage extends StatelessWidget {

  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: AppTranslationConstants.aboutApp.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              HeaderWidget(
                AppTranslationConstants.help.tr,
                secondHeader: true,
              ),
              SettingRowWidget(
                AppTranslationConstants.helpCenter.tr,
                vPadding: 0,
                showDivider: false,
                url: AppFlavour.getWebContact(),
              ),
              HeaderWidget(AppTranslationConstants.websites.tr),
              SettingRowWidget(
                  AppConstants.appTitle.tr,
                  showDivider: true,
                  url: AppFlavour.getLandingPageUrl(),
              ),
              SettingRowWidget(
                  AppConstants.blog,
                  showDivider: true,
                  url: AppFlavour.getBlogUrl(),
              ),
              HeaderWidget(AppTranslationConstants.developer.tr),
              const SettingRowWidget(
                AppConstants.github,
                showDivider: true,
                url: UrlConstants.devGithub
              ),
              const SettingRowWidget(
                AppConstants.linkedin,
                showDivider: true,
                url: UrlConstants.devLinkedIn
              ),
            ],
          ),
        ),
      ),
    );
  }
}
