import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/event_firestore.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/position_utilities.dart';
import 'package:sint/sint.dart';

class WebUpcomingEvents extends StatefulWidget {
  const WebUpcomingEvents({super.key});

  @override
  State<WebUpcomingEvents> createState() => _WebUpcomingEventsState();
}

class _WebUpcomingEventsState extends State<WebUpcomingEvents> {
  List<Event> _events = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUpcomingEvents();
  }

  Future<void> _loadUpcomingEvents() async {
    if (!Sint.isRegistered<UserService>()) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    try {
      final userService = Sint.find<UserService>();
      final userPos = userService.profile.position;

      // Fetch events from firestore
      final allEventsMap = await EventFirestore().getEvents();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final upcomingEvents = allEventsMap.values.where((event) {
        // Handle both seconds and milliseconds since epoch
        final epoch = event.eventDate;
        final ms = epoch > 100000000000 ? epoch : epoch * 1000;
        return ms >= nowMs;
      }).toList();

      if (upcomingEvents.isEmpty) {
        if (mounted) setState(() => _loaded = true);
        return;
      }

      // Sort by proximity to user
      if (userPos != null) {
        upcomingEvents.sort((a, b) {
          if (a.position == null && b.position == null) return 0;
          if (a.position == null) return 1;
          if (b.position == null) return -1;
          final distA = PositionUtilities.distanceBetweenPositions(userPos, a.position!);
          final distB = PositionUtilities.distanceBetweenPositions(userPos, b.position!);
          return distA.compareTo(distB);
        });
      }

      // Cache distances in model property for display
      for (final event in upcomingEvents) {
        if (userPos != null && event.position != null) {
          event.distanceKm = PositionUtilities.distanceBetweenPositions(userPos, event.position!).round();
        }
      }

      if (mounted) {
        setState(() {
          _events = upcomingEvents.take(3).toList();
          _loaded = true;
        });
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_home', operation: '_loadUpcomingEvents');
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _events.isEmpty) return const SizedBox.shrink();

    final languageCode = Sint.locale?.languageCode ?? 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          CommonTranslationConstants.comingEvents.tr,
          style: TextStyle(
            color: AppColor.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Event list
        ..._events.map((event) {
          final epoch = event.eventDate;
          final dt = DateTime.fromMillisecondsSinceEpoch(epoch > 100000000000 ? epoch : epoch * 1000);
          final shortDay = DateFormat.E(languageCode).format(dt);
          final dayStr = DateFormat.d(languageCode).format(dt);
          final hourStr = DateFormat.jm(languageCode).format(dt);

          final distanceText = event.distanceKm > 0
              ? ' • ${event.distanceKm.toStringAsFixed(1)} km'
              : '';

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Sint.toNamed(
                '${AppRouteConstants.eventDetails}/${event.id}',
                arguments: event,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    // Glassmorphic Date Badge
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.getMain().withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColor.getMain().withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shortDay.toUpperCase(),
                            style: TextStyle(
                              color: AppColor.getMain(),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            dayStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Event info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$hourStr${(event.place?.name ?? '').isNotEmpty ? ' • ${event.place!.name}' : ''}$distanceText',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
