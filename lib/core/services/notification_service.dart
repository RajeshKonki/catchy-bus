import 'dart:io';
import 'dart:typed_data';
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

  // Channel IDs
  static const String _generalChannelId = 'catchybus_general';
  static const String _alarmChannelId = 'catchybus_alarm';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // General notifications channel
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          'CatchyBus Notifications',
          description: 'Bus tracking and trip updates',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // High-priority alarm channel (bus approaching alert)
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _alarmChannelId,
          'CatchyBus Alarms',
          description: 'Alerts when your bus is approaching your stop',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        ),
      );

      // Request POST_NOTIFICATIONS permission on Android 13+
      await androidPlugin?.requestNotificationsPermission();
    }

    if (Platform.isIOS) {
      // Request iOS notification permissions at init time
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      _generalChannelId,
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

  /// Shows a high-priority alarm notification (bus approaching stop).
  /// Works on both Android and iOS — fires even when the app is in the
  /// foreground so the user always gets an audible + vibration alert.
  static Future<void> showAlarm({
    required String stopName,
    required int etaMinutes,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      'CatchyBus Alarms',
      channelDescription: 'Alerts when your bus is approaching your stop',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      // Aggressive repeating vibration: 0.5s on, 0.2s off, repeatable
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 1000, 200, 1000]),
      // System-level alarm behavior
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // Display as heads-up / pop-over banner
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ticker: '🚌 Bus Alert',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Time-sensitive breakthrough for Focus/DND modes
      interruptionLevel: InterruptionLevel.timeSensitive,
      sound: 'default',
    );

    final id = stopName.hashCode.abs() % 100000;

    await _plugin.show(
      id: id,
      title: '🚌 Bus Approaching!',
      body: 'Your bus will reach $stopName in ~$etaMinutes min. Get ready!',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'alarm:$stopName',
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

/// Public helper to fire an alarm notification from anywhere in the app.
/// Call this instead of (or in addition to) showing an in-app dialog.
Future<void> showAlarmNotification({
  required String stopName,
  required int etaMinutes,
}) async {
  await _LocalNotificationHelper.showAlarm(
    stopName: stopName,
    etaMinutes: etaMinutes,
  );
}

/// Shows an attendance notification when a student boards the bus.
Future<void> showAttendanceNotification({
  required String studentName,
  required String busNumber,
  required String stopName,
}) async {
  await _LocalNotificationHelper.show(
    title: '🚌 Boarding Confirmed',
    body: '$studentName onboarded at pickup stop named $stopName on bus $busNumber.',
  );
}


final notificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});


