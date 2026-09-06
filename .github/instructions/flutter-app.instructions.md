---
applyTo: "lib/**,test/**"
---

<!-- GENERATED from .claude/rules/flutter-app.md by bin/sync-instructions. Edit that file, not this one. -->

# The Flutter app

Applies to `lib/` and `test/`. Colours, the component folder contract and the anti-pattern table live in `.github/instructions/design.instructions.md`, which loads alongside this file.

## The two skills are the standard, and this file is only where we differ

`magic-framework` and `wind-ui` define how code on this stack is written, and copies of both sit at `.github/skills/` so a reviewer with only this checkout has them too. Load them before the first line of Dart rather than working from memory. This file does not restate them; it carries what this app does differently, and what has not been built yet.

## No controller and no dedicated view class here yet

This boilerplate ships zero files under `lib/app/controllers/` and zero `MagicStatefulView`. `lib/resources/views/dashboard_view.dart` and `welcome_view.dart` are plain `StatelessWidget`, reading config directly (`Config.get('app.name', ...)`) rather than through a `MagicController`. That is a real gap, not a style choice: a screen with a network call, a form, or any state that must reset between logins needs the framework's pattern rather than a hand-rolled `StatefulWidget`, and neither the `magic-framework` skill's shape nor a local instance of it exists in this repo to copy from.

When you add the first one, follow the skill's definition rather than inventing a shape here:

- A controller is a `MagicController` resolved through a canonical `static X get instance => Magic.findOrPut(X.new);`, notifying through `refreshUI()` rather than calling `notifyListeners()` directly.
- A view pairs with it as `MagicStatefulView<XController>` / `MagicStatefulViewState`. Do not pass a controller through a view's constructor; nothing then resets it between logins or tests.
- No app shell under `lib/ui/layouts/`. `lib/routes/app.dart:16` already mounts `magic_starter`'s `layout.app` through `MagicRoute.group(layout: ...)`; a second shell competes with it and decays.

## Routes register in `boot()`, not `register()`

`RouteServiceProvider.boot()` (`lib/app/providers/route_service_provider.dart`) calls `registerAppRoutes()` and the starter route registrars, then registers the dev-only preview catalog, all inside `boot()`. That is deliberate here: the preview registration must land before `MagicRouter` locks its route table on first build, and `boot()` is the phase both dev tooling and the app routes share. Do not move route registration into `register()` on the assumption that is the framework default; it is not what this repo does, and the comment at that call site explains why.

## Config-plus-factory is the wiring shape for a new subsystem

A subsystem gets its own `lib/config/<name>.dart` exposing a single `Map<String, dynamic> get <name>Config => {...}` getter, then a `() => <name>Config` entry added to the `configFactories` list in `lib/main.dart`. `lib/config/localization.dart` and `lib/config/notifications.dart` are the two current instances (wired at `lib/main.dart:39-41`); read either before adding a third. Every value goes through `env()` with an explicit fallback rather than requiring a `.env` entry, and each non-obvious default carries a comment saying why that default and not another (see `notifications.dart`'s push section). This is the only place a subsystem is configured; do not scatter its options across the provider that consumes it.

## Generated files, never hand-edited

`lib/config/wind_theme.g.dart` (`design:sync`), `lib/_previews.g.dart` (`previews:refresh`), `lib/app/_plugins.g.dart` and `lib/app/commands/_index.g.dart` (`commands:refresh`). Regenerate through the dispatcher command named in parentheses; a hand edit is overwritten on the next run and diverges from `analysis_options.yaml`'s strict-mode expectations in the meantime.
