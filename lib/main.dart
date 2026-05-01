import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';

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
      // Disable reCAPTCHA for testing
      if (kDebugMode) {
        await FirebaseAuth.instance.setSettings(
          forceRecaptchaFlow: false,
          appVerificationDisabledForTesting: true,
        );
        print(
          '🛡️ Firebase Auth: App verification disabled for testing (reCAPTCHA removed)',
        );
      }

      // Initialize App Check
      await FirebaseAppCheck.instance.activate();

      print('🔥 Firebase Initialized successfully');
    } catch (e) {
      print('❌ Firebase Initialization Error: $e');
    }
  }

  // Initialize dependencies
  await initializeDependencies();

  // Initialize Notification Service (foreground + token registration)
  await PushNotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          routerConfig: AppRouter.router,
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
