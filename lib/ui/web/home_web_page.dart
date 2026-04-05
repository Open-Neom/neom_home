import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:sint/sint.dart';

import '../../domain/models/home_tab_item.dart';
import '../home_controller.dart';
import 'left_sidebar.dart';
import 'right_sidebar.dart';
import 'widgets/web_notification_panel.dart';
import 'widgets/web_search_panel.dart';

/// Builder types for audio player widgets injected from the app layer.
/// This avoids coupling neom_home to neom_audio_player.
typedef WebBottomPlayerBuilder = Widget Function({
  VoidCallback? onQueueToggle,
  VoidCallback? onArtworkTap,
});

typedef WebNowPlayingBuilder = Widget Function({
  required VoidCallback onClose,
  VoidCallback? onToggleQueue,
});

typedef WebQueuePanelBuilder = Widget Function({
  VoidCallback? onClose,
});

class HomeWebPage extends StatefulWidget {
  final List<HomeTabItem> tabs;
  final Widget? miniPlayer;

  /// Optional mini Neom Chamber player.
  final Widget? miniNeomPlayer;

  /// Optional Spotify-like web player builders (injected from app layer).
  final WebBottomPlayerBuilder? webBottomPlayerBuilder;
  final WebNowPlayingBuilder? webNowPlayingFullBuilder;
  final WebQueuePanelBuilder? webQueuePanelBuilder;

  /// Optional chat bubble widget (e.g. SaiaChatBubble) for bottom-right corner.
  final Widget? chatBubble;

  /// Optional onboarding overlay (e.g. CyberneomOnboardingOverlay) shown on first visit.
  final Widget? onboardingOverlay;

  const HomeWebPage({
    super.key,
    required this.tabs,
    this.miniPlayer,
    this.miniNeomPlayer,
    this.webBottomPlayerBuilder,
    this.webNowPlayingFullBuilder,
    this.webQueuePanelBuilder,
    this.chatBubble,
    this.onboardingOverlay,
  });

  @override
  State<HomeWebPage> createState() => _HomeWebPageState();
}

class _HomeWebPageState extends State<HomeWebPage> {
  bool _showQueue = false;
  bool _showFullNowPlaying = false;

  /// Key on the ConstrainedBox (750px feed content) to detect if
  /// a scroll event is already handled by the feed's CustomScrollView.
  final GlobalKey _feedContentKey = GlobalKey();

  void _toggleQueue() => setState(() => _showQueue = !_showQueue);

  /// Facebook-style: forward pointer scroll events from sidebars and
  /// empty areas to the central feed's ScrollController.
  void _forwardScrollToFeed(PointerScrollEvent event, HomeController controller) {
    // If the cursor is directly over the feed content (750px center), the
    // page's own CustomScrollView handles the event — skip to avoid 2x scroll.
    final feedBox = _feedContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (feedBox != null) {
      final localPos = feedBox.globalToLocal(event.position);
      if (localPos.dx >= 0 && localPos.dx <= feedBox.size.width &&
          localPos.dy >= 0 && localPos.dy <= feedBox.size.height) {
        return;
      }
    }

    // Forward to the active feed's scroll controller
    final scrollController = controller.timelineServiceImpl?.getScrollController();
    if (scrollController != null && scrollController.hasClients) {
      final newOffset = (scrollController.offset + event.scrollDelta.dy)
          .clamp(0.0, scrollController.position.maxScrollExtent);
      scrollController.jumpTo(newOffset);
    }
  }

  /// Builds an overlay panel (notifications or search) with backdrop.
  Widget _buildPanelOverlay({
    required VoidCallback onClose,
    required double sidebarWidth,
    required Widget panel,
  }) {
    return Stack(
      children: [
        // Semi-transparent backdrop — tap to dismiss
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withAlpha(100)),
        ),
        // Panel positioned next to collapsed sidebar
        Positioned(
          left: sidebarWidth,
          top: 0,
          bottom: 0,
          width: 400,
          child: panel,
        ),
      ],
    );
  }

  /// Whether the web player is available (builders provided).
  bool get _hasWebPlayer => widget.webBottomPlayerBuilder != null;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pageWidgets = widget.tabs
        .where((tab) => tab.page != null)
        .map((tab) => tab.page!)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final showRightSidebar = screenWidth > 1200;
    final sidebarExpanded = screenWidth > 1400;

    return SintBuilder<HomeController>(
      id: AppPageIdConstants.home,
      initState: (_) {
        Sint.find<HomeController>().initTabs(widget.tabs);
      },
      builder: (controller) {
        return WebKeyboardManager(
          pageId: 'home',
          pageShortcuts: {
            const SingleActivator(LogicalKeyboardKey.keyN): () => controller.toggleNotificationPanel(),
            const SingleActivator(LogicalKeyboardKey.keyS): () => controller.toggleSearchPanel(),
            const SingleActivator(LogicalKeyboardKey.keyQ): () {
              if (_hasWebPlayer) _toggleQueue();
            },
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_showFullNowPlaying) {
                setState(() => _showFullNowPlaying = false);
              } else if (controller.showNotificationPanel.value) {
                controller.toggleNotificationPanel();
              } else if (controller.showSearchPanel.value) {
                controller.toggleSearchPanel();
              } else if (_showQueue) {
                setState(() => _showQueue = false);
              }
            },
          },
          child: Scaffold(
            backgroundColor: AppFlavour.getBackgroundColor(),
            body: Stack(
              children: [
                // ─── Main layout: Column with content + bottom player ───
                Column(
                  children: [
                    // Top area: 3-column layout with FB-style global scroll
                    Expanded(
                      child: Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _forwardScrollToFeed(event, controller);
                          }
                        },
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left sidebar — collapses when panel overlays are open
                          Obx(() => LeftSidebar(
                            expanded: sidebarExpanded && !controller.hasOverlayPanel,
                            currentTabIndex: controller.currentIndex,
                            onTabSelected: (index) => controller.selectTab(index, context: context),
                          )),

                          // Center feed
                          Expanded(
                            child: Container(
                              decoration: AppTheme.appBoxDecoration,
                              child: Center(
                                child: ConstrainedBox(
                                  key: _feedContentKey,
                                  constraints: const BoxConstraints(maxWidth: 800),
                                  child: Column(
                                    children: [
                                      // Stories row at the top — disabled temporarily
                                      // const WebStoriesRow(),

                                      // Main content (tab pages)
                                      Expanded(
                                        child: PageView(
                                          physics: const NeverScrollableScrollPhysics(),
                                          controller: controller.pageController,
                                          children: pageWidgets,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Right sidebar OR Queue panel (mutually exclusive)
                          if (_showQueue && widget.webQueuePanelBuilder != null)
                            Container(
                              width: 320,
                              margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                              child: widget.webQueuePanelBuilder!(
                                onClose: () => setState(() => _showQueue = false),
                              ),
                            )
                          else if (showRightSidebar)
                            const RightSidebar(),
                        ],
                      ),
                    ),),

                    // ─── Mini Neom Chamber player (above audio player) ───
                    if (widget.miniNeomPlayer != null) widget.miniNeomPlayer!,

                    // ─── Bottom player bar (Spotify-style, 80px) ───
                    if (_hasWebPlayer)
                      Obx(() => (controller.timelineReady && controller.mediaPlayerEnabled)
                          ? widget.webBottomPlayerBuilder!(
                              onQueueToggle: _toggleQueue,
                              onArtworkTap: () => setState(() => _showFullNowPlaying = true),
                            )
                          : const SizedBox.shrink()),

                    // Fallback: mobile-style miniPlayer (for apps without web player)
                    if (!_hasWebPlayer && widget.miniPlayer != null)
                      Obx(() => (controller.timelineReady && controller.mediaPlayerEnabled)
                          ? widget.miniPlayer!
                          : const SizedBox.shrink()),
                  ],
                ),

                // ─── Notification panel overlay (Instagram-style) ───
                Obx(() => controller.showNotificationPanel.value
                    ? _buildPanelOverlay(
                        onClose: controller.toggleNotificationPanel,
                        sidebarWidth: 72.0,
                        panel: WebNotificationPanel(
                          onClose: controller.toggleNotificationPanel,
                        ),
                      )
                    : const SizedBox.shrink()),

                // ─── Search panel overlay (Instagram-style) ───
                Obx(() => controller.showSearchPanel.value
                    ? _buildPanelOverlay(
                        onClose: controller.toggleSearchPanel,
                        sidebarWidth: 72.0,
                        panel: WebSearchPanel(
                          onClose: controller.toggleSearchPanel,
                        ),
                      )
                    : const SizedBox.shrink()),

                // ─── Full-screen Now Playing overlay (Spotify-style) ───
                if (_showFullNowPlaying && widget.webNowPlayingFullBuilder != null)
                  widget.webNowPlayingFullBuilder!(
                    onClose: () => setState(() => _showFullNowPlaying = false),
                    onToggleQueue: _toggleQueue,
                  ),

                // ─── Itzli Chat Bubble (bottom-right) ───
                if (widget.chatBubble != null)
                  Positioned(
                    right: 24,
                    bottom: _hasWebPlayer ? 104 : 24,
                    child: widget.chatBubble!,
                  ),

                // ─── Loading overlay ───
                Obx(() => controller.isLoading.value
                    ? Container(
                        decoration: AppTheme.appBoxDecoration,
                        child: const AppCircularProgressIndicator(showLogo: false),
                      )
                    : const SizedBox.shrink()),

                // ─── Onboarding overlay (first visit, covers everything) ───
                if (widget.onboardingOverlay != null)
                  Positioned.fill(child: widget.onboardingOverlay!),
              ],
            ),
          ),
        );
      },
    );
  }
}
