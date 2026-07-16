import 'dart:math';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/position_utilities.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/home_translation_constants.dart';

class ProfileWithDistance {
  final AppProfile profile;
  final double distance;
  ProfileWithDistance(this.profile, this.distance);
}

class WebSuggestedUsersNearby extends StatefulWidget {
  const WebSuggestedUsersNearby({super.key});

  @override
  State<WebSuggestedUsersNearby> createState() => _WebSuggestedUsersNearbyState();
}

class _WebSuggestedUsersNearbyState extends State<WebSuggestedUsersNearby> {
  List<ProfileWithDistance> _suggestions = [];
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
      final userService = Sint.find<UserService>();
      final myProfile = userService.profile;
      final userPos = myProfile.position;

      // Fetch profiles
      final profilesMap = await ProfileFirestore().retrieveAllProfiles(limit: 50);
      final allProfiles = profilesMap.values.toList();

      final following = myProfile.following ?? [];

      // Filter: not self and not already following
      final potentialMates = allProfiles.where((p) {
        return p.id.isNotEmpty && p.id != myProfile.id && !following.contains(p.id);
      }).toList();

      if (potentialMates.isEmpty) {
        if (mounted) setState(() => _loaded = true);
        return;
      }

      final List<ProfileWithDistance> sortedMates = [];
      for (final p in potentialMates) {
        double dist = 0;
        if (userPos != null && p.position != null) {
          dist = PositionUtilities.distanceBetweenPositions(userPos, p.position!);
        } else {
          // If no location, give them a high distance to rank lower
          dist = 9999.0;
        }
        sortedMates.add(ProfileWithDistance(p, dist));
      }

      // Sort by proximity
      sortedMates.sort((a, b) => a.distance.compareTo(b.distance));

      if (mounted) {
        setState(() {
          _suggestions = sortedMates.take(5).toList();
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
              style: TextStyle(
                color: AppColor.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.search),
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

        // Suggestion rows
        ..._suggestions.map((suggestion) => _NearbySuggestionRow(
              suggestion: suggestion,
              onFollowed: () {
                if (mounted) {
                  setState(() {
                    _suggestions.removeWhere((item) => item.profile.id == suggestion.profile.id);
                  });
                }
              },
            )),
      ],
    );
  }
}

class _NearbySuggestionRow extends StatefulWidget {
  final ProfileWithDistance suggestion;
  final VoidCallback? onFollowed;
  const _NearbySuggestionRow({required this.suggestion, this.onFollowed});

  @override
  State<_NearbySuggestionRow> createState() => _NearbySuggestionRowState();
}

class _NearbySuggestionRowState extends State<_NearbySuggestionRow> {
  bool _isFollowing = false;
  bool _isLoading = false;

  Future<void> _handleFollow() async {
    if (_isLoading || _isFollowing) return;

    final userService = Sint.find<UserService>();
    final myProfileId = userService.profile.id;

    if (myProfileId.isEmpty) {
      Sint.toNamed(AppRouteConstants.login);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ProfileFirestore().followProfile(
        profileId: myProfileId,
        followedProfileId: widget.suggestion.profile.id,
      );

      if (success) {
        // Update local following list
        userService.profile.following ??= [];
        userService.profile.following!.add(widget.suggestion.profile.id);

        if (mounted) {
          setState(() {
            _isFollowing = true;
            _isLoading = false;
          });
        }

        // Delay removal from widget tree for transition
        Future.delayed(const Duration(milliseconds: 300), () {
          if (widget.onFollowed != null) widget.onFollowed!();
        });
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
    final profile = widget.suggestion.profile;
    final distance = widget.suggestion.distance;

    final distanceStr = distance < 9990.0
        ? '${distance.toStringAsFixed(1)} km'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Sint.toNamed(
              AppRouteConstants.matePath(profile.id, slug: profile.slug),
              arguments: profile,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: platformCircleAvatar(
                imageUrl: profile.photoUrl.isNotEmpty ? profile.photoUrl : AppProperties.getAppLogoUrl(),
                radius: 19,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Sint.toNamed(
                    AppRouteConstants.matePath(profile.id, slug: profile.slug),
                    arguments: profile,
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (distanceStr.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    distanceStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Follow button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _handleFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _isFollowing
                      ? Colors.transparent
                      : AppColor.getMain().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isFollowing
                        ? Colors.white.withOpacity(0.1)
                        : AppColor.getMain().withOpacity(0.3),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    : Text(
                        _isFollowing
                            ? HomeTranslationConstants.followed.tr
                            : HomeTranslationConstants.follow.tr,
                        style: TextStyle(
                          color: _isFollowing ? Colors.white60 : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
