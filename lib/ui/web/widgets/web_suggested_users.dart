import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/home_translation_constants.dart';

/// Instagram-style "Suggestions for you" widget.
/// Shows followers the user doesn't follow back.
class WebSuggestedUsers extends StatefulWidget {
  const WebSuggestedUsers({super.key});

  @override
  State<WebSuggestedUsers> createState() => _WebSuggestedUsersState();
}

class _WebSuggestedUsersState extends State<WebSuggestedUsers> {
  List<AppProfile> _suggestions = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (!Sint.isRegistered<UserService>()) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    try {
      final profile = Sint.find<UserService>().profile;
      final followers = profile.followers ?? [];
      final following = profile.following ?? [];

      // Find followers the user doesn't follow back
      final notFollowedBack = followers.where((id) => !following.contains(id)).take(8).toList();

      if (notFollowedBack.isEmpty) {
        if (mounted) setState(() => _loaded = true);
        return;
      }

      final firestore = ProfileFirestore();
      final List<AppProfile> profiles = [];

      for (final id in notFollowedBack.take(5)) {
        try {
          final p = await firestore.retrieve(id);
          if (p.id.isNotEmpty && p.name.isNotEmpty) {
            profiles.add(p);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _suggestions = profiles;
          _loaded = true;
        });
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_home', operation: '_loadSuggestions');
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              HomeTranslationConstants.suggestionsForYou.tr,
              style: TextStyle(color: AppColor.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.search),
              child: Text(
                HomeTranslationConstants.seeAll.tr,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Suggestion rows
        ...(_suggestions.map((profile) => _SuggestionRow(
          profile: profile,
          onFollowed: () {
            // Remove from suggestions after following
            if (mounted) {
              setState(() {
                _suggestions.removeWhere((p) => p.id == profile.id);
              });
            }
          },
        ))),
      ],
    );
  }
}

class _SuggestionRow extends StatefulWidget {
  final AppProfile profile;
  final VoidCallback? onFollowed;
  const _SuggestionRow({required this.profile, this.onFollowed});

  @override
  State<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends State<_SuggestionRow> {
  bool _isFollowing = false;
  bool _isLoading = false;

  Future<void> _handleFollow() async {
    if (_isLoading || _isFollowing) return;

    setState(() => _isLoading = true);

    try {
      final userService = Sint.find<UserService>();
      final myProfileId = userService.profile.id;

      final success = await ProfileFirestore().followProfile(
        profileId: myProfileId,
        followedProfileId: widget.profile.id,
      );

      if (success) {
        // Update local following list
        userService.profile.following ??= [];
        userService.profile.following!.add(widget.profile.id);

        if (mounted) {
          setState(() {
            _isFollowing = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_home', operation: '_handleFollow');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Sint.toNamed(AppRouteConstants.matePath(widget.profile.id), arguments: widget.profile.id),
            child: platformCircleAvatar(
              imageUrl: widget.profile.photoUrl.isNotEmpty ? widget.profile.photoUrl : AppProperties.getAppLogoUrl(),
              radius: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.matePath(widget.profile.id), arguments: widget.profile.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.profile.aboutMe.isNotEmpty)
                    Text(
                      widget.profile.aboutMe,
                      style: TextStyle(color: AppColor.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isLoading
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              )
            : GestureDetector(
                onTap: _isFollowing ? null : _handleFollow,
                child: Text(
                  _isFollowing ? HomeTranslationConstants.followed.tr : HomeTranslationConstants.follow.tr,
                  style: TextStyle(
                    color: _isFollowing ? AppColor.textMuted : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
