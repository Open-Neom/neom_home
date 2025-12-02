import 'package:flutter/material.dart';

class HomeTabItem {
  final String title;
  final IconData icon;
  final Widget? page; // Si es null, es un botón de acción (como el central)
  final bool isActionButton; // Para identificar si abre modal o cambia página
  final String? route; // Por si alguna tab navega a otra pantalla full screen

  HomeTabItem({
    required this.title,
    required this.icon,
    this.page,
    this.isActionButton = false,
    this.route,
  });
}
