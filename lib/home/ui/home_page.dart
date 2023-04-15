import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import '../drawer/app_drawer.dart';
import '../utils/constants/home_constants.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../widgets/custom_bottom_bar_item.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return GetBuilder<HomeController>(
      id: AppPageIdConstants.home,
      init: HomeController(),
      builder: (_) => Scaffold(
        appBar: CustomAppBar(
            title: AppConstants.appTitle,
            profileImg: _.userController.profile.photoUrl.isNotEmpty
            ? _.userController.profile.photoUrl : AppFlavour.getNoImageUrl(),
            profileId: _.userController.profile.id),
        drawer: const AppDrawer(),
        body: _.isLoading ? Container(
            decoration: AppTheme.appBoxDecoration,
            child: const Center(
                child: CircularProgressIndicator()
            )
        ) : PageView(          
          physics: const NeverScrollableScrollPhysics(),
          controller: _.pageController,
          children: AppFlavour.appInUse == AppInUse.gigmeout
              ? HomeConstants.gigHomePages
              : HomeConstants.emxiHomePages
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.grey[900]),
          child: CustomBottomAppBar(
            backgroundColor: AppColor.bottomNavigationBar,
            color: Colors.white54,
            selectedColor: Theme.of(context).colorScheme.secondary,
            notchedShape: const CircularNotchedRectangle(),
            iconSize: 20.0,
            onTabSelected:(int index) => _.selectPageView(index),
            items: [
              CustomBottomAppBarItem(iconData: FontAwesomeIcons.house, text: AppTranslationConstants.home.tr),
              CustomBottomAppBarItem(
                  iconData: AppFlavour.appInUse == AppInUse.gigmeout
                      ? Icons.library_music : FontAwesomeIcons.bookOpen,
                  text: AppTranslationConstants.itemlists.tr,
                  animation: _.hasItems ? null : Column(
                    children: [
                      SizedBox(
                        child: DefaultTextStyle(
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                          child: AnimatedTextKit(
                            repeatForever: true,
                            animatedTexts: [
                              FlickerAnimatedText(AppTranslationConstants.addItems.tr),
                        ],
                        onTap: () {
                        },
                      ),
                    ),
                  ),
                  AppTheme.widthSpace10,
                ],
              )),
              CustomBottomAppBarItem(
                  iconData: AppFlavour.appInUse == AppInUse.gigmeout
                      ? FontAwesomeIcons.building : FontAwesomeIcons.filePen,
                  text: AppFlavour.appInUse == AppInUse.gigmeout
                      ? AppTranslationConstants.directory.tr : AppTranslationConstants.inspiration.tr),
              CustomBottomAppBarItem(iconData: FontAwesomeIcons.comments, text: AppTranslationConstants.inbox),
            ],
          ),
        ),
        floatingActionButtonLocation: AppFlavour.appInUse == AppInUse.emxi
            && _.currentIndex == 2 ? null : FloatingActionButtonLocation.centerDocked,
        floatingActionButton:  AppFlavour.appInUse == AppInUse.emxi
            && _.currentIndex == 2 ? Container()
            : FloatingActionButton(
          tooltip: AppTranslationConstants.createPost.tr,
          splashColor: Colors.white,
          onPressed: () => _.modalBottomSheetMenu(context),
          elevation: 0,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
    );
  }

}
