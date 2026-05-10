# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CO2 Exist Portal — a Flutter web/mobile admin portal for managing eco-footprint events. Built with Supabase as the backend (auth, database, storage).

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (web is the primary target)
flutter run -d chrome

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (lint)
flutter analyze

# Build for web
flutter build web
```

## Architecture

**Clean Architecture with BLoC pattern**, organized by feature under `lib/features/`. Each feature follows the layered structure:

```
features/<feature>/
  data/         # Repositories impl, datasources
  domain/       # Models, repository interfaces
  presentation/ # BLoC (events/states), pages, widgets
  di/           # Feature-specific dependency injection
```

Current features: `auth`, `events`, `app_configs`, `dashboard` (dashboard has presentation only).

**Core layer** (`lib/core/`):
- `network/` — Dio-based `ApiClient` and `NetworkInfo` (connectivity checking)
- `constants/` — App-wide constants including Supabase URL/keys (`AppConstants`)
- `errors/` — Custom exception and failure types
- `utils/` — Router (`go_router`), date formatting, validators, `Either` type
- `theme/` — App theme configuration
- `common_widgets/` — Shared UI components

**Key patterns:**
- **Dependency injection**: `get_it` via `lib/di/injection_container.dart`. Features register their own deps via `registerXDependencies(sl)` functions in their `di/` folders.
- **State management**: `flutter_bloc` — BLoCs are provided at the app level in `main.dart` (`AuthBloc`, `AppConfigBloc`) and at the shell route level (`EventBloc`).
- **Routing**: `go_router` with auth guard redirect in `lib/core/utils/app_router.dart`. Auth routes are top-level; dashboard routes use a `ShellRoute` for persistent layout.
- **Backend**: All data goes through Supabase (`supabase_flutter`). The `ApiClient` (Dio) exists but Supabase client is the primary data layer.
- **Error handling**: `Either<Failure, T>` pattern for repository return types; custom exceptions map to `Failure` subtypes.

## Dart SDK

Requires Dart SDK `^3.9.2`. Uses `flutter_lints` for analysis rules.

## Environments & deployment

Two environments live in parallel — staging and production — each backed by a separate Supabase project and a separate Netlify site. Env config is supplied at build time via `--dart-define-from-file=config/<env>.json` and read by `String.fromEnvironment(...)` in `lib/core/constants/app_constants.dart` (`ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`).

There are **no fallback values**. A build with no `--dart-define-from-file` flag will throw `StateError` at startup (`lib/main.dart`). This is deliberate — silently hitting the wrong project once cost real debugging time.

Edge function calls (`account_service.dart`, `event_repository_impl.dart`) derive their URL + bearer from `AppConstants.baseUrl` / `AppConstants.apiKey` — never hardcode a project ref or anon key. The footer in `dashboard.dart` displays the env name and Supabase URL so the running env is visible at a glance.

### Deploying to staging — read this before running `netlify deploy`

Two foot-guns, both painful, both have bitten us:

**1. `netlify deploy` re-runs the build by default and uses production config.**
The checked-in `netlify.toml` hardcodes `flutter build web --dart-define-from-file=config/production.json` as its `command`. `netlify deploy` (and `netlify deploy --dir=build/web`) will run that command locally before uploading, silently overwriting your staging-built `build/web` with a production-built one. **You must pass `--no-build`** to deploy what you have on disk.

**2. Flutter web's incremental build cache does not invalidate on `--dart-define-from-file` changes.**
A build with `staging.json` after a build with `production.json` (or vice versa) reuses stale compiled artifacts and bakes in the *previous* env's URLs/keys. Always `flutter clean` between env switches.

Correct staging deploy:

```bash
flutter clean && flutter pub get
flutter build web --dart-define-from-file=config/staging.json

# Verify the right project ref is baked in BEFORE uploading
grep -c iunetwvtaqvwuevqgqum build/web/main.dart.js   # staging — should be > 0
grep -c hvgxicauyuchtqcdmdgp build/web/main.dart.js   # prod    — should be 0

netlify deploy --prod --no-build --dir=build/web \
  --site=78ad8b33-aa41-46cb-b013-bf72c019bd47       # papaya-cassata-86434e (staging)

# Verify the live deploy
curl -s https://papaya-cassata-86434e.netlify.app/main.dart.js | grep -c iunetwvtaqvwuevqgqum
```

Production deploys can let `netlify.toml`'s build command run as-is (no `--no-build` needed), since it already targets production config.

`--prod` here means *"make this the live deploy of that Netlify site"* — it does NOT cross environments. Deploying with `--prod --site=<staging-id>` updates the staging site only.
