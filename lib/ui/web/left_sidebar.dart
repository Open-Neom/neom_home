import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/settings_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

class LeftSidebar extends StatelessWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUser = Sint.isRegistered<UserService>();
    final profile = hasUser ? Sint.find<UserService>().profile : null;

    return Container(
      width: 250,
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Profile header
          if (profile != null && profile.id.isNotEmpty)
            _SidebarItem(
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  profile.photoUrl.isNotEmpty ? profile.photoUrl : AppProperties.getAppLogoUrl(),
                ),
              ),
              label: profile.name.isNotEmpty ? profile.name : 'Perfil',
              onTap: () => Sint.toNamed(AppRouteConstants.profile),
            ),

          const SizedBox(height: 8),

          // Menu items
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Amigos',
            onTap: () => Sint.toNamed(AppRouteConstants.mates),
          ),
          if (AppFlavour.showBlog())
            _SidebarItem(
              icon: FontAwesomeIcons.gamepad,
              label: 'Juegos',
              onTap: () => Sint.toNamed(AppRouteConstants.games),
            ),
          if (AppFlavour.showBlog())
            _SidebarItem(
              icon: FontAwesomeIcons.filePen,
              label: 'Blog',
              onTap: () => Sint.toNamed(AppRouteConstants.blog),
            ),
          _SidebarItem(
            icon: Icons.event_outlined,
            label: 'Eventos',
            onTap: () => Sint.toNamed(AppRouteConstants.events),
          ),
          _SidebarItem(
            icon: Icons.menu_book_outlined,
            label: 'Libros',
            onTap: () => Sint.toNamed(AppRouteConstants.libraryHome),
          ),
          _SidebarItem(
            icon: Icons.headphones_outlined,
            label: 'Audio',
            onTap: () => Sint.toNamed(AppRouteConstants.audioPlayer),
          ),
          _SidebarItem(
            icon: Icons.email_outlined,
            label: 'Solicitudes',
            onTap: () => Sint.toNamed(AppRouteConstants.request),
          ),

          const Divider(color: Colors.white24, indent: 16, endIndent: 16),

          if (Sint.isRegistered<SettingsService>())
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: 'Configuracion',
              onTap: () => Sint.toNamed(AppRouteConstants.settingsPrivacy),
            ),
          if (Sint.isRegistered<LoginService>())
            _SidebarItem(
              icon: Icons.logout,
              label: 'Cerrar Sesion',
              onTap: () => Sint.toNamed(AppRouteConstants.logout, arguments: [AppRouteConstants.logout]),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback onTap;

  const _SidebarItem({
    this.icon,
    this.leading,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.leading != null) widget.leading!
              else Icon(widget.icon, color: AppColor.lightGrey, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: AppColor.lightGrey,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
