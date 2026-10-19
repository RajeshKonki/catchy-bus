import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';

import 'features/bus_tracking/presentation/providers/alarm_provider.dart';
import 'features/bus_tracking/presentation/providers/bus_tracking_provider.dart';
import 'features/bus_tracking/presentation/state/bus_tracking_state.dart';

void main() async {
  // Ensure Flutter binds are ready for plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ FCM background handler MUST be registered before Firebase.initializeApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firebase with defensive check against race conditions
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      print('🔥 Firebase Initialized successfully');
    } catch (e) {
      print('❌ Firebase Initialization Error: $e');
    }
  }

  // Disable app verification (reCAPTCHA) for testing/debugging
  // try {
  //   await FirebaseAuth.instance.setSettings(
  //     appVerificationDisabledForTesting: true,
  //   );
  //   print('🛡️ App verification (reCAPTCHA) disabled for testing');
  // } catch (e) {
  //   print('⚠️ Failed to disable app verification: $e');
  // }

  // Initialize dependencies
  await initializeDependencies();

  // Initialize Notification Service (foreground + token registration)
  await PushNotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch alarmManagerProvider to initialize the global dynamic alarm checker
    ref.watch(alarmManagerProvider);

    // Listen to changes in the bus tracking provider state at the root level
    ref.listen<BusTrackingState>(busTrackingProvider, (previous, next) {
      next.maybeWhen(
        loaded: (busRoute) {
          if (busRoute.isTripActive) {
            ref.read(alarmManagerProvider.notifier).checkAlarms(busRoute);
          } else {
            // Reset triggered alarms when trip is inactive
            ref.read(alarmManagerProvider.notifier).clearTriggeredAlarms();
          }
        },
        orElse: () {},
      );
    });

    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'CatchyBus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,

          themeMode: ThemeMode.light,
          routerConfig: router,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
        );
      },
    );
  }
}
