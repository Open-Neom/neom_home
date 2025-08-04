
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/enums/dot_menu_choices.dart';
import 'package:neom_commons/utils/share_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/settings_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

class HomeAppBarLite extends StatelessWidget implements PreferredSizeWidget {

  const HomeAppBarLite({super.key});

  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColor.appBar,
      elevation: 0.0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: CircleAvatar(
          maxRadius: 60,
          backgroundImage: AssetImage(AppAssets.icon),
        ),
        onPressed: ()=> Scaffold.of(context).openDrawer(),
      ),
      title: GestureDetector(
        child: Image.asset(
          AppAssets.logoCompanyWhite,
          height: 22.5, ///previous height: 60, width: 150,
          fit: BoxFit.fitHeight,
        ),
        onTap: () {
          AppAlerts.showAlert(context, message: "${AppTranslationConstants.version.tr} "
              "${AppConfig.instance.appVersion}${kDebugMode ? " - Dev Mode" : ""}");
        }
      ),
      actionsIconTheme: const IconThemeData(size: 20),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: PopupMenuButton<DotMenuChoices>(
            color: AppColor.getMain(),
            onSelected: choiceAction,
            itemBuilder: (BuildContext context) {
              return DotMenuChoices.values.map((DotMenuChoices choice){
                return PopupMenuItem<DotMenuChoices>(
                  value: choice,
                  child: Text(choice.name.tr.capitalizeFirst),
                );
              }).toList();
            },
            child: const Icon(FontAwesomeIcons.ellipsisVertical,
              color: Colors.white70,
            ),
          )
        ),
      ],
    );
  }

  void choiceAction(DotMenuChoices choice) async {
    switch(choice) {
      case DotMenuChoices.settings:
        if(Get.isRegistered<SettingsService>()) {
          Get.toNamed(AppRouteConstants.settingsPrivacy);
        }

        break;
      case DotMenuChoices.logout:
        if(Get.isRegistered<LoginService>()) {
          Get.find<LoginService>().signOut();
        }
        break;
      case DotMenuChoices.shareApp:
        await ShareUtilities.shareApp();
        break;
    }
  }

}
