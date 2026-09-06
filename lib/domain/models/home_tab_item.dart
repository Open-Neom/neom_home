import 'package:flutter/material.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';

class HomeTabItem {
  final String title;
  final IconData icon;
  final Widget? page; // Si es null, es un botón de acción (como el central)
  final bool isActionButton; // Para identificar si abre modal o cambia página
  final String? route; // Por si alguna tab navega a otra pantalla full screen

  bool get requiresAccount => title == AppTranslationConstants.events;

  /// IndexedStack mounts every child, including tabs that are not selected.
  /// Keep protected pages out of the tree until their account gate is open.
  Widget? get accessiblePage => requiresAccount && !AuthGuard.isAuthenticated
      ? const SizedBox.shrink()
      : page;

  HomeTabItem({
    required this.title,
    required this.icon,
    this.page,
    this.isActionButton = false,
    this.route,
  });
}
