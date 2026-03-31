import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../providers/auth_provider.dart';

/// OTP Verification page
class OtpVerificationPage extends ConsumerStatefulWidget {
  final String identifier;
  final String role;

  const OtpVerificationPage({
    super.key,
    required this.identifier,
    required this.role,
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

  // Resend countdown
  int _resendCountdown = 30;
  Timer? _timer;
  bool get _canResend => _resendCountdown == 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otp.length == 6;

  void _handleVerify() {
    if (_isOtpComplete) {
      ref
          .read(authProvider.notifier)
          .verifyOtp(_otp, widget.role, widget.identifier);
    }
  }

  void _handleResendCode() {
    if (!_canResend) return;
    ref.read(authProvider.notifier).sendOtp(widget.identifier, widget.role);
    UIHelpers.showSuccessTooltip(context, 'OTP resent successfully!');
    for (var c in _otpControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _startCountdown();
  }

  String _getMaskedIdentifier() {
    final identifier = widget.identifier;
    if (identifier.contains('@')) {
      final parts = identifier.split('@');
      if (parts[0].length > 2) {
        return '${parts[0].substring(0, 2)}${'*' * (parts[0].length - 2)}@${parts[1]}';
      }
      return identifier;
    } else {
      if (identifier.length > 4) {
        return '${identifier.substring(0, identifier.length - 4)}${'*' * 4}';
      }
      return identifier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        UIHelpers.showErrorTooltip(context, next.error!);
      }

      if (next.isAuthenticated) {
        if (widget.role == 'Student' || widget.role == 'Parent') {
          context.go(AppRouter.studentLanding);
        } else {
          // Driver: go to route selection before starting trip
          context.go(AppRouter.routeSelection);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Wave background
          Positioned.fill(
            child: CustomPaint(painter: _WaveBackgroundPainter()),
          ),
          // Back button sitting on the wave
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.deepBlue,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          // Main content
          // Background paint handled by Positioned.fill above
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Space to clear wave
                    const SizedBox(height: 40),

                    // Logo first
                    _buildLogo(),
                    const SizedBox(height: 12),

                    // Tagline second
                    Text(
                      'Your college bus, always on track.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

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
                            text: 'Enter the 6-digit code sent to\n',
                          ),
                          TextSpan(
                            text: _getMaskedIdentifier(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isOtpComplete ? _handleVerify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brightOrange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.brightOrange
                              .withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
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
                                'Verify OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resend code section
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: _canResend ? _handleResendCode : null,
                        style: TextButton.styleFrom(
                          backgroundColor: _canResend
                              ? AppColors.lightOrange
                              : Colors.grey[100],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _canResend
                            ? const Text(
                                'Resend OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.brightOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Text(
                                'Resend OTP in $_resendCountdown s',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Help text
                    const Text(
                      'Having trouble logging in?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {},
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
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icons/catchy_logo.png',
      height: 80,
      fit: BoxFit.contain,
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
    final isFocused = _focusNodes[index].hasFocus;
    final isFilled = _otpControllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: isFilled
            ? AppColors.deepBlue.withValues(alpha: 0.07)
            : AppColors.lightYellow,
        border: Border.all(
          color: isFocused
              ? AppColors.deepBlue
              : isFilled
              ? AppColors.primaryYellow
              : Colors.grey[300]!,
          width: isFocused ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isFilled ? AppColors.deepBlue : AppColors.darkCharcoal,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              if (_isOtpComplete) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _handleVerify(),
                );
              }
            }
          } else {
            if (index > 0) _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
        onTap: () {
          _otpControllers[index].clear();
          setState(() {});
        },
      ),
    );
  }
}

/// Two yellow waves at the top of the screen
class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.primaryYellow
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, size.height * 0.22);
    path1.cubicTo(
      size.width * 0.30,
      size.height * 0.34,
      size.width * 0.65,
      size.height * 0.14,
      size.width,
      size.height * 0.26,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
