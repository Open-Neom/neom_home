import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_audio_player/ui/player/miniplayer.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';

import '../drawer/app_drawer.dart';
import '../utils/constants/home_constants.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../widgets/custom_bottom_bar_item.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  @override
  Widget build(BuildContext context){
    return GetBuilder<HomeController>(
      id: AppPageIdConstants.home,
      init: HomeController(),
      builder: (_) =>
    // Obx(()=>
    Scaffold(
        backgroundColor: AppFlavour.appInUse == AppInUse.g ? AppColor.getMain() : AppColor.main50,
        appBar: PreferredSize(
    preferredSize: const Size.fromHeight(56.0), // Altura del AppBar
    child: Obx(()=> _.currentIndex.value != 0 ||  _.timelineController.showAppBar.value
            ? CustomAppBar(
            title: AppConstants.appTitle,
            profileImg: _.userController.profile.photoUrl.isNotEmpty
                ? _.userController.profile.photoUrl : AppFlavour.getNoImageUrl(),
            profileId: _.userController.profile.id
        ) : const SizedBox.shrink(),),),
        drawer: const AppDrawer(),
        body: Obx(()=>  _.isLoading.value ? Container(
            decoration: AppTheme.appBoxDecoration,
            child: const AppCircularProgressIndicator(showLogo: false,)
        ) : Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _.pageController,
              children: HomeConstants.homePages,
            ),
            if(_.mediaPlayerEnabled.value && _.timelineReady.value) const Positioned(
              left: 0, right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),),
        bottomNavigationBar: CustomBottomAppBar(
          backgroundColor: AppColor.bottomNavigationBar,
          color: Colors.white54,
          selectedColor: Colors.white.withOpacity(0.9),
          notchedShape: const CircularNotchedRectangle(),
          onTabSelected:(int index) => _.selectPageView(index, context: context),
          items: [
            CustomBottomAppBarItem(iconData: FontAwesomeIcons.house, text: AppTranslationConstants.home.tr),
            CustomBottomAppBarItem(iconData: AppFlavour.getSecondTabIcon(), text: AppFlavour.getSecondTabTitle().tr,),
            CustomBottomAppBarItem(iconData: AppFlavour.getThirdTabIcon(), text: AppFlavour.getThirdTabTitle().tr),
            CustomBottomAppBarItem(iconData: AppFlavour.getForthTabIcon(), text: AppFlavour.getFortTabTitle().tr,)
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          width: 43, height: 43,
          child: FloatingActionButton(
            tooltip: AppFlavour.appInUse != AppInUse.c
              ? AppTranslationConstants.createPost.tr : AppTranslationConstants.session.tr,
            splashColor: AppColor.white,
            onPressed: () => AppFlavour.appInUse != AppInUse.c
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
