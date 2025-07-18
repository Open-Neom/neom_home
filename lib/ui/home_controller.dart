import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/implementations/app_initialization_controller.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/use_cases/home_service.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';

import '../utilities/constants/home_constants.dart';
import '../utilities/constants/home_translation_constants.dart';

class HomeController extends GetxController implements HomeService {


  final loginController = Get.find<LoginService>();
  final userController = Get.find<UserController>();
  final timelineServiceImpl = Get.find<TimelineService>();

  bool startingHome = true;
  bool hasItems = false;

  RxBool isLoading = true.obs;
  final RxBool _mediaPlayerEnabled = true.obs;
  Event event = Event();

  final PageController pageController = PageController();

  final RxInt _currentIndex = 0.obs;
  String toRoute = "";
  final RxBool _timelineReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("Home Controller Init");

    try {

      if(userController.user.id.isEmpty) {
        Get.toNamed(AppRouteConstants.logout,
            arguments: [AppRouteConstants.logout]
        );
        return;
      }

      pageController.addListener(() {
        int newIndex = pageController.page!.toInt();
        if (_currentIndex.value != newIndex) {
          _currentIndex.value = newIndex;
        }
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

      if(!_currentIndex.value.isEqual(toIndex) || _currentIndex.value == 0) {
        selectPageView(toIndex);
      }

      hasItems = (userController.profile.favoriteItems?.length ?? 0) > 1;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("Home Controller Ready");

    try {
      loginController.setAuthStatus(AuthStatus.loggedIn);
      loginController.setIsLoading(false);
      isLoading.value = false;

      startingHome = false;

      if(event.id.isNotEmpty) {
        AppConfig.logger.i("Coming from payment event processed successfully Event: ${event.id}");
        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.paymentProcessed.tr,
          message: CommonTranslationConstants.paymentProcessedMsg.tr,
        );

        //TODO
        // await timelineController.gotoEventDetails(event);
      }

      if(toRoute.isNotEmpty) {
        Get.toNamed(toRoute);
      }

      // WidgetsBinding.instance.addPostFrameCallback((_) async {
      //   Future.delayed(const Duration(milliseconds: 1), () => NeomAudioUtilities.getAudioHandler());
      // });
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  Future<void> _loadUserProfileFeatures() async {
    if(userController.user.profiles.isNotEmpty && userController.user.profiles.first.id.isNotEmpty) {
      userController.user.profiles.first = await ProfileFirestore().getProfileFeatures(userController.user.profiles.first);
      userController.profile = userController.user.profiles.first;
    }
  }

  @override
  void selectPageView(int index, {BuildContext? context}) async {
    AppConfig.logger.d("Changing page view to index: $index");

    try {
      switch(index) {
        case CoreConstants.firstHomeTabIndex:
          timelineServiceImpl.setScrollOffset(0);
          await setInitialTimeline();
          break;
        case CoreConstants.secondHomeTabIndex:
          break;
        case CoreConstants.thirdHomeTabIndex:
          break;
        case CoreConstants.forthHomeTabIndex:
          break;
      }

      if(pageController.hasClients) {
        switch(index) {
          case CoreConstants.firstHomeTabIndex:
            // pageController.jumpToPage(index);
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutBack,
            );
            _currentIndex.value = index;
            break;
          case CoreConstants.secondHomeTabIndex:
            // pageController.jumpToPage(index);
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
            _currentIndex.value = index;
            break;
          case CoreConstants.thirdHomeTabIndex:
            if(AppConfig.instance.appInUse == AppInUse.e) {
              Get.toNamed(AppRouteConstants.libraryHome);
            } else {
              pageController.jumpToPage(index);
              pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
              _currentIndex.value = index;
            }
            break;
          case CoreConstants.forthHomeTabIndex:
            Get.toNamed(AppRouteConstants.audioPlayerHome);
            break;
        }
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

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
                            case CommonTranslationConstants.createPost:
                              Get.toNamed(HomeConstants.bottomMenuItems[index].appRoute);
                              break;
                            case HomeTranslationConstants.organizeEvent:
                              if(AppConfig.instance.appInUse == AppInUse.c) {
                                Get.toNamed(AppRouteConstants.createNeomEventType);
                              } else {
                                Get.toNamed(HomeConstants.bottomMenuItems[index].appRoute);
                              }
                              break;
                            case HomeTranslationConstants.shareComment:
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
    if(_currentIndex.value == 0 && !startingHome) {
      if(timelineServiceImpl.getScrollController().hasClients) {
        await timelineServiceImpl.getScrollController().animateTo(
            0.0, curve: Curves.easeOut,
            duration: const Duration(milliseconds: 1000));
      }
      await timelineServiceImpl.getTimeline();
    }
  }

  @override
  void timelineIsReady({bool isReady = true}) async {

    _mediaPlayerEnabled.value = AppConfig.instance.appInfo.mediaPlayerEnabled;
    if(startingHome) _loadUserProfileFeatures();

    _timelineReady.value = isReady;

    AppInitializationController.runPostLoginTasks();
    AppInitializationController.initAudioHandler();
  }

  @override
  int get currentIndex => _currentIndex.value;

  @override
  bool get timelineReady => _timelineReady.value;

  @override
  bool get mediaPlayerEnabled => _mediaPlayerEnabled.value;

  @override
  set currentIndex(int index) {
    if(_currentIndex.value != index) {
      _currentIndex.value = index;
      AppConfig.logger.d("Current Index set to: $index");
    }
  }

  @override
  double getTimelineScrollOffset() {
    if(timelineServiceImpl.getScrollController().hasClients) {
      return timelineServiceImpl.getScrollController().offset;
    }
    return 0.0;
  }

}
