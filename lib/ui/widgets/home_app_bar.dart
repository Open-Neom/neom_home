import 'dart:async'; // Importar para el Timer si se requiere manejo avanzado, o usar Future.delayed
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
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
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';

import '../home_controller.dart';

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

  // 2. Variable para controlar la notificación falsa
  bool showFakeNotification = false;
  Timer? _guestTimer;
  Future<List<ActivityFeed>>? _activityFeedFuture;

  @override
  void initState() {
    super.initState();
    _startGuestTimer();
    if (widget.profileId.isNotEmpty) {
      _activityFeedFuture = ActivityFeedFirestore().retrieve(widget.profileId);
    }
  }

  @override
  void didUpdateWidget(HomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 3. Seguridad: Solo volvemos a llamar a Firebase si el ID del usuario CAMBIÓ
    if (widget.profileId != oldWidget.profileId) {
      if (widget.profileId.isNotEmpty) {
        _activityFeedFuture = ActivityFeedFirestore().retrieve(widget.profileId);
      } else {
        _activityFeedFuture = null;
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
            fit: BoxFit.fitHeight,
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
              if(!Get.isRegistered<HomeController>()) {
                AppConfig.logger.d("HomeController not registered, registering now");
                Get.put(HomeController());
              }
              Get.find<HomeController>().modalBottomAddMenu(context);
            }
        ),
        if(AppFlavour.showAppBarDirectoryBtn()) IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.building),
            color: Colors.white70,
            onPressed: () {
              Get.toNamed(AppRouteConstants.directory);
            }
        ),
        buildNotificationFeed(context),
        IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.magnifyingGlass),
            color: Colors.white70,
            onPressed: () => {
              Get.toNamed(AppRouteConstants.search, arguments: [SearchType.any])
            }
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(FontAwesomeIcons.comments),
          color: Colors.white70,
          onPressed: () {
            AuthGuard.protect(context, () {
              Get.toNamed(AppRouteConstants.inbox);
            });
          } ,
        ),
      ],
    );
  }

  Widget buildNotificationFeed(BuildContext context) {
    return Stack(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(FontAwesomeIcons.bell),
            color: Colors.white70,
            onPressed: () {
              // El AuthGuard interceptará esto y pedirá registro
              AuthGuard.protect(context, () {
                Get.toNamed(AppRouteConstants.feedActivity);
              });
            },
          ),
          FutureBuilder<List<ActivityFeed>>(
            future: _activityFeedFuture,
            builder: (context, snapshot) {

              int unreadCount = 0;

              if(snapshot.hasData) {
                List<ActivityFeed> unreadActivityFeed = [];
                for (var activityFeed in snapshot.data!) {
                  if(activityFeed.unread) {
                    unreadActivityFeed.add(activityFeed);
                  }
                }
                unreadCount = unreadActivityFeed.length;
              } else if (showFakeNotification) {
                unreadCount = 1;
              }

              if(unreadCount > 0) {
                return Positioned(
                  right: 11, top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15, minHeight: 15,
                    ),
                    child: Text(unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          )
          // CASO USUARIO REAL (Lógica original)

        ]);
  }
}
