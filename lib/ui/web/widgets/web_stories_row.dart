import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../../domain/models/story_data.dart';
import '../../../utils/constants/home_translation_constants.dart';

/// Web-optimized stories row displayed at the top of the center feed.
/// Self-contained — queries Firestore directly without neom_stories dependency.
class WebStoriesRow extends StatefulWidget {
  const WebStoriesRow({super.key});

  @override
  State<WebStoriesRow> createState() => _WebStoriesRowState();
}

class _WebStoriesRowState extends State<WebStoriesRow> {
  List<StoryData> _stories = [];
  bool _loaded = false;

  String get _profileId => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.id
      : '';

  String get _profileAvatarUrl => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.photoUrl
      : '';

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    if (_profileId.isEmpty) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final profile = Sint.find<UserService>().profile;
      final followingIds = [profile.id,
        ...List<String>.from(profile.following ?? [])];
      final stories = await _fetchActiveStories(followingIds);

      if (mounted) {
        setState(() {
          _stories = stories;
          _loaded = true;
        });
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_home', operation: '_loadStories');
      if (mounted) setState(() => _loaded = true);
    }
  }

  /// Fetches active (non-expired) stories from Firestore for the given user IDs.
  /// Handles the Firestore `whereIn` limit of 10 by chunking.
  Future<List<StoryData>> _fetchActiveStories(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final storiesRef = FirebaseFirestore.instance
        .collection(AppFirestoreCollectionConstants.stories);
    final List<StoryData> allStories = [];

    // Chunk IDs (Firestore whereIn limit = 10)
    for (var i = 0; i < userIds.length; i += 10) {
      final chunk = userIds.sublist(
        i,
        i + 10 > userIds.length ? userIds.length : i + 10,
      );
      final snapshot = await storiesRef
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: now)
          .where('ownerId', whereIn: chunk)
          .orderBy('createdTime', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        allStories.add(StoryData.fromMap(doc.data()));
      }
    }
    return allStories;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    // Group stories by owner
    final Map<String, List<StoryData>> grouped = {};
    for (final story in _stories) {
      grouped.putIfAbsent(story.ownerId, () => []).add(story);
    }
    final ownerIds = grouped.keys.toList();

    // If no stories and no logged-in user, hide entirely
    if (ownerIds.isEmpty && _profileId.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 95,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColor.white10),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ownerIds.length + 1, // +1 for "create" circle
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) return _buildCreateCircle();

          final ownerId = ownerIds[index - 1];
          final ownerStories = grouped[ownerId]!;
          final first = ownerStories.first;
          final hasUnseen = ownerStories.any(
            (s) => !s.viewerIds.contains(_profileId),
          );

          return _WebStoryCircle(
            avatarUrl: first.ownerAvatarUrl,
            name: first.ownerName,
            hasUnseen: hasUnseen,
            onTap: () {
              Sint.toNamed(
                AppRouteConstants.storyViewer,
                arguments: [_stories.indexOf(first)],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCreateCircle() {
    return GestureDetector(
      onTap: () => Sint.toNamed(AppRouteConstants.storyCreate),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                platformCircleAvatar(
                  imageUrl: _profileAvatarUrl,
                  radius: 26,
                  backgroundColor: Colors.grey.shade800,
                  child: _profileAvatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 26, color: Colors.white54)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColor.getMain(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              HomeTranslationConstants.yourStory.tr,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Instagram-style story circle with gradient ring indicator.
class _WebStoryCircle extends StatefulWidget {
  final String avatarUrl;
  final String name;
  final bool hasUnseen;
  final VoidCallback onTap;

  const _WebStoryCircle({
    required this.avatarUrl,
    required this.name,
    required this.hasUnseen,
    required this.onTap,
  });

  @override
  State<_WebStoryCircle> createState() => _WebStoryCircleState();
}

class _WebStoryCircleState extends State<_WebStoryCircle> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: 62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.hasUnseen
                        ? const LinearGradient(
                            colors: [Color(0xFFDE0046), Color(0xFFF7A34B)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : null,
                    border: widget.hasUnseen
                        ? null
                        : Border.all(color: Colors.grey.shade700, width: 2),
                  ),
                  child: platformCircleAvatar(
                    imageUrl: widget.avatarUrl,
                    radius: 23,
                    backgroundColor: Colors.grey.shade900,
                    child: widget.avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 22, color: Colors.white38)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.name.isNotEmpty ? widget.name : '...',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
