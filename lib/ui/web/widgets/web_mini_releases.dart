import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:sint/sint.dart';

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
              'Novedades',
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to audio or shelf details
                if (items.isNotEmpty) AppFlavour.navigateToShelfItem(items.first);
              },
              child: const Text(
                'Ver todo',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Release covers row
        Row(
          children: items.asMap().entries.map((entry) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry.key < items.length - 1 ? 8 : 0),
              child: _ReleaseCover(item: entry.value),
            ),
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
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
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
        ),
      ),
    );
  }
}
