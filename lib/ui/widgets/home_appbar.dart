import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/enums/dot_menu_choices.dart';
import 'package:neom_commons/utils/share_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';

import '../home_controller.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {

  final String profileImg;
  final String profileId;

  const HomeAppBar({
    required this.profileImg,
    required this.profileId,
    super.key
  });

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
          backgroundImage: CachedNetworkImageProvider(profileImg.isNotEmpty
              ? profileImg : AppProperties.getAppLogoUrl())
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
      actionsIconTheme: const IconThemeData(size: 18),
      actions: <Widget>[
        if(AppFlavour.showAppBarAddButton()) IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_box_outlined, size: 25,),
            color: Colors.white70,
            onPressed: () {
              if(!Get.isRegistered<HomeController>()) {
                AppConfig.logger.d("HomeController not registered, registering now");
                Get.put(HomeController());
              }
              Get.find<HomeController>().modalBottomSheetMenu(context);
            }
        ),
        if(AppFlavour.showAppBarAddButton() || true) IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.building),
            color: Colors.white70,
            onPressed: () {
              Get.toNamed(AppRouteConstants.directory);
            }
        ),
        buildNotificationFeed(),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(FontAwesomeIcons.magnifyingGlass),
          color: Colors.white70,
          onPressed: () => {
            Get.toNamed(AppRouteConstants.search, arguments: [SearchType.any])
          }
        ),
        IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.comments),
            color: Colors.white70,
            onPressed: () => Get.toNamed(AppRouteConstants.inbox)
        ),
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
        Get.toNamed(AppRouteConstants.settingsPrivacy);
        break;
      case DotMenuChoices.logout:
        Get.find<LoginService>().signOut();
        break;
      case DotMenuChoices.shareApp:
        await ShareUtilities.shareApp();
        break;
    }
  }

  Widget buildNotificationFeed() {
    return Stack(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.bell),
            color: Colors.white70,
            onPressed: () => Get.toNamed(AppRouteConstants.feedActivity),
          ),
          FutureBuilder<List<ActivityFeed>>(
            future: ActivityFeedFirestore().retrieve(profileId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<ActivityFeed> unreadActivityFeed = [];
                for (var activityFeed in snapshot.data!) {
                  if(activityFeed.unread) {
                    unreadActivityFeed.add(activityFeed);
                  }
                }
                return unreadActivityFeed.isNotEmpty
                    ? Positioned(
                  right: 11, top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15, minHeight: 15,
                    ),
                    child: Text(unreadActivityFeed.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ) : const SizedBox.shrink();
              } else {
                return const SizedBox.shrink();
              }
            },
          )
        ]);
  }

}
