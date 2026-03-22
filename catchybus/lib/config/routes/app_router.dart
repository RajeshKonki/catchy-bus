import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/driver/presentation/pages/driver_home_page.dart';
import '../../features/driver/presentation/pages/trip_tracking_page.dart';
import '../../features/driver/presentation/pages/end_trip_summary_page.dart';
import '../../features/driver/domain/entities/trip_summary.dart';
import '../../features/bus_tracking/presentation/pages/bus_tracking_home_page.dart';
import '../../features/bus_tracking/presentation/pages/student_landing_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/bus_tracking/presentation/pages/location_alarms_page.dart';
import '../../features/bus_tracking/presentation/pages/student_qr_page.dart';
import '../../features/driver/presentation/pages/attendance_qr_scanner_page.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// App routes configuration using GoRouter
class AppRouter {
  static const String login = '/login';
  static const String home = '/home';
  static const String driverHome = '/driver-home';
  static const String tripTracking = '/trip-tracking';
  static const String endTripSummary = '/end-trip-summary';
  static const String busTracking = '/bus-tracking';
  static const String studentLanding = '/student-landing';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String splash = '/splash';
  static const String locationAlarms = '/location-alarms';
  static const String studentQr = '/student-qr';
  static const String attendanceQrScanner = '/attendance-qr-scanner';
  static const String notificationSettings = '/notification-settings';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(
                      curve: Curves.easeInOut,
                    ).animate(animation),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: driverHome,
        name: 'driver-home',
        builder: (context, state) => const DriverHomePage(),
      ),
      GoRoute(
        path: tripTracking,
        name: 'trip-tracking',
        builder: (context, state) => const TripTrackingPage(),
      ),
      GoRoute(
        path: endTripSummary,
        name: 'end-trip-summary',
        builder: (context, state) {
          final summary = state.extra as TripSummary;
          return EndTripSummaryPage(summary: summary);
        },
      ),
      GoRoute(
        path: busTracking,
        name: 'bus-tracking',
        builder: (context, state) {
          if (state.extra is Map<String, String?>) {
            final data = state.extra as Map<String, String?>;
            return BusTrackingHomePage(
              busNumber: data['busNumber'],
              studentName: data['studentName'],
            );
          }
          return BusTrackingHomePage(
            busNumber: state.extra as String?,
          );
        },
      ),
      GoRoute(
        path: studentLanding,
        name: 'student-landing',
        builder: (context, state) => const StudentLandingPage(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: locationAlarms,
        name: 'location-alarms',
        builder: (context, state) => const LocationAlarmsPage(),
      ),
      GoRoute(
        path: studentQr,
        name: 'student-qr',
        builder: (context, state) {
          final student = state.extra as UserEntity;
          return StudentQrPage(student: student);
        },
      ),
      GoRoute(
        path: attendanceQrScanner,
        name: 'attendance-qr-scanner',
        builder: (context, state) => const AttendanceQrScannerPage(),
      ),
      GoRoute(
        path: notificationSettings,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
