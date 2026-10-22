# GoldVault

**GoldVault** is a cross-platform personal finance platform built with **Flutter (Dart)** and **Kotlin**, backed by **Supabase (PostgreSQL + Google OAuth)** and deployed on **Vercel** (Web PWA) and **GitHub Releases** (Native Android APK).

## Key Features

- **Native Android Bank Notification Listener (`BankNotificationService.kt`)**:
  - Uses Android's native `NotificationListenerService` to monitor notifications 24/7 in the background—without third-party automation apps—for **Nequi**, **Nu Bank**, **Lulo Bank**, **ARQ**, and **Morse**.
  - Automatically parses payment amounts (including automatic USD-to-COP FX conversion for ARQ/USD transactions), merchant descriptions, categories, and bank accounts, while filtering out OTP codes, login alerts, and declined transactions.
  - Syncs directly to Supabase via the `public.ingest_bank_notification` PostgreSQL RPC (`SECURITY DEFINER`) even when the Flutter UI is closed.
- **Mandatory Google Authentication & Online Sync**:
  - Enforces Google OAuth (`supabase_flutter`) and active internet connectivity (`OfflineGuardScreen`) to ensure real-time cloud consistency across devices.
- **Standardized 8-Tier Typographic System (`GVTxt`)**:
  - Strict typographic hierarchy (`display`, `h1`, `h2`, `h3`, `body`, `sm`, `xs`, `xs2`) across light (*Warm Ivory*) and dark (*Obsidian + Liquid Gold*) themes.
- **Spaces, Goals, Budgets & Natural Language Quick Entry**:
  - Multi-space architecture with custom categories, category budget caps, savings goals, 6-month trend bar charts, and natural language expense parsing (e.g., `20 mil almuerzo en nequi`).

## Repository Structure

```text
├── android/
│   └── app/src/main/kotlin/app/goldvault/goldvault/
│       ├── BankNotificationService.kt   # Native Android 24/7 NotificationListenerService
│       └── MainActivity.kt              # MethodChannel bridge & Android 13+ settings helper
├── api/
│   └── bank.js                          # Serverless webhook endpoint for iOS Shortcuts / Apple Pay
├── lib/
│   ├── main.dart                        # App entry point & root state gate
│   ├── models/models.dart               # Domain models & BankNotificationParser
│   ├── screens/home_and_shells.dart     # UI screens, navigation shell & modals
│   ├── state/app_state.dart             # Reactive state & Supabase synchronization
│   ├── theme/gold_theme.dart            # Color palettes, 8-tier typography & vector logo
│   └── widgets/charts.dart              # CustomPainter 6-month trend & category donut charts
└── test/
    └── widget_test.dart                 # Unit & widget layout test suite
```

## Development & Build Commands

```bash
# Run static analysis and unit/widget tests
flutter analyze
flutter test

# Build Web production bundle (deployed to Vercel)
flutter build web --release --pwa-strategy=none

# Build Native Android Release APK
flutter build apk --release
```

## Production Links

- **Web App (PWA)**: [https://goldvault-app.vercel.app](https://goldvault-app.vercel.app)
- **Android Native APK**: [GitHub Releases (`latest`)](https://github.com/santiago-jv/goldvault/releases/latest)
