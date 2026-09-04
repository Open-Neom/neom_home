## [2026-09-03] - Pestanas del home y logo ausente
- **Las pestanas no cambiaban de pagina.** `selectTab()` asignaba
  `_currentIndex` unicamente dentro de `if (pageController.hasClients)`, pero
  `home_page.dart` renderiza un `IndexedStack` gobernado por `pageIndex` (que
  lee `_currentIndex`) y el `PageController` creado en `onInit` nunca se
  conecta a ningun `PageView`. `hasClients` era false siempre, el bloque no se
  ejecutaba jamas y tocar una pestana registraba "Selecting tab index: N" sin
  hacer nada. La asignacion pasa fuera del `if`; el `jumpToPage` se conserva
  para vistas que si tengan un `PageView` real.
- **`home_appbar_lite` reventaba sin el logo.** `Image.asset` sobre
  `AppAssets.logoCompanyWhite` sin `errorBuilder`: una app que no enviara ese
  archivo mostraba la caja roja de error cruzando su app bar, en todas las
  pantallas y para siempre. Ahora cae al nombre de la app.
- Ambos verificados en dispositivo (Samsung S25, Android 16).

## [2026-07-25] - Dependencias Externas
- Actualizacion de dependencias externas a sus versiones mas recientes y compatibles.


## [2.0.0-unreleased] - 2026-07-21
- Refactor and compatibility updates for left_sidebar.dart, right_sidebar.dart, web_suggested_users.dart, pubspec.lock.
# Changelog — neom_home

## [2.0.1] - 2026-07-16
- Update Home Web Page to support floating Winamp-style player layout and sidebars customization.
- Add suggested users and upcoming events widgets.

## [1.1.0] - 2026-07-09
- Refactor left sidebar navigation design layout.

## Unreleased - Show role instead of "free account" for staff
- The web home mini-profile card no longer shows "Cuenta gratuita" for staff accounts. Priority is now: active subscription → plan name; else **staff role** (Admin, Desarrollador, Administrativo, Soporte, Editor, Super Administrador); else "Cuenta gratuita" (regular subscribers). An admin doesn't pay a subscription but isn't "free", so their role is shown.
- New reusable `UserRoleLabel` extension (`neom_commons/utils/user_role_label.dart`) with localized `label` + `isStaff`. New role translations (`roleEditor/roleSupport/roleErp/roleDeveloper`) in ES/EN/FR/DE. Same fix applied to the Settings web billing card.

## [2.0.0] - 2026-05-21
- Stable 2.0.0 release of neom_home.
- Fix `LeftSidebar` navigation when rendered outside of home context (e.g. biblioteca).
- `onTabSelected` in non-home routes now calls `Sint.back()` + `HomeController.selectTab(index)` so Inicio/Eventos work correctly.

## [1.5.0] - 2026-03-14
- Fix navigation stack accumulation: `Sint.toNamed` → `Sint.offNamed` for tab routes and initial route.
- Clean up web layout widgets: sidebar, top bar, notification/search panels, stories, suggested users.
