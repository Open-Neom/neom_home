import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
import 'package:sint/sint.dart';

import '../domain/models/home_tab_item.dart';
import 'home_controller.dart';
import 'web/home_web_page.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_appbar_lite.dart';

class HomePage extends StatelessWidget {

  final List<HomeTabItem> tabs;
  final bool addCentralActionButton;
  final Widget? miniPlayer;

  /// Optional Spotify-like web player builders (forwarded to HomeWebPage).
  final WebBottomPlayerBuilder? webBottomPlayerBuilder;
  final WebNowPlayingBuilder? webNowPlayingFullBuilder;
  final WebQueuePanelBuilder? webQueuePanelBuilder;

  /// Optional chat bubble widget (e.g. ItzliChatBubble) for web bottom-right.
  final Widget? chatBubble;

  const HomePage({super.key, required this.tabs,
    this.addCentralActionButton = false,
    this.miniPlayer,
    this.webBottomPlayerBuilder,
    this.webNowPlayingFullBuilder,
    this.webQueuePanelBuilder,
    this.chatBubble,
  });

  @override
  Widget build(BuildContext context){
    // Use web layout on wide screens
    if (kIsWeb && MediaQuery.of(context).size.width > 900) {
      return HomeWebPage(
        tabs: tabs,
        miniPlayer: miniPlayer,
        webBottomPlayerBuilder: webBottomPlayerBuilder,
        webNowPlayingFullBuilder: webNowPlayingFullBuilder,
        webQueuePanelBuilder: webQueuePanelBuilder,
        chatBubble: chatBubble,
      );
    }
    return _buildMobileHome(context);
  }

  Widget _buildMobileHome(BuildContext context){
    final List<Widget> pageWidgets = tabs
        .where((tab) => tab.page != null)
        .map((tab) => tab.page!).toList();

    return SintBuilder<HomeController>(
      id: AppPageIdConstants.home,
      initState: (_) {
        Sint.find<HomeController>().initTabs(tabs);
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
            if(miniPlayer != null) Obx(()=> (controller.timelineReady
                && controller.mediaPlayerEnabled) ?
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
          backgroundColor: AppColor.surfaceElevated,
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
            onPressed: () => Sint.toNamed(AppRouteConstants.generator),
            elevation: 10,
            backgroundColor: AppColor.white80,
            foregroundColor: Colors.black87,
            child: Icon(AppFlavour.getHomeActionBtnIcon()),
          ),
        ) : null,
      ),
      // ),
    );
  }

}
