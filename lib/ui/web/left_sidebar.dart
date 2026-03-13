import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_core/app_config.dart';
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

  String get _profileImg => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.photoUrl
      : '';

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
    } catch (e) {
      AppConfig.logger.e("LeftSidebar: Error loading counts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = widget.expanded ? 220 : 72;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
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
                  label: 'Inicio',
                  expanded: widget.expanded,
                  isActive: widget.currentTabIndex == 0,
                  onTap: () => widget.onTabSelected(0),
                ),
                _NavItem(
                  icon: Icons.search,
                  label: 'Buscar',
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
                  label: 'Eventos',
                  expanded: widget.expanded,
                  isActive: widget.currentTabIndex == 1,
                  onTap: () => widget.onTabSelected(1),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Libros',
                  expanded: widget.expanded,
                  onTap: () => Sint.toNamed(AppRouteConstants.libraryHome),
                ),
                _NavItem(
                  icon: Icons.palette,
                  label: 'Galería',
                  expanded: widget.expanded,
                  onTap: () => Sint.toNamed(AppRouteConstants.museumHome),
                ),
                if (!kReleaseMode || _isSupportOrAbove)
                  _NavItem(
                    icon: Icons.headphones_outlined,
                    label: 'Audio',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.audioPlayer),
                  ),
                if (AppFlavour.showBlog())
                  _NavItem(
                    icon: FontAwesomeIcons.gamepad,
                    label: 'Juegos',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.games),
                  ),
                if (AppFlavour.showBlog())
                  _NavItem(
                    icon: FontAwesomeIcons.filePen,
                    label: 'Blog',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.blog),
                  ),
                if (AppFlavour.showVst())
                  _NavItem(
                    icon: FontAwesomeIcons.guitar,
                    label: 'VST',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.vstHome),
                  ),
                if (AppFlavour.showDaw())
                  _NavItem(
                    icon: FontAwesomeIcons.sliders,
                    label: 'DAW',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.dawProjects),
                  ),
                if (AppFlavour.showLearning())
                  _NavItem(
                    icon: Icons.school,
                    label: 'Aprender',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.learning),
                  ),
                if (AppFlavour.showBands() && _isArtistNonSubscriber)
                  _NavItem(
                    icon: Icons.people,
                    label: 'Bandas',
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
                  label: 'Notificaciones',
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
                  label: 'Mensajes',
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
                    label: 'Crear',
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
                  if (AppFlavour.showNupale())
                    _NavItem(
                      icon: FontAwesomeIcons.bookOpenReader,
                      label: 'NUPALE',
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.nupaleHome),
                    ),
                  if (AppFlavour.showCasete())
                    _NavItem(
                      icon: FontAwesomeIcons.solidFileAudio,
                      label: 'CASETE',
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.caseteHome),
                    ),
                  if (AppFlavour.showReleaseUpload() && _isSupportOrAbove)
                    _NavItem(
                      icon: AppFlavour.getAppItemIcon(),
                      label: 'Subir',
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.releaseUpload),
                    ),
                  if (AppFlavour.showWallet())
                    _NavItem(
                      icon: FontAwesomeIcons.coins,
                      label: 'Wallet',
                      expanded: widget.expanded,
                      onTap: () => Sint.toNamed(AppRouteConstants.wallet),
                    ),
                  if (AppFlavour.showServices()) ...[
                    _NavItem(
                      icon: Icons.room_service,
                      label: 'Servicios',
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
                    icon: Icons.analytics,
                    label: 'ERP',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.erpDashboard),
                  ),
                  _NavItem(
                    icon: Icons.hub,
                    label: 'Hub',
                    expanded: widget.expanded,
                    onTap: () => Sint.toNamed(AppRouteConstants.hubDashboard),
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
                    label: 'Configuracion',
                    expanded: widget.expanded,
                    onTap: () {
                      AuthGuard.protect(context, () {
                        Sint.toNamed(AppRouteConstants.settingsPrivacy);
                      });
                    },
                  ),
                _NavItem(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundImage: AppProperties.getAppLogoUrl().isNotEmpty
                        ? NetworkImage(AppProperties.getAppLogoUrl())
                        : null,
                  ),
                  label: _profileName.isNotEmpty ? _profileName : 'Perfil',
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
            margin: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 8 : 8,
              vertical: 2,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 12 : 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _isHovered ? Colors.white.withAlpha(18) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
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
                    // Badge
                    if (widget.badge > 0)
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
