import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/app_info_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
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
import 'package:neom_timeline/timeline/ui/timeline_controller.dart';
import '../utils/constants/home_constants.dart';

class HomeController extends GetxController implements HomeService {


  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();
  final timelineController = Get.put(TimelineController());

  bool startingHome = true;
  bool hasItems = false;

  bool isLoading = true;
  bool isPressed = false;
  bool mediaPlayerEnabled = true;
  Event event = Event();

  final PageController pageController = PageController();
  final ScrollController scrollController = ScrollController();

  int currentIndex = 0;
  String toRoute = "";

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("Home Controller Init");

    try {

      if(userController.user.id.isEmpty) {
        Get.toNamed(AppRouteConstants.logout,
            arguments: [AppRouteConstants.logout]
        );
        return;
      }

      pageController.addListener(() {
        currentIndex = pageController.page!.toInt();
      });

      int toIndex =  0;

      if(Get.arguments != null) {
        if (Get.arguments[0] is int) {
          toIndex = Get.arguments[0] as int;
        } else if (Get.arguments[0] is Event) {
          event = Get.arguments[0] as  Event;
        } else if (Get.arguments[0] is String) {
          toRoute = Get.arguments[0] as String;
        }
      }

      if(!currentIndex.isEqual(toIndex) || currentIndex == 0) {
        selectPageView(toIndex);
      }

      if(userController.user.fcmToken.isEmpty
          || userController.user.fcmToken != userController.fcmToken) {
        UserFirestore().updateFcmToken(userController.user.id, userController.fcmToken);
      }

      hasItems = (userController.profile.favoriteItems?.length ?? 0) > 1;
      await verifyLocation();
      UserFirestore().updateLastTimeOn(userController.user.id);

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
    isLoading = false;
    update([AppPageIdConstants.home]);

    try {
      AppInfo appInfo = await AppInfoFirestore().retrieve();
      mediaPlayerEnabled = appInfo.mediaPlayerEnabled;
      if(startingHome) _loadUserProfileFeatures();
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    startingHome = false;

    if(event.id.isNotEmpty) {
      AppUtilities.logger.i("Coming from payment event processed successfully Event: ${event.id}");
      AppUtilities.showSnackBar(
        title: AppTranslationConstants.paymentProcessed.tr,
        message: AppTranslationConstants.paymentProcessedMsg.tr,
      );

      //TODO
      // await timelineController.gotoEventDetails(event);
    }

    if(toRoute.isNotEmpty) {
      await Get.toNamed(toRoute);
    }

    update([AppPageIdConstants.home]);
  }

  Future<void> _loadUserProfileFeatures() async {
    if(userController.user.profiles.isNotEmpty && userController.user.profiles.first.id.isNotEmpty) {
      userController.user.profiles.first = await ProfileFirestore().getProfileFeatures(userController.user.profiles.first);
      userController.profile = userController.user.profiles.first;
    }
  }

  @override
  void selectPageView(int index, {BuildContext? context}) async {
    AppUtilities.logger.t("Changing page view to index: $index");

    try {
      switch(index) {
        case HomeConstants.firstTabIndex:
          timelineController.scrollOffset = 0;
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
        switch(index) {
          case 0:
            pageController.jumpToPage(index);
            currentIndex = index;
            break;
          case 1:
            pageController.jumpToPage(index);
            currentIndex = index;
            break;
          case 2:
            if(AppFlavour.appInUse == AppInUse.e) {
              Get.toNamed(AppRouteConstants.libraryHome);
            } else {
              pageController.jumpToPage(index);
              currentIndex = index;
            }
            break;
          case 3:
            Get.toNamed(AppRouteConstants.musicPlayerHome);
            break;
        }

        ///DEPRECATED
        // if(index != HomeConstants.forthTabIndex) {
        //   pageController.jumpToPage(index);
        //   currentIndex = index;
        // } else {
        //   if(AppFlavour.appInUse == AppInUse.e) {
        //     Get.toNamed(AppRouteConstants.libraryHome);
        //   } else {
        //     await Get.toNamed(AppRouteConstants.musicPlayerHome);
        //   }
        // }
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
      isLoading = false;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.home, AppPageIdConstants.timeline]);
  }


  @override
  Future<void> modalBottomSheetMenu(BuildContext context) async {
    isPressed = true;
    await showModalBottomSheet(
        elevation: 0,
        backgroundColor: AppTheme.canvasColor25(context),
        context: context,
        builder: (BuildContext ctx) {
          return Column(
            children: <Widget>[
              Container(
                height: 260,
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
                        title: Text(HomeConstants.bottomMenuItems[index].title.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        subtitle: Text(HomeConstants.bottomMenuItems[index].subtitle.tr,
                          style: const TextStyle(fontSize: 13),),
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
                height: 43, width: 43,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(30))
                ),
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
