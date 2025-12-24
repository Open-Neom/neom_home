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
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../domain/models/home_tab_item.dart';
import 'home_controller.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_appbar_lite.dart';

class HomePage extends StatelessWidget {

  final List<HomeTabItem> tabs;
  final bool addCentralActionButton;

  const HomePage({super.key, required this.tabs,
    this.addCentralActionButton = false});

  @override
  Widget build(BuildContext context){
    final List<Widget> pageWidgets = tabs
        .where((tab) => tab.page != null)
        .map((tab) => tab.page!).toList();

    return GetBuilder<HomeController>(
      id: AppPageIdConstants.home,
      init: HomeController(),
      initState: (_) {
        Get.find<HomeController>().initTabs(tabs);
      },
      builder: (homeController) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // Altura del AppBar
          child:Obx(()=>  (homeController.userServiceImpl == null) ? HomeAppBarLite()
              : (homeController.currentIndex != 0 || (homeController.timelineServiceImpl?.showAppBar ?? false))
              ? HomeAppBar(
              profileImg: (homeController.userServiceImpl?.profile.photoUrl.isNotEmpty ?? false)
                  ? homeController.userServiceImpl?.profile.photoUrl ?? '' : AppProperties.getAppLogoUrl(),
              profileId: homeController.userServiceImpl?.profile.id ?? ''
          ) : const SizedBox.shrink(),
        ),),
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: homeController.pageController,
              children: pageWidgets,
            ),
            Obx(()=> homeController.isLoading.value ? Container(
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
          onTabSelected: (int index) => homeController.selectTab(index, context: context),
          items: tabs.map((tab) => NeomBottomAppBarItem(
              iconData: tab.icon,
              text: tab.title.tr
          )).toList(),
          showText: false,
          currentIndex: homeController.currentIndex,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: homeController.timelineServiceImpl != null && addCentralActionButton ? SizedBox(
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
