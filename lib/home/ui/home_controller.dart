import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_audio_player/utils/neom_audio_utilities.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_timeline/timeline/ui/timeline_controller.dart';
import '../utils/constants/home_constants.dart';

class HomeController extends GetxController implements HomeService {


  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();
  final timelineController = Get.put(TimelineController());

  bool startingHome = true;
  bool hasItems = false;

  RxBool isLoading = true.obs;
  RxBool mediaPlayerEnabled = true.obs;
  Event event = Event();

  final PageController pageController = PageController();
  // final ScrollController scrollController = ScrollController();

  RxInt currentIndex = 0.obs;
  String toRoute = "";
  RxBool timelineReady = false.obs;

  @override
  void onInit() {
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
        currentIndex.value = pageController.page!.toInt();
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

      if(!currentIndex.value.isEqual(toIndex) || currentIndex == 0) {
        selectPageView(toIndex);
      }

      hasItems = (userController.profile.favoriteItems?.length ?? 0) > 1;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();
    AppUtilities.logger.t("Home Controller Ready");

    loginController.authStatus.value = AuthStatus.loggedIn;
    loginController.setIsLoading(false);
    isLoading.value = false;
    // update([AppPageIdConstants.home]);

    try {
      ///DEPRECAGTED
      // AppInfo appInfo = await AppInfoFirestore().retrieve();
      // mediaPlayerEnabled.value = appInfo.mediaPlayerEnabled;
      // if(startingHome) _loadUserProfileFeatures();
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
      Get.toNamed(toRoute);
    }

    // update([AppPageIdConstants.home]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(const Duration(milliseconds: 1), () => NeomAudioUtilities.getAudioHandler());
    });
  }

  Future<void> _loadUserProfileFeatures() async {
    if(userController.user.profiles.isNotEmpty && userController.user.profiles.first.id.isNotEmpty) {
      userController.user.profiles.first = await ProfileFirestore().getProfileFeatures(userController.user.profiles.first);
      userController.profile = userController.user.profiles.first;
    }
  }

  @override
  void selectPageView(int index, {BuildContext? context}) async {
    AppUtilities.logger.d("Changing page view to index: $index");

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
          case HomeConstants.firstTabIndex:
            pageController.jumpToPage(index);
            currentIndex.value = index;
            break;
          case HomeConstants.secondTabIndex:
            pageController.jumpToPage(index);
            currentIndex.value = index;
            break;
          case HomeConstants.thirdTabIndex:
            if(AppFlavour.appInUse == AppInUse.e) {
              Get.toNamed(AppRouteConstants.libraryHome);
            } else {
              pageController.jumpToPage(index);
              currentIndex.value = index;
            }
            break;
          case HomeConstants.forthTabIndex:
            Get.toNamed(AppRouteConstants.audioPlayerHome);
            break;
        }
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    // update([AppPageIdConstants.home]);
  }

  @override
  Future<void> modalBottomSheetMenu(BuildContext context) async {
    // isPressed.value = true;
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

  void timelineIsReady({bool isReady = true}) async {

    AppInfo appInfo = await AppInfoFirestore().retrieve();
    mediaPlayerEnabled.value = appInfo.mediaPlayerEnabled;
    if(startingHome) _loadUserProfileFeatures();

    timelineReady.value = isReady;

    userController.getUserSubscription();
    Future.microtask(() => UserFirestore().updateLastTimeOn(userController.user.id));
    Future.microtask(() => AppHiveController().fetchCachedData());
    Future.microtask(() => AppHiveController().fetchSettingsData());

    if(userController.user.fcmToken.isEmpty
        || userController.user.fcmToken != userController.fcmToken) {
      Future.microtask(() => UserFirestore().updateFcmToken(userController.user.id, userController.fcmToken));
    }
    // Inicialización de las notificaciones
    Future.microtask(() => verifyLocation());
    Future.microtask(() => PushNotificationService.init());
    Future.microtask(() => AppHiveController().setFirstTime(false));
  }

  @override
  Future<void> verifyLocation() async {
    AppUtilities.logger.t("Verifying location");
    try {
      userController.profile.position = await GeoLocatorController().updateLocation(userController.profile.id, userController.profile.position);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

}
