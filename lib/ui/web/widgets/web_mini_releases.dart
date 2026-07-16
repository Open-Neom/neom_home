import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/home_translation_constants.dart';

/// Compact release shelf for the right sidebar.
/// Shows up to 4 release covers in a horizontal row.
class WebMiniReleases extends StatelessWidget {
  const WebMiniReleases({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Sint.isRegistered<TimelineService>()) return const SizedBox.shrink();

    final controller = Sint.find<TimelineService>();
    final items = controller.mainItems.values.take(4).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              HomeTranslationConstants.newReleases.tr,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to audio or shelf details
                if (items.isNotEmpty) AppFlavour.navigateToShelfItem(items.first);
              },
              child: Text(
                HomeTranslationConstants.seeAll.tr,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Release covers list (Vertical)
        Column(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReleaseCover(item: item),
          )).toList(),
        ),
      ],
    );
  }
}

class _ReleaseCover extends StatefulWidget {
  final AppReleaseItem item;
  const _ReleaseCover({required this.item});

  @override
  State<_ReleaseCover> createState() => _ReleaseCoverState();
}

class _ReleaseCoverState extends State<_ReleaseCover> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => AppFlavour.navigateToShelfItem(widget.item),
        onLongPress: () => Sint.toNamed(
          AppFlavour.getMainItemDetailsRoute(widget.item.id),
          arguments: [widget.item],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // 1. Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: platformNetworkImage(
                    imageUrl: widget.item.imgUrl.isNotEmpty
                        ? widget.item.imgUrl
                        : AppProperties.getAppLogoUrl(),
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.album, color: Colors.white38, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Title & Artist Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Play Icon Indicator
              Icon(
                Icons.play_arrow_rounded,
                color: _isHovered ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
