import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'app_settings_controller.dart';

class SettingsPrivacyPage extends StatelessWidget {

  const SettingsPrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      id: AppPageIdConstants.settingsPrivacy,
      init: AppSettingsController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppConstants.settingsPrivacy.tr),
        body: Obx(()=>Container(
          decoration: AppTheme.appBoxDecoration,
          child: _.isLoading ? Container(
              decoration: AppTheme.appBoxDecoration,
              child: const Center(
                  child: CircularProgressIndicator()
              )
          ) : ListView(
          children: <Widget>[
            HeaderWidget(_.userController.user!.name),
            TitleSubtitleRow(AppTranslationConstants.account.tr, navigateTo: AppRouteConstants.settingsAccount),
            TitleSubtitleRow(AppTranslationConstants.privacyAndPolicy.tr, navigateTo: AppRouteConstants.privacyAndTerms),
            TitleSubtitleRow(AppTranslationConstants.contentPreferences.tr, navigateTo: AppRouteConstants.contentPreferences),
            const HeaderWidget(AppTranslationConstants.general, secondHeader: true,),
            TitleSubtitleRow(AppTranslationConstants.aboutApp.tr, navigateTo: AppRouteConstants.about),
            //TODO
            _.userController.user!.userRole != UserRole.subscriber ?
            Column(
              children: [
                HeaderWidget(AppTranslationConstants.adminCenter.tr, secondHeader: true),
                TitleSubtitleRow(AppTranslationConstants.createCoupon.tr, navigateTo: AppRouteConstants.createCoupon),
                TitleSubtitleRow(AppTranslationConstants.createSponsor.tr, navigateTo: AppRouteConstants.createSponsor),
                TitleSubtitleRow(AppTranslationConstants.seeAnalytics.tr, navigateTo: AppRouteConstants.analytics),
                _.userController.user!.userRole == UserRole.superAdmin ?
                Column(
                  children: [
                    TitleSubtitleRow(AppTranslationConstants.runAnalyticsJobs.tr, onPressed: _.runAnalyticJobs),
                    TitleSubtitleRow(AppTranslationConstants.runProfileJobs.tr, onPressed: _.runProfileJobs),
                ],) : Container(),
              ],
            ) : Container(),
            TitleSubtitleRow("", showDivider: false, vPadding: 10, subtitle: AppTranslationConstants.settingPrivacyMsg.tr),
          ],
        ),
        ),),
    ),);
  }
}
