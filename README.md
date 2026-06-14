# Tamm

Field service management platform for AC maintenance and solar energy installation, built for the Yemeni market.

![Version](https://img.shields.io/badge/version-1.2.1-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/license-Proprietary-red)

---

## Overview

Tamm is a Flutter-based mobile and web application that connects customers with certified AC and solar energy technicians. The platform supports the complete service lifecycle — from quote requests and product orders through technician dispatch, on-site task completion, and payment confirmation.

The application shares a Supabase backend with a companion Next.js web dashboard used by managers.

---

## Features

### Customer
- Browse and order AC units, solar panels, and accessories from the product store
- Submit quote requests for custom installations with file attachments (PDF, images)
- Book service appointments with GPS-based location capture
- Track order and quote status in real time
- Manage saved addresses and product favorites
- In-app review and direct support contact

### Manager
- Dashboard with live order and quote statistics
- Quote lifecycle management: review, assign technicians, approve or reject
- Product and service catalog management with image uploads
- Technician roster management
- Promotional pricing and discount tools

### Technician
- Task queue with assigned jobs and scheduling details
- On-site notes and status updates
- Two-party cash payment confirmation
- Earnings summary and job history
- Push notification delivery for new assignments

---

## Technology

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart SDK ^3.11.0) |
| State Management | Riverpod 2.x with code generation |
| Navigation | go_router 13 |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| Push Notifications | Firebase Cloud Messaging (Android only) |
| UI Font | Alexandria (Google Fonts) |
| Models | Freezed + JSON Serializable |
| Auth | Supabase Auth with Google Sign-In |

---

## Architecture

The project follows a feature-first structure with a layered internal architecture.

```
lib/
  core/           # Design tokens, constants, theme, shared widgets
  features/
    auth/         # Authentication flow
    customer/     # Home, Store, Services, Search, Profile
    manager/      # Dashboard, Quotes, Products, Technician management
    technician/   # Tasks, Earnings, History, Profile
    notifications/
    profile/      # Shared profile logic
  shared/
    models/       # Freezed data models
    providers/    # Riverpod providers
    repositories/ # Data access layer
```

**Layer order:** Screen → Provider → Repository → Supabase

All errors propagate through `AppException`. New features follow the path `lib/features/[role]/[module]/presentation/`.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK ^3.11.0
- A Supabase project with the Tamm schema applied
- Firebase project with FCM enabled (for Android push notifications)
- Android Studio or Xcode for native builds

### Setup

1. Clone the repository.
2. Copy your Supabase credentials into the environment configuration.
3. Place `google-services.json` in `android/app/` (not committed — see `.gitignore`).
4. Run `flutter pub get`.
5. Run code generation: `dart run build_runner build --delete-conflicting-outputs`.

### Running

```bash
# Mobile (debug)
flutter run

# Web
flutter run -d chrome
```

---

## Building

### Android Release

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

Signing configuration uses `key.properties` (not committed). See [Flutter deployment documentation](https://docs.flutter.dev/deployment/android) for keystore setup.

### Web

```bash
flutter build web --release
```

---

## Project Information

| Field | Value |
|---|---|
| App Name | تمّ (Tamm) |
| Package ID | com.bagomri.tamm |
| Version | 1.2.1+5 |
| Minimum Android SDK | 21 (Android 5.0) |
| Target Platforms | Android, Web |
| Backend | Supabase |
| Primary Language | Arabic (RTL) |
| Location Permission | Fine and coarse location (for service address capture) |

---

## Privacy

The application requests device location solely for capturing service delivery addresses during booking. Location data is stored in the user's order record and is not used for tracking or analytics.

---

## License

Copyright (c) 2026 Saleh Bagomri. All rights reserved.

See [LICENSE](LICENSE) for the full terms.

---

## Contact

- **Developer:** Saleh Bagomri
- **Website:** [www.bagomri.com](https://www.bagomri.com)
- **Email:** [s.bagomri@gmail.com](mailto:s.bagomri@gmail.com)
- **Google Play:** [Tamm](https://play.google.com/store/apps/details?id=com.bagomri.tamm)
