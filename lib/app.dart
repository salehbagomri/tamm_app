import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/widgets/in_app_notification_banner.dart';
import 'features/auth/presentation/reset_password_screen.dart'
    show passwordResetSignOutProvider;
import 'shared/providers/theme_provider.dart';


class TammApp extends ConsumerStatefulWidget {
  const TammApp({super.key});

  @override
  ConsumerState<TammApp> createState() => _TammAppState();
}

class _TammAppState extends ConsumerState<TammApp> {
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<Uri> _linkSubscription;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();

    // ── Auth state listener ──────────────────────────────────────────────────
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final router = ref.read(appRouterProvider);

      switch (data.event) {
        case AuthChangeEvent.signedOut:
          // During a password-reset flow the screen calls signOut() and then
          // navigates to /login itself — don't override that navigation.
          final isPasswordReset =
              ref.read(passwordResetSignOutProvider);
          if (isPasswordReset) {
            ref.read(passwordResetSignOutProvider.notifier).state = false;
          } else {
            router.go('/customer/home');
          }
        case AuthChangeEvent.passwordRecovery:
          // Code was exchanged — take user to the "set new password" screen.
          router.go('/reset-password');
        default:
          break;
      }
    });

    // ── Deep link listener ───────────────────────────────────────────────────
    _initDeepLinks();

    // ── FcmService callbacks ─────────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      FcmService.setNavigationCallback((route) => router.push(route));
      FcmService.setBannerCallback((
          {required String title,
          required String body,
          String? orderId,
          String? notificationType}) {
        ref.read(inAppNotificationProvider.notifier).show(
          title: title,
          body: body,
          orderId: orderId,
          notificationType: notificationType,
        );
      });
    });
  }

  Future<void> _initDeepLinks() async {
    // Cold start: app was launched by tapping the deep link.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await _handleDeepLink(initial);
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    // Hot start: app was already running when the link was tapped.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (e) => debugPrint('Deep link stream error: $e'),
    );
  }

  /// Exchange the Supabase PKCE code carried in [uri] for a session.
  /// On success Supabase emits [AuthChangeEvent.passwordRecovery] which
  /// the auth listener above turns into a navigation to /reset-password.
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('Deep link received: $uri');
    if (uri.scheme == 'tamm') {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('getSessionFromUrl error: $e');
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _linkSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.read(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'تمّ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              child!,
              const InAppNotificationBanner(),
            ],
          ),
        );
      },
    );
  }
}
