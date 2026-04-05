import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/activity_feed_type.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

/// Instagram-style notification panel overlay for web.
/// Slides out from the left sidebar and displays activity feed items.
/// Loads data directly from Firestore (no dependency on neom_notifications).
class WebNotificationPanel extends StatefulWidget {
  final VoidCallback onClose;

  const WebNotificationPanel({super.key, required this.onClose});

  @override
  State<WebNotificationPanel> createState() => _WebNotificationPanelState();
}

class _WebNotificationPanelState extends State<WebNotificationPanel> {
  List<ActivityFeed> _items = [];
  bool _isLoading = true;

  String get _profileId => Sint.isRegistered<UserService>()
      ? Sint.find<UserService>().profile.id
      : '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_profileId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final personal = await ActivityFeedFirestore().retrieve(_profileId);
      final global = await ActivityFeedFirestore().retrieveGlobal();
      final filtered = global.where((item) => item.profileId != _profileId).toList();

      final merged = [...personal, ...filtered];
      merged.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      // Mark personal as read
      for (var item in personal) {
        if (item.unread) {
          ActivityFeedFirestore().setAsRead(ownerId: _profileId, activityFeedId: item.id);
          item.unread = false;
        }
      }

      if (mounted) {
        setState(() {
          _items = merged;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_home', operation: '_loadNotifications');
      if (mounted) setState(() => _isLoading = false);
    }
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
                    AppTranslationConstants.notifications.tr,
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
            const Divider(color: Colors.white12, height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: AppCircularProgressIndicator(showLogo: false))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            AppTranslationConstants.noResults.tr,
                            style: const TextStyle(color: Colors.white54, fontSize: 15),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const Divider(
                              color: Colors.white10,
                              height: 1,
                              indent: 70,
                            ),
                            itemBuilder: (context, index) {
                              return _buildNotificationItem(_items[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(ActivityFeed activityFeed) {
    return InkWell(
      onTap: () {
        widget.onClose();
        _gotoReference(activityFeed);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            GestureDetector(
              onTap: () {
                widget.onClose();
                Sint.toNamed(AppRouteConstants.matePath(activityFeed.profileId), arguments: [activityFeed.profileId]);
              },
              child: platformCircleAvatar(
                imageUrl: activityFeed.profileImgUrl.isNotEmpty
                      ? activityFeed.profileImgUrl
                      : AppProperties.getAppLogoUrl(),
                radius: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, height: 1.35, color: Colors.white),
                      children: [
                        TextSpan(
                          text: activityFeed.profileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' ${_getActivityText(activityFeed)}',
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeUtilities.formatTimeAgo(
                      DateTime.fromMillisecondsSinceEpoch(activityFeed.createdTime),
                    ),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),

            // Media thumbnail
            if (activityFeed.mediaUrl.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: kIsWeb
                    ? platformNetworkImage(imageUrl: activityFeed.mediaUrl, fit: BoxFit.cover)
                    : Image(
                        image: platformImageProvider(activityFeed.mediaUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.image, size: 18, color: Colors.white38),
                        ),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActivityText(ActivityFeed activityFeed) {
    switch (activityFeed.activityFeedType) {
      case ActivityFeedType.follow:
        return CommonTranslationConstants.startedFollowingYou.tr;
      case ActivityFeedType.like:
        return CommonTranslationConstants.likedYourPost.tr;
      case ActivityFeedType.comment:
      case ActivityFeedType.reply:
        return activityFeed.message.isNotEmpty
            ? activityFeed.message
            : CommonTranslationConstants.likedYourPost.tr;
      case ActivityFeedType.event:
        return CommonTranslationConstants.eventCreated.tr;
      case ActivityFeedType.request:
        return CommonTranslationConstants.hasSentRequest.tr;
      case ActivityFeedType.newRelease:
        return activityFeed.message.isNotEmpty ? activityFeed.message : '';
      default:
        return activityFeed.message.isNotEmpty ? activityFeed.message : '';
    }
  }

  void _gotoReference(ActivityFeed activityFeed) {
    switch (activityFeed.activityFeedType) {
      case ActivityFeedType.follow:
      case ActivityFeedType.itemmate:
        Sint.toNamed(AppRouteConstants.matePath(activityFeed.profileId), arguments: [activityFeed.profileId]);
        break;
      case ActivityFeedType.like:
      case ActivityFeedType.comment:
      case ActivityFeedType.commentLike:
      case ActivityFeedType.reply:
      case ActivityFeedType.mention:
        if (activityFeed.activityReferenceId.isNotEmpty) {
          Sint.toNamed(AppRouteConstants.postPath(activityFeed.activityReferenceId), arguments: [activityFeed.activityReferenceId]);
        }
        break;
      case ActivityFeedType.newRelease:
        if (activityFeed.activityReferenceId.isNotEmpty) {
          Sint.toNamed(AppRouteConstants.listItems, arguments: activityFeed.activityReferenceId);
        }
        break;
      default:
        break;
    }
  }
}
