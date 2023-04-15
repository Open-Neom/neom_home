import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_commons/core/domain/model/activity_feed.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/search_type.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {

  final String title;
  final String profileImg;
  final String profileId;

  const CustomAppBar({
    required this.title,
    required this.profileImg,
    required this.profileId,
    Key? key
  }) : super(key: key);


  @override
  Size get preferredSize => AppTheme.appBarHeight;


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.appBar,
      elevation: 0.0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: CircleAvatar(
          maxRadius: 60,
          backgroundImage: CachedNetworkImageProvider(profileImg.isNotEmpty
              ? profileImg : AppFlavour.getNoImageUrl())
        ),
        onPressed: ()=> Scaffold.of(context).openDrawer(),
      ),
      title: GestureDetector(child: Row(
        children: [
          Image.asset(
            AppAssets.logoCompanyWhite,
            height: 60,
            width: 150,
          )
      ],), onTap: () => {
            AppUtilities.showAlert(context,
                AppFlavour.appInUse.value,
                "${AppTranslationConstants.version.tr} ${AppFlavour.appVersion}"),
          }
      ),
      actions: <Widget>[
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: Colors.white70,
              onPressed: ()=> {
                Get.toNamed(AppRouteConstants.feedActivity)
              }
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
                  ) : Container();
                } else {
                  return Container();
                }
              },
            )
        ]),
        Container(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
              icon: const Icon(Icons.search),
              color: Colors.white70,
              onPressed: ()=>{
                Get.toNamed(AppRouteConstants.search, arguments: SearchType.profile)
              }
          ),
        ),
        Container(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuButton<String>(
              color: AppColor.getMain(),
              onSelected: choiceAction,
              itemBuilder: (BuildContext context){
                return AppConstants.choices.map((String choice){
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice.tr.capitalizeFirst!),
                  );
                }).toList();
              },
              child: const Icon(FontAwesomeIcons.ellipsisVertical,
                size: 20,
                color: Colors.white70,
              ),
            )
        ),
        const Divider()
      ],
    );
  }

  void choiceAction(String choice) async {
    switch(choice) {
      case AppConstants.settings:
        Get.toNamed(AppRouteConstants.settingsPrivacy);
        break;
      case AppConstants.logout:
        Get.find<LoginController>().signOut();
        break;
      case MessageTranslationConstants.toShareApp:
        await CoreUtilities().shareApp();
        break;
    }
  }

}
