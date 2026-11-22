# GoldVault

**GoldVault** is a cross-platform personal finance platform built with **Flutter (Dart)**, **Kotlin** (Android), and **Swift** (iOS), backed by **Supabase (PostgreSQL + Google OAuth)** and deployed on **Vercel** (Web PWA) and **GitHub Releases** (Native Android APK).

## Key Features

- **Native Android Bank Notification Listener (`BankNotificationService.kt`)**:
  - Uses Android's native `NotificationListenerService` to monitor notifications 24/7 in the background—without third-party automation apps—for **Nequi**, **Nu Bank**, **Lulo Bank**, **ARQ**, and **Morse**.
  - Automatically parses payment amounts (including automatic USD-to-COP FX conversion for ARQ/USD transactions), merchant descriptions, categories, and bank accounts, while filtering out OTP codes, login alerts, and declined transactions.
  - Syncs directly to Supabase via the `public.ingest_bank_notification` PostgreSQL RPC (`SECURITY DEFINER`) even when the Flutter UI is closed.
- **Native iOS Project (`ios/`) & iOS Shortcuts Webhook (`api/bank.js`)**:
  - Configured with bundle ID `app.goldvault.goldvault`, OAuth deep link schemes (`goldvault://` and `io.supabase.goldvault://`), obsidian launch screen, App Store-compliant opaque icons, and personal webhook URL for Apple Pay / iOS Shortcuts.
- **Mandatory Google Authentication & Resilient Cloud Sync**:
  - Enforces Google OAuth (`supabase_flutter`) with automatic sync recovery: failed cloud mutations are persisted in a local pending queue and flushed in causal order before pulling remote state, preventing unsynced edits from being overwritten and preventing initial sync failures from routing existing users to onboarding.
- **Standardized 8-Tier Typographic System (`GVTxt`)**:
  - Strict typographic hierarchy (`display`, `h1`, `h2`, `h3`, `body`, `sm`, `xs`, `xs2`) across light (*Warm Ivory*) and dark (*Obsidian + Liquid Gold*) themes.
- **Spaces, Goals, Budgets & Natural Language Quick Entry**:
  - Multi-space architecture with custom categories, category budget caps, savings goals, 6-month trend bar charts, and natural language expense parsing (e.g., `20 mil almuerzo en nequi`).

## Repository Structure

```text
├── android/
│   ├── app/src/main/kotlin/app/goldvault/goldvault/
│   │   ├── BankNotificationService.kt   # Native Android 24/7 NotificationListenerService
│   │   └── MainActivity.kt              # MethodChannel bridge & Android 13+ settings helper
│   └── key.properties.example           # Template for local Android release signing
├── ios/
│   └── Runner/                          # Native iOS runner, OAuth URL schemes, launch screen & icons
├── api/
│   └── bank.js                          # Serverless webhook endpoint for iOS Shortcuts / Apple Pay
├── lib/
│   ├── main.dart                        # App entry point, status bar styling & root state gate
│   ├── models/models.dart               # Domain models & BankNotificationParser
│   ├── screens/account_screens.dart     # Login, Offline guard, Sync error recovery & Onboarding
│   ├── screens/goals_tab.dart           # Savings goals Bento view
│   ├── screens/home_and_shells.dart     # Lightweight navigation shell coordinating tabs & glass dock
│   ├── screens/home_tab.dart            # Dashboard with Anodized Hero Card, charts & bank review
│   ├── screens/movement_sheet.dart      # Apple-style movement creation/editing bottom sheet
│   ├── screens/movements_tab.dart       # Searchable grouped inset movements list
│   ├── screens/settings_tab.dart        # Appearance, account/sync, bank automation & customization
│   ├── screens/space_modals.dart        # Spaces switcher, space customization & add-goal sheets
│   ├── state/app_state.dart             # Reactive state, pending sync queue & Supabase adapter
│   ├── theme/gold_theme.dart            # Apple Daylight & Space Black Pro tokens + vector logo
│   └── widgets/
│       ├── charts.dart                  # CustomPainter 6-month trend & category donut charts
│       └── gv_components.dart           # Reusable Apple Bento design system primitives
├── scripts/
│   └── check_release_version.py         # Verifies release tag vX.Y.Z matches pubspec.yaml
└── test/
    ├── sync_recovery_test.dart          # Sync failure recovery & platform UI test suite
    └── widget_test.dart                 # Unit & widget layout test suite
```

## Android Release Signing

Release signing credentials are never committed to Git. Configure signing via one of:

- **Local builds**: Copy `android/key.properties.example` to `android/key.properties` (gitignored) and populate `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.
- **GitHub Actions releases**: Configure these repository secrets in GitHub Settings:
  - `ANDROID_KEYSTORE_BASE64` (base64-encoded `.jks` keystore)
  - `KEYSTORE_PASSWORD`
  - `KEY_ALIAS`
  - `KEY_PASSWORD`

Tag builds (`vX.Y.Z`) enforce `REQUIRE_RELEASE_SIGNING=true` and verify the APK signature with `apksigner verify` to guarantee no debug-signed release is ever published.

## Automatic Vercel Web Deployment (GitHub Actions)

The `deploy-web` job in `.github/workflows/build-apk.yml` takes the compiled Flutter Web bundle (`build/web`) together with the `/api/bank` serverless function and deploys via `vercel pull` → `vercel build` → `vercel deploy --prebuilt` (preview URLs on pull requests, `--prod` on `master`/`main`, tags, and manual dispatch).

Configure these repository secrets in GitHub Settings:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

## Development & Build Commands

```bash
# Run static analysis and unit/widget tests
flutter analyze --no-fatal-infos
flutter test

# Build Web production bundle (deployed to Vercel)
flutter build web --release --pwa-strategy=none

# Build Native Android Release APK
flutter build apk --release --no-tree-shake-icons

# Build Native iOS Release (unsigned verification)
flutter build ios --release --no-codesign
```

## Production Links

- **Web App (PWA)**: [https://goldvault-app.vercel.app](https://goldvault-app.vercel.app)
- **Android Native APK**: [GitHub Releases (`latest`)](https://github.com/santiago-jv/goldvault/releases/latest)
