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
