import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/widgets/images/web_network_image_stub.dart'
    if (dart.library.html) 'package:neom_commons/ui/widgets/images/web_network_image_impl.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/settings_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/home_translation_constants.dart';
import '../home_controller.dart';

/// Instagram-style left sidebar navigation for web.
/// Collapsed (72px) on screens ≤ 1400px, expanded (220px) on wider screens.
class LeftSidebar extends StatefulWidget {
  final bool expanded;
  final int currentTabIndex;
  final Function(int) onTabSelected;

  const LeftSidebar({
    super.key,
    this.expanded = false,
    required this.currentTabIndex,
    required this.onTabSelected,
  });

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  Timer? _pollingTimer;
  int _unreadNotifications = 0;
  int _unreadInbox = 0;

  String get _profileId => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.id
      : '';

  String get _profileImg {
    if (!Sint.isRegistered<UserService>()) return '';
    final url = Sint.find<UserService>().profile.photoUrl.trim();
    return url.startsWith('http') ? url : '';
  }

  String get _profileName => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.name
      : '';

  /// True if user is creator-verified or has support+ role (for NUPALE/CASETE/Wallet)
  bool get _isCreatorOrSupport {
    if (!Sint.isRegistered<UserService>()) return false;
    final service = Sint.find<UserService>();
    return service.profile.verificationLevel.value >= VerificationLevel.creator.value
        || service.user.userRole.value >= UserRole.support.value;
  }

  /// True if user has support+ role (for Release Upload)
  bool get _isSupportOrAbove {
    if (!Sint.isRegistered<UserService>()) return false;
    return Sint.find<UserService>().user.userRole.value >= UserRole.support.value;
  }

  /// True if user has erp+ role (for ERP Dashboard)
  bool get _isErpOrAbove {
    if (!Sint.isRegistered<UserService>()) return false;
    return Sint.find<UserService>().user.userRole.value >= UserRole.erp.value;
  }

  /// True if user is an artist profile and not a basic subscriber
  bool get _isArtistNonSubscriber {
    if (!Sint.isRegistered<UserService>()) return false;
    final service = Sint.find<UserService>();
    return service.profile.type == ProfileType.appArtist
        && service.user.userRole != UserRole.subscriber;
  }

  @override
  void initState() {
    super.initState();
    if (_profileId.isNotEmpty) {
      _loadCounts();
      _pollingTimer = Timer.periodic(const Duration(minutes: 2), (_) => _loadCounts());
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    if (_profileId.isEmpty) return;
    try {
      final results = await Future.wait([
        ActivityFeedFirestore().getUnreadNotificationsCount(_profileId),
        InboxFirestore().getUnreadInboxCount(_profileId),
      ]);
      if (mounted) {
        setState(() {
          _unreadNotifications = results[0];
          _unreadInbox = results[1];
        });
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_home', operation: '_loadCounts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = widget.expanded ? 240 : 72;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      padding: EdgeInsets.only(left: widget.expanded ? 15 : 0),
      decoration: BoxDecoration(
        gradient: AppTheme.appBoxDecoration.gradient,
        border: Border(
          right: BorderSide(color: AppColor.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          // Logo — tap to show app version (same as mobile HomeAppBar)
          GestureDetector(
            onTap: () {
              AppAlerts.showAlert(context, message: "${AppTranslationConstants.version.tr} "
                  "${AppConfig.instance.appVersion}");
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 20,
                horizontal: widget.expanded ? 16 : 0,
              ),
              child: widget.expanded
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(AppAssets.logoCompanyWhite, height: 28, fit: BoxFit.contain),
                    )
                  : Image.asset(AppAssets.logoCompanyWhite, height: 24, fit: BoxFit.contain),
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: HomeTranslationConstants.navHome.tr,
                  expanded: widget.expanded,
                  isActive: widget.currentTabIndex == 0,
                  onTap: () => widget.onTabSelected(0),
                ),
                _NavItem(
                  icon: Icons.search,
                  label: HomeTranslationConstants.navSearch.tr,
                  expanded: widget.expanded,
                  onTap: () {
                    AuthGuard.protect(context, () {
                      // Web: toggle search panel overlay (Instagram-style)
                      if (kIsWeb && Sint.isRegistered<HomeController>()) {
                        Sint.find<HomeController>().toggleSearchPanel();
                      } else {
                        Sint.toNamed(AppRouteConstants.search, arguments: [SearchType.any]);
                      }
                    });
                  },
                ),
                _NavItem(
                  icon: Icons.event_outlined,
                  label: HomeTranslationConstants.navEvents.tr,
                  expanded: widget.expanded,
                  isActive: widget.currentTabIndex == 1,
                  onTap: () => widget.onTabSelected(1),
                ),
                if (AppConfig.instance.appInUse == AppInUse.c)
                  _NavItem(
                    icon: Icons.blur_circular,
                    label: HomeTranslationConstants.navChamber.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.generator),
                  ),
                if (AppConfig.instance.appInUse == AppInUse.c)
                  _NavItem(
                    icon: Icons.compare_arrows,
                    label: HomeTranslationConstants.navInter.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed('/inter'),
                  ),
                if (AppConfig.instance.appInUse == AppInUse.e)
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    label: HomeTranslationConstants.navBooks.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.libraryHome),
                  ),
                if (AppFlavour.showDirectory())
                  _NavItem(
                    icon: Icons.business_outlined,
                    label: HomeTranslationConstants.navDirectory.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.directory),
                  ),
                if (AppFlavour.showBooking())
                  _NavItem(
                    icon: Icons.calendar_month_outlined,
                    label: HomeTranslationConstants.navBooking.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.booking),
                  ),
                if (AppConfig.instance.appInUse == AppInUse.e)
                  _NavItem(
                    icon: Icons.palette,
                    label: HomeTranslationConstants.navGallery.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.museumHome),
                  ),
                if (!kReleaseMode || _isSupportOrAbove)
                  _NavItem(
                    icon: Icons.headphones_outlined,
                    label: HomeTranslationConstants.navAudio.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.audioPlayer),
                  ),
                if (AppFlavour.showBlog())
                  _NavItem(
                    icon: FontAwesomeIcons.gamepad,
                    label: HomeTranslationConstants.navGames.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.games),
                  ),
                if (AppFlavour.showBlog())
                  _NavItem(
                    icon: FontAwesomeIcons.filePen,
                    label: HomeTranslationConstants.navBlog.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.blog),
                  ),
                if (AppFlavour.showVst() && _isSupportOrAbove)
                  _NavItem(
                    icon: FontAwesomeIcons.guitar,
                    label: HomeTranslationConstants.navVst.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.vstHome),
                  ),
                if (AppFlavour.showDaw() && _isSupportOrAbove)
                  _NavItem(
                    icon: FontAwesomeIcons.sliders,
                    label: HomeTranslationConstants.navDaw.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.dawProjects),
                  ),
                if (AppFlavour.showBands() && _isArtistNonSubscriber)
                  _NavItem(
                    icon: Icons.people,
                    label: HomeTranslationConstants.navBands.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.bands),
                  ),

                // Divider
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.expanded ? 16 : 12,
                    vertical: 8,
                  ),
                  child: const Divider(color: Colors.white12, height: 1),
                ),

                // Notifications
                _NavItem(
                  icon: FontAwesomeIcons.bell,
                  label: HomeTranslationConstants.navNotifications.tr,
                  expanded: widget.expanded,
                  badge: _unreadNotifications,
                  onTap: () {
                    AuthGuard.protect(context, () {
                      // Web: toggle notification panel overlay (Instagram-style)
                      if (kIsWeb && Sint.isRegistered<HomeController>()) {
                        Sint.find<HomeController>().toggleNotificationPanel();
                      } else {
                        Sint.toNamed(AppRouteConstants.feedActivity);
                      }
                      Future.delayed(const Duration(seconds: 1), _loadCounts);
                    });
                  },
                ),
                _NavItem(
                  icon: FontAwesomeIcons.comments,
                  label: HomeTranslationConstants.navMessages.tr,
                  expanded: widget.expanded,
                  badge: _unreadInbox,
                  onTap: () {
                    AuthGuard.protect(context, () {
                      Sint.toNamed(AppRouteConstants.inbox);
                      Future.delayed(const Duration(seconds: 1), _loadCounts);
                    });
                  },
                ),
                if (AppFlavour.showAppBarAddBtn())
                  _NavItem(
                    icon: Icons.add_circle_outline,
                    label: HomeTranslationConstants.navCreate.tr,
                    expanded: widget.expanded,
                    onTap: () {
                      AuthGuard.protect(context, () {
                        if (Sint.isRegistered<HomeController>()) {
                          Sint.find<HomeController>().modalBottomAddMenu(context);
                        } else {
                          Sint.toNamed(AppRouteConstants.generator);
                        }
                      });
                    },
                  ),

                // Subscriber/Creator options
                if (_isCreatorOrSupport) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.expanded ? 16 : 12,
                      vertical: 8,
                    ),
                    child: const Divider(color: Colors.white12, height: 1),
                  ),
                  if (AppFlavour.showReleaseUpload() && _isSupportOrAbove)
                    _NavItem(
                      icon: AppFlavour.getAppItemIcon(),
                      label: AppConfig.instance.appInUse == AppInUse.e
                          ? HomeTranslationConstants.navUploadWork.tr
                          : HomeTranslationConstants.navUpload.tr,
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.releaseUpload),
                    ),
                  if (AppFlavour.showNupale())
                    _NavItem(
                      icon: FontAwesomeIcons.bookOpenReader,
                      label: HomeTranslationConstants.navNupale.tr,
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.nupaleHome),
                    ),
                  if (AppFlavour.showCasete())
                    _NavItem(
                      icon: FontAwesomeIcons.solidFileAudio,
                      label: HomeTranslationConstants.navCasete.tr,
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.caseteHome),
                    ),
                  if (AppFlavour.showWallet())
                    _NavItem(
                      icon: FontAwesomeIcons.coins,
                      label: HomeTranslationConstants.navWallet.tr,
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.wallet),
                    ),
                  if (AppFlavour.showServices()) ...[
                    _NavItem(
                      icon: Icons.room_service,
                      label: HomeTranslationConstants.navServices.tr,
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.services),
                    ),
                  ],
                ],
                if (_isErpOrAbove) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.expanded ? 16 : 12,
                      vertical: 8,
                    ),
                    child: const Divider(color: Colors.white12, height: 1),
                  ),
                  _NavItem(
                    icon: Icons.hub,
                    label: HomeTranslationConstants.navErp.tr,
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.erpDashboard),
                  ),
                ],
              ],
            ),
          ),

          // Bottom section: Settings + Profile
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                const Divider(color: Colors.white12, height: 1, indent: 12, endIndent: 12),
                const SizedBox(height: 8),
                if (Sint.isRegistered<SettingsService>())
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: HomeTranslationConstants.navSettings.tr,
                    expanded: widget.expanded,
                    onTap: () {
                      AuthGuard.protect(context, () {
                        Sint.toNamed(AppRouteConstants.settingsPrivacy);
                      });
                    },
                  ),
                _NavItem(
                  leading: platformCircleAvatar(
                    imageUrl: _profileImg.isNotEmpty ? _profileImg : AppProperties.getAppLogoUrl(),
                    radius: 14,
                  ),
                  label: _profileName.isNotEmpty
                      ? '${_profileName[0].toUpperCase()}${_profileName.substring(1)}'
                      : AppTranslationConstants.profile.tr,
                  expanded: widget.expanded,
                  onTap: () {
                    AuthGuard.protect(context, () {
                      Sint.toNamed(AppRouteConstants.profile);
                    });
                  },
                ),
                if (Sint.isRegistered<LoginService>() && !AppConfig.instance.isGuestMode)
                  _NavItem(
                    icon: Icons.logout,
                    label: AppTranslationConstants.logout.tr,
                    expanded: widget.expanded,
                    onTap: () {
                      if (Sint.isRegistered<LoginService>()) {
                        Sint.find<LoginService>().signOut();
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual navigation item for the Instagram-style sidebar.
class _NavItem extends StatefulWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final bool expanded;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.leading,
    required this.label,
    required this.expanded,
    this.isActive = false,
    this.badge = 0,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.expanded ? '' : widget.label,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _isHovered ? Colors.white.withAlpha(18) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Icon or leading widget with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (widget.leading != null)
                      widget.leading!
                    else
                      Icon(
                        widget.icon,
                        color: widget.isActive ? Colors.white : AppColor.lightGrey,
                        size: 24,
                      ),
                    // Badge — only show in expanded mode to avoid overflow
                    if (widget.badge > 0 && widget.expanded)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            widget.badge > 99 ? '99+' : widget.badge.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    // Collapsed mode: small dot indicator for badge
                    if (widget.badge > 0 && !widget.expanded)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),

                // Label (expanded mode only)
                if (widget.expanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isActive ? Colors.white : AppColor.lightGrey,
                        fontSize: 15,
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
