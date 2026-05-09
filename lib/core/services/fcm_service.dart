import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';

/// Background message handler — يجب أن تكون top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  /// Navigation callback: يُضبط من app.dart بعد إنشاء الـ router
  static Function(String route)? _navigationCallback;

  /// InApp banner callback: يُضبط من app.dart
  static Function({
    required String title,
    required String body,
    String? orderId,
    String? notificationType,
  })?
  _bannerCallback;

  static void setNavigationCallback(Function(String route) cb) {
    _navigationCallback = cb;
  }

  static void setBannerCallback(
    Function({
      required String title,
      required String body,
      String? orderId,
      String? notificationType,
    })
    cb,
  ) {
    _bannerCallback = cb;
  }

  /// يُستدعى مرة واحدة في main()
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // طلب إذن الإشعارات
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // على الويب نكتفي بإذن الإشعارات بدون Local Notifications
    if (kIsWeb) return;

    // --- Mobile only ---
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // إعداد Local Notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // إنشاء قناة إشعارات Android
    const channel = AndroidNotificationChannel(
      'tamm_notifications',
      'إشعارات تمّ',
      description: 'إشعارات تطبيق تمّ للتكييف والطاقة الشمسية',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // ── Foreground: عرض InAppBanner بدلاً من Local Notification ──────
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      final data = message.data;
      _bannerCallback?.call(
        title: notification.title ?? '',
        body: notification.body ?? '',
        orderId: data['order_id'],
        notificationType: data['notification_type'],
      );
    });

    // ── Background → foreground (user tapped notification) ────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageNavigation(message);
    });

    // ── Terminated (app was closed) ───────────────────────────────────
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // تأخير للتأكد من جهوزية الـ widget tree
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  /// يُوجّه المستخدم للمسار المناسب بناءً على payload الإشعار ودور المستخدم
  static Future<void> _handleMessageNavigation(RemoteMessage message) async {
    final data = message.data;
    final orderId = data['order_id'] as String?;
    final notificationType = data['notification_type'] as String?;

    if (orderId == null || _navigationCallback == null) return;

    // جلب دور المستخدم مباشرة من Supabase
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    String role = 'customer';
    try {
      final res = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      role = res['role'] as String? ?? 'customer';
    } catch (_) {
      // استخدم الافتراضي
    }

    final route = _buildRoute(notificationType, orderId, role);
    if (route != null) _navigationCallback!(route);
  }

  /// بناء المسار حسب نوع الإشعار والدور
  static String? _buildRoute(String? type, String orderId, String role) {
    if (type == 'new_assignment') {
      return '/technician/task/$orderId';
    }

    switch (role) {
      case 'manager':
        if (type == 'quote_sent' || type == 'quote_responded') {
          return '/manager/quote/$orderId';
        }
        return '/manager/order/$orderId';
      case 'technician':
        return '/technician/task/$orderId';
      case 'customer':
      default:
        if (type == 'quote_sent') {
          return '/customer/quote-response/$orderId';
        }
        return '/customer/order/$orderId';
    }
  }

  /// يُستدعى بعد تسجيل الدخول — يحفظ FCM Token في قاعدة البيانات
  static Future<void> registerToken() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      await _client.from('device_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'device_platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');

      // استمع لتغيير Token
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = _client.auth.currentUser;
        if (currentUser == null) return;
        await _client.from('device_tokens').upsert({
          'user_id': currentUser.id,
          'fcm_token': newToken,
          'device_platform': 'android',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,fcm_token');
      });
    } catch (e) {
      // تجاهل الخطأ — لا نريد إيقاف التطبيق بسببه
    }
  }

  /// يُستدعى عند تسجيل الخروج
  static Future<void> unregisterToken() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      await _client
          .from('device_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('fcm_token', token);
    } catch (e) {
      // تجاهل الخطأ
    }
  }
}
