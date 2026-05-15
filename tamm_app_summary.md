# Tamm App — Comprehensive Project Summary

> Generated: 2026-05-14 | Version: 1.1.0+3 | Flutter SDK: ^3.11.0

---

## 1. Project Overview

**تمّ** is a Flutter mobile/web application for AC (air conditioning) and solar energy services in Yemen. It connects three user roles in a single codebase:

| Role | Entry Point | Description |
|------|-------------|-------------|
| **Customer** | `/customer/home` | Browse store, book services, request quotes, track orders |
| **Manager** | `/manager/dashboard` | Manage orders, technicians, products, services, promotions, quotes |
| **Technician** | `/technician/tasks` | View assigned tasks, update status, manage profile |

Guests (unauthenticated) can browse the store and services but are prompted to log in before adding to cart or placing orders. Guest cart state is preserved in-memory and merged into Supabase on login.

---

## 2. Tech Stack & Key Dependencies

### Core Framework
- **Flutter** 3.x — cross-platform (Android, iOS, Web, Windows, Linux, macOS)
- **Dart** SDK ^3.11.0

### State Management
- `flutter_riverpod: ^2.5.1` — primary state management
- `riverpod_annotation: ^2.3.5` + `riverpod_generator` — code-gen providers

### Navigation
- `go_router: ^13.2.0` — declarative routing with shell routes

### Backend / Auth
- `supabase_flutter: ^2.5.0` — database, auth, realtime, storage
- `http: ^1.2.1` — wrapped in custom `TammHttpClient` with 5s timeout

### Push Notifications
- `firebase_core: ^4.5.0` + `firebase_messaging: ^16.1.2` — FCM
- `flutter_local_notifications: ^21.0.0` — local notification display

### Code Generation
- `freezed: ^2.5.2` + `freezed_annotation: ^2.4.1`
- `json_serializable: ^6.8.0` + `json_annotation: ^4.9.0`
- `build_runner: ^2.4.9`

### Forms
- `reactive_forms: ^17.0.1`

### UI / Assets
- `google_fonts: ^6.2.1` — **Alexandria** font (Arabic-optimized)
- `cached_network_image: ^3.3.1`
- `shimmer: ^3.0.0`
- `flutter_svg: ^2.0.10+1`
- `lottie: ^3.1.0`

### Auth
- `google_sign_in: ^7.2.0`

### Utilities
- `shared_preferences: ^2.2.3` — theme persistence
- `flutter_secure_storage: ^9.0.0`
- `intl: any` — Arabic date formatting
- `uuid: ^4.4.0`
- `image_picker: ^1.2.1`
- `file_picker: ^11.0.2`
- `permission_handler: ^11.3.1`
- `url_launcher: ^6.3.2`
- `geolocator: ^14.0.2`
- `app_links: ^7.0.0` — deep links (password reset via `tamm://` scheme)

---

## 3. Directory Structure

```
tamm_app/
├── lib/
│   ├── main.dart                    # App entry — Supabase init, FCM init, ProviderScope
│   ├── app.dart                     # TammApp widget — auth listener, deep links, FCM callbacks
│   ├── firebase_options.dart        # Generated Firebase config
│   │
│   ├── core/
│   │   ├── config/
│   │   │   └── env.dart             # Env vars (SUPABASE_URL, SUPABASE_ANON_KEY)
│   │   ├── constants/
│   │   │   ├── app_colors.dart      # Raw color constants (dark palette)
│   │   │   ├── app_spacing.dart     # 4pt grid spacing, border radii, icon sizes
│   │   │   ├── app_strings.dart     # Localized UI strings
│   │   │   ├── app_text_styles.dart # Font sizes, weights, style builders
│   │   │   └── product_specs.dart   # Product spec field definitions
│   │   ├── errors/
│   │   │   ├── app_exception.dart   # Sealed exception hierarchy
│   │   │   ├── error_mapper.dart    # Maps raw exceptions → AppException
│   │   │   └── error_notifier.dart  # Central error state (errorProvider)
│   │   ├── network/
│   │   │   └── tamm_http_client.dart # Custom HTTP client with 5s timeout
│   │   ├── router/
│   │   │   └── app_router.dart      # All GoRouter routes (appRouterProvider)
│   │   ├── services/
│   │   │   └── fcm_service.dart     # Firebase Cloud Messaging service
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # ThemeData for dark + light
│   │   │   └── tamm_colors.dart     # TammColors ThemeExtension + context.colors
│   │   ├── utils/
│   │   │   ├── auth_guard.dart      # requireAuth() — shows login bottom sheet
│   │   │   ├── platform_utils.dart  # Platform detection helpers
│   │   │   └── responsive.dart      # Breakpoints: mobile <768, tablet <1200, desktop 1200+
│   │   └── widgets/
│   │       ├── adaptive_shell.dart  # BottomNav (mobile) / Sidebar (tablet/desktop)
│   │       ├── error_state_widget.dart
│   │       ├── in_app_notification_banner.dart # FCM foreground banner (slide-in)
│   │       ├── responsive_wrapper.dart
│   │       ├── specs_editor.dart
│   │       ├── tamm_app_bar.dart
│   │       ├── tamm_bottom_nav.dart
│   │       ├── tamm_button.dart
│   │       ├── tamm_card.dart
│   │       ├── tamm_empty_state.dart
│   │       ├── tamm_loading.dart
│   │       ├── tamm_notification_bell.dart
│   │       ├── tamm_shimmer.dart
│   │       ├── tamm_success_badge.dart
│   │       ├── tamm_text_field.dart
│   │       └── tamm_theme_selector.dart
│   │
│   ├── features/
│   │   ├── auth/presentation/       # 7 auth screens
│   │   ├── customer/
│   │   │   ├── customer_shell.dart  # Customer ShellRoute wrapper (4-tab nav)
│   │   │   ├── home/
│   │   │   ├── profile/
│   │   │   ├── search/
│   │   │   ├── services/
│   │   │   └── store/
│   │   ├── manager/
│   │   │   ├── manager_shell.dart   # Manager ShellRoute wrapper (6-tab nav)
│   │   │   ├── dashboard/
│   │   │   ├── orders/
│   │   │   ├── products/
│   │   │   ├── promotions/
│   │   │   ├── quotes/
│   │   │   ├── services/
│   │   │   └── technicians/
│   │   ├── notifications/presentation/
│   │   ├── profile/screens/
│   │   └── technician/
│   │       ├── technician_shell.dart # Technician ShellRoute wrapper (2-tab nav)
│   │       ├── profile/
│   │       └── tasks/
│   │
│   └── shared/
│       ├── models/                  # 6 data models
│       ├── providers/               # 10 Riverpod provider files
│       └── repositories/           # 9 repository classes
│
├── assets/
│   ├── icons/                       # tamm-logo.png
│   ├── images/
│   └── lottie/
│
├── supabase/                        # Supabase migrations/config
├── ARCHITECTURE.md                  # Dev standards reference
└── pubspec.yaml
```

---

## 4. Architecture Pattern

```
UI Screen
   ↓  consumes
Riverpod Provider (FutureProvider / StateNotifierProvider)
   ↓  calls
Repository (direct Supabase calls)
   ↓  queries
Supabase (PostgreSQL + RLS + Realtime)
```

**Error flow:**
```
Repository throws AppException
   → Provider catches / surfaces via AsyncValue.error
   → Screen's .when(error: ...) renders ErrorStateWidget
   → OR: ref.read(errorProvider.notifier).show(e) → Shell SnackBar
```

**State hydration pattern:** Every shell invalidates its providers on tab tap (pull-to-refresh equivalent). No manual caching layer — Riverpod `autoDispose` handles cleanup.

---

## 5. Models (`lib/shared/models/`)

### `UserProfile`
```
id, email, fullName, phone, role (customer|manager|technician),
isComplete, avatarUrl, address, createdAt
```
Computed: `isCustomer`, `isManager`, `isTechnician`

### `Order`
```
id, orderNumber, customerId, orderType, status, totalAmount,
address, preferredDate, preferredTimeSlot, notes, includeInstallation,
createdAt, items: List<OrderItem>, customerProfile,
technicianNotes, technicianName,
scheduledPeriod, scheduledHour,
quotePrice, quoteDetails, quoteDuration, quoteStatus,
quoteSentAt, quoteRespondedAt, rejectionReason, quoteAttachmentUrl
```
Order types: `product` | `service` | `product_and_service` | `quote_request`
Statuses: `pending` → `confirmed` → `assigned` → `on_the_way` → `in_progress` → `completed` | `cancelled`
Quote statuses: `pending` → `sent` → `accepted` | `rejected`

### `OrderItem`
```
id, orderId, itemType (product|service), productId?, serviceTypeId?,
quantity, unitPrice, totalPrice, includeInstallation
```

### `Product`
```
id, name, description, category, price, isPriceOnRequest, imageUrl,
brand, specs: Map, isAvailable, isFeatured, requiresInstallation,
installationPrice, oldPrice
```
Categories: `ac` | `solar_panel` | `solar_battery` | `solar_inverter` | `accessory`
Computed: `hasDiscount`, `discountPercentage`, `categoryLabel`

### `ServiceType`
```
id, name, description, category, basePrice, iconName,
isActive, isQuoteBased, includes: List<String>, estimatedDuration
```

### `CartItem`
```
product: Product, quantity, includeInstallation
```
Computed: `total` (price + optional installation) × quantity

### `Promotion`
```
id, title, subtitle, iconName, gradientStart, gradientEnd,
destination, sortOrder, isActive
```
Computed: `icon` (from iconMap), `gradientColors`

---

## 6. Repositories (`lib/shared/repositories/`)

| Repository | Supabase Tables | Key Operations |
|------------|-----------------|----------------|
| `AuthRepository` | `profiles`, `device_tokens` | signIn/signUp (email + Google), resetPassword, updatePassword, getProfile, completeProfile, updateProfile, signOut, deleteAccount |
| `OrderRepository` | `orders`, `order_items`, `assignments` | getMyOrders, getAllOrders(filter), getOrder, createOrder, updateOrderStatus, updateQuoteStatus |
| `ProductRepository` | `products` | getProducts(category?), getProduct, createProduct, updateProduct, deleteProduct |
| `CartRepository` | `cart_items` | getCartItems, addToCart (upsert), updateQuantity, removeItem, clearCart, getCartCount (stream) |
| `LocalCartRepository` | In-memory only | Guest cart — addToCart, updateQuantity, removeItem, clear, extractAndClear (merge on login) |
| `ServiceRepository` | `service_types` | getServiceTypes (active only), getAllServiceTypes, addServiceType, updateServiceType, hideServiceType |
| `TechnicianRepository` | `technicians`, `profiles`, `assignments` | getTechnicians, addTechnician, updateTechnicianStatus, updateMyAvailability, getProfileByPhone, promoteToTechnician, getTechnicianDetails, getDashboardStats |
| `AssignmentRepository` | `assignments`, `orders` | assignTechnician, getAssignmentsForOrder, getAssignmentsForTechnician, updateAssignmentStatus, updateAssignmentData |
| `NotificationRepository` | `notifications` | getNotifications, markAsRead, markAllRead |
| `PromotionRepository` | `promotions` | getActivePromotions, getAllPromotions |

---

## 7. Providers (`lib/shared/providers/`)

### Auth Providers (`auth_providers.dart`)
| Provider | Type | Description |
|----------|------|-------------|
| `authRepositoryProvider` | `Provider<AuthRepository>` | Repository singleton |
| `authStateProvider` | `StreamProvider<AuthState>` | Supabase auth stream |
| `userProfileProvider` | `FutureProvider.autoDispose<UserProfile?>` | Current user profile, re-fetches on auth change |
| `roleStreamProvider` | `StreamProvider<String?>` | Real-time role from `profiles` table |
| `isGuestProvider` | `Provider<bool>` | True when no authenticated user |

### Order / Cart Providers (`order_providers.dart`)
| Provider | Type | Description |
|----------|------|-------------|
| `orderRepositoryProvider` | `Provider` | Repository singleton |
| `myOrdersProvider` | `FutureProvider.autoDispose` | Customer's orders |
| `allOrdersProvider` | `FutureProvider.autoDispose.family<_, String?>` | Manager's orders, filtered by status |
| `recentOrdersProvider` | `FutureProvider.autoDispose` | Latest 3 orders (home screen) |
| `activeOrderStreamProvider` | `StreamProvider.autoDispose<Order?>` | Real-time active order (non-completed/cancelled) |
| `orderDetailProvider` | `FutureProvider.autoDispose.family<Order, String>` | Single order by ID |
| `cartProvider` | `StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>` | Full cart state (online + guest) |
| `cartCountProvider` | `Provider<int>` | Total quantity in cart (badge) |
| `localCartProvider` | `Provider<LocalCartRepository>` | Guest cart singleton |

**CartNotifier** — handles both authenticated (Supabase) and guest (in-memory) carts. On login, calls `mergeGuestCart()` to sync.

### Product Providers (`product_providers.dart`)
| Provider | Type | Description |
|----------|------|-------------|
| `productRepositoryProvider` | `Provider` | Repository singleton |
| `allProductsProvider` | `FutureProvider<List<Product>>` | All available products (base cache) |
| `storeFilterProvider` | `StateProvider<StoreFilterState>` | Active filter/sort state |
| `storeFilteredProductsProvider` | `Provider<AsyncValue<List<Product>>>` | Derived — filtered + sorted products |
| `categoryCountsProvider` | `Provider<Map<String?, int>>` | Product counts per category |
| `productsProvider` | `FutureProvider.family<_, String?>` | Products by category |
| `featuredProductsProvider` | `FutureProvider<List<Product>>` | Featured products only |
| `productDetailProvider` | `FutureProvider.family<Product, String>` | Single product |
| `dealsProvider` | `FutureProvider<List<Product>>` | Discounted products |

**StoreFilterState** fields: `category`, `searchQuery`, `sort (ProductSort)`, `dealsOnly`, `featuredOnly`

### Service Providers (`service_providers.dart`)
| Provider | Description |
|----------|-------------|
| `serviceTypesProvider` | Active service types (customer-facing) |
| `serviceDetailProvider.family` | Single service type by ID |

### Notification Providers (`notification_providers.dart`)
| Provider | Type | Description |
|----------|------|-------------|
| `notificationsProvider` | `StateNotifierProvider<NotificationNotifier, AsyncValue<List<Map>>>` | Notifications with realtime Supabase stream subscription |
| `unreadCountProvider` | `Provider<int>` | Count of unread notifications (bell badge) |

**NotificationNotifier** — subscribes to `notifications` table stream on init; exposes `markAsRead`, `markAllRead`.

### Manager Providers (`manager_providers.dart`)
| Provider | Description |
|----------|-------------|
| `technicianRepositoryProvider` | Repository singleton |
| `assignmentRepositoryProvider` | Repository singleton |
| `techniciansProvider` | All active technicians |
| `dashboardStatsProvider` | `{pending, quotes_need_action, completed, in_progress, technicians}` |
| `technicianDetailProvider.family` | Single technician details + assignments |
| `managerServicesProvider` | All service types (active + inactive) |

### Technician Providers (`technician_providers.dart`)
| Provider | Description |
|----------|-------------|
| `myAssignmentsProvider` | Current technician's assignments (assigned + started) |
| `myTechnicianProfileProvider` | Technician profile + completed assignment count |

### Other Providers
| Provider | File | Description |
|----------|------|-------------|
| `activePromotionsProvider` | `promotion_providers.dart` | Active promo banners |
| `allPromotionsProvider` | `promotion_providers.dart` | All promotions (manager) |
| `themeModeProvider` | `theme_provider.dart` | `StateNotifierProvider<ThemeModeNotifier>` — persisted to SharedPreferences |
| `errorProvider` | `core/errors/error_notifier.dart` | Central error display, auto-clears after 5s |
| `inAppNotificationProvider` | `core/widgets/in_app_notification_banner.dart` | FCM foreground banner state, auto-dismisses after 4s |

---

## 8. Services (`lib/core/services/`)

### `FcmService`
Static class — initialized once in `main()`.

**Responsibilities:**
- Firebase + local notification initialization
- Android notification channel setup (`tamm_notifications`)
- Foreground messages → `InAppNotificationBanner` (via `_bannerCallback`)
- Background/terminated → local notification
- Notification tap → role-aware navigation (via `_navigationCallback`)
- FCM token registration/unregistration in `device_tokens` table

**Navigation routing logic by notification type:**
| Type | Customer | Manager | Technician |
|------|----------|---------|-----------|
| `quote_sent` | `/customer/quote-response/:id` | `/manager/quote/:id` | — |
| `new_assignment` | — | — | `/technician/task/:id` |
| `quote_responded` | — | `/manager/quote/:id` | — |
| default | `/customer/order/:id` | `/manager/order/:id` | `/technician/task/:id` |

### `TammHttpClient`
Custom `http.BaseClient` wrapping Supabase HTTP calls with a configurable timeout (default 5s). Throws `TimeoutException` on expiry instead of hanging indefinitely.

---

## 9. Router (`lib/core/router/app_router.dart`)

`appRouterProvider` — Riverpod `Provider<GoRouter>`. Uses 4 navigator keys: `_rootNavigatorKey`, `_customerShellKey`, `_managerShellKey`, `_technicianShellKey`.

### Auth Routes (root navigator)
| Path | Screen |
|------|--------|
| `/` | `SplashScreen` — redirect logic |
| `/login` | `LoginScreen` |
| `/onboarding` | `OnboardingScreen` |
| `/welcome` | `WelcomeScreen` |
| `/register` | `RegisterScreen` |
| `/forgot-password` | `ForgotPasswordScreen` |
| `/reset-password` | `ResetPasswordScreen` |

### Shared Routes (root navigator)
| Path | Screen |
|------|--------|
| `/notifications` | `NotificationsScreen` |
| `/profile/edit` | `EditProfileScreen` |

### Customer Shell Routes (bottom nav: Home / Store / Services / Profile)
| Path | Screen |
|------|--------|
| `/customer/home` | `CustomerHomeScreen` |
| `/customer/store` | `StoreScreen` |
| `/customer/services?category=` | `ServicesScreen` |
| `/customer/profile` | `CustomerProfileScreen` |

### Customer Detail Routes (root navigator, no bottom nav)
| Path | Screen |
|------|--------|
| `/customer/search` | `SearchScreen` |
| `/customer/catalog/:filter` | `ProductCatalogScreen` (filter: `deals` \| `bestSellers`) |
| `/customer/product/:id` | `ProductDetailScreen` |
| `/customer/cart` | `CartScreen` |
| `/customer/checkout` | `CheckoutScreen` |
| `/customer/order-success/:id` | `OrderSuccessScreen` |
| `/customer/service-request/:id` | `ServiceRequestScreen` |
| `/customer/service-detail/:id` | `ServiceDetailScreen` |
| `/customer/booking-confirmation/:id` | `BookingConfirmationScreen` |
| `/customer/quote-request/:id` | `QuoteRequestScreen` |
| `/customer/quote-response/:id` | `QuoteResponseScreen` |
| `/customer/orders` | `MyOrdersScreen` |
| `/customer/order/:id` | `OrderDetailScreen` |
| `/customer/devices` | `MyDevicesScreen` |

### Manager Shell Routes (6-tab: Dashboard / Orders / Technicians / Products / Services / Quotes)
| Path | Screen |
|------|--------|
| `/manager/dashboard` | `ManagerDashboardScreen` |
| `/manager/orders` | `ManagerOrdersScreen` |
| `/manager/technicians` | `TechniciansScreen` |
| `/manager/products` | `ManageProductsScreen` |
| `/manager/services` | `ManageServicesScreen` |
| `/manager/quotes` | `ManagerQuotesScreen` |

### Manager Detail Routes (root navigator)
| Path | Screen |
|------|--------|
| `/manager/order/:id` | `ManagerOrderDetailScreen` |
| `/manager/quote/:id` | `ManagerQuoteDetailScreen` |
| `/manager/add-technician` | `AddTechnicianScreen` |
| `/manager/technicians/:id` | `ManagerTechnicianDetailScreen` |
| `/manager/product/form` | `ProductFormScreen` (extra: `String? productId`) |
| `/manager/promotions` | `ManagePromotionsScreen` |
| `/manager/promotion/form` | `PromotionFormScreen` (extra: `Promotion?`) |
| `/manager/service/form` | `ServiceFormScreen` (extra: `ServiceType?`) |

### Technician Shell Routes (2-tab: Tasks / Profile)
| Path | Screen |
|------|--------|
| `/technician/tasks` | `TechTasksScreen` |
| `/technician/profile` | `TechProfileScreen` |

### Technician Detail Routes (root navigator)
| Path | Screen |
|------|--------|
| `/technician/task/:id` | `TechTaskDetailScreen` |

---

## 10. Screens — Complete List (46 screens)

### Auth (7 screens)
| Screen | Path | Purpose |
|--------|------|---------|
| `SplashScreen` | `/` | Logo + animated dots; redirects based on auth state + role |
| `WelcomeScreen` | `/welcome` | First-run welcome (sets `hasSeenWelcome` pref) |
| `LoginScreen` | `/login` | Email/password + Google sign-in |
| `RegisterScreen` | `/register` | Email/password registration |
| `OnboardingScreen` | `/onboarding` | Complete profile (name + phone) after first sign-in |
| `ForgotPasswordScreen` | `/forgot-password` | Send password reset email |
| `ResetPasswordScreen` | `/reset-password` | Set new password after deep-link redirect |

### Customer (18 screens)
| Screen | Description |
|--------|-------------|
| `CustomerHomeScreen` | Dashboard: promo slider, featured products, active order card, recent orders, quick service access |
| `StoreScreen` | Product grid with category tabs + filter/sort |
| `ProductCatalogScreen` | Filtered catalog (deals or best-sellers) |
| `ProductDetailScreen` | Product detail + installation option + add to cart |
| `CartScreen` | Cart management + installation toggles |
| `CheckoutScreen` | Address, date/time, notes → place order |
| `OrderSuccessScreen` | Post-order confirmation with order number |
| `ServicesScreen` | Service type grid, supports `?category` query param |
| `ServiceDetailScreen` | Service detail + choose book/quote |
| `ServiceRequestScreen` | Book a service (fixed price) |
| `BookingConfirmationScreen` | Post-booking confirmation |
| `QuoteRequestScreen` | Request a quote (free-form service) |
| `QuoteResponseScreen` | View quote sent by manager, accept/reject |
| `CustomerProfileScreen` | Profile overview: name, orders, devices shortcuts |
| `MyOrdersScreen` | Full order history |
| `OrderDetailScreen` | Single order status + items + technician info |
| `MyDevicesScreen` | Registered devices |
| `SearchScreen` | Product search |

### Manager (14 screens)
| Screen | Description |
|--------|-------------|
| `ManagerDashboardScreen` | Stats cards: pending, in-progress, completed today, quotes needing action, technician count |
| `ManagerOrdersScreen` | Order list with status filter tabs |
| `ManagerOrderDetailScreen` | Order detail + assign technician |
| `ManagerQuotesScreen` | Quote requests list |
| `ManagerQuoteDetailScreen` | Quote detail + send/update quote |
| `TechniciansScreen` | Technician list with status |
| `AddTechnicianScreen` | Add new technician by phone + specialization |
| `ManagerTechnicianDetailScreen` | Technician assignments + profile |
| `ManageProductsScreen` | Product CRUD list |
| `ProductFormScreen` | Add/edit product with specs editor |
| `ManageServicesScreen` | Service type CRUD list |
| `ServiceFormScreen` | Add/edit service type |
| `ManagePromotionsScreen` | Promo banner CRUD list |
| `PromotionFormScreen` | Add/edit promotion |

### Technician (3 screens)
| Screen | Description |
|--------|-------------|
| `TechTasksScreen` | Active assignments list |
| `TechTaskDetailScreen` | Task detail + update status (on the way / in progress / completed) + notes |
| `TechProfileScreen` | Technician profile + availability toggle + completed task count |

### Shared (4 screens)
| Screen | Description |
|--------|-------------|
| `NotificationsScreen` | Notification list with read/unread state |
| `EditProfileScreen` | Edit name, phone, address, avatar |

---

## 11. Shell Architecture

Each role has a `ShellRoute` with an `AdaptiveShell` wrapper:

```
AdaptiveShell
├── Mobile (<768px)  → BottomNavigationBar
└── Tablet/Desktop (≥768px) → _TammSidebar (NavigationRail-style)
    └── Desktop (≥1200px) → Extended sidebar (icons + labels, width 220)
```

**CustomerShell** (4 tabs: Home / Store / Services / Profile)
- Listens to `roleStreamProvider` — auto-redirects if role changes
- Listens to `errorProvider` — shows SnackBar with retry/relogin actions
- Shows cart badge count on Store tab

**ManagerShell** (6 tabs: Dashboard / Orders / Technicians / Products / Services / Quotes)
- Same error/role listeners as CustomerShell

**TechnicianShell** (2 tabs: Tasks / Profile)
- Same error/role listeners

---

## 12. App Startup Flow (`SplashScreen`)

```
App launches → /
  ↓
  Not logged in?
    ├── hasSeenWelcome=false → /welcome
    └── hasSeenWelcome=true  → /customer/home (guest mode)
  ↓
  Logged in, profile incomplete → /onboarding
  ↓
  Logged in, profile complete:
    ├── role=manager     → /manager/dashboard
    ├── role=technician  → /technician/tasks
    └── role=customer    → /customer/home
  ↓
  Error (network) → /login
```

---

## 13. Auth Flow

```
TammApp (app.dart) listens to Supabase.auth.onAuthStateChange:
  signedIn  → invalidate notificationsProvider + cartProvider
  signedOut → invalidate notificationsProvider + cartProvider
            → go('/customer/home') (unless password reset flow)
  passwordRecovery → go('/reset-password')

Deep links (tamm:// scheme):
  app_links listens for tamm://reset-password?...
  → Supabase.auth.getSessionFromUrl(uri)
  → triggers passwordRecovery event
  → navigates to /reset-password
```

---

## 14. Theme System

### Color Tokens (`TammColors` ThemeExtension)
| Token | Dark | Light |
|-------|------|-------|
| `bgPrimary` | `#080E18` | `#F4F7FB` |
| `bgSurface` | `#0D1825` | `#FFFFFF` |
| `bgSurface2` | `#121F30` | `#EAF0F6` |
| `border` | `#1A2E44` | `#D6E2ED` |
| `bluePrimary` | `#1576D4` | `#1576D4` (same) |
| `blueLight` | `#3E9EF5` | `#3E9EF5` |
| `blueSky` | `#8DCBFA` | `#8DCBFA` |
| `textPrimary` | `#E8F0F8` | `#0F1A26` |
| `textSecond` | `#7A96B0` | `#4A5D70` |
| `textFaint` | `#3E5468` | `#8BA0B5` |
| `success` | `#22C98A` | same |
| `error` | `#E05252` | same |
| `warning` | `#F5A623` | same |

Access via: `context.colors.tokenName`

### Theme Persistence
`themeModeProvider` (`ThemeModeNotifier`) persists `ThemeMode` to `shared_preferences` key `tamm_theme_mode`. Defaults to `ThemeMode.system`.

### Typography
Font: **Alexandria** (Google Fonts, Arabic-optimized) — applied globally via `GoogleFonts.alexandriaTextTheme`.

### Design Token Rules
- Spacing: 4pt grid via `AppSpacing` constants — never hardcode `EdgeInsets.all(16)`
- Border radius: `AppSpacing.radius` (12) default — never `BorderRadius.circular(12)`
- Font sizes: `AppTextStyles.fontSizeXxx` — never raw `fontSize: 16`
- Colors: `context.colors.xxx` — never `Colors.blue`

---

## 15. Error Handling

### Exception Hierarchy (sealed class)
```
AppException (sealed)
├── NetworkException    — retry action, "no internet"
├── AuthException       — relogin action, "session expired"
├── ServerException     — retry action, "server error"
├── PermissionException — dismiss action, "access denied"
├── ValidationException — dismiss action, custom message
└── UnknownException    — retry action, fallback
```

### `ErrorMapper.from(Object e)` mapping
| Raw Error | AppException |
|-----------|-------------|
| `PostgrestException` (code 42501/403) | `PermissionException` |
| `PostgrestException` (other) | `ServerException` |
| `AuthException` | `AuthException` |
| `TimeoutException` | `NetworkException` ("connection timed out") |
| Message contains network keywords | `NetworkException` |
| Other | `UnknownException` |

### Display pattern
All shells listen to `errorProvider` — displays a floating `SnackBar` (4s) with contextual action button. Screens display `ErrorStateWidget(message, onRetry)` for async provider errors.

---

## 16. Supabase Database Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles — id, email, full_name, phone, role, is_complete, avatar_url, address |
| `products` | Product catalog — name, category, price, is_price_on_request, specs (JSONB), is_available, is_featured, requires_installation, installation_price, old_price, sort_order |
| `service_types` | Service catalog — name, category, base_price, is_quote_based, includes (array), is_active, sort_order |
| `orders` | All order types — order_type, status, total_amount, address, preferred_date/time, include_installation, quote_price/details/status/duration, scheduled_period/hour, latitude, longitude |
| `order_items` | Line items for orders — item_type, product_id?, service_type_id?, quantity, unit_price, include_installation |
| `cart_items` | Persistent cart per user — user_id, product_id, quantity, include_installation |
| `technicians` | Technician records — profile_id (FK), specialization, phone, status, is_active |
| `assignments` | Order-technician assignments — order_id, technician_id, assigned_by, status, started_at, completed_at, technician_notes |
| `notifications` | Push notification log — user_id, title, body, is_read, order_id, notification_type |
| `device_tokens` | FCM tokens — user_id, fcm_token, device_platform |
| `promotions` | Promo banner config — title, subtitle, icon_name, gradient_start/end, destination, sort_order, is_active |

**Custom RPC functions:**
- `promote_to_technician(p_profile_id, p_phone, p_specialization)` — elevates user role + inserts technician record
- `delete_user_account()` — cascading account deletion

**Realtime subscriptions:**
- `notifications` table (per user) → `NotificationNotifier`
- `orders` table (per user) → `activeOrderStreamProvider`
- `profiles` table (per user) → `roleStreamProvider`

---

## 17. Notification System

### FCM Notification Types
| `notification_type` | Trigger | Banner Icon |
|--------------------|---------|-------------|
| `new_order` | Customer places order | shopping_bag |
| `on_the_way` | Tech marked on the way | directions_car |
| `in_progress` | Tech started work | build |
| `completed` | Order completed | task_alt |
| `quote_sent` | Manager sent quote | request_quote |
| `quote_responded` | Customer accepted/rejected | reply |
| `new_assignment` | Manager assigned tech | assignment |

### In-App Banner (`InAppNotificationBanner`)
- Overlaid globally via `Stack` in `TammApp.builder`
- Slides in from top (`AnimatedPositioned`)
- Auto-dismisses after 4s; swipe-up or close button to dismiss
- Tap navigates to relevant screen

---

## 18. Current State & Known Patterns

### Guest Mode
- Customers can browse store/services without signing in
- Cart stored in `LocalCartRepository` (in-memory)
- `requireAuth()` called before checkout/service booking — shows login bottom sheet
- On login: `CartNotifier.mergeGuestCart()` syncs guest cart to Supabase

### Quote Flow
```
Customer requests quote (quote_request order, quoteStatus=pending)
  → Manager views in /manager/quotes
  → Manager sends quote (sets quoteStatus=sent, quotePrice, quoteDetails)
  → Customer receives push notification, views at /customer/quote-response/:id
  → Customer accepts → status=confirmed, totalAmount=quotePrice
  → Customer rejects → quoteStatus=rejected (manager can send new quote)
  → After acceptance, manager assigns technician → normal order flow
```

### Product Purchase Flow
```
Customer browses store → adds to cart (with optional installation)
  → CartScreen → CheckoutScreen (address, date, notes)
  → OrderRepository.createOrder() → /customer/order-success/:id
```

### Service Booking Flow
```
Customer selects service → ServiceDetailScreen
  ├── Fixed price → ServiceRequestScreen → BookingConfirmationScreen
  └── Quote-based → QuoteRequestScreen → (quote flow above)
```

### Responsive Layout
| Width | Layout |
|-------|--------|
| < 768px | Bottom navigation bar |
| 768–1199px | Collapsed sidebar (icons only, width 72) |
| ≥ 1200px | Extended sidebar (icons + labels, width 220) |

### Platform Detection (Web)
`FcmService` skips local notifications on web. `AuthRepository` uses Supabase OAuth redirect for Google sign-in on web vs. `google_sign_in` package on mobile.

### Security
- Supabase Row Level Security (RLS) enforced server-side
- `PermissionException` returned on 403/42501 Postgres errors
- Env vars injected via `--dart-define` (not hardcoded in committed code intent, though defaults present in `env.dart`)
- FCM tokens cleaned up on sign-out via `FcmService.unregisterToken()`
- Password reset uses PKCE flow via `tamm://` deep link scheme

---

*This summary covers all 109 Dart source files, 46 screens, 35+ providers, 10 repositories, 6 models, and the full routing table as of the last commit (575a55a).*
