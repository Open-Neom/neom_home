import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/app_drawer.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../domain/models/bottom_bar_item.dart';
import 'home_controller.dart';
import 'widgets/home_appbar.dart';
import 'widgets/home_bottom_app_bar.dart';

class HomePage extends StatelessWidget {

  final Widget firstPage;
  final Widget? secondPage;
  final Widget? thirdPage;
  final Widget? forthPage;

  const HomePage({super.key, required this.firstPage, this.secondPage, this.thirdPage, this.forthPage});

  @override
  Widget build(BuildContext context){
    return GetBuilder<HomeController>(
      id: AppPageIdConstants.home,
      init: HomeController(),
      builder: (_) => Scaffold(
        backgroundColor: AppConfig.instance.appInUse == AppInUse.g ? AppColor.getMain() : AppColor.main50,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0), // Altura del AppBar
          child: Obx(()=> _.currentIndex != 0 ||  _.timelineServiceImpl.showAppBar
              ? HomeAppBar(
              profileImg: _.userController.profile.photoUrl.isNotEmpty
                  ? _.userController.profile.photoUrl : AppProperties.getAppLogoUrl(),
              profileId: _.userController.profile.id
          ) : const SizedBox.shrink(),),
        ),
        drawer: const AppDrawer(),
        body: Obx(()=>  _.isLoading.value ? Container(
            decoration: AppTheme.appBoxDecoration,
            child: const AppCircularProgressIndicator(showLogo: false,)
        ) : Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _.pageController,
              children: [
                firstPage,
                if(secondPage != null) secondPage!,
                if(thirdPage != null) thirdPage!,
                if(forthPage != null) forthPage!
              ]
            ),
            // if(_.mediaPlayerEnabled && _.timelineReady) const Positioned(
            //   left: 0, right: 0,
            //   bottom: 0,
            //   child: MiniPlayer(),
            // ),
          ],
        ),),
        bottomNavigationBar: HomeBottomAppBar(
          backgroundColor: AppColor.bottomNavigationBar,
          color: Colors.white54,
          selectedColor: Colors.white.withOpacity(0.9),
          notchedShape: const CircularNotchedRectangle(),
          onTabSelected:(int index) => _.selectPageView(index, context: context),
          items: [
            BottomAppBarItem(iconData: FontAwesomeIcons.house, text: AppTranslationConstants.home.tr),
            if(secondPage != null) BottomAppBarItem(iconData: AppFlavour.getSecondTabIcon(), text: AppFlavour.getSecondTabTitle().tr,),
            if(thirdPage != null) BottomAppBarItem(iconData: AppFlavour.getThirdTabIcon(), text: AppFlavour.getThirdTabTitle().tr),
            if(forthPage != null) BottomAppBarItem(iconData: AppFlavour.getForthTabIcon(), text: AppFlavour.getFortTabTitle().tr,)
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          width: 43, height: 43,
          child: FloatingActionButton(
            tooltip: AppFlavour.getHomeActionBtnTooltip(),
            splashColor: AppColor.white,
            onPressed: () => AppConfig.instance.appInUse != AppInUse.c
              ? _.modalBottomSheetMenu(context)
              : Get.toNamed(AppRouteConstants.generator),
            elevation: 10,
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black87,
            child: Icon(AppFlavour.getHomeActionBtnIcon()),
          ),
        ),
      ),
      // ),
    );
  }

}
