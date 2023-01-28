import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'app_settings_controller.dart';
import 'widgets/header_widget.dart';
import 'widgets/settings_row_widget.dart';

class SettingsPrivacyPage extends StatelessWidget {

  const SettingsPrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      id: AppPageIdConstants.settingsPrivacy,
      init: AppSettingsController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppConstants.settingsPrivacy.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
          children: <Widget>[
            HeaderWidget(_.userController.user!.name),
            SettingRowWidget(AppTranslationConstants.account.tr, navigateTo: AppRouteConstants.settingsAccount),
            SettingRowWidget(AppTranslationConstants.privacyAndPolicy.tr, navigateTo: AppRouteConstants.privacyAndTerms),
            SettingRowWidget(AppTranslationConstants.contentPreferences.tr, navigateTo: AppRouteConstants.contentPreferences),
            const HeaderWidget(AppTranslationConstants.general, secondHeader: true,),
            SettingRowWidget(AppTranslationConstants.aboutApp.tr, navigateTo: AppRouteConstants.about),
            //TODO
            _.userController.user!.userRole == UserRole.subscriber
                ? Container() :
                Column(children: [
                  const HeaderWidget("Admin Center", secondHeader: true,),
                  SettingRowWidget(AppTranslationConstants.createCoupon.tr, navigateTo: AppRouteConstants.createCoupon),
                  const SettingRowWidget("Crear Patrocinador", navigateTo: AppRouteConstants.createSponsor),
                ],),

            SettingRowWidget("", showDivider: false, vPadding: 10, subtitle: AppTranslationConstants.settingPrivacyMsg.tr),
          ],
        ),
        ),
    ),);
  }
}
