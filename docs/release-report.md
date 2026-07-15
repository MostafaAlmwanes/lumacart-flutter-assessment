# Android Release Report

## Release status

**Blocked in this execution environment.** The Android project and release configuration are present, but no APK was generated because Flutter, Dart, and the Android SDK were not installed. The source archive is deliverable; an APK is not.

## Toolchain information

| Item | Detected value |
|---|---|
| Host | Linux x86_64 |
| Java | OpenJDK 21.0.10 |
| Flutter | Not installed; `flutter doctor -v` exited 127 |
| Dart | Not installed independently; `dart format` exited 127 |
| Android SDK | Not installed/detected |
| Gradle wrapper | Included, configured for Gradle 9.1.0 |
| Gradle execution | Wrapper started, then distribution download failed due unavailable DNS for `services.gradle.org` |

The Android scaffold is aligned with the Flutter 3.44.6 template defaults: Gradle 9.1.0, Android Gradle Plugin 9.0.1, Kotlin Gradle Plugin 2.3.20, minimum SDK 24, and compile/target SDK 36. The actual release machine must still record `flutter --version` and `flutter doctor -v` output.

## Android configuration

- Application ID: `com.lumacart.store`
- Display name: `LumaCart`
- Minimum SDK: 24
- Compile/target SDK: inherited from Flutter 3.44.6 (template baseline: Android API 36)
- Internet permission: declared
- Development banner: disabled in application configuration
- Launcher/splash: buildable vector placeholders supplied; Android 12+ splash resources are separated under `values-v31`
- Universal APK command: `flutter build apk --release`
- Expected APK path: `build/app/outputs/flutter-apk/app-release.apk`

## Commands and results

| Command | Result |
|---|---|
| `flutter doctor -v` | Failed before execution: Flutter command not found, exit 127 |
| `flutter clean` | Failed before execution: Flutter command not found, exit 127 |
| `flutter pub get` | Failed before execution: Flutter command not found, exit 127 |
| `flutter analyze` | Failed before execution: Flutter command not found, exit 127 |
| `flutter test` | Failed before execution: Flutter command not found, exit 127 |
| `flutter build apk --release` | Failed before execution: Flutter command not found, exit 127 |
| `./android/gradlew --version` | Wrapper launched; Gradle distribution download failed with `UnknownHostException` |

Raw logs are in `docs/validation-logs/`.

## APK artifact

| Field | Value |
|---|---|
| Filename | Not generated |
| Path | Expected: `build/app/outputs/flutter-apk/app-release.apk` |
| Size | Not available |
| SHA-256 | Not available |
| Signing status | Source is configured to use the local Android debug key for an installable assessment release fallback; no key is committed |
| Installation result | Not performed |
| Smoke-test result | Not performed |

## Signing

No private keystore, password, or `key.properties` file is committed. The current `release` build type references Android's local debug signing configuration so an assessor can produce an installable local assessment APK after installing the toolchain.

For a distributable production build:

1. Generate or supply a release keystore outside source control.
2. Store aliases and passwords outside the repository, preferably through CI secrets or an untracked properties file.
3. Define a release signing configuration in `android/app/build.gradle.kts`.
4. Replace the assessment debug signing reference with the release signing configuration.
5. Run format, analysis, tests, and the release build before publishing.
6. Record `sha256sum build/app/outputs/flutter-apk/app-release.apk` and verify the signing certificate with Android build tools.

## Release-machine procedure

```bash
flutter doctor -v
flutter clean
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
sha256sum build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Then perform the manual matrix in `docs/test-report.md`, including cold start, API login, local registration/restart, cached offline catalog, cart persistence, saved-cart restore, logout guarding, large text, and TalkBack.

## Known release limitations

- There is no built APK, checksum, installation result, or smoke-test result from this environment.
- Package resolution and Android plugin compatibility remain to be verified on the release machine.
- Placeholder launcher and empty-state visuals should be replaced using `assets/image-prompts.md` only after generated assets are supplied.
