
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
