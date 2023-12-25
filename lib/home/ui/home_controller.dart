import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/app_info_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/data/implementations/geolocator_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_info.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/domain/use_cases/home_service.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/auth_status.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';

import 'package:neom_timeline/timeline/ui/timeline_controller.dart';
import '../utils/constants/home_constants.dart';

class HomeController extends GetxController implements HomeService {


  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();
  final timelineController = Get.put(TimelineController());

  bool startingHome = true;
  bool hasItems = false;

  final RxBool isLoading = true.obs;
  final RxBool isPressed = false.obs;
  final RxBool mediaPlayerEnabled = true.obs;
  final Rx<Event> event = Event().obs;

  final PageController pageController = PageController();
  final ScrollController scrollController = ScrollController();

  int currentIndex = 0;
  String toRoute = "";

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("Home Controller Init");

    try {

      pageController.addListener(() {
        currentIndex = pageController.page!.toInt();
      });

      int toIndex =  0;

      if(Get.arguments != null) {
        if (Get.arguments[0] is int) {
          toIndex = Get.arguments[0] as int;
        } else if (Get.arguments[0] is Event) {
          event.value = Get.arguments[0] as  Event;
        } else if (Get.arguments[0] is String) {
          toRoute = Get.arguments[0] as String;
        }
      }

      if(!currentIndex.isEqual(toIndex) || currentIndex == 0) {
        selectPageView(toIndex);
      }

      if(userController.user!.fcmToken.isEmpty
          || userController.user!.fcmToken != userController.fcmToken) {
        UserFirestore().updateFcmToken(userController.user!.id, userController.fcmToken);
      }

      hasItems = (userController.profile.favoriteItems?.length ?? 0) > 1;
      await verifyLocation();
      UserFirestore().updateLastTimeOn(userController.user!.id);

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.t("Home Controller Ready");

    loginController.authStatus.value = AuthStatus.loggedIn;
    loginController.setIsLoading(false);
    startingHome = false;
    isLoading.value = false;
    update([AppPageIdConstants.home]);

    try {
      AppInfo appInfo = await AppInfoFirestore().retrieve();
      mediaPlayerEnabled.value = appInfo.mediaPlayerEnabled;

      ///DEPRECATED
      // bool isAppBadgeSupported = await FlutterAppBadger.isAppBadgeSupported();
      // if (isAppBadgeSupported) {
      //   AppUtilities.logger.i('App Badger supported.');
      //   List<ActivityFeed> unreadActivityFeed = [];
      //   unreadActivityFeed = await ActivityFeedFirestore().retrieve(userController.profile.id);
      //   unreadActivityFeed.removeWhere((element) => element.unread == false);
      //   if (unreadActivityFeed.isNotEmpty) {
      //     FlutterAppBadger.updateBadgeCount(unreadActivityFeed.length + 10);
      //   } else {
      //     FlutterAppBadger.removeBadge();
      //   }
      // } else {
      //   AppUtilities.logger.i('App Badger not supported.');
      // }
    } catch(e) {
      AppUtilities.logger.e('Failed to get badge support.');
    }

    if(event.value.id.isNotEmpty) {
      AppUtilities.logger.i("Coming from payment event processed successfully Event: ${event.value.id}");
      Get.snackbar(
        AppTranslationConstants.paymentProcessed.tr,
        AppTranslationConstants.paymentProcessedMsg.tr,
        snackPosition: SnackPosition.bottom,
      );

      //TODO
      // await timelineController.gotoEventDetails(event);
    }

    if(toRoute.isNotEmpty) {
      await Get.toNamed(toRoute);
    }

    update([AppPageIdConstants.home]);
  }


  @override
  void selectPageView(int index, {BuildContext? context}) async {
    AppUtilities.logger.t("Changing page view to index: $index");

    try {
      switch(index) {
        case HomeConstants.firstTabIndex:
          await setInitialTimeline();
          break;
        case HomeConstants.secondTabIndex:
          break;
        case HomeConstants.thirdTabIndex:
          break;
        case HomeConstants.forthTabIndex:
          break;
      }

      if(pageController.hasClients) {
        if(AppFlavour.appInUse == AppInUse.e && index == HomeConstants.forthTabIndex) {
          Get.toNamed(AppRouteConstants.libraryHome);
        } else if((AppFlavour.appInUse == AppInUse.g
            || userController.user!.userRole != UserRole.subscriber)
            && index == HomeConstants.forthTabIndex) {
          // Get.delete<NeomMusicPlayerApp>();
          await Get.toNamed(AppRouteConstants.musicPlayerHome);
          // if(context != null) {
          //   Navigator.pushNamed(context, AppRouteConstants.musicPlayerHome);
          // }

        } else {
          pageController.jumpToPage(index);
          currentIndex = index;
        }
      }


    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.home]);
  }


  @override
  Future<void> verifyLocation() async {
    AppUtilities.logger.t("Verifying location");
    try {
      userController.profile.position = await GeoLocatorController()
          .updateLocation(userController.profile.id, userController.profile.position);
      isLoading.value = false;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.home, AppPageIdConstants.timeline]);
  }


  @override
  Future<void> modalBottomSheetMenu(BuildContext context) async {
    isPressed.value = true;
    await showModalBottomSheet(
        elevation: 0,
        backgroundColor: AppTheme.canvasColor25(context),
        context: context,
        builder: (BuildContext ctx) {
          return Column(
            children: <Widget>[
              Container(
                height: 280,
                padding: const EdgeInsets.only(top: 10),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                    color: AppColor.main95,
                    borderRadius: const BorderRadius.all(Radius.circular(10.0))
                ),
                child: ListView.separated(
                    separatorBuilder:  (context, index) => const Divider(),
                    itemCount: HomeConstants.bottomMenuItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(30)),
                            color: Colors.teal[100],
                          ),
                          child: Icon(HomeConstants.bottomMenuItems[index].icon, color: Colors.white),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 15,),
                        title: Text(
                          HomeConstants.bottomMenuItems[index].title.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        subtitle: Text(HomeConstants.bottomMenuItems[index].subtitle.tr),
                        onTap: () {
                          Navigator.pop(ctx);
                          switch (HomeConstants.bottomMenuItems[index].title) {
                            case AppTranslationConstants.createPost:
                              Get.toNamed(HomeConstants.bottomMenuItems[index].appRoute);
                              break;
                            case AppTranslationConstants.organizeEvent:
                              if(AppFlavour.appInUse == AppInUse.c) {
                                Get.toNamed(AppRouteConstants.createNeomEventType);
                              } else {
                                Get.toNamed(HomeConstants.bottomMenuItems[index].appRoute);
                              }
                              break;
                            case AppTranslationConstants.shareComment:
                              Get.toNamed(HomeConstants.bottomMenuItems[index].appRoute);
                              break;
                          }
                        },
                      );
                    }
                ),
              ),
              Container(
                  height: 60, width: 60,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(30))),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, size: 25, color: Colors.grey[900])
                  )
              ),
            ],
          );
        });
  }

  void gotoEvent(Event event) {
    Get.toNamed(AppRouteConstants.eventDetails, arguments: [event]);
  }

  Future<void> setInitialTimeline() async {
    if(timelineController.initialized && currentIndex == 0 && !startingHome) {
      if(timelineController.timelineScrollController.hasClients) {
        await timelineController.timelineScrollController.animateTo(
            0.0, curve: Curves.easeOut,
            duration: const Duration(milliseconds: 1000));
      }
      await timelineController.getTimeline();
    }
  }

}
