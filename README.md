# LumaCart

LumaCart is a local-first Flutter E-Store assessment application built against the Fake Store API. It demonstrates authenticated sessions, defensive API integration, an offline-capable product catalog, a persistent active cart, saved cart snapshots, and profile rendering through a feature-first BLoC architecture.

> Validation status: the complete source, tests, Android scaffold, and documentation are present. This execution environment did not contain Flutter, Dart, or the Android SDK, so `flutter analyze`, `flutter test`, and the release APK build could not be executed here. Exact command logs are preserved in `docs/validation-logs/`.

## Features

- Existing Fake Store API user sign-in through `POST /auth/login`, followed by profile matching from `GET /users`.
- Local sign-up with the demonstration `POST /users` call and reliable device-side account persistence.
- Salted PBKDF2-HMAC-SHA256 password hashing for local accounts. Raw passwords are never persisted.
- Secure storage for active session data and API token material.
- Session restoration and guarded navigation with `go_router`.
- Responsive product catalog with cached images, ratings, category chips, 350 ms debounced search, pull-to-refresh, skeletons, empty states, retry, and cached offline fallback.
- Product details with Hero image transition, quantity selection, and add-to-cart feedback.
- Persistent active cart with duplicate-line merging, quantity controls, removal with undo, integer-cent totals, clear confirmation, and per-account ownership.
- Saved carts with editable names, stable IDs, timestamps, newest-first ordering, detail view, delete, and merge-or-replace restoration.
- Optional simulated remote cart save for API users. Local cart data remains authoritative.
- Profile for both API and locally registered users, with logout and no password/token exposure.
- Material 3 light and dark themes, semantic labels, 48 logical-pixel targets, large-text-aware layouts, and purposeful reduced-motion-aware transitions.

## Screenshots

Screenshots were not captured because no Flutter runtime or Android device was available in the execution environment.

| Screen | Placeholder |
|---|---|
| Sign in | `docs/screenshots/sign-in.png` |
| Product catalog | `docs/screenshots/home.png` |
| Product details | `docs/screenshots/product-details.png` |
| Cart | `docs/screenshots/cart.png` |
| Saved carts | `docs/screenshots/saved-carts.png` |
| Profile | `docs/screenshots/profile.png` |

## Architecture

The project uses pragmatic feature-first clean architecture:

```text
lib/
  app/                 # composition, router, shell, theme
  core/                # networking, storage, failures, utilities, shared widgets
  features/
    auth/               # data, domain, BLoC, pages
    products/           # data, domain, BLoC/Cubit, pages
    cart/               # data, domain, BLoC, pages
    profile/            # profile presentation
  main.dart
```

Widgets depend on BLoCs/Cubits and repository contracts. Repository implementations own API and persistence concerns. Domain code does not call Dio, Hive, secure storage, or widgets directly. Detailed dependency and source-of-truth rules are in `docs/architecture.md`.

## Package choices

The constraints in `pubspec.yaml` were selected deliberately rather than copied from a random tutorial fossil.

| Package | Constraint | Purpose and rationale |
|---|---:|---|
| `flutter_bloc` | `^9.1.1` | Explicit event/state transitions and testable presentation logic. |
| `dio` | `^5.10.0` | Timeouts, typed request configuration, interceptors, and centralized exception mapping. |
| `go_router` | `^17.3.0` | Declarative guarded routing and a stateful bottom-navigation shell. |
| `hive_ce_flutter` | `^2.3.4` | Maintained structured local persistence without native SQL setup or generated adapters. |
| `flutter_secure_storage` | `^10.3.1` | Platform-backed storage for session/token-sensitive material. |
| `cryptography` | `^2.9.0` | PBKDF2-HMAC-SHA256 hashing with secure random salt generation. |
| `cached_network_image` | `^3.4.1` | Product image caching, placeholders, and error handling. |
| `equatable` | `^2.1.0` | Predictable immutable state comparison. |
| `intl` | `^0.20.2` | Currency/date presentation. |
| `uuid` | `^4.5.3` | Stable local account and saved-cart identifiers. |
| `bloc_test` / `mocktail` | `^10.0.0` / `^1.0.5` | BLoC transition and repository interaction tests. |

No source generation is used. Models use explicit defensive parsing so the assessment remains easy to inspect and change.

## Fake Store API limitation

Fake Store API create, update, and delete calls return simulated responses but do not permanently alter its database. LumaCart therefore follows these rules:

- API users authenticate remotely and then receive their full profile by username matching against `/users`.
- Sign-up calls `/users` for integration demonstration, then stores the new account locally with a salted hash so it remains usable after restart.
- Current and saved carts are always persisted locally and are the reliable source of truth.
- A remote cart POST is optional feedback only. Failure never removes or invalidates the local saved cart.

API base URL: `https://fakestoreapi.com`

Official documentation: `https://fakestoreapi.com/docs`

## Demo API credentials

The provided API reference includes this existing account:

```text
Username: mor_2314
Password: 83r5^_
```

These are public demonstration credentials from the fake API, not application secrets.

## Setup

Prerequisites:

- Flutter 3.44 or newer on the stable channel, with its bundled Dart 3.12 or newer SDK.
- Android Studio or Android command-line tools, a configured Android SDK, and accepted licenses.
- Java compatible with the installed Flutter/Android Gradle Plugin toolchain.

From the repository root:

```bash
flutter doctor -v
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

The API base URL defaults to Fake Store API and can be overridden without editing source:

```bash
flutter run --dart-define=API_BASE_URL=https://fakestoreapi.com
```

## Code generation

None. There is no `build_runner` step.

## Tests

The repository contains 16 executable test suites plus shared fixtures/fakes. Run:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Coverage areas include model parsing, password hashing, Dio error mapping, authentication transitions, product loading/filtering/cache fallback, cart arithmetic/persistence/restore behavior, and key widget states.

## Android release build

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Expected universal APK path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The checked-in release configuration uses the standard local debug signing key only as an installable assessment fallback. Replace it with a non-committed production keystore configuration before distribution. See `docs/release-report.md`.

## Documentation

- `docs/requirements.md`
- `docs/visual-identity.md`
- `docs/ux-plan.md`
- `docs/architecture.md`
- `docs/progress.md`
- `docs/test-report.md`
- `docs/release-report.md`
- `assets/image-prompts.md`
- `assets/README.md`

## Known limitations

- Flutter, Dart, and the Android SDK were unavailable in the execution environment, so dependency resolution, analyzer execution, Flutter tests, APK compilation, installation, and device smoke testing remain unverified here.
- The Gradle wrapper is present, but its distribution download failed because external DNS access was unavailable.
- Generated brand illustrations and raster launcher assets are intentionally not included. Buildable vector placeholders are supplied, and production prompts are documented in `assets/image-prompts.md`.
- Remote cart history is supported in the repository layer but intentionally not promoted as the local saved-cart source of truth.
- No checkout, payment, order processing, admin CRUD, or wishlist functionality is included.
