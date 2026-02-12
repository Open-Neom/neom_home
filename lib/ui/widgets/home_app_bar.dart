import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';

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

  // Streams para conteo en tiempo real
  Stream<int>? _unreadNotificationsStream;
  Stream<int>? _unreadInboxStream;

  @override
  void initState() {
    super.initState();
    _startGuestTimer();
    if (widget.profileId.isNotEmpty) {
      _unreadNotificationsStream = ActivityFeedFirestore().getUnreadNotificationsCountStream(widget.profileId);
      _unreadInboxStream = InboxFirestore().getUnreadInboxCountStream(widget.profileId);
    }
  }

  @override
  void didUpdateWidget(HomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo volvemos a llamar a Firebase si el ID del usuario CAMBIÓ
    if (widget.profileId != oldWidget.profileId) {
      if (widget.profileId.isNotEmpty) {
        _unreadNotificationsStream = ActivityFeedFirestore().getUnreadNotificationsCountStream(widget.profileId);
        _unreadInboxStream = InboxFirestore().getUnreadInboxCountStream(widget.profileId);
      } else {
        _unreadNotificationsStream = null;
        _unreadInboxStream = null;
      }
    }
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
    _guestTimer?.cancel(); // Limpiamos el timer para evitar fugas de memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColor.appBar,
      elevation: 0.0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: CircleAvatar(
            maxRadius: 60,
            backgroundImage: CachedNetworkImageProvider(widget.profileImg.isNotEmpty
                ? widget.profileImg : AppProperties.getAppLogoUrl())
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
        buildNotificationFeed(context),
        IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.magnifyingGlass),
            color: Colors.white70,
            onPressed: () => {
              Sint.toNamed(AppRouteConstants.search, arguments: [SearchType.any])
            }
        ),
        buildInboxIcon(context),
      ],
    );
  }

  /// Construye el ícono de notificaciones con badge de conteo en tiempo real.
  Widget buildNotificationFeed(BuildContext context) {
    // Si no hay stream (usuario no logueado), mostrar sin badge o con fake
    if (_unreadNotificationsStream == null) {
      return AppBarIconBadge(
        icon: FontAwesomeIcons.bell,
        count: showFakeNotification ? 1 : 0,
        onPressed: () {
          AuthGuard.protect(context, () {
            Sint.toNamed(AppRouteConstants.feedActivity);
          });
        },
      );
    }

    return StreamBuilder<int>(
      stream: _unreadNotificationsStream,
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          unreadCount = snapshot.data!;
        } else if (showFakeNotification) {
          unreadCount = 1;
        }

        return AppBarIconBadge(
          icon: FontAwesomeIcons.bell,
          count: unreadCount,
          onPressed: () {
            AuthGuard.protect(context, () {
              Sint.toNamed(AppRouteConstants.feedActivity);
            });
          },
        );
      },
    );
  }

  /// Construye el ícono de inbox/mensajes con badge de conteo en tiempo real.
  Widget buildInboxIcon(BuildContext context) {
    // Si no hay stream (usuario no logueado), mostrar sin badge o con fake
    if (_unreadInboxStream == null) {
      return AppBarIconBadge(
        icon: FontAwesomeIcons.comments,
        count: showFakeNotification ? 1 : 0,
        onPressed: () {
          AuthGuard.protect(context, () {
            Sint.toNamed(AppRouteConstants.inbox);
          });
        },
      );
    }

    return StreamBuilder<int>(
      stream: _unreadInboxStream,
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          unreadCount = snapshot.data!;
        } else if (showFakeNotification) {
          // Para usuarios guest, mostrar 1 mensaje falso
          unreadCount = 1;
        }

        return AppBarIconBadge(
          icon: FontAwesomeIcons.comments,
          count: unreadCount,
          onPressed: () {
            AuthGuard.protect(context, () {
              Sint.toNamed(AppRouteConstants.inbox);
            });
          },
        );
      },
    );
  }
}
