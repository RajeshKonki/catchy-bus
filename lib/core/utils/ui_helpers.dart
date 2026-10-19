import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

class UIHelpers {
  /// Formats distance from KM into a user-friendly string (KM or Meters)
  static String formatDistance(double? km) {
    if (km == null) return '...';
    final int totalMeters = (km * 1000).round();
    if (totalMeters < 1000) {
      return '$totalMeters m';
    } else {
      final int wholeKm = totalMeters ~/ 1000;
      final int remainingMeters = totalMeters % 1000;
      if (remainingMeters == 0) {
        return '$wholeKm km';
      }
      return '$wholeKm km $remainingMeters m';
    }
  }

  /// Shows a user-friendly tooltip/snackbar for errors
  static void showErrorTooltip(BuildContext context, String message) {
    // Make the message more user friendly by stripping technical prefixes
    String cleanMessage = _getReadableErrorMessage(message);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cleanMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.locationRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a user-friendly tooltip/snackbar for success messages
  static void showSuccessTooltip(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a user-friendly tooltip/snackbar for warning messages
  static void showWarningTooltip(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Maps technical error messages to user-friendly ones
  static String _getReadableErrorMessage(String message) {
    final lower = message.toLowerCase();
    
    // Firebase auth errors
    if (lower.contains('invalid-verification-code')) {
      return 'The OTP entered is incorrect. Please try again.';
    } else if (lower.contains('session-expired')) {
      return 'The OTP has expired. Please request a new one.';
    } else if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (lower.contains('invalid-phone-number')) {
      return 'Please enter a valid mobile number.';
    } else if (lower.contains('network-request-failed')) {
      return 'Please check your internet connection and try again.';
    }
    
    // Our API specific errors from the backend
    else if (lower.contains('driver not found') || lower.contains('no driver account')) {
      return 'No driver account found with this number.';
    } else if (lower.contains('student not found') || lower.contains('no student account')) {
      return 'No student/parent account found with this number.';
    } else if (lower.contains('invalid credentials')) {
      return 'Invalid credentials. Please verify your details.';
    } else if (lower.contains('account inactive')) {
      return 'Your account is currently inactive. Contact support.';
    }
    
    // General connection errors
    else if (lower.contains('connection refused') || lower.contains('socketexception') || lower.contains('timeout')) {
      return 'Unable to connect to the server. Please ensure you have an active internet connection.';
    }

    // fallback
    // remove some technical jargon like 'Exception:' or '[firebase_auth/something]'
    String clean = message.replaceAll(RegExp(r'\[.*?\]\s*'), '');
    clean = clean.replaceAll('Exception:', '').trim();
    if (clean.isEmpty) return 'An unexpected error occurred.';
    return clean;
  }

  /// Shows a prominent disclosure dialog for location permissions
  /// Required by Google Play for background location usage.
  static Future<bool> showLocationDisclosure(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.deepBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.deepBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'You can change this anytime in your device settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No Thanks',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Allow',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
