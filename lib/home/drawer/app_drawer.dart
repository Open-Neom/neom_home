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
import 'package:neom_commons/core/utils/enums/app_drawer_menu.dart';
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
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      Obx(()=>_menuHeader(context, _)),
                      const Divider(),
                      _menuListRowButton(AppDrawerMenu.profile,  const Icon(Icons.person), true, context),
                      _.appProfile.type != ProfileType.instrumentist ? Container() :
                      _menuListRowButton(AppDrawerMenu.instruments, Icon(
                          AppFlavour.getInstrumentIcon()), true, context),
                      //TODO To Implement
                      //_menuListRowButton(AppConstants.genres, const Icon(FontAwesomeIcons.music), true, context),
                      AppFlavour.appInUse == AppInUse.gigmeout && _.appProfile.type == ProfileType.instrumentist
                       ? _menuListRowButton(AppDrawerMenu.bands, const Icon(Icons.people), true, context)
                      : Container(),
                      AppFlavour.appInUse == AppInUse.emxi ?
                      _menuListRowButton(AppDrawerMenu.events, const Icon(FontAwesomeIcons.calendar), true, context) : Container(),
                      _menuListRowButton(AppDrawerMenu.requests, const Icon(Icons.email), true, context),
                      //TODO To enable when users create events.
                      // AppFlavour.appInUse == AppInUse.gigmeout
                      //     ? _menuListRowButton(AppConstants.eventsCalendar, const Icon(FontAwesomeIcons.calendarCheck), true, context)
                      //     : Container(),
                      AppFlavour.appInUse == AppInUse.emxi
                          ? Column(
                        children: [
                          const Divider(),
                          _menuListRowButton(AppDrawerMenu.releaseUpload, Icon(AppFlavour.getAppItemIcon()), true, context),
                          _menuListRowButton(AppDrawerMenu.appItemQuotation, const Icon(Icons.attach_money), true, context),
                          _menuListRowButton(AppDrawerMenu.services, const Icon(Icons.room_service), true, context),
                          _menuListRowButton(AppDrawerMenu.directory, const Icon(FontAwesomeIcons.building), true, context),
                          // _menuListRowButton(AppConstants.crowdfunding, const Icon(FontAwesomeIcons.gifts), true, context),
                      ],) : Container(),
                      const Divider(),
                      _menuListRowButton(AppDrawerMenu.wallet, const Icon(FontAwesomeIcons.coins), true, context),
                      const Divider(),
                      _menuListRowButton(AppDrawerMenu.settings, const Icon(Icons.settings), true, context),
                      // _.user.userRole != UserRole.subscriber
                      //     ? _menuListRowButton('Admin Center', const Icon(Icons.admin_panel_settings), true, context)
                      //     : Container(),
                      const Divider(),
                      _menuListRowButton(AppDrawerMenu.logout, const Icon(Icons.logout), true, context),
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

  ListTile _menuListRowButton(AppDrawerMenu selectedMenu, Icon icon, bool isEnabled, BuildContext context) {
    return ListTile(
      onTap: () {
        if(isEnabled) {
          switch(selectedMenu) {
            case AppDrawerMenu.profile:
              Get.toNamed(AppRouteConstants.profile);
              break;
            case AppDrawerMenu.instruments:
              Get.toNamed(AppRouteConstants.instrumentsFav);
              break;
            case AppDrawerMenu.genres:
              if (isEnabled) Get.toNamed(AppRouteConstants.genresFav);
              break;
            case AppDrawerMenu.bands:
              Get.toNamed(AppRouteConstants.bands);
              break;
            case AppDrawerMenu.events:
              Get.toNamed(AppRouteConstants.events);
              break;
            case AppDrawerMenu.calendar:
              Get.toNamed(AppRouteConstants.calendar);
              break;
            case AppDrawerMenu.services:
              Get.toNamed(AppRouteConstants.services);
              break;
            case AppDrawerMenu.requests:
              Get.toNamed(AppRouteConstants.request);
              break;
            case AppDrawerMenu.booking:
              Get.toNamed(AppRouteConstants.booking);
              break;
            case AppDrawerMenu.directory:
              Get.toNamed(AppRouteConstants.directory);
              break;
            case AppDrawerMenu.wallet:
              Get.toNamed(AppRouteConstants.wallet);
              break;
            case AppDrawerMenu.settings:
              Get.toNamed(AppRouteConstants.settingsPrivacy);
              break;
            case AppDrawerMenu.crowdfunding:
              CoreUtilities.launchURL(AppFlavour.getCrowdfundingUrl());
              break;
            case AppDrawerMenu.appItemQuotation:
              Get.toNamed(AppRouteConstants.quotation);
              break;
            case AppDrawerMenu.logout:
              Get.toNamed(AppRouteConstants.logout,
                  arguments: [AppRouteConstants.logout]
              );
              break;
            case AppDrawerMenu.releaseUpload:
              Get.toNamed(AppRouteConstants.releaseUpload);
              break;
            case AppDrawerMenu.digitalLibrary:
              // TODO: Handle this case.
              break;
          }
        }
      },
      leading: Container(
          padding: const EdgeInsets.only(top: 5),
          child: icon
      ),
      title: customText(
        selectedMenu.name.tr.capitalize!,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
