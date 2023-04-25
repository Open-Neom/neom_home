import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/implementations/app_drawer_controller.dart';
import 'package:neom_commons/core/ui/widgets/custom_widgets.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppDrawerController>(
    id: AppPageIdConstants.appDrawer,
    init: AppDrawerController(),
    builder: (_) {
      return Drawer(
        child: Container(
          color: AppColor.drawer,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(bottom: 45),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      Obx(()=>_menuHeader(context, _)),
                      const Divider(),
                      _menuListRowButton(AppConstants.profile,  const Icon(Icons.person), true, context),
                      _.appProfile.type != ProfileType.instrumentist ? Container() :
                      _menuListRowButton(AppConstants.instruments, Icon(
                          AppFlavour.getInstrumentIcon()), true, context),
                      //TODO To Implement
                      //_menuListRowButton(AppConstants.genres, const Icon(FontAwesomeIcons.music), true, context),
                      AppFlavour.appInUse == AppInUse.gigmeout && _.appProfile.type == ProfileType.instrumentist
                       ? _menuListRowButton(AppConstants.bands, const Icon(Icons.people), true, context)
                      : Container(),
                      _menuListRowButton(AppConstants.events, const Icon(FontAwesomeIcons.calendar), true, context),
                      //TODO To enable when users create events.
                      // AppFlavour.appInUse == AppInUse.gigmeout
                      //     ? _menuListRowButton(AppConstants.eventsCalendar, const Icon(FontAwesomeIcons.calendarCheck), true, context)
                      //     : Container(),
                      AppFlavour.appInUse == AppInUse.emxi
                          ? _menuListRowButton(AppConstants.directory, const Icon(FontAwesomeIcons.building), true, context)
                          : Container(),
                      _menuListRowButton(AppConstants.requests, const Icon(Icons.email), true, context),
                      AppFlavour.appInUse == AppInUse.emxi
                          ? _menuListRowButton(AppConstants.digitalLibrary, const Icon(FontAwesomeIcons.shop), true, context)
                          : Container(),
                      AppFlavour.appInUse == AppInUse.gigmeout && _.user.userRole != UserRole.subscriber
                          ? _menuListRowButton(AppConstants.wallet, const Icon(FontAwesomeIcons.coins), true, context)
                          : Container(),
                      const Divider(),
                      _menuListRowButton(AppConstants.settings, const Icon(Icons.settings), true, context),
                      // _.user.userRole != UserRole.subscriber
                      //     ? _menuListRowButton('Admin Center', const Icon(Icons.admin_panel_settings), true, context)
                      //     : Container(),
                      const Divider(),
                      _menuListRowButton(AppConstants.logout, const Icon(Icons.logout), true, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _menuHeader(BuildContext context, AppDrawerController _) {
    if (_.user.id.isEmpty) {
      return customInkWell(
        context: context,
        onPressed: () {
          Get.offAllNamed(AppRouteConstants.login);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, minHeight: 100),
          child: Center(
            child: Text(
              AppTranslationConstants.loginToContinue.tr,
              style: AppTheme.primaryTitleText,
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              child: Container(
              height: 56,
              width: 56,
              margin: const EdgeInsets.only(left: 20, top: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(_.appProfile.photoUrl.isNotEmpty
                      ? _.appProfile.photoUrl : AppFlavour.getNoImageUrl()),
                  fit: BoxFit.cover,
                  ),
                ),
              ),
              onTap: ()=> Get.toNamed(AppRouteConstants.profile),
            ),
            ListTile(
              onTap: () {
                Get.toNamed(AppRouteConstants.profile);
              },
              title: Row(
                children: [
                  Text(
                    _.appProfile.name.length > AppConstants.maxArtistNameLength
              ? "${_.appProfile.name.substring(0,AppConstants.maxArtistNameLength)}..." : _.appProfile.name,
                    style: AppTheme.primaryTitleText,
                    overflow: TextOverflow.fade,
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    onPressed: ()=> _.isButtonDisabled ? {} : _.selectProfileModal(context))
                ],
              ),
              subtitle: Row(
                children: [
                  customText(CoreUtilities.getProfileMainFeature(_.appProfile).tr.capitalize!,
                    style: AppTheme.primarySubtitleText.copyWith(
                        color: Colors.white70, fontSize: 15),
                    context: context),
                AppTheme.widthSpace5,
                _.user.isVerified ? const Icon(Icons.verified) : const Icon(Icons.verified_outlined, color: Colors.white70)
              ]),
            ),
          ],
        ),
      );
    }
  }

  ListTile _menuListRowButton(String title, Icon icon, bool isEnabled, BuildContext context) {
    return ListTile(
      onTap: () {
        switch(title) {
          case AppConstants.profile:
            if (isEnabled) Get.toNamed(AppRouteConstants.profile);
            break;
          case AppConstants.instruments:
            if (isEnabled) Get.toNamed(AppRouteConstants.instrumentsFav);
            break;
          case AppConstants.genres:
            if (isEnabled) Get.toNamed(AppRouteConstants.genresFav);
            break;
          case AppConstants.digitalLibrary:
            if (isEnabled) CoreUtilities.launchURL(AppFlavour.getECommerceUrl());
            break;
          case AppConstants.bands:
            if (isEnabled) Get.toNamed(AppRouteConstants.bands);
            break;
          case AppConstants.events:
            if (isEnabled) Get.toNamed(AppRouteConstants.events);
            break;
          case AppConstants.eventsCalendar:
            if (isEnabled) Get.toNamed(AppRouteConstants.calendar);
            break;
          case AppConstants.requests:
            if (isEnabled) Get.toNamed(AppRouteConstants.request);
            break;
          case AppConstants.booking:
            if (isEnabled) Get.toNamed(AppRouteConstants.booking);
            break;
          case AppConstants.directory:
            if (isEnabled) Get.toNamed(AppRouteConstants.directory);
            break;
          case AppConstants.wallet:
            if (isEnabled) Get.toNamed(AppRouteConstants.wallet);
            break;
          case AppConstants.settings:
            if (isEnabled) Get.toNamed(AppRouteConstants.settingsPrivacy);
            break;
          case AppConstants.logout:
            if (isEnabled) {
              Get.toNamed(AppRouteConstants.logout,
                arguments: [AppRouteConstants.logout]
              );
            }
            break;
        }
      },
      leading: Container(
          padding: const EdgeInsets.only(top: 5),
          child: icon
      ),
      title: customText(
        title.tr.capitalize!,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
