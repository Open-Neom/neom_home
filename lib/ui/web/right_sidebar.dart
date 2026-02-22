import 'package:flutter/material.dart';

class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _SidebarSection(
            title: 'Libros Activos',
            icon: Icons.menu_book_rounded,
            child: _buildBooksList(),
          ),
          const SizedBox(height: 20),
          _SidebarSection(
            title: 'Comunidad',
            icon: Icons.people_rounded,
            child: _buildCommunityInfo(),
          ),
          const SizedBox(height: 20),
          _SidebarSection(
            title: 'Escritores MXI',
            icon: Icons.info_outline,
            child: _buildAboutSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList() {
    return Column(
      children: [
        _buildPlaceholderTile(Icons.book_outlined, 'Explora la biblioteca'),
        _buildPlaceholderTile(Icons.auto_stories_outlined, 'Descubre nuevos autores'),
      ],
    );
  }

  Widget _buildCommunityInfo() {
    return Column(
      children: [
        _buildPlaceholderTile(Icons.group_add_outlined, 'Conecta con escritores'),
        _buildPlaceholderTile(Icons.event_outlined, 'Proximos eventos'),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Plataforma para escritores mexicanos independientes',
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
    );
  }

  Widget _buildPlaceholderTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SidebarSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
