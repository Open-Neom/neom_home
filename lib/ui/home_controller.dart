import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/implementations/app_initialization_controller.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/use_cases/home_service.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';

import '../domain/models/home_tab_item.dart';
import '../utilities/constants/home_constants.dart';
import '../utilities/constants/home_translation_constants.dart';

class HomeController extends GetxController implements HomeService {


  final loginServiceImpl = Get.isRegistered<LoginService>() ? Get.find<LoginService>() : null;
  final userServiceImpl = Get.isRegistered<UserService>() ? Get.find<UserService>() : null;
  final timelineServiceImpl = Get.isRegistered<TimelineService>() ? Get.find<TimelineService>() : null;

  List<HomeTabItem> _tabs = [];

  bool startingHome = true;
  bool hasItems = false;

  RxBool isLoading = true.obs;
  final RxBool _mediaPlayerEnabled = true.obs;
  Event event = Event();

  late PageController pageController;

  final RxInt _currentIndex = 0.obs;
  int toIndex =  0;
  String toRoute = "";
  final RxBool _timelineReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("Home Controller Init");

    try {

      if(Get.arguments != null) {
        if (Get.arguments[0] is int) {
          toIndex = Get.arguments[0] as int;
        } else if (Get.arguments[0] is Event) {
          event = Get.arguments[0] as  Event;
        } else if (Get.arguments[0] is String) {
          toRoute = Get.arguments[0] as String;
        }
      }

      if (AppConfig.instance.appInUse ==  AppInUse.d) {
        toIndex = 2;
      }

      if(toIndex > 0) {
        _currentIndex.value = toIndex;
      }

      pageController = PageController(initialPage: _getPageIndexFromVisualIndex(toIndex));
      pageController.addListener(() {
        // int newIndex = pageController.page!.toInt();
        // if (_currentIndex.value != newIndex) {
        //   _currentIndex.value = newIndex;
        // }
      });

      hasItems = (userServiceImpl?.profile.favoriteItems?.length ?? 0) > 1;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("Home Controller Ready");

    try {
      if(userServiceImpl?.user.id.isNotEmpty ?? false) {
        loginServiceImpl?.setAuthStatus(AuthStatus.loggedIn);
        loginServiceImpl?.setIsLoading(false);  
      }
      
      isLoading.value = false;

      startingHome = false;

      if(event.id.isNotEmpty) {
        AppConfig.logger.i("Coming from payment event processed successfully Event: ${event.id}");
        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.paymentProcessed.tr,
          message: MessageTranslationConstants.paymentProcessedMsg.tr,
        );

        //TODO
        // await timelineController.gotoEventDetails(event);
      }

      if(toRoute.isNotEmpty) Get.toNamed(toRoute);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  void initTabs(List<HomeTabItem> tabs) {
    _tabs = tabs;
  }

  int _getPageIndexFromVisualIndex(int visualIndex) {
    int pageIndex = 0;
    for (int i = 0; i < visualIndex; i++) {
      if (i < _tabs.length && _tabs[i].page != null) {
        pageIndex++;
      }
    }
    return pageIndex;
  }

  Future<void> _loadUserProfileFeatures() async {
    if(userServiceImpl == null) return;
    if(userServiceImpl!.user.profiles.isNotEmpty && userServiceImpl!.user.profiles.first.id.isNotEmpty) {
      userServiceImpl!.user.profiles.first = await ProfileFirestore().getProfileFeatures(userServiceImpl!.user.profiles.first);
      userServiceImpl!.profile = userServiceImpl!.user.profiles.first;
    }
  }

  @override
  void selectTab(int index, {BuildContext? context}) async {
    if (index >= _tabs.length) return;

    AppConfig.logger.d("Selecting tab index: $index");
    HomeTabItem selectedTab = _tabs[index];

    if (selectedTab.isActionButton) {
      if(context != null) {
        if(selectedTab.title == AppTranslationConstants.add) {
          modalBottomAddMenu(context);
        }
      }

      return;
    }

    if (selectedTab.route != null) {
      Get.toNamed(selectedTab.route!);
      return;
    }

    isLoading.value = true;

    try {
      if (index == 0 && timelineServiceImpl != null) {
        timelineServiceImpl!.setScrollOffset(0);
        await setInitialTimeline();
      }

      int targetPageIndex = _getPageIndexFromVisualIndex(index);

      if (pageController.hasClients) {
        pageController.jumpToPage(targetPageIndex);
        _currentIndex.value = index;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.home]);
  }

  @override
  Future<void> modalBottomAddMenu(BuildContext context) async {
    await showModalBottomSheet(
        elevation: 0,
        backgroundColor: AppTheme.canvasColor50(context),
        context: context,
        builder: (BuildContext ctx) {
          return Column(
            children: <Widget>[
              Container(
                height: 260,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                    color: AppColor.getMain(),
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
                          AuthGuard.protect(context, () {
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
                          });
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
      if(timelineServiceImpl?.getScrollController().hasClients ?? false) {
        await timelineServiceImpl?.getScrollController().animateTo(
            0.0, curve: Curves.easeOut,
            duration: const Duration(milliseconds: 1000));
      }
      await timelineServiceImpl?.getTimeline();
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
  set mediaPlayerEnabled(bool enabled) {
    _mediaPlayerEnabled.value = enabled;
  }

  @override
  set currentIndex(int index) {
    if(_currentIndex.value != index) {
      _currentIndex.value = index;
      AppConfig.logger.d("Current Index set to: $index");
    }
  }

  @override
  double getTimelineScrollOffset() {
    if(timelineServiceImpl?.getScrollController().hasClients ?? false) {
      return timelineServiceImpl!.getScrollController().offset;
    }
    return 0.0;
  }

}
