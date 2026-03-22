import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/injection.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Background message handler — MUST be a top-level function (not a class method)
// This fires when a data-only FCM message arrives while the app is terminated/backgrounded.
// ──────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show a local notification for background/terminated data messages
  await _LocalNotificationHelper.show(
    title: message.notification?.title ?? message.data['title'] ?? 'CatchyBus',
    body: message.notification?.body ?? message.data['body'] ?? '',
  );
}

// Internal helper — static so it can be used both in the service and the bg handler
class _LocalNotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We ask via FCM instead
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create a notification channel for Android 8+
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'catchybus_general',
        'CatchyBus Notifications',
        description: 'Bus tracking and trip updates',
        importance: Importance.high,
        playSound: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'catchybus_general',
      'CatchyBus Notifications',
      channelDescription: 'Bus tracking and trip updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }
}

class PushNotificationService {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Wire up background handler — must be registered before any other FCM setup
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize the local notifications plugin early
    await _LocalNotificationHelper.init();

    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('[FCM] Permission status: ${settings.authorizationStatus}');

    // ── Token acquisition ─────────────────────────────────────────────────────
    // ⚠️  iOS Simulator: APNs is NOT supported by Apple. FCM on iOS routes
    //     through APNs, so getToken() will always fail on simulator.
    //     Test push notifications on a real iPhone.
    //
    // ⚠️  Android Emulator: Works ONLY on emulators that include Google Play
    //     Services (choose a "Google APIs" or "Google Play" system image).
    //     AOSP emulators have no GMS and FCM tokens cannot be obtained.
    // ─────────────────────────────────────────────────────────────────────────
    await _acquireAndUploadToken();

    // Refresh token whenever FCM rotates it
    _fcm.onTokenRefresh.listen(_updateTokenOnServer);

    // ── Foreground messages ───────────────────────────────────────────────────
    // By default FCM does NOT show a heads-up notification when the app is
    // in the foreground. We show one ourselves via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title =
          message.notification?.title ?? message.data['title'] ?? 'CatchyBus';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      if (body.isNotEmpty) {
        _LocalNotificationHelper.show(title: title, body: body);
      }
    });

    // ── App opened from a notification (background → foreground) ─────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM] App opened from notification: ${message.data}');
      // TODO: Navigate to the relevant screen based on message.data
    });

    // Check if app was launched from a terminated state via a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('[FCM] App launched from terminated notification: ${initialMessage.data}');
    }
  }

  Future<void> updateToken() async {
    await _acquireAndUploadToken();
  }

  Future<void> _acquireAndUploadToken() async {
    try {
      if (Platform.isIOS) {
        // Give APNs a moment to register on real devices
        await Future.delayed(const Duration(seconds: 2));

        // On simulator this will fail — catch gracefully
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          print(
            '[FCM] ⚠️ APNS token is null. '
            'Push notifications are NOT supported on iOS Simulator. '
            'Test on a real device.',
          );
          return;
        }
      }

      final token = await _fcm.getToken();
      if (token != null) {
        print('[FCM] ✅ Token obtained: ${token.substring(0, 20)}...');
        await _updateTokenOnServer(token);
      } else {
        print(
          '[FCM] ⚠️ FCM token is null. '
          'On Android emulator, ensure you are using a Google APIs/Play image.',
        );
      }
    } catch (e) {
      print('[FCM] ❌ Token error: $e');
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      final authRepository = getIt<AuthRepository>();
      if (await authRepository.isLoggedIn()) {
        await authRepository.updateFcmToken(token);
        print('[FCM] Token uploaded to server.');
      }
    } catch (e) {
      print('[FCM] ❌ Failed to upload token: $e');
    }
  }
}

final notificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
