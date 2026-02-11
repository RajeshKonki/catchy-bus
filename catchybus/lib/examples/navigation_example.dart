import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/routes/app_router.dart';
import '../config/theme/app_theme.dart';

/// Example widget showing how to navigate to the Bus Tracking Home Page
class NavigationExample extends StatelessWidget {
  const NavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: Navigate using context.go
            ElevatedButton(
              onPressed: () {
                context.go(AppRouter.busTracking);
              },
              child: const Text('Go to Bus Tracking (Replace)'),
            ),

            const SizedBox(height: 16),

            // Example 2: Navigate using context.push
            ElevatedButton(
              onPressed: () {
                context.push(AppRouter.busTracking);
              },
              child: const Text('Push Bus Tracking (Stack)'),
            ),

            const SizedBox(height: 16),

            // Example 3: Navigate using named route
            ElevatedButton(
              onPressed: () {
                context.goNamed('bus-tracking');
              },
              child: const Text('Go to Bus Tracking (Named)'),
            ),

            const SizedBox(height: 32),

            // Information card
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightYellow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryYellow, width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Bus Tracking Home Screen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The bus tracking screen shows:\n'
                    '• Real-time bus location on map\n'
                    '• Current location and next stop\n'
                    '• Arrival time and distance\n'
                    '• Call driver functionality\n'
                    '• Route visualization',
                    style: TextStyle(color: AppColors.darkCharcoal),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Note: Currently using mock data. Configure Google Maps API and connect to your backend for real data.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
