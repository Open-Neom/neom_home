import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/mate_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

/// Instagram-style search panel overlay for web.
/// Slides out from the left sidebar and displays search results.
/// Loads data directly from Firestore/MateService (no dependency on neom_search).
class WebSearchPanel extends StatefulWidget {
  final VoidCallback onClose;

  const WebSearchPanel({super.key, required this.onClose});

  @override
  State<WebSearchPanel> createState() => _WebSearchPanelState();
}

class _WebSearchPanelState extends State<WebSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileFirestore _profileFirestore = ProfileFirestore();
  Timer? _debounce;

  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  // Cached data — only followers + following (lightweight)
  Map<String, AppProfile> _nearProfiles = {};
  Map<String, AppMediaItem> _allMediaItems = {};
  Map<String, AppReleaseItem> _allReleaseItems = {};

  // Filtered results
  List<AppProfile> _filteredProfiles = [];
  List<AppMediaItem> _filteredMediaItems = [];
  List<AppReleaseItem> _filteredReleaseItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final futures = <Future>[];

      // Lightweight: only use followers + following already in memory (no extra Firestore calls)
      if (Sint.isRegistered<MateService>()) {
        final mateService = Sint.find<MateService>();
        _nearProfiles = {
          ...mateService.followerProfiles,
          ...mateService.followingProfiles,
        };
      }

      // Load media items and release items in parallel
      futures.add(AppMediaItemFirestore().fetchAll().then((items) {
        _allMediaItems = items;
      }).catchError((e) {
        AppConfig.logger.e("WebSearchPanel media: $e");
      }));

      futures.add(AppReleaseItemFirestore().retrieveAll().then((items) {
        _allReleaseItems = items;
      }).catchError((e) {
        AppConfig.logger.e("WebSearchPanel releases: $e");
      }));

      await Future.wait(futures);

      // Show followers/following + recent releases/media when no query
      _applyLocalFilter();
    } catch (e) {
      AppConfig.logger.e("WebSearchPanel: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _searchQuery = trimmed.toLowerCase();
      if (_searchQuery.isEmpty) {
        setState(() {
          _isSearching = false;
          _applyLocalFilter();
        });
      } else {
        _searchRemote(trimmed);
      }
    });
  }

  /// Filter from already-loaded data (no Firestore calls)
  void _applyLocalFilter() {
    _filteredProfiles = _nearProfiles.values
        .where((p) => p.name.isNotEmpty && p.isActive)
        .take(8)
        .toList();
    _filteredMediaItems = _allMediaItems.values.take(4).toList();
    _filteredReleaseItems = _allReleaseItems.values.take(4).toList();
  }

  /// Search using Firestore index for profiles, local filter for media/releases
  Future<void> _searchRemote(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      // Search profiles via Firestore searchByName index
      final results = await _profileFirestore.searchByName(query, limit: 10);
      if (!mounted || _searchQuery != query.toLowerCase()) return;

      // Also include local matches from followers/following
      final localMatches = _nearProfiles.values.where((p) =>
          p.name.isNotEmpty && p.isActive &&
          (p.name.toLowerCase().contains(_searchQuery) ||
              p.mainFeature.toLowerCase().contains(_searchQuery)));

      // Merge: local matches first, then remote (deduplicate by id)
      final seen = <String>{};
      final merged = <AppProfile>[];
      for (final p in [...localMatches, ...results]) {
        if (seen.add(p.id) && p.isActive) merged.add(p);
      }

      _filteredProfiles = merged.take(10).toList();
    } catch (e) {
      AppConfig.logger.e("WebSearchPanel search profiles: $e");
      // Fallback: filter from local near profiles
      _filteredProfiles = _nearProfiles.values.where((p) =>
          p.name.isNotEmpty && p.isActive &&
          (p.name.toLowerCase().contains(_searchQuery) ||
              p.mainFeature.toLowerCase().contains(_searchQuery))
      ).take(10).toList();
    }

    // Filter media and releases locally
    _filteredMediaItems = _allMediaItems.values.where((item) =>
        item.name.toLowerCase().contains(_searchQuery) ||
        item.ownerName.toLowerCase().contains(_searchQuery)
    ).take(6).toList();

    _filteredReleaseItems = _allReleaseItems.values.where((item) =>
        item.name.toLowerCase().contains(_searchQuery) ||
        item.ownerName.toLowerCase().contains(_searchQuery) ||
        item.categories.any((c) => c.toLowerCase().contains(_searchQuery))
    ).take(6).toList();

    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.appBoxDecoration.gradient,
          border: Border(
            right: BorderSide(color: AppColor.borderSubtle),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslationConstants.search.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 22),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: AppTranslationConstants.search.tr,
                  hintStyle: TextStyle(
                    color: Colors.white.withAlpha(76),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withAlpha(76)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withAlpha(76), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColor.dividerColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: AppCircularProgressIndicator(showLogo: false))
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final hasProfiles = _filteredProfiles.isNotEmpty;
    final hasMedia = _filteredMediaItems.isNotEmpty;
    final hasReleases = _filteredReleaseItems.isNotEmpty;

    if (_isSearching) {
      return const Center(child: Padding(
        padding: EdgeInsets.only(top: 40),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30)),
      ));
    }

    if (!hasProfiles && !hasMedia && !hasReleases) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColor.white15),
            const SizedBox(height: 12),
            Text(
              AppTranslationConstants.noResults.tr,
              style: TextStyle(color: AppColor.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Profiles section
        if (hasProfiles) ...[
          _buildSectionHeader(AppTranslationConstants.profiles.tr),
          ..._filteredProfiles.map(_buildProfileTile),
        ],
        // Releases section
        if (hasReleases) ...[
          _buildSectionHeader(AppTranslationConstants.releases.tr),
          ..._filteredReleaseItems.map(_buildReleaseTile),
        ],
        // Media section
        if (hasMedia) ...[
          _buildSectionHeader(AppTranslationConstants.audioLibrary.tr),
          ..._filteredMediaItems.map(_buildMediaTile),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileTile(AppProfile profile) {
    return InkWell(
      onTap: () {
        widget.onClose();
        Sint.toNamed(AppRouteConstants.matePath(profile.id), arguments: profile.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: platformImageProvider(
                profile.photoUrl.isNotEmpty
                    ? profile.photoUrl
                    : AppProperties.getAppLogoUrl(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.verificationLevel != VerificationLevel.none) ...[
                        const SizedBox(width: 4),
                        AppFlavour.getVerificationIcon(profile.verificationLevel, size: 16),
                      ],
                    ],
                  ),
                  if (profile.mainFeature.isNotEmpty)
                    Text(
                      profile.mainFeature.tr,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseTile(AppReleaseItem item) {
    return InkWell(
      onTap: () {
        widget.onClose();
        AppFlavour.navigateToReleaseItem(item.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.imgUrl.isNotEmpty
                  ? platformNetworkImage(
                      imageUrl: item.imgUrl,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      errorWidget: Image(fit: BoxFit.cover, image: const AssetImage(AppAssets.mainItemCover)),
                    )
                  : Image(fit: BoxFit.cover, image: const AssetImage(AppAssets.mainItemCover)),
            ),
          ),
          title: Text(
            TextUtilities.getMediaName(item.name),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            TextUtilities.getArtistName(item.ownerName),
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTile(AppMediaItem item) {
    return InkWell(
      onTap: () {
        widget.onClose();
        if (item.type == MediaItemType.song ||
            item.type == MediaItemType.podcast ||
            item.type == MediaItemType.audiobook) {
          Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [item]);
        } else {
          Sint.toNamed(AppFlavour.getMainItemDetailsRoute(item.id), arguments: [item]);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.imgUrl.isNotEmpty
                  ? platformNetworkImage(
                      imageUrl: item.imgUrl,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      errorWidget: Image(fit: BoxFit.cover, image: const AssetImage(AppAssets.mainItemCover)),
                    )
                  : Image(fit: BoxFit.cover, image: const AssetImage(AppAssets.mainItemCover)),
            ),
          ),
          title: Text(
            TextUtilities.getMediaName(item.name),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            TextUtilities.getArtistName(item.ownerName),
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
