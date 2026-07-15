# Test and Quality Report

## Scope

The project includes 16 executable Dart/Flutter test suites and two shared helper files. The suite is designed to cover domain parsing, hashing, failure mapping, repository behavior, BLoC transitions, and critical widget states.

## Commands attempted

| Command | Result | Evidence |
|---|---|---|
| `flutter clean` | Not executed: `flutter` command unavailable, exit 127. | `docs/validation-logs/flutter-clean.txt` |
| `dart format --set-exit-if-changed .` | Not executed: `dart` command unavailable, exit 127. | `docs/validation-logs/dart-format.txt` |
| `flutter analyze` | Not executed: `flutter` command unavailable, exit 127. | `docs/validation-logs/flutter-analyze.txt` |
| `flutter test` | Not executed: `flutter` command unavailable, exit 127. | `docs/validation-logs/flutter-test.txt` |
| Dart syntax parse using Tree-sitter | Passed for all 66 Dart files. | `docs/validation-logs/dart-parse.txt` |
| Repository structure/import/XML check | Passed after required delivery files were added. | `docs/validation-logs/static-structure.txt` |
| Source, secret/binary, logging, and required-file audit | Passed. | `docs/validation-logs/source-audit.txt` |
| `git diff --check` | Passed. | `docs/validation-logs/git-diff-check.txt` |

A syntax parser and structural checks are useful preflight evidence, but they do not replace Dart formatting, Flutter analysis, package resolution, compilation, or tests. No Flutter test is reported as passed.

## Test inventory

### Unit and repository tests

- `test/features/auth/auth_models_test.dart`
- `test/features/auth/auth_repository_test.dart`
- `test/features/products/product_model_test.dart`
- `test/features/cart/cart_models_test.dart`
- `test/core/utils/password_hasher_test.dart`
- `test/core/network/dio_failure_test.dart`
- `test/features/products/products_repository_test.dart`

Coverage includes defensive malformed-field parsing, PBKDF2 verification, safe failure categories, cached product fallback, currency totals in integer cents, quantity clamping, and merge/replace semantics.

### BLoC tests

- `test/features/auth/auth_bloc_test.dart`
- `test/features/products/products_bloc_test.dart`
- `test/features/cart/cart_bloc_test.dart`

Coverage includes session restoration, successful and failed authentication, local registration, logout, loading/refresh/retry/filter transitions, cart mutation, persistence, snapshot saving, restore, and deletion.

### Widget tests

- `test/features/auth/presentation/sign_in_page_test.dart`
- `test/features/auth/presentation/sign_up_page_test.dart`
- `test/features/products/presentation/home_page_test.dart`
- `test/features/products/presentation/product_details_page_test.dart`
- `test/features/cart/presentation/cart_page_test.dart`
- `test/features/profile/presentation/profile_page_test.dart`

Coverage includes validation messages, password visibility, product loading/content/empty states, product add-to-cart action, empty/populated cart rendering, and safe profile display.

## Automated totals

- Dart source files parsed: 66
- Application Dart files: 48
- Test/helper Dart files: 18
- Executable `*_test.dart` suites authored: 16
- Flutter tests executed: 0, because Flutter was not installed
- Analyzer findings: unavailable, because Flutter/Dart were not installed

## Manual test matrix

The following matrix must be executed on a Flutter-supported emulator or device before accepting a release:

| Area | Scenario | Expected result | Status here |
|---|---|---|---|
| Session | Cold launch with no session | Sign-in screen appears | Not run |
| Session | Relaunch after API/local sign-in | Main shell is restored | Not run |
| API auth | Valid demo credentials | Token stored securely, profile matched, shell opens | Not run |
| API auth | Invalid credentials | Specific safe failure, no session created | Not run |
| Local auth | Register, terminate, then sign in | Account remains usable; no plaintext password | Not run |
| Catalog | Online first load | Products/categories render with images and ratings | Not run |
| Catalog | Offline after prior success | Cached products remain visible with offline notice | Not run |
| Search | Title/category query and chip filtering | Debounced case-insensitive results | Not run |
| Details | Select quantity and add | Correct quantity enters cart; feedback appears | Not run |
| Cart | Add duplicate product | Existing line quantity increases | Not run |
| Cart | Increment/decrement/remove/undo | Quantities and totals update and persist | Not run |
| Saved carts | Save, reopen, restore replace/merge, delete | Stable snapshots survive restart | Not run |
| Profile | API and local profiles | Safe fields render; no token/password | Not run |
| Logout | Logout from protected route | Session clears and protected route redirects | Not run |
| Accessibility | 200% text scale and TalkBack | No critical clipping; controls are labeled and reachable | Not run |

## Device and environment

- Host: Linux x86_64
- Java: OpenJDK 21.0.10
- Flutter SDK: not installed
- Dart SDK: not installed independently
- Android SDK/platform tools: not installed
- Emulator/physical device: unavailable

## Known quality limitations

- Dependency compatibility and analyzer lint compliance must still be confirmed with `flutter pub get` and `flutter analyze` in a real Flutter environment.
- Widget rendering and animation behavior require Flutter test/runtime execution.
- Network behavior against the live Fake Store API requires an environment with network access.
- Android installation, rotation, process-death restoration, TalkBack, and large-text checks remain manual release gates.
