import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:sint/sint.dart';

import '../widgets/app_bar_icon_badge.dart';

class WebTopBar extends StatefulWidget implements PreferredSizeWidget {
  final int currentTabIndex;
  final Function(int) onTabSelected;

  const WebTopBar({
    super.key,
    required this.currentTabIndex,
    required this.onTabSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<WebTopBar> createState() => _WebTopBarState();
}

class _WebTopBarState extends State<WebTopBar> {
  Timer? _pollingTimer;
  int _unreadNotifications = 0;
  int _unreadInbox = 0;

  String get _profileId => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.id
      : '';

  String get _profileImg => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.photoUrl
      : '';

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
      AppConfig.logger.e("WebTopBar: Error loading counts: $e");
    }
  }

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.event_rounded, label: 'Eventos'),
    (icon: Icons.menu_book_rounded, label: 'Libros'),
    (icon: Icons.headphones_rounded, label: 'Audio'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColor.appBar,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Image.asset(AppAssets.logoCompanyWhite, height: 28, fit: BoxFit.contain),
          ),

          // Center tabs
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_tabs.length, (i) => _buildTab(i)),
            ),
          ),

          // Right actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(AppFlavour.showAppBarAddBtn()) IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                color: Colors.white70,
                tooltip: 'Crear',
                onPressed: () => Sint.toNamed(AppRouteConstants.generator),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
                color: Colors.white70,
                tooltip: 'Buscar',
                onPressed: () => Sint.toNamed(AppRouteConstants.search, arguments: [SearchType.any]),
              ),
              AppBarIconBadge(
                icon: FontAwesomeIcons.bell,
                count: _unreadNotifications,
                onPressed: () {
                  AuthGuard.protect(context, () {
                    Sint.toNamed(AppRouteConstants.feedActivity);
                    Future.delayed(const Duration(seconds: 1), _loadCounts);
                  });
                },
              ),
              AppBarIconBadge(
                icon: FontAwesomeIcons.comments,
                count: _unreadInbox,
                onPressed: () {
                  AuthGuard.protect(context, () {
                    Sint.toNamed(AppRouteConstants.inbox);
                    Future.delayed(const Duration(seconds: 1), _loadCounts);
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => Sint.toNamed(AppRouteConstants.profile),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      _profileImg.isNotEmpty ? _profileImg : AppProperties.getAppLogoUrl(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final isSelected = widget.currentTabIndex == index;
    final tab = _tabs[index];
    return Tooltip(
      message: tab.label,
      child: InkWell(
        onTap: () => widget.onTabSelected(index),
        child: Container(
          width: 80,
          height: 56,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Icon(
            tab.icon,
            color: isSelected ? Colors.white : Colors.white54,
            size: 24,
          ),
        ),
      ),
    );
  }
}
