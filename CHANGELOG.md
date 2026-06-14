# Changelog

All notable changes to this project are documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.2.1] - 2026-06-15

### Changed
- Updated terms of use URL to point to `terms.html`

### Fixed
- Stack product stock and discount/featured badges vertically in the top-right of product cards
- Anchor product card favorite button at top-left for consistent alignment across screen sizes
- Unified product card grid aspect ratio to 0.68 for consistent visual identity

---

## [1.2.0] - 2026-05

### Added
- Multi-image product gallery with pinch-to-zoom lightbox
- Synchronized `product_images` database table with Flutter Product model and repository

---

## [1.1.0] - 2026-04 to 2026-05

### Added
- Customer profile Phase 2: favorites (heart button on ProductCard + My Favorites screen)
- Customer profile Phase 2: saved addresses (CRUD + checkout integration)
- Customer profile Phase 2: direct avatar upload from profile header
- Customer profile Phase 2: help center FAQ screen
- Premium beta disclaimer dialog with SharedPreferences persistence
- Two-party cash payment confirmation: customer acknowledgment and technician enforcement
- Manager promotion and product sales tools
- Home screen promotional slider and deals section

### Changed
- Redesigned customer home screen layout
- Redesigned customer profile (My Account) screen
- Replaced help center WhatsApp button with email contact launcher
- Support email updated to s.bagomri@gmail.com
- Quote request and checkout UI unified with reusable appointment picker

### Fixed
- Delivery-only product orders excluded from commission calculation
- Commission calculation returning zero in edge cases
- Technician tasks not appearing in "My Tasks" and history views
- Technician cash confirmation required before task completion
- Saved address picker top padding in checkout flow
- Conditional label rendering in TammTextField to prevent layout gaps
- In-app review launching store listing in debug mode instead of in-app sheet
- Address save failing due to missing userId
- Avatar upload MIME type mapping (jpg to jpeg)
- Profile screen: removed language tile, corrected My Devices section and rating button behavior

---

## [1.0.0] - 2026-01 to 2026-04

### Added
- Complete quote system (Phases 1-5): customer submission with file attachments, manager review, technician assignment, status tracking in real time
- Manager workflow: assign technician after quote acceptance, cancel order
- Manager order detail route and stats cards
- Technician management: add technician, view details, realtime roster
- GPS location capture for service orders
- FCM push notifications infrastructure (Android) with Supabase Edge Function
- Custom installation pricing per product
- Category filter chips on services screen linked from home
- Manager service management CRUD screens
- Manager product image upload from gallery
- Cart migrated to Supabase for persistence across sessions
- Google Sign-In authentication
- Technician advanced workflow: notes sync, UI unification (Phases 4-6)
- Pull-to-refresh and realtime updates on manager dashboard

### Changed
- App name updated to "تمّ" with new launcher icons
- Application ID changed to `com.bagomri.tamm`
- Auth migrated from email/password to Supabase Auth with Google Sign-In
- Currency unified to SAR (ر.س) across the application

### Fixed
- Navigation back button and app logo alignment
- Duplicate page key assertion resolved with navigatorKey on ShellRoutes
- Missing manage services route causing navigation assertion failure
- Arabic locale initialization for AppointmentPicker and QuoteRequest screens
- RLS infinite recursion on role-based policies
- Quote status not updating after customer accept/reject
- Dashboard quote counts and filter logic
- PDF file picker integration and non-blocking upload error handling
- Memory leak: provider cache carrying over after logout
- Layout overflow and infinite width constraint in Add Technician screen
- GridView replaced with Row for stats cards to eliminate overflow on small screens
- Phone call launcher failing silently on specific Android launchers
- Keyboard bottom overflow in technician task detail screen

---

## [0.1.0] - 2026-01

### Added
- Initial implementation: authentication, customer home, manager dashboard, technician task list
- Supabase schema and RLS policies
- Three-role architecture: customer, manager, technician
- go_router shell navigation with bottom navigation bars per role
- Riverpod state management with repository pattern
