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
import 'package:neom_commons/core/utils/enums/verification_level.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppDrawerController>(
    id: AppPageIdConstants.appDrawer,
    init: AppDrawerController(),
    builder: (_) {
      return Drawer(
        child: Container(
          decoration: AppTheme.appBoxDecoration,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      AppTheme.heightSpace10,
                      _menuHeader(context, _),
                      const Divider(),
                      drawerRowOption(AppDrawerMenu.profile,  const Icon(Icons.person), context),
                      if(AppFlavour.appInUse == AppInUse.c)
                        drawerRowOption(AppDrawerMenu.frequencies, Icon(AppFlavour.getInstrumentIcon()), context),
                      if(AppFlavour.appInUse == AppInUse.c)
                        drawerRowOption(AppDrawerMenu.presets, const Icon(Icons.surround_sound_outlined), context),
                      if(AppFlavour.appInUse == AppInUse.e)
                        drawerRowOption(AppDrawerMenu.inspiration, const Icon(FontAwesomeIcons.filePen), context),
                      ///DEPRECATED
                      // if(AppFlavour.appInUse != AppInUse.c && _.appProfile.type == ProfileType.instrumentist)
                      //   drawerRowOption(AppDrawerMenu.instruments, Icon(AppFlavour.getInstrumentIcon()), context),
                      //TODO To Implement
                      //_menuListRowButton(AppConstants.genres, const Icon(FontAwesomeIcons.music), true, context),
                      if(AppFlavour.appInUse == AppInUse.g && _.appProfile.type == ProfileType.appArtist)
                        drawerRowOption(AppDrawerMenu.bands, const Icon(Icons.people), context),
                      if(AppFlavour.appInUse != AppInUse.c) //TODO Not implemented on "C" app yet
                        drawerRowOption(AppDrawerMenu.requests, const Icon(Icons.email), context),
                      if(AppFlavour.appInUse == AppInUse.c && _.userController.user.userRole != UserRole.subscriber)
                        Column(
                          children: [
                            const Divider(),
                            drawerRowOption(AppDrawerMenu.inbox, const Icon(FontAwesomeIcons.comments), context),
                          ],
                        ),
                      drawerRowOption(AppDrawerMenu.calendar, const Icon(FontAwesomeIcons.calendar), context),
                      if(AppFlavour.appInUse == AppInUse.e)
                        Column(
                          children: [
                            const Divider(),
                            drawerRowOption(AppDrawerMenu.directory, const Icon(FontAwesomeIcons.building), context),
                          ],
                        ),
                      Column(
                        children: [
                          const Divider(),
                          if(
                          // ((_.appProfile.type == ProfileType.artist || _.appProfile.type == ProfileType.facilitator)
                          //     && (_.userController.userSubscription?.level?.value ?? 0) > 1) ||
                              _.user.userRole != UserRole.subscriber && AppFlavour.appInUse != AppInUse.c)
                          drawerRowOption(AppDrawerMenu.releaseUpload, Icon(AppFlavour.getAppItemIcon()), context),
                          if(AppFlavour.appInUse == AppInUse.e)
                            Column(
                              children: [
                                drawerRowOption(AppDrawerMenu.appItemQuotation, const Icon(Icons.attach_money), context),
                                drawerRowOption(AppDrawerMenu.services, const Icon(Icons.room_service), context),
                                ///DEPRECATED
                                const Divider(),
                              ],
                            )
                          ///NOT READY FOR THIS FUNCITONALITY OF CROWDFUNDING
                          // _menuListRowButton(AppConstants.crowdfunding, const Icon(FontAwesomeIcons.gifts), true, context),
                        ],
                      ),
                      if(AppFlavour.appInUse != AppInUse.c) Column(
                        children: [
                          drawerRowOption(AppDrawerMenu.wallet, const Icon(FontAwesomeIcons.coins), context),
                          const Divider(),
                        ],
                      ),
                      drawerRowOption(AppDrawerMenu.settings, const Icon(Icons.settings), context),
                      const Divider(),
                      drawerRowOption(AppDrawerMenu.logout, const Icon(Icons.logout), context),
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _.appProfile.name.length > AppConstants.maxArtistNameLength
                            ? "${_.appProfile.name.substring(0,AppConstants.maxArtistNameLength).capitalizeFirst}..." : _.appProfile.name.capitalizeFirst,
                        style: AppTheme.primaryTitleText,
                        overflow: TextOverflow.fade,
                      ),
                      if(_.user.userRole != UserRole.subscriber) IconButton(
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.keyboard_arrow_down_outlined),
                          onPressed: ()=> _.isButtonDisabled.value ? {} : _.selectProfileModal(context))
                    ],
                  ),
                  if(_.userController.user.userRole != UserRole.subscriber)
                    Text(_.userController.user.userRole.name.tr, style: const TextStyle(fontSize: 14)),
                ],
              ),
              subtitle: AppFlavour.appInUse != AppInUse.c ? buildVerifyProfile(_,context) : null,
            ),
          ],
        ),
      );
    }
  }

  Widget buildVerifyProfile(AppDrawerController _, BuildContext context) {
    List<Widget> widgets = [];

    if(_.appProfile.verificationLevel != VerificationLevel.none) {
      widgets.add(AppFlavour.getVerificationIcon(_.appProfile.verificationLevel));
    } else if(_.appProfile.type != ProfileType.general) {
      widgets.add(customText(CoreUtilities.getProfileMainFeature(_.appProfile).tr.capitalize,
          style: AppTheme.primarySubtitleText.copyWith(
              color: Colors.white70, fontSize: 15),
          context: context));
      widgets.add(AppTheme.widthSpace5);
      widgets.add(const Icon(Icons.verified_outlined, color: Colors.white70));
      widgets.add(TextButton(
          onPressed: () => _.subscriptionController.getSubscriptionAlert(context, AppRouteConstants.home, hideBasic: true),
          child: Text(AppTranslationConstants.verifyProfile.tr,
            style: const TextStyle(decoration: TextDecoration.underline),
          )
      ));
    } else if(_.userController.userSubscription?.subscriptionId.isEmpty ?? true) {
      widgets.add(TextButton(
        onPressed: () => _.subscriptionController.getSubscriptionAlert(context, AppRouteConstants.home),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero, // Remove padding here
          textStyle: const TextStyle(decoration: TextDecoration.underline), // Keep your underline style
        ),
        child: Text(AppTranslationConstants.acquireSubscription.tr,),
      ));
    } else {
      widgets.add(Text(AppTranslationConstants.activeSubscription.tr,));
    }


    return Row(children: widgets);
  }

  ListTile drawerRowOption(AppDrawerMenu selectedMenu, Icon icon, BuildContext context, {bool isEnabled = true}) {
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
            case AppDrawerMenu.inbox:
              Get.toNamed(AppRouteConstants.inbox);
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
            case AppDrawerMenu.frequencies:
              Get.toNamed(AppRouteConstants.frequencyFav);
              break;
            case AppDrawerMenu.presets:
              Get.toNamed(AppRouteConstants.chamber);
              break;
            case AppDrawerMenu.inspiration:
              Get.toNamed(AppRouteConstants.blog);
              // TODO: Handle this case.
          }
        }
      },
      leading: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: icon
      ),
      title: customText(
        selectedMenu.name.tr.capitalize,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
