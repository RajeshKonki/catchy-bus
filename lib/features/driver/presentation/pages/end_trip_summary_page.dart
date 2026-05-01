import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../domain/entities/trip_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/socket_service.dart';
import 'package:catchybus/features/bus_tracking/presentation/providers/bus_tracking_provider.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/localization/app_strings.dart';

class EndTripSummaryPage extends ConsumerStatefulWidget {
  final TripSummary summary;
  const EndTripSummaryPage({super.key, required this.summary});

  @override
  ConsumerState<EndTripSummaryPage> createState() => _EndTripSummaryPageState();
}

class _EndTripSummaryPageState extends ConsumerState<EndTripSummaryPage> {
  double _progress = 0.0;
  Timer? _timer;
  bool _isHolding = false;
  bool _isEnded = false;
  bool _isEnding = false;
  bool _showForceClose = false;

  void _startHolding() {
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _timer?.cancel();
          _onHoldComplete();
        }
      });
    });
  }

  void _stopHolding() {
    if (_progress < 1.0) {
      _timer?.cancel();
      setState(() {
        _isHolding = false;
        _progress = 0.0;
      });
    }
  }

  void _onHoldComplete() {
    final socketService = getIt<SocketService>();
    if (mounted) {
      setState(() {
        _isEnding = true;
        _showForceClose = false;
      });
    }

    // Show force close option after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted && _isEnding) {
        setState(() => _showForceClose = true);
      }
    });

    // Safety timeout: If server doesn't respond in 12s, proceed anyway
    Timer? safetyTimer;
    safetyTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _isEnding) {
        socketService.off('trip_ended');
        socketService.off('trip_end_error');
        setState(() {
          _isEnded = true;
          _isEnding = false;
        });
        ref.read(busTrackingProvider.notifier).clearActiveTrip();
        ref.read(busTrackingProvider.notifier).loadBusRoute(widget.summary.busId);
      }
    });

    socketService.on('trip_ended', (_) {
      safetyTimer?.cancel();
      socketService.off('trip_ended');
      socketService.off('trip_end_error');
      if (mounted) {
        setState(() {
          _isEnded = true;
          _isEnding = false;
          _isHolding = false;
          _progress = 0.0;
        });
        ref.read(busTrackingProvider.notifier).clearActiveTrip();
        ref.read(busTrackingProvider.notifier).loadBusRoute(widget.summary.busId);
      }
    });

    socketService.on('trip_end_error', (data) {
      safetyTimer?.cancel();
      socketService.off('trip_ended');
      socketService.off('trip_end_error');
      
      final msg = data['message'] as String? ?? 'Cannot end trip here.';
      if (mounted) {
        setState(() => _isEnding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    });
    
    socketService.endTrip(
      widget.summary.busId,
      driverLat: widget.summary.driverLat ?? 0,
      driverLng: widget.summary.driverLng ?? 0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = getIt<SocketService>();
    final strings = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.deepBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: currentLang,
                icon: const Icon(Icons.language, color: AppColors.deepBlue, size: 16),
                onChanged: (AppLanguage? newLang) {
                  if (newLang != null) {
                    ref.read(languageProvider.notifier).setLanguage(newLang);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('Eng', style: TextStyle(color: AppColors.deepBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.telugu,
                    child: Text('తెలుగు', style: TextStyle(color: AppColors.deepBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                strings.get('trip_completed'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${strings.get('bus_number')}: ${widget.summary.busId}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.timer_outlined,
                      label: strings.get('duration'),
                      value: _formatDuration(widget.summary.duration),
                      color: Colors.blue,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow(
                      icon: Icons.route_outlined,
                      label: strings.get('distance'),
                      value: UIHelpers.formatDistance(widget.summary.distanceKm),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              if (_isEnding)
                Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.brightOrange),
                    const SizedBox(height: 16),
                    const Text('Closing trip on server...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    if (_showForceClose) ...[
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          socketService.off('trip_ended');
                          socketService.off('trip_end_error');
                          setState(() {
                            _isEnded = true;
                            _isEnding = false;
                          });
                          ref.read(busTrackingProvider.notifier).clearActiveTrip();
                          ref.read(busTrackingProvider.notifier).loadBusRoute(widget.summary.busId);
                        },
                        child: const Text('Server not responding? Force Close', 
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ],
                )
              else if (!_isEnded) 
                _buildHoldToEndButton(strings)
              else 
                _buildCompletionActions(strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionActions(AppStrings strings) {
    final bool canStartReturn = widget.summary.routeId != null && !widget.summary.isReverse;
    
    return Column(
      children: [
        if (canStartReturn)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.pushReplacement(
                  AppRouter.tripTracking,
                  extra: {
                    'routeId': widget.summary.routeId,
                    'routeName': widget.summary.routeName,
                    'driverLat': widget.summary.driverLat,
                    'driverLng': widget.summary.driverLng,
                    'isReverse': true,
                  },
                );
              },
              icon: const Icon(Icons.swap_horiz),
              label: Text(strings.get('start_return_trip')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        if (canStartReturn) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(AppRouter.routeSelection),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.deepBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoldToEndButton(AppStrings strings) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _startHolding(),
          onTapUp: (_) => _stopHolding(),
          onTapCancel: () => _stopHolding(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brightOrange,
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isHolding ? AppColors.brightOrange : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: _isHolding ? Colors.white : AppColors.brightOrange,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isHolding ? 'Release to Cancel' : 'Hold to End Trip',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _isHolding ? AppColors.brightOrange : Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
