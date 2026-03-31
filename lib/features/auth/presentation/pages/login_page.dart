import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/ui_helpers.dart';

/// Login page
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  String _selectedRole = 'Student';

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      final phone = '+91${_identifierController.text.trim()}';
      ref.read(authProvider.notifier).sendOtp(phone, _selectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        UIHelpers.showErrorTooltip(context, next.error!);
      }

      if (next.verificationId != null &&
          next.verificationId != previous?.verificationId) {
        context.push(
          AppRouter.otpVerification,
          extra: {
            'identifier': _identifierController.text.trim(),
            'role': _selectedRole,
          },
        );
      }

      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        UIHelpers.showSuccessTooltip(context, 'Login successful!');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Faint wave background
          Positioned.fill(
            child: CustomPaint(painter: _WaveBackgroundPainter()),
          ),
          // Logo sitting on the wave curve
          // Background paint handled by Positioned.fill above
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
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
                      const SizedBox(height: 32),

                      // Role Toggle
                      _buildRoleToggle(),
                      const SizedBox(height: 24),

                      // Mobile number field
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: '10-digit mobile number',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.deepBlue,
                              size: 20,
                            ),
                            prefixText: '+91  ',
                            prefixStyle: const TextStyle(
                              color: AppColors.deepBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppColors.lightYellow,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.deepBlue,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.locationRed,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.locationRed,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (value.length != 10) {
                              return 'Mobile number must be exactly 10 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Helper text
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Enter the mobile number registered with your college',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Continue button
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : _handleContinue,
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
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

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

  Widget _buildRoleToggle() {
    final roles = [
      ('Student', Icons.school_rounded),
      ('Driver', Icons.drive_eta_rounded),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRole == role.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: role.$1 == 'Student' ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.deepBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.deepBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.deepBlue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role.$2,
                      size: 22,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
