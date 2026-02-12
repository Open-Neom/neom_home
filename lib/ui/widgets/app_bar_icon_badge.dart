import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar un ícono con badge de contador.
///
/// Se usa en el AppBar para mostrar contadores de notificaciones,
/// mensajes sin leer, etc.
class AppBarIconBadge extends StatelessWidget {
  /// El ícono a mostrar
  final IconData icon;

  /// Número a mostrar en el badge (0 = sin badge)
  final int count;

  /// Callback cuando se presiona el ícono
  final VoidCallback onPressed;

  /// Color del ícono
  final Color iconColor;

  /// Color de fondo del badge
  final Color badgeColor;

  /// Color del texto del badge
  final Color badgeTextColor;

  const AppBarIconBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.onPressed,
    this.iconColor = Colors.white70,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon),
          color: iconColor,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 15,
                minHeight: 15,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
