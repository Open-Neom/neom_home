import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/app_drawer.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/neom_bottom_app_bar.dart';
import 'package:neom_commons/ui/widgets/neom_bottom_app_bar_item.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../domain/models/home_tab_item.dart';
import 'home_controller.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_appbar_lite.dart';

class HomePage extends StatelessWidget {

  final List<HomeTabItem> tabs;
  final bool addCentralActionButton;
  final Widget? miniPlayer;

  const HomePage({super.key, required this.tabs,
    this.addCentralActionButton = false,
    this.miniPlayer,});

  @override
  Widget build(BuildContext context){
    final List<Widget> pageWidgets = tabs
        .where((tab) => tab.page != null)
        .map((tab) => tab.page!).toList();

    return GetBuilder<HomeController>(
      id: AppPageIdConstants.home,
      ///DEPRECATED init: HomeController(),
      initState: (_) {
        Get.find<HomeController>().initTabs(tabs);
      },
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // Altura del AppBar
          child: Obx(()=>  (controller.userServiceImpl == null) ? HomeAppBarLite()
              : (controller.currentIndex != 0 || (controller.timelineServiceImpl?.showAppBar ?? false))
              ? HomeAppBar(
              profileImg: (controller.userServiceImpl?.profile.photoUrl.isNotEmpty ?? false)
                  ? controller.userServiceImpl?.profile.photoUrl ?? '' : AppProperties.getAppLogoUrl(),
              profileId: controller.userServiceImpl?.profile.id ?? ''
          ) : const SizedBox.shrink(),
        ),),
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller.pageController,
              children: pageWidgets,
            ),
            Obx(()=> (Get.isRegistered<UserService>() && Get.find<UserService>().user.id.isNotEmpty && miniPlayer != null
                && (controller.timelineReady) && (controller.mediaPlayerEnabled)) ?
              Positioned(left: 0, right: 0, bottom: 0, child: miniPlayer!,)
                : SizedBox.shrink()
            ),
            Obx(()=> controller.isLoading.value ? Container(
              decoration: AppTheme.appBoxDecoration,
                  child: const AppCircularProgressIndicator(showLogo: false,)
              ) : SizedBox.shrink()),
          ],
        ),
        bottomNavigationBar: NeomBottomAppBar(
          backgroundColor: AppColor.bottomNavigationBar,
          color: Colors.white54,
          selectedColor: Colors.white,
          height: 55,
          notchedShape: const CircularNotchedRectangle(),
          onTabSelected: (int index) => controller.selectTab(index, context: context),
          items: tabs.map((tab) => NeomBottomAppBarItem(
              iconData: tab.icon,
              text: tab.title.tr
          )).toList(),
          showText: false,
          currentIndex: controller.currentIndex,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: controller.timelineServiceImpl != null && addCentralActionButton ? SizedBox(
          width: 43, height: 43,
          child: FloatingActionButton(
            tooltip: AppFlavour.getHomeActionBtnTooltip(),
            splashColor: AppColor.white,
            onPressed: () => Get.toNamed(AppRouteConstants.generator),
            elevation: 10,
            backgroundColor: Colors.white.withAlpha(230),
            foregroundColor: Colors.black87,
            child: Icon(AppFlavour.getHomeActionBtnIcon()),
          ),
        ) : null,
      ),
      // ),
    );
  }

}
