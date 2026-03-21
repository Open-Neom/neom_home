import 'dart:math';

import 'package:flutter/material.dart';
import 'package:neom_commons/ui/models/literary_game_info.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_home/utils/constants/home_translation_constants.dart';
import 'package:sint/sint.dart';

/// Compact literary games section for the right sidebar (300px).
/// Shows 3 random games as clickable rows with colored accents.
class WebSidebarGames extends StatefulWidget {
  const WebSidebarGames({super.key});

  @override
  State<WebSidebarGames> createState() => _WebSidebarGamesState();
}

class _WebSidebarGamesState extends State<WebSidebarGames> {
  late List<LiteraryGameInfo> _selectedGames;

  @override
  void initState() {
    super.initState();
    final shuffled = List<LiteraryGameInfo>.from(LiteraryGameInfo.allGames)
      ..shuffle(Random());
    _selectedGames = shuffled.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              CommonTranslationConstants.literaryGames.tr,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.games),
              child: Text(
                HomeTranslationConstants.seeAll.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Game rows
        ..._selectedGames.map((game) => _SidebarGameRow(game: game)),
      ],
    );
  }
}

/// A single compact game row for the sidebar.
class _SidebarGameRow extends StatefulWidget {
  final LiteraryGameInfo game;

  const _SidebarGameRow({required this.game});

  @override
  State<_SidebarGameRow> createState() => _SidebarGameRowState();
}

class _SidebarGameRowState extends State<_SidebarGameRow> {
  bool _hovered = false;

  /// Normalizes color brightness for readability on dark background.
  Color _normalizeColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = hsl.lightness < 0.5 ? 0.6 : hsl.lightness;
    final adjustedSaturation = hsl.saturation > 0.8 ? 0.75 : hsl.saturation;
    return hsl
        .withLightness(adjustedLightness.clamp(0.5, 0.75))
        .withSaturation(adjustedSaturation)
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = _normalizeColor(widget.game.color);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Sint.toNamed(widget.game.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? displayColor.withValues(alpha: 0.12)
                : Colors.grey.shade900.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: displayColor.withValues(alpha: 0.7),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      displayColor.withValues(alpha: 0.25),
                      displayColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.game.icon, size: 16, color: displayColor),
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  widget.game.titleKey.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Play arrow
              Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: displayColor.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
