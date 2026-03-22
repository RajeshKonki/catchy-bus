import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../config/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Wave slides in from top
  late AnimationController _waveController;
  late Animation<double> _waveSlide;

  // Logo + tagline fade + scale in
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<double> _contentScale;

  // Exit: logo slides up and fades out
  late AnimationController _exitController;
  late Animation<double> _exitSlide;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // 1. Wave entrance
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _waveSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOutCubic),
    );

    // 2. Content entrance
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentFade = CurvedAnimation(
        parent: _contentController, curve: Curves.easeOut);
    _contentScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController, curve: Curves.easeOutBack),
    );

    // 3. Exit: content slides up & fades out
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitSlide = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Wave slides in
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _waveController.forward();

    // Content fades in
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _contentController.forward();

    // Hold, then play exit animation
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _exitController.forward();

    // Navigate once exit finishes
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      if (authState.user!.type == 'driver') {
        context.go(AppRouter.driverHome);
      } else {
        context.go(AppRouter.studentLanding);
      }
    } else {
      context.go(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _contentController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Wave (also slides up on exit) ───────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_waveSlide, _exitSlide]),
            builder: (context, _) {
              final entranceOffset = _waveSlide.value * size.height * 0.45;
              final exitOffset = _exitController.isAnimating || _exitController.isCompleted
                  ? _exitSlide.value * size.height * 0.45
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, entranceOffset + exitOffset),
                child: CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _SplashWavePainter(),
                ),
              );
            },
          ),

          // ── Logo + tagline (slide up on exit) ───────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_exitSlide, _exitFade]),
            builder: (context, child) {
              final slideOffset = (_exitController.isAnimating ||
                      _exitController.isCompleted)
                  ? _exitSlide.value * size.height * 0.35
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, slideOffset),
                child: Opacity(
                  opacity: (_exitController.isAnimating ||
                          _exitController.isCompleted)
                      ? _exitFade.value
                      : 1.0,
                  child: child,
                ),
              );
            },
            child: Center(
              child: FadeTransition(
                opacity: _contentFade,
                child: ScaleTransition(
                  scale: _contentScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/icons/catchy_logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),

                      // Tagline
                      Text(
                        'Your college bus, always on track.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
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
}

/// Same wave shape as login / OTP screens
class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryYellow
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.22);
    path.cubicTo(
      size.width * 0.30,
      size.height * 0.34,
      size.width * 0.65,
      size.height * 0.14,
      size.width,
      size.height * 0.26,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
