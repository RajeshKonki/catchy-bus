import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../providers/auth_provider.dart';

/// OTP Verification page
class OtpVerificationPage extends ConsumerStatefulWidget {
  final String identifier; // Mobile number or email
  final bool isStudent;

  const OtpVerificationPage({
    super.key,
    required this.identifier,
    required this.isStudent,
  });

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp {
    return _otpControllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete {
    return _otp.length == 6;
  }

  void _handleVerify() {
    if (_isOtpComplete) {
      // TODO: Implement actual OTP verification logic with backend
      // ref.read(authProvider.notifier).verifyOtp(widget.identifier, _otp);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // Navigate based on user role after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        if (widget.isStudent) {
          // Navigate to student bus tracking page
          context.go(AppRouter.busTracking);
        } else {
          // Navigate to driver home page
          context.go(AppRouter.home);
        }
      });
    }
  }

  void _handleResendCode() {
    // TODO: Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent successfully'),
        backgroundColor: Colors.green,
      ),
    );
    // Clear all fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  String _getMaskedIdentifier() {
    final identifier = widget.identifier;
    if (identifier.contains('@')) {
      // Email masking
      final parts = identifier.split('@');
      if (parts[0].length > 2) {
        return '${parts[0].substring(0, 2)}${'X' * (parts[0].length - 2)}@${parts[1]}';
      }
      return identifier;
    } else {
      // Phone number masking
      if (identifier.length > 4) {
        return '${identifier.substring(0, identifier.length - 4)}${'X' * 4}';
      }
      return identifier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Logo
                _buildLogo(),
                const SizedBox(height: 24),

                // Tagline
                const Text(
                  'Track your college bus',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.brightOrange,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'in real time',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.brightOrange,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Instruction text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkCharcoal,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Enter the 6-digit code sent to you at\n',
                      ),
                      TextSpan(
                        text: _getMaskedIdentifier(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // OTP Input Fields
                _buildOtpFields(),
                const SizedBox(height: 32),

                // Verify button
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isOtpComplete ? _handleVerify : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brightOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.brightOrange
                          .withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend code button
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _handleResendCode,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.lightOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Resend code',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.brightOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Help text
                const Text(
                  'Having trouble logging in?',
                  style: TextStyle(fontSize: 14, color: AppColors.darkCharcoal),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // Navigate to contact/help page
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Contact your college transport office',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.deepBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bus icon with location pin
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.deepBlue, width: 2),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 40,
                  color: AppColors.deepBlue,
                ),
              ),
              Positioned(
                right: -8,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppColors.locationRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Catchy Bus text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Catchy',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Bus',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brightOrange,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) => _buildOtpBox(index)),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.darkCharcoal,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last field, unfocus
              _focusNodes[index].unfocus();
              // Auto-verify if all fields are filled (after current frame)
              if (_isOtpComplete) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleVerify();
                });
              }
            }
          } else {
            // Move to previous field on backspace
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {}); // Update button state
        },
        onTap: () {
          // Clear the field when tapped
          _otpControllers[index].clear();
        },
      ),
    );
  }
}
