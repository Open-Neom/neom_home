# Changelog — neom_home

## [2.0.0] - 2026-05-21
- Stable 2.0.0 release of neom_home.
- Fix `LeftSidebar` navigation when rendered outside of home context (e.g. biblioteca).
- `onTabSelected` in non-home routes now calls `Sint.back()` + `HomeController.selectTab(index)` so Inicio/Eventos work correctly.

## [1.5.0] - 2026-03-14
- Fix navigation stack accumulation: `Sint.toNamed` → `Sint.offNamed` for tab routes and initial route.
- Clean up web layout widgets: sidebar, top bar, notification/search panels, stories, suggested users.
