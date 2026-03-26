import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/literature_books.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';
import 'package:neom_home/utils/constants/home_translation_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

import 'widgets/web_mini_releases.dart';
import 'widgets/web_sidebar_games.dart';
import 'widgets/web_suggested_users.dart';

/// Instagram-style right sidebar with real data.
/// Shows: mini profile, suggested users, new releases, featured books, footer.
class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUser = Sint.isRegistered<UserService>();
    final profile = hasUser ? Sint.find<UserService>().profile : null;

    return Container(
      width: 320,
      padding: const EdgeInsets.only(left: 16, right: 30, top: 20, bottom: 20),
      decoration: AppTheme.appBoxDecoration,
      child: ListView(
        // NeverScrollableScrollPhysics: prevents sidebar from stealing
        // mouse-wheel events — scroll is forwarded to the central feed
        // by the Listener in HomeWebPage (Facebook-style global scroll).
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // A. Mini profile card
          if (profile != null && profile.id.isNotEmpty)
            Builder(builder: (_) {
              String subLabel = CommonTranslationConstants.freeAccount.tr;
              if (hasUser) {
                final userSub = Sint.find<UserService>().userSubscription;
                if (userSub != null && userSub.status == SubscriptionStatus.active) {
                  final levelName = userSub.level?.name ?? '';
                  final displayLevel = levelName.isNotEmpty
                      ? '${levelName[0].toUpperCase()}${levelName.substring(1)}'
                      : '';
                  subLabel = displayLevel.isNotEmpty
                      ? '${AppProperties.getGeneralSubscriptionName()} — $displayLevel'
                      : AppProperties.getGeneralSubscriptionName();
                }
              }
              return _MiniProfileCard(
                name: profile.name,
                photoUrl: profile.photoUrl,
                subscriptionLabel: subLabel,
                onTap: () => Sint.toNamed(AppRouteConstants.profile),
              );
            }),

          const SizedBox(height: 24),

          // B. Suggested users
          const WebSuggestedUsers(),

          const SizedBox(height: 24),

          // C. Mini releases
          const WebMiniReleases(),

          const SizedBox(height: 24),

          // D. FIL Guadalajara CTA (solo EMXI)
          if (AppConfig.instance.appInUse == AppInUse.e) ...[
            const _FilGuadalajaraCta(),
            const SizedBox(height: 24),
          ],

          // E. Quick actions (EMXI y Gigmeout)
          if (AppConfig.instance.appInUse == AppInUse.e
              || AppConfig.instance.appInUse == AppInUse.g) ...[
            const _QuickActionsSection(),
            const SizedBox(height: 24),
          ],

          // F. Featured books (conditional)
          _FeaturedBooksSection(),

          // G. Literary games (solo Emxi)
          if (AppConfig.instance.appInUse == AppInUse.e) ...[
            const SizedBox(height: 24),
            const WebSidebarGames(),
          ],

          const SizedBox(height: 32),

          // H. Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            _footerLink(CommonTranslationConstants.aboutApp.tr),
            _footerDot(),
            _footerLink(CommonTranslationConstants.help.tr),
            _footerDot(),
            _footerLink(CommonTranslationConstants.privacy.tr),
            _footerDot(),
            _footerLink(CommonTranslationConstants.conditions.tr),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '\u00a9 2026 ${AppProperties.getAppName()}',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
    );
  }

  Widget _footerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text('\u00b7', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
    );
  }
}

/// Quick action buttons for EMXI sidebar — editorial tools.
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  static bool _hasActiveSubscription() {
    if (!Sint.isRegistered<UserService>()) return false;
    final sub = Sint.find<UserService>().userSubscription;
    return sub != null && sub.status == SubscriptionStatus.active;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CommonTranslationConstants.tools.tr,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (AppConfig.instance.appInUse == AppInUse.e) ...[
          _QuickActionTile(
            icon: Icons.calculate_outlined,
            label: CommonTranslationConstants.quotationTool.tr,
            subtitle: CommonTranslationConstants.quotationToolDesc.tr,
            color: const Color(0xFF4FC3F7),
            onTap: () => Sint.toNamed(AppRouteConstants.quotation),
          ),
          const SizedBox(height: 6),
        ],
        _QuickActionTile(
          icon: Icons.school_outlined,
          label: HomeTranslationConstants.navLearning.tr,
          subtitle: AppConfig.instance.appInUse == AppInUse.e
              ? CommonTranslationConstants.improveWriting.tr
              : AppConfig.instance.appInUse == AppInUse.c
                  ? CommonTranslationConstants.expandConsciousness.tr
                  : CommonTranslationConstants.improveSkills.tr,
          color: const Color(0xFFAED581),
          onTap: () => Sint.toNamed(AppRouteConstants.learning),
        ),
        if (!_hasActiveSubscription()) ...[
          const SizedBox(height: 6),
          Builder(builder: (context) {
            return _QuickActionTile(
              icon: Icons.workspace_premium_outlined,
              label: CommonTranslationConstants.acquireSubscription.tr,
              subtitle: CommonTranslationConstants.unlockAllTools.tr,
              color: const Color(0xFFFFB74D),
              onTap: () => AuthGuard.protect(
                context,
                () => Sint.toNamed(AppRouteConstants.subscriptionPlans),
                redirectRoute: AppRouteConstants.subscriptionPlans,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? widget.color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withValues(alpha: 0.2), widget.color.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini profile card at top of right sidebar.
class _MiniProfileCard extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String subscriptionLabel;
  final VoidCallback onTap;

  const _MiniProfileCard({
    required this.name,
    required this.photoUrl,
    required this.subscriptionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : AppTranslationConstants.profile.tr;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          platformCircleAvatar(
            imageUrl: photoUrl.isNotEmpty ? photoUrl : AppProperties.getAppLogoUrl(),
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subscriptionLabel,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Featured books section — shows Top 10 most-read books from NupaleSession data.
class _FeaturedBooksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Sint.isRegistered<TimelineService>()) return const SizedBox.shrink();

    final controller = Sint.find<TimelineService>();
    final List<LiteraryBook> books = controller.featuredBooks.take(5).toList();

    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              HomeTranslationConstants.topFive.tr,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.topBooks),
              child: Text(
                HomeTranslationConstants.seeAll.tr,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...books.asMap().entries.map((entry) {
          final index = entry.key;
          final book = entry.value;
          return _TopBookTile(book: book, rank: index + 1);
        }),
      ],
    );
  }
}

class _TopBookTile extends StatelessWidget {
  final LiteraryBook book;
  final int rank;

  const _TopBookTile({required this.book, required this.rank});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (book.htmlUrl.isNotEmpty) {
          Sint.toNamed(
            AppFlavour.getMainItemDetailsRoute(book.htmlUrl),
            arguments: [book.htmlUrl],
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Cover — uses platformNetworkImage to bypass CanvasKit CORS
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: book.coverUrl.isNotEmpty
                  ? platformNetworkImage(
                      imageUrl: book.coverUrl,
                      width: 36,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 10),
            // Title + Author
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.author.isNotEmpty)
                    Text(
                      book.author,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      maxLines: 1,
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

  Widget _placeholder() {
    return Container(
      width: 36,
      height: 50,
      color: Colors.grey.shade900,
      child: const Icon(Icons.menu_book, color: Colors.white38, size: 16),
    );
  }
}

/// FIL Guadalajara 2025 call-to-action card.
class _FilGuadalajaraCta extends StatefulWidget {
  const _FilGuadalajaraCta();

  @override
  State<_FilGuadalajaraCta> createState() => _FilGuadalajaraCtaState();
}

class _FilGuadalajaraCtaState extends State<_FilGuadalajaraCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Sint.toNamed('/fil/fil-guadalajara-2026'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)]
                  : [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [BoxShadow(color: const Color(0xFF7B1FA2).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'FIL Guadalajara 2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.6), size: 12),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Quiero participar en la\nFeria Internacional del Libro',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Espacios limitados',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
