# The Flutter kit

Contents:
1. Day 0; 2. Module map; 3. Rules the gates enforce; 4. Add when needed

The kit at `assets/flutter-kit/` is a complete, brand-free Flutter app: theme, core, app layer, about 35 widgets with a gallery, one example feature (`features/settings`), tests, and the gates. A new project copies it and owns the copy; nothing in it is a package to upgrade.

## 1. Day 0

1. Run the script. Pass the app name alone and it derives the package and the target (`./<package>` under the current directory, or under `$NEW_FLUTTER_APP_ROOT`, printed), or pass all three:

```bash
scripts/new-flutter-app "Atlas"
scripts/new-flutter-app ~/code/atlas atlas "Atlas" --org com.acme
```

It refuses a non-empty target, runs `flutter create` for ios, android and web, copies the kit, renames `kit_app` and `Kit App` everywhere (imports, pubspec, ARB, platform names, bundle and application ids), copies the env examples to git-ignored `env/dev.json` and `env/prod.json`, runs `pub get --enforce-lockfile` and `gen-l10n`, and stages the files. Every direct dependency is an exact version and the kit's `pubspec.lock` travels with it, so a new app starts on the versions the kit was proven on; commit the lock, and bump a package on purpose with `flutter pub upgrade <package>` and a green `verify.sh`. Without `--org` the ids start with `dev.<package>`: set your own domain before a release.

2. Fill `lib/core/theme/brand.dart` (two seeds, an accent, font roles). `flutter test test/core/theme` names any text colour that misses WCAG AA. Replace `assets/images/logo.png`, same path.
3. Set `Env`: edit `env/dev.json` and `env/prod.json` (`BASE_URL`, `FLAVOR`), and add a key to `Env` and to the example files for each new setting. Never commit a real env file.
4. Replace `AppRole` and `UserStatus` in `core/session/app_role.dart`, then `RouteGuard.access`, `destinationsFor` and `AppRole.parse` in the same change.
5. Replace the example paths in `core/network/api_endpoints.dart`; list every sign-in path in `signInPaths`.
6. Add the first feature by copying `features/settings` (model, source, repository, contract, Cubit, view, widgets) and its tests; register it in a module under `app/di/modules/`.
7. Run `bash tool/verify.sh`. Run `flutter run --dart-define-from-file=env/dev.json`; add `--dart-define=KIT_GALLERY=true` to open the widget gallery first.

## 2. Module map

For each module: what it gives, then the file to change first.

- **theme**
  - Gives: tokens, palette, text styles (weight axis for Bold Text), `Motion` and reduce-motion scope, contrast, haptics, page transitions, platform style.
  - Change first: `core/theme/brand.dart`.
- **utils**
  - Gives: width classes (phone, tablet, web) and layout helpers.
  - Change first: `core/utils/responsive.dart` (breakpoints).
- **helpers** (`core/utils`, `core/validation`, `core/logging`, `core/l10n/format_extensions.dart`, `core/platform/link_actions.dart`)
  - Gives: `context.l10n`, `formats` and `isRtl`; `westernDigits` for every field the API gets; `apiDate` (UTC) vs `displayDate` (local); `Validators` (EN and AR messages); `AppLog` (redacts secrets, silent in release, errors go to the crash reporter by type); `Debouncer`; `LinkActions` (opens web, mail and phone links, copies on the web, never throws).
  - Change first: the phone and password rules in `core/validation/validators.dart`, if the product's differ.
- **l10n**
  - Gives: Arabic-Indic digits in the UI, Western digits and `'en'` dates for the API, `AutoDirectionText` (text that sets its own direction) and `AppDirectionalIcon` (an icon that mirrors in RTL), EN and AR ARB.
  - Change first: `lib/l10n/app_en.arb` and `app_ar.arb` (add a key to both).
- **platform**
  - Gives: `PlatformCapabilities`: what the platform can do, so screens never test `kIsWeb`.
  - Change first: `core/platform/platform_capabilities.dart` when a capability is added.
- **config**
  - Gives: `Env` read from `--dart-define-from-file`; no defaults, a missing key stops the boot.
  - Change first: `core/config/env.dart`, `env/*.example.json`.
- **network**
  - Gives: Dio client, auth interceptor, retry (idempotent calls only), status and network-health interceptors, reachability, request policy, `json_read`.
  - Change first: `core/network/api_endpoints.dart`.
- **session**
  - Gives: session Cubit, repository, sign-out with a session generation, stale-session guard, startup decision, `SessionBound`.
  - Change first: `core/session/app_role.dart`, `session_remote_source.dart`.
- **storage**
  - Gives: secure storage with one writer (keychain or keystore on phones, memory only on the web, so a token never lands in localStorage), preferences that keep only the named user fields, key registry, schema-version stamp with a migrate hook.
  - Change first: `core/storage/storage_keys.dart`.
- **error**
  - Gives: `Failure` types, error handler, failure messages, `guardStep`.
  - Change first: `core/error/failure_messages.dart` (copy).
- **time**
  - Gives: `AppClock` over `package:clock`, time units.
  - Change first: none; use it instead of `DateTime.now()`.
- **cache and state**
  - Gives: `CacheLayer.cacheThenNetwork` (memory, disk, time to live, stale then fresh, offline fallback, cleared on sign-out), `ViewState` and `ViewCubit` on `SafeCubit`, `PagedListCubit` for `AppPagedList`, `debounce` and `throttle` for Bloc events.
  - Change first: none; give each cached call its own key and time to live.
- **di**
  - Gives: `get_it` locator that is safe to reset and rebuild on a boot retry.
  - Change first: `app/di/modules/` (one module per area).
- **crash, telemetry**
  - Gives: `CrashReporter` and `AnalyticsSink` interfaces with no-op defaults; a recording mask.
  - Change first: register the vendor in `app/di/modules/core_module.dart`.
- **router**
  - Gives: `go_router`, route names, guards and redirects, pending deep link.
  - Change first: `app/router/app_router.dart`, `core/router/route_names.dart`. Every route inside the shell's `ShellRoute` must be a tab in `shell_destinations.dart` or under one (`/tab/...`): a debug build asserts on any other, and a release build highlights no tab. Put a full-screen route outside the `ShellRoute`.
- **app**
  - Gives: guarded boot steps, boot failure screen, startup gate, lifecycle wiring, session recovery, adaptive shell (tab bar on phone, rail on tablet and web), kit gallery.
  - Change first: `app/shell/shell_destinations.dart`.
- **notifications, permissions** (`core/notifications`, `core/permissions`, `core/platform/plugin_*`)
  - Gives: `PushService` (no-op; the vendor slot), local notifications on channel `general` (the channel id is a project setting: pick it before the first release and never rename it), taps routed through the guard and `PendingDeepLink` (only an in-app path opens), `Permissions` with every state (not asked, granted, limited, denied, permanently denied, revoked, unavailable), `PermissionCubit` and `PermissionPrompt`; sign-out clears both.
  - Change first: the usage strings, in both languages: English in `ios/Runner/Info.plist` and Arabic in `ios/Runner/ar.lproj/InfoPlist.strings` (the kit ships quiet generic ones; rewrite both for the product), the small notification icon `android/app/src/main/res/drawable/ic_notification.xml` (one flat colour, no brand), and the channel name copy (`notificationChannelGeneral`; it follows the app language).
  - Photos on Android: the scaffold adds `READ_MEDIA_IMAGES` and `READ_EXTERNAL_STORAGE` (up to API 32). On the web the camera reads "not asked" until the browser has asked, and photos are picked in the browser; a refused permission shows one line asking for the browser's site settings, with no button (pass `canOpenSettings: capabilities.appSettingsPage` to `PermissionPrompt`).
  - On macOS a failed iOS configuration step stops the scaffold. Off macOS the scaffold cannot run the iOS configuration step. On a Mac run `flutter build ios --config-only --no-codesign`, then add `PERMISSION_NOTIFICATIONS=1`, `PERMISSION_CAMERA=1` and `PERMISSION_PHOTOS=1` to `GCC_PREPROCESSOR_DEFINITIONS` in the Podfile's `post_install`.
- **media** (`core/media`, `AppNetworkImage`, `AppAvatarUpload`)
  - Gives: picking (the camera explains itself through `Permissions` and `PermissionPrompt` first, photos go through the system picker, no location data kept), the `ImageCropSlot` (ships `NoCrop`), cached images with shimmer and unavailable states, and an avatar upload with whole-percent progress and a retry that keeps the photo; sign-out empties the image cache.
  - Change first: `ApiEndpoints.avatar` and the multipart field name in `DioAvatarUploader`.
- **widgets**
  - Gives: button, text field, sheet, dialog, row, group, segmented, pickers, state views, loading, shimmer, skeletons, snackbar, lists, banners, avatar, scaffold, rolling digits and more.
  - Change first: `core/widgets/` (use as is; see the gallery).
- **auth feature**
  - Gives: sign in, sign up, verify code (with resend cooldown), forgot and reset password, complete profile, blocked and no-access screens, on `AuthRepository`; the guard moves screens on when the session changes.
  - Change first: the paths in `ApiEndpoints`, the body keys in `AuthRemoteSource`, and `RouteGuard.nameMissing` if the product needs other profile fields.
- **settings feature**
  - Gives: theme, language and text size across every layer, and a quiet sign-out under the settings groups.
  - Change first: copy it for the first feature.
- **tool and test**
  - Gives: `verify.sh`, analyze gate, coverage gate, secret scan (file names and key-shaped content), strict format, gen-l10n drift check, architecture rules and tests, goldens.
  - Change first: `tool/architecture_rules.dart` when a rule changes.
- **.github/workflows/verify.yml**
  - Gives: `tool/verify.sh` on every pull request on Flutter 3.44.9, with Flutter and pub caches (the pub key hashes `pubspec.yaml` and `pubspec.lock` together; the kit ships its lock, so keep it committed); packages resolve with `flutter pub get --enforce-lockfile`, so a lock out of step with `pubspec.yaml` fails the run; goldens skip on CI; actions pinned to commit SHAs, read-only token. The pinned actions run on Node 24 and need Actions Runner 2.327.1 or newer: fine on GitHub-hosted runners, update a self-hosted one first.
  - Change first: nothing; raise the Flutter pin here when the project upgrades.

## 3. Rules the gates enforce

`bash tool/verify.sh` is the one command, locally and in CI. It fails on:

- a secret file tracked or about to be (`env/*.json` other than examples, keys, certificates);
- unformatted new code, a stale generated l10n file, or an analyzer finding (`very_good_analysis`, empty baseline);
- a failing test, a Cubit below the coverage gate, or a planned task with no test named for its id (traceability);
- an architecture rule, named in `tool/architecture_rules.dart`: a feature importing another feature or legacy code, core importing a feature, a screen importing a data source, a repository implementation or an HTTP, storage or SDK package, a feature file outside `data/` that re-exports anything in `data/` other than models, a raw host in `lib/`, a platform check outside `PlatformCapabilities`, an `// ignore:` comment, a skipped test, a runtime font fetch, a date format outside l10n or an API date without `'en'`, a raw colour, inline `TextStyle`, raw dimension or raw motion duration in UI code, a left or right edge instead of a directional one, text built by interpolation in a feature, a file over 400 lines.

To change a rule, edit `tool/architecture_rules.dart` and the architecture doc in one change, with the reason. Never exempt one file.

## 4. Add when needed

The kit leaves these out on purpose. Each is added behind `PlatformCapabilities`, with a no-op or hidden default on the web.

- **In-app calls and the system call UI.**
  - Pick a call SDK and a call-UI plugin.
  - Define a `CallService` contract under `features/call/domain/`, implement it in `data/`, register it in a DI module.
  - Gate the feature on `PlatformCapabilities.nativeCalls`.
  - Report each call to the OS from one owner only, to avoid duplicate rings.
  - Android needs the foreground-service permissions; iOS needs the VoIP background mode.
- **In-app purchase.**
  - Add the store plugin, define product ids in one registry file with a test, and verify receipts on your backend.
  - Gate on `PlatformCapabilities.inAppPurchase`; the web shows a different path to pay.
  - Never rename a live product id.
- **Session recording.**
  - Add the vendor SDK, then register a `RecordingMasker` that wraps a child in the vendor's mask widget (`core/telemetry/recording_mask.dart`).
  - Wrap every sensitive widget with `AppSensitive`.
  - Start the recorder after consent only.
- **Glass.**
  - The shell has a frosted fallback.
  - For the system look, add the glass package, build one adapter widget in `core/widgets/`, and choose it only where `PlatformStyle` says the platform supports it.
- **Brand fonts.**
  - Bundle the font files under `assets/fonts/`, declare them in `pubspec.yaml`, then set `Brand.bodyFamily` and the other font roles.
  - Never fetch a font at run time (the gate refuses it).
  - Test the Arabic glyphs and the weight axis.
- **Push.**
  - The kit ships `PushService` with a no-op default and no vendor SDK.
  - Implement `PushService` in `lib/core/platform/<vendor>_push_service.dart`, register it in `registerNotificationsModule`, ask `Permissions.request(AppPermission.notifications)` from a screen that explains why, send `tokens` to the backend, and send `data.location` (an in-app path) in each message.
  - Key the notification id on the vendor's message id in every path.
  - Never log a token or a message's text.
- **A high-contrast palette.**
  - The kit ships none. The shell's bar already turns opaque when `MediaQuery.highContrastOf` is on.
  - To add one, build a second `AppColors` from `brand.dart` with stronger ink and outlines, pick it in `AppTheme` when `highContrastOf` is on, and run the contrast tests against it.
- **Native launch screen theming.**
  - Edit `ios/Runner/Base.lproj/LaunchScreen.storyboard` and `android/app/src/main/res/values/styles.xml` (plus the `-night` file) to the brand's background and logo.
  - Match the first Flutter frame to avoid a flash; check light and dark.
