import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_core/domain/use_cases/shop_cart_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:sint/sint.dart';

import '../home_controller.dart';
import 'app_bar_icon_badge.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {

  final String profileImg;
  final String profileId;

  const HomeAppBar({
    required this.profileImg,
    required this.profileId,
    super.key
  });

  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {

  // Variable para controlar la notificación falsa (modo guest)
  bool showFakeNotification = false;
  Timer? _guestTimer;
  Timer? _pollingTimer;

  // OPTIMIZED: Use cached counts instead of real-time streams to reduce Firestore reads
  int _unreadNotificationsCount = 0;
  int _unreadInboxCount = 0;
  bool _isLoadingCounts = false;
  bool _unreadLoaded = false;

  // Cache duration - fetch every 2 minutes instead of real-time
  static const _pollInterval = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _startGuestTimer();
    if (widget.profileId.isNotEmpty) {
      // OPTIMIZED: Load counts once on init, then poll periodically
      _loadUnreadCounts();
      _startPollingTimer();
    }
  }

  @override
  void didUpdateWidget(HomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo volvemos a llamar a Firebase si el ID del usuario CAMBIÓ
    if (widget.profileId != oldWidget.profileId) {
      _pollingTimer?.cancel();
      if (widget.profileId.isNotEmpty) {
        _loadUnreadCounts();
        _startPollingTimer();
      } else {
        _unreadNotificationsCount = 0;
        _unreadInboxCount = 0;
      }
    }
  }

  /// OPTIMIZED: Start periodic polling instead of real-time streams
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted && widget.profileId.isNotEmpty) {
        _loadUnreadCounts();
      }
    });
  }

  /// OPTIMIZED: Load counts with a single Future call instead of continuous streams
  Future<void> _loadUnreadCounts() async {
    if (_unreadLoaded ||_isLoadingCounts || widget.profileId.isEmpty) return;
    _isLoadingCounts = true;

    try {
      // Fetch both counts in parallel
      final results = await Future.wait([
        ActivityFeedFirestore().getUnreadNotificationsCount(widget.profileId),
        InboxFirestore().getUnreadInboxCount(widget.profileId),
      ]);

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = results[0];
          _unreadInboxCount = results[1];
        });
      }
    } catch (e) {
      AppConfig.logger.e("Error loading unread counts: $e");
    } finally {
      _isLoadingCounts = false;
    }

    _unreadLoaded = true;
  }

  /// Public method to refresh counts (can be called after viewing notifications/inbox)
  void refreshUnreadCounts() {
    _loadUnreadCounts();
  }

  void _startGuestTimer() {
    // Verificamos si es Guest y si el perfil está vacío (indicador de no logueado)
    if (widget.profileId.isEmpty && AppConfig.instance.isGuestMode) {
      _guestTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            showFakeNotification = true;
            AppConfig.logger.d("Triggering fake guest notification");
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _guestTimer?.cancel();
    _pollingTimer?.cancel(); // OPTIMIZED: Cancel polling timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColor.surfaceElevated,
      elevation: 0.0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: platformCircleAvatar(
            imageUrl: widget.profileImg.isNotEmpty
                ? widget.profileImg : AppProperties.getAppLogoUrl(),
            radius: 60,
        ),
        onPressed: () {
          AuthGuard.protect(context, () {
            Scaffold.of(context).openDrawer();
          });
        },
      ),
      title: GestureDetector(
          child: Image.asset(
            AppAssets.logoCompanyWhite,
            height: 25,
            fit: BoxFit.contain,
          ),
          onTap: () {
            AppAlerts.showAlert(context, message: "${AppTranslationConstants.version.tr} "
                "${AppConfig.instance.appVersion}${kDebugMode ? " - Dev Mode" : ""}");
          }
      ),
      actionsIconTheme: const IconThemeData(size: 18),
      actions: <Widget>[
        if(AppFlavour.showAppBarAddBtn()) IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_box_outlined, size: 25,),
            color: Colors.white70,
            onPressed: () {
              if(!Sint.isRegistered<HomeController>()) {
                AppConfig.logger.d("HomeController not registered, registering now");
                Sint.put(HomeController());
              }
              Sint.find<HomeController>().modalBottomAddMenu(context);
            }
        ),
        if(AppFlavour.showAppBarDirectoryBtn()) IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.building),
            color: Colors.white70,
            onPressed: () {
              Sint.toNamed(AppRouteConstants.directory);
            }
        ),
        _buildCartBadge(),
        buildNotificationFeed(context),
        IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.magnifyingGlass),
            color: Colors.white70,
            onPressed: () {
              AuthGuard.protect(context, () {
                Sint.toNamed(AppRouteConstants.search, arguments: [SearchType.any]);
              });
            },
        ),
        buildInboxIcon(context),
      ],
    );
  }

  /// OPTIMIZED: Construye el ícono de notificaciones con badge usando polling en lugar de streams.
  Widget buildNotificationFeed(BuildContext context) {
    int displayCount = widget.profileId.isEmpty && showFakeNotification
        ? 1
        : _unreadNotificationsCount;

    return AppBarIconBadge(
      icon: FontAwesomeIcons.bell,
      count: displayCount,
      onPressed: () {
        AuthGuard.protect(context, () {
          Sint.toNamed(AppRouteConstants.feedActivity);
          // Refresh counts after viewing notifications
          Future.delayed(const Duration(seconds: 1), () => refreshUnreadCounts());
        });
      },
    );
  }

  /// OPTIMIZED: Construye el ícono de inbox/mensajes con badge usando polling en lugar de streams.
  Widget buildInboxIcon(BuildContext context) {
    int displayCount = widget.profileId.isEmpty && showFakeNotification
        ? 1
        : _unreadInboxCount;

    return AppBarIconBadge(
      icon: FontAwesomeIcons.comments,
      count: displayCount,
      onPressed: () {
        AuthGuard.protect(context, () {
          Sint.toNamed(AppRouteConstants.inbox);
          // Refresh counts after viewing inbox
          Future.delayed(const Duration(seconds: 1), () => refreshUnreadCounts());
        });
      },
    );
  }

  /// Cart badge icon — only visible when ShopCartService is registered (e.g. EMXI).
  Widget _buildCartBadge() {
    try {
      final cartService = Sint.find<ShopCartService>();
      return Obx(() {
        final count = cartService.itemCount;
        return IconButton(
          padding: EdgeInsets.zero,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 22),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColor.bondiBlue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          color: Colors.white70,
          onPressed: () {
            Sint.toNamed(AppRouteConstants.shopCart);
          },
        );
      });
    } catch (_) {
      // ShopCartService not registered — hide the cart icon
      return const SizedBox.shrink();
    }
  }
}
