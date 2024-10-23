import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';

import 'account_settings_controller.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountSettingsController>(
      id: AppPageIdConstants.accountSettings,
      init: AccountSettingsController(),
      builder: (_) => Scaffold(
      appBar: AppBarChild(title: AppTranslationConstants.accountSettings.tr),
      backgroundColor: AppColor.main50,
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: ListView(
        children: <Widget>[
          HeaderWidget(AppTranslationConstants.loginAndSecurity.tr),
          TitleSubtitleRow(
            AppTranslationConstants.username.tr,
            subtitle: _.user.name,
          ),
          const Divider(height: 0),
          if(_.userController.user.userRole != UserRole.subscriber || kDebugMode) TitleSubtitleRow(
            AppTranslationConstants.subscription.tr,
            subtitle: _.user.subscriptionId.isNotEmpty ? AppTranslationConstants.active.tr.capitalize : AppTranslationConstants.activateSubscription.tr,
            onPressed: () => _.user.subscriptionId.isEmpty ? _.getSubscriptionAlert(context) : (),
          ),
          TitleSubtitleRow(
            AppTranslationConstants.phone.tr,
            subtitle: _.user.phoneNumber.isEmpty ? AppTranslationConstants.notSpecified.tr : "+${_.user.countryCode} ${_.user.phoneNumber}",
            onPressed: () => _.getUpdatePhoneAlert(context),
          ),
          TitleSubtitleRow(
            AppTranslationConstants.email.tr,
            subtitle: _.user.email,
          ),
          const Divider(height: 0),
          if(_.user.subscriptionId.isNotEmpty)
            TitleSubtitleRow(AppTranslationConstants.cancelSubscription.tr,  textColor: AppColor.ceriseRed,
              onPressed: (){
                showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        backgroundColor: AppColor.getMain(),
                        title: Text(AppTranslationConstants.cancelThisSubscription.tr),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.yes.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              _.subscriptionController.cancelSubscription();
                            },
                          ),
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.no.tr,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
                },
            ),
          if(_.user.profiles.length > 1)
            TitleSubtitleRow(AppTranslationConstants.removeProfile.tr,  textColor: AppColor.ceriseRed,
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        backgroundColor: AppColor.main50,
                        title: Text(AppTranslationConstants.removeThisAccount.tr),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.remove.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Get.toNamed(AppRouteConstants.profileRemove, arguments: [AppRouteConstants.accountSettings, AppRouteConstants.profileRemove]);
                            },
                          ),
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.cancel.tr,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    }
                );

              },
            ),
          TitleSubtitleRow(AppTranslationConstants.removeAccount.tr,  textColor: AppColor.ceriseRed,
            onPressed: (){
            showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    backgroundColor: AppColor.getMain(),
                    title: Text(AppTranslationConstants.removeThisAccount.tr),
                    children: <Widget>[
                      SimpleDialogOption(
                        child: Text(
                          AppTranslationConstants.remove.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Get.toNamed(AppRouteConstants.accountRemove, arguments: [AppRouteConstants.accountSettings, AppRouteConstants.accountRemove]);
                          },
                      ),
                      SimpleDialogOption(
                        child: Text(
                          AppTranslationConstants.cancel.tr,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          },
                      ),
                    ],
                  );
                });
            },),
        ],),
      ),
      ),
    );
  }
}
