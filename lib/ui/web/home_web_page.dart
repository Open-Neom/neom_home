import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:sint/sint.dart';

import '../../domain/models/home_tab_item.dart';
import '../home_controller.dart';
import 'left_sidebar.dart';
import 'right_sidebar.dart';
import 'web_top_bar.dart';

class HomeWebPage extends StatelessWidget {
  final List<HomeTabItem> tabs;
  final Widget? miniPlayer;

  const HomeWebPage({
    super.key,
    required this.tabs,
    this.miniPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> pageWidgets = tabs
        .where((tab) => tab.page != null)
        .map((tab) => tab.page!)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final showRightSidebar = screenWidth > 1200;
    final showLeftSidebar = screenWidth > 900;

    return SintBuilder<HomeController>(
      id: AppPageIdConstants.home,
      initState: (_) {
        Sint.find<HomeController>().initTabs(tabs);
      },
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Column(
          children: [
            // Top bar
            WebTopBar(
              currentTabIndex: controller.currentIndex,
              onTabSelected: (index) => controller.selectTab(index, context: context),
            ),

            // Main content (3 columns)
            Expanded(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left sidebar
                      if (showLeftSidebar) const LeftSidebar(),

                      // Center feed
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: PageView(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: controller.pageController,
                              children: pageWidgets,
                            ),
                          ),
                        ),
                      ),

                      // Right sidebar
                      if (showRightSidebar) const RightSidebar(),
                    ],
                  ),

                  // MiniPlayer overlay
                  if (miniPlayer != null)
                    Obx(() => (controller.timelineReady && controller.mediaPlayerEnabled)
                        ? Positioned(left: 0, right: 0, bottom: 0, child: miniPlayer!)
                        : const SizedBox.shrink()),

                  // Loading overlay
                  Obx(() => controller.isLoading.value
                      ? Container(
                          decoration: AppTheme.appBoxDecoration,
                          child: const AppCircularProgressIndicator(showLogo: false),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
