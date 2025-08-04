import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/app_drawer.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../domain/models/bottom_bar_item.dart';
import 'home_controller.dart';
import 'widgets/home_appbar.dart';
import 'widgets/home_appbar_lite.dart';
import 'widgets/home_bottom_app_bar.dart';

class HomePage extends StatelessWidget {

  final Widget firstPage;
  final String firstTabName;
  final Widget? secondPage;
  final String secondTabName;
  final Widget? thirdPage;
  final String thirdTabName;
  final Widget? forthPage;
  final String forthTabName;

  const HomePage({super.key, required this.firstPage, required this.firstTabName, this.secondPage, this.secondTabName = '',
    this.thirdPage, this.thirdTabName = '', this.forthPage, this.forthTabName = ''});

  @override
  Widget build(BuildContext context){
    return GetBuilder<HomeController>(
      id: AppPageIdConstants.home,
      init: HomeController(),
      builder: (homeController) => Scaffold(
        backgroundColor: AppConfig.instance.appInUse == AppInUse.g ? AppColor.getMain() : AppColor.main50,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0), // Altura del AppBar
          child: (homeController.userServiceImpl == null) ? HomeAppBarLite() : (homeController.currentIndex != 0 || (homeController.timelineServiceImpl?.showAppBar ?? false))
              ? HomeAppBar(
              profileImg: (homeController.userServiceImpl?.profile.photoUrl.isNotEmpty ?? false)
                  ? homeController.userServiceImpl?.profile.photoUrl ?? '' : AppProperties.getAppLogoUrl(),
              profileId: homeController.userServiceImpl?.profile.id ?? ''
          ) : const SizedBox.shrink()
        ),
        drawer: const AppDrawer(),
        body: Obx(()=>  homeController.isLoading.value ? Container(
            decoration: AppTheme.appBoxDecoration,
            child: const AppCircularProgressIndicator(showLogo: false,)
        ) : PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: homeController.pageController,
            children: [
              firstPage,
              if(secondPage != null) secondPage!,
              if(thirdPage != null) thirdPage!,
              if(forthPage != null) forthPage!
            ]
        ),),
        bottomNavigationBar: HomeBottomAppBar(
          backgroundColor: AppColor.bottomNavigationBar,
          color: Colors.white54,
          selectedColor: Colors.white.withOpacity(0.9),
          notchedShape: const CircularNotchedRectangle(),
          onTabSelected:(int index) => homeController.selectPageView(index, context: context),
          items: [
            BottomAppBarItem(iconData: FontAwesomeIcons.house, text: firstTabName.tr),
            if(secondPage != null) BottomAppBarItem(iconData: AppFlavour.getSecondTabIcon(), text: secondTabName.tr,),
            if(thirdPage != null) BottomAppBarItem(iconData: AppFlavour.getThirdTabIcon(), text: thirdTabName.tr),
            if(forthPage != null) BottomAppBarItem(iconData: AppFlavour.getForthTabIcon(), text: forthTabName.tr,)
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: homeController.timelineServiceImpl != null ? SizedBox(
          width: 43, height: 43,
          child: FloatingActionButton(
            tooltip: AppFlavour.getHomeActionBtnTooltip(),
            splashColor: AppColor.white,
            onPressed: () => AppConfig.instance.appInUse != AppInUse.c
              ? homeController.modalBottomSheetMenu(context)
              : Get.toNamed(AppRouteConstants.generator),
            elevation: 10,
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black87,
            child: Icon(AppFlavour.getHomeActionBtnIcon()),
          ),
        ) : null,
      ),
      // ),
    );
  }

}
