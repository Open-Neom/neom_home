import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/literature_books.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
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
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: AppTheme.appBoxDecoration,
      child: ListView(
        // NeverScrollableScrollPhysics: prevents sidebar from stealing
        // mouse-wheel events — scroll is forwarded to the central feed
        // by the Listener in HomeWebPage (Facebook-style global scroll).
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // A. Mini profile card
          if (profile != null && profile.id.isNotEmpty)
            _MiniProfileCard(
              name: profile.name,
              photoUrl: profile.photoUrl,
              bio: profile.aboutMe,
              onTap: () => Sint.toNamed(AppRouteConstants.profile),
            ),

          const SizedBox(height: 24),

          // B. Suggested users
          const WebSuggestedUsers(),

          const SizedBox(height: 24),

          // C. Mini releases
          const WebMiniReleases(),

          const SizedBox(height: 24),

          // D. Featured books (conditional)
          _FeaturedBooksSection(),

          // E. Literary games (solo Emxi)
          if (AppConfig.instance.appInUse == AppInUse.e) ...[
            const SizedBox(height: 24),
            const WebSidebarGames(),
          ],

          const SizedBox(height: 32),

          // F. Footer
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
            _footerLink('Acerca de'),
            _footerDot(),
            _footerLink('Ayuda'),
            _footerDot(),
            _footerLink('Privacidad'),
            _footerDot(),
            _footerLink('Condiciones'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '\u00a9 2026 EMXI',
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

/// Mini profile card at top of right sidebar.
class _MiniProfileCard extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String bio;
  final VoidCallback onTap;

  const _MiniProfileCard({
    required this.name,
    required this.photoUrl,
    required this.bio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(
              photoUrl.isNotEmpty ? photoUrl : AppProperties.getAppLogoUrl(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Perfil',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (bio.isNotEmpty)
                  Text(
                    bio,
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
    final List<LiteraryBook> books = controller.featuredBooks;

    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top 10',
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.topBooks),
              child: const Text(
                'Ver todo',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: book.coverUrl.isNotEmpty
                  ? Image.network(
                      book.coverUrl,
                      width: 36,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
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
