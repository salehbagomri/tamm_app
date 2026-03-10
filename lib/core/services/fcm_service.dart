import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler — يجب أن تكون top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  /// يُستدعى مرة واحدة في main()
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // طلب إذن الإشعارات
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // إعداد Local Notifications (للإشعارات أثناء استخدام التطبيق)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // عرض الإشعارات أثناء استخدام التطبيق (foreground)
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'tamm_notifications',
              'إشعارات تمّ',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  /// يُستدعى بعد تسجيل الدخول — يحفظ FCM Token في قاعدة البيانات
  static Future<void> registerToken() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      await _client.from('device_tokens').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'device_platform': 'android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );

      // استمع لتغيير Token
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = _client.auth.currentUser;
        if (currentUser == null) return;
        await _client.from('device_tokens').upsert(
          {
            'user_id': currentUser.id,
            'fcm_token': newToken,
            'device_platform': 'android',
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,fcm_token',
        );
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
