import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

class UIHelpers {
  /// Formats distance from KM into a user-friendly string (KM or Meters)
  static String formatDistance(double? km) {
    if (km == null) return '...';
    if (km < 1.0) {
      return '${(km * 1000).toInt()} m';
    } else {
      return '${km.toStringAsFixed(1)} km';
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
}
