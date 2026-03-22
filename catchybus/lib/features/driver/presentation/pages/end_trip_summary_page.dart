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
    
    // Listen for server confirmation to ensure DB has been updated
    socketService.on('trip_ended', (_) {
      socketService.off('trip_ended');
      if (mounted) {
        socketService.disconnect();
        // Update local state first for immediate UI response
        ref.read(busTrackingProvider.notifier).clearActiveTrip();
        ref.read(busTrackingProvider.notifier).loadBusRoute(widget.summary.busId);
        context.go(AppRouter.driverHome);
      }
    });
    
    // Timeout fallback fallback
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        socketService.off('trip_ended');
        socketService.disconnect();
        // Force refresh the route so we land on a clean state
        ref.read(busTrackingProvider.notifier).clearActiveTrip();
        ref.read(busTrackingProvider.notifier).loadBusRoute(widget.summary.busId);
        if (GoRouter.of(context).state.matchedLocation.contains('end-trip')) {
           context.go(AppRouter.driverHome);
        }
      }
    });

    socketService.endTrip(widget.summary.busId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.locationRed,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Warning Icon
            const Center(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'End Trip?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'This will stop location tracking and notify all students',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),

            // Stats Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow(
                    Icons.access_time_filled,
                    'Trip Duration',
                    widget.summary.durationString,
                    const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    Icons.directions_bus,
                    'Distance',
                    '${widget.summary.distanceKm.toStringAsFixed(1)} km',
                    const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 24),

                  // Hold to End Button
                  GestureDetector(
                    onTapDown: (_) => _startHolding(),
                    onTapUp: (_) => _stopHolding(),
                    onTapCancel: () => _stopHolding(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background/Progress
                        Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.locationRed,
                              ),
                              minHeight: 60,
                            ),
                          ),
                        ),
                        // Text Overlay
                        const Text(
                          'Hold to End Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isHolding)
                          Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.locationRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Hold to End Trip',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // No Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.locationRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: AppColors.locationRed,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Footer Info
            const Text(
              'Hold the button for 3 seconds to confirm',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.deepBlue, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.deepBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
