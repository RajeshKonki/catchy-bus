import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/utils/logger.dart';
import 'package:catchybus/features/bus_tracking/presentation/providers/bus_tracking_provider.dart';
import 'package:catchybus/features/auth/presentation/providers/auth_provider.dart';
import 'package:catchybus/features/bus_tracking/domain/entities/bus_route.dart';
import 'package:catchybus/features/driver/domain/entities/trip_summary.dart';
import '../../../../core/utils/ui_helpers.dart';
import 'package:catchybus/features/driver/presentation/pages/attendance_qr_scanner_page.dart';

class TripTrackingPage extends ConsumerStatefulWidget {
  const TripTrackingPage({super.key});

  @override
  ConsumerState<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends ConsumerState<TripTrackingPage> {
  final SocketService _socketService = getIt<SocketService>();
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _refreshTimer; // Add this
  String _busId = "Bus No. 10"; // Match format used in student side
  bool _isTracking = false;
  String? _selectedCancelReason;
  String? _selectedSkipReason;
  final Set<String> _selectedStudents = {};
  List<Map<String, dynamic>> _currentStopStudents = [];
  bool _isLoadingStudents = false;
  Function(void Function())? _modalSetter;
  DateTime? _startTime;
  double _totalDistanceKm = 0.0;
  Position? _lastPosition;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final user = ref.read(authProvider).user;
    if (user?.busNumber != null) {
      if (mounted) {
        setState(() {
          _busId = user!.busNumber!;
        });
      }
      ref.read(busTrackingProvider.notifier).loadBusRoute(_busId);
      // Also start listening to tracking updates for the driver's own view
      ref.read(busTrackingProvider.notifier).startTracking(_busId);
    }
    // Start tracking after we have the initial busId
    _startTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    _socketService.off('students_list');
    super.dispose();
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Log.e('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Log.e('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Log.e('Location permissions are permanently denied');
      return;
    }

    final authState = ref.read(authProvider);
    _socketService.connect(token: authState.lastIdToken);

    // Join the bus room so server knows which bus we are
    _socketService.joinBus(_busId);
    
    // Notify server that a trip has started (or resume existing)
    _socketService.startTrip(_busId);

    _socketService.on('students_list', (data) {
      Log.i('Received students list: ${data['students'].length} students for ${data['stopName']}');
      if (mounted) {
        setState(() {
          _currentStopStudents = List<Map<String, dynamic>>.from(data['students']);
          _isLoadingStudents = false;
        });
        _modalSetter?.call(() {});
      }
    });

    // Send initial location immediately to ensure server and students see us starting
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      _socketService.updateLocation(
        busId: _busId,
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
        bearing: initialPosition.heading,
      );
      Log.i('Initial starting location sent: ${initialPosition.latitude}, ${initialPosition.longitude}');
    } catch (e) {
      Log.w('Could not send initial location immediately: $e');
    }



    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5, // Update every 5 meters for better rotation
          ),
        ).listen((Position position) {
          if (_lastPosition != null) {
            final distance = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            _totalDistanceKm += distance / 1000;
          }
          _lastPosition = position;
          
          // 1. Send to server
          _socketService.updateLocation(
            busId: _busId,
            latitude: position.latitude,
            longitude: position.longitude,
            bearing: position.heading,
          );
          
          // 2. Immediately update local UI for perceived responsiveness
          ref.read(busTrackingProvider.notifier).updateLocalPosition(
            BusPosition(
              latitude: position.latitude,
              longitude: position.longitude,
              bearing: position.heading,
            ),
          );
          
          Log.d(
            'Location updated: ${position.latitude}, ${position.longitude}, Heading: ${position.heading}, Distance: $_totalDistanceKm km',
          );
        });

    if (mounted) {
      setState(() {
        _isTracking = true;
        _startTime = DateTime.now();
      });
      
      // Setup 5-second periodic refresh as requested
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
          );
          _socketService.updateLocation(
            busId: _busId,
            latitude: position.latitude,
            longitude: position.longitude,
            bearing: position.heading,
          );
          
          ref.read(busTrackingProvider.notifier).updateLocalPosition(
            BusPosition(
              latitude: position.latitude,
              longitude: position.longitude,
              bearing: position.heading,
            ),
          );
          
          Log.d('DEBUG: Periodic 5s location refresh sent: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          Log.w('Could not perform periodic refresh: $e');
        }
      });
    }
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    _refreshTimer?.cancel();
    _socketService.disconnect();
    _isTracking = false;
  }

  @override
  Widget build(BuildContext context) {
    final busState = ref.watch(busTrackingProvider);
    final busRoute = busState.maybeWhen(
      loaded: (route) => route,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.deepBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  Icon(
                    _isTracking ? Icons.sensors : Icons.sensors_off,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isTracking ? 'TRACKING ON' : 'TRACKING OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showCancelTripModal(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel Trip',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    iconColor: Colors.blue[800]!,
                    value: busRoute != null
                        ? busRoute.students.length.toString()
                        : '...',
                    label: 'Total',
                    onTap: () {
                      if (busRoute != null) {
                         _showStudentListModal(context, 'Total Students', busRoute.students);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.check_circle,
                    iconColor: Colors.orange[800]!,
                    value: busRoute != null
                        ? busRoute.students.where((s) => s['isBoarded'] == true).length.toString()
                        : '...',
                    label: 'Boarded',
                    onTap: () {
                      if (busRoute != null) {
                        final boardedStudents = busRoute.students.where((s) => s['isBoarded'] == true).toList();
                        _showStudentListModal(context, 'Boarded Students', boardedStudents);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.access_time_filled,
                    iconColor: Colors.red[800]!,
                    value: busRoute != null
                        ? (busRoute.students.length - 
                           busRoute.students.where((s) => s['isBoarded'] == true).length).toString()
                        : '...',
                    label: 'Pending',
                    onTap: () {
                      if (busRoute != null) {
                        final pendingStudents = busRoute.students.where((s) => s['isBoarded'] == false || s['isBoarded'] == null).toList();
                        _showStudentListModal(context, 'Pending Students', pendingStudents);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Content Area (Timeline)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildRouteTimeline(),
                              const SizedBox(height: 100), // Space for FAB
                            ],
                          ),
                        ),
                      ),
                      // Floating Action Button
                      if (busRoute != null)
                        Positioned(
                          bottom: 30,
                          right: 20,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => _showTripCompletedModal(context, busRoute),
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a compact status chip for a route stop.
  Widget _buildStopStatusChip({
    required RouteStop stop,
    required bool isPassed,
    required bool isAtStop,
    required bool isTransitApproaching,
  }) {
    String label;
    Color bg;
    Color fg;
    IconData icon;

    if (isPassed) {
      if (stop.actualArrivalTime != null && stop.scheduledTime != null) {
        // Compute delay: compare actual arrival vs scheduled
        final delay = _computeDelay(stop.actualArrivalTime!, stop.scheduledTime!);
        if (delay <= 0) {
          label = 'Reached · On Time';
          bg = const Color(0xFFE8F5E9);
          fg = const Color(0xFF2E7D32);
          icon = Icons.check_circle_outline;
        } else {
          label = 'Reached · $delay min late';
          bg = const Color(0xFFFFF3E0);
          fg = const Color(0xFFE65100);
          icon = Icons.schedule;
        }
      } else {
        label = 'Reached';
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.check_circle_outline;
      }
    } else if (isAtStop) {
      if (stop.delayMinutes > 0) {
        label = 'Arrived · ${stop.delayMinutes} min late';
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        icon = Icons.sports_score;
      } else {
        label = 'Arrived · On Time';
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        icon = Icons.sports_score;
      }
    } else if (isTransitApproaching) {
      label = 'Bus Approaching';
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
      icon = Icons.directions_bus;
    } else {
      // Upcoming stop
      if (stop.estimatedArrivalMinutes != null) {
        if (stop.delayMinutes > 0) {
          label = 'ETA ${stop.estimatedArrivalMinutes} min · ${stop.delayMinutes} min delay';
          bg = const Color(0xFFFFEBEE);
          fg = const Color(0xFFB71C1C);
          icon = Icons.access_time_filled;
        } else {
          label = 'ETA ${stop.estimatedArrivalMinutes} min · On Time';
          bg = const Color(0xFFE8F5E9);
          fg = const Color(0xFF388E3C);
          icon = Icons.access_time;
        }
      } else {
        label = 'Upcoming';
        bg = Colors.grey[100]!;
        fg = Colors.grey[600]!;
        icon = Icons.radio_button_unchecked;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Compare actual arrival DateTime against scheduled time string (e.g. "08:30 AM").
  /// Returns delay in minutes (negative = early).
  int _computeDelay(DateTime actual, String scheduled) {
    try {
      final parts = scheduled.trim().split(RegExp(r'[\s:]'));
      int h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (parts.length > 2) {
        final ampm = parts[2].toUpperCase();
        if (ampm == 'PM' && h < 12) h += 12;
        if (ampm == 'AM' && h == 12) h = 0;
      }
      final scheduledDt = DateTime(actual.year, actual.month, actual.day, h, m);
      return actual.difference(scheduledDt).inMinutes;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTimeline() {
    final busState = ref.watch(busTrackingProvider);

    return busState.when(
      initial: () => const Center(child: CircularProgressIndicator()),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (message) => Center(child: Text('Error: $message')),
      loaded: (busRoute) {
        final stopsData = busRoute.stops;

        final bool isInTransit = busRoute.transitFromStopIndex >= 0;
        final int transitFrom = busRoute.transitFromStopIndex;
        final double transitProg = busRoute.transitProgress;

        // When NOT in transit, find the index of the current stop dot
        int? atStopIndex;
        if (!isInTransit) {
          for (int i = 0; i < stopsData.length; i++) {
            if (stopsData[i].type == StopType.currentLocation) {
              atStopIndex = i;
              break;
            }
          }
          // Fallback: last passed stop
          atStopIndex ??= () {
            int last = 0;
            for (int i = 0; i < stopsData.length; i++) {
              if (stopsData[i].type == StopType.passedStop) last = i;
            }
            return last;
          }();
        }

        return Column(
          children: List.generate(stopsData.length, (index) {
            final RouteStop stop = stopsData[index];
            final isLast = index == stopsData.length - 1;
            final isPassed = stop.type == StopType.passedStop;
            final isSkipped = stop.type == StopType.skippedStop;
            final isAtStop = !isInTransit && index == atStopIndex;
            final bool isTransitSegment = isInTransit && index == transitFrom;
            final isFuture = !isPassed && !isSkipped && !isAtStop && !isTransitSegment;
            
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Column
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        if (isAtStop)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1.05),
                            duration: const Duration(seconds: 1),
                            builder: (context, value, child) => Transform.scale(
                              scale: value,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 28,
                                  height: 44,
                                  child: Image.asset(
                                    'assets/icons/tracker.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            onEnd: () {}, // Pulse effect
                          )
                        else if (isPassed || (isInTransit && index <= transitFrom))
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else if (isSkipped)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF5350),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[400]!, width: 2),
                            ),
                          ),
                        if (!isLast)
                          Expanded(
                            child: isTransitSegment
                              // Active transit segment: split line at bus position
                              ? Stack(
                                  clipBehavior: Clip.none, // allow bus icon to overflow line bounds
                                  alignment: Alignment.center,
                                  children: [
                                    // Full column: blue top (done) + grey bottom (ahead)
                                    Column(
                                      children: [
                                        Expanded(
                                          flex: (transitProg * 100).round().clamp(1, 99),
                                          child: Container(
                                            width: 6,
                                            color: AppColors.deepBlue,
                                          ),
                                        ),
                                        Expanded(
                                          flex: ((1 - transitProg) * 100).round().clamp(1, 99),
                                          child: Container(
                                            width: 4,
                                            color: Colors.grey[300]!.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Bus icon at the exact split point — OverflowBox allows full size
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment(0, -1.0 + (transitProg * 2.0)),
                                        child: OverflowBox(
                                          minWidth: 0,
                                          maxWidth: 40,
                                          minHeight: 0,
                                          maxHeight: 60,
                                          child: Image.asset(
                                            'assets/icons/tracker.png',
                                            width: 28,
                                            height: 44,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              // Fully passed or future segment: solid single-color line
                              : Container(
                                  width: isPassed ? 6 : 4,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: () {
                                      if (isInTransit) {
                                        // In transit: segments before the active leg are blue
                                        return index < transitFrom
                                            ? AppColors.deepBlue
                                            : Colors.grey[300]!.withOpacity(0.8);
                                      } else {
                                        // At a stop: all segments before current stop are blue
                                        return (atStopIndex != null && index < atStopIndex)
                                            ? AppColors.deepBlue
                                            : Colors.grey[300]!.withOpacity(0.8);
                                      }
                                    }(),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                stop.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (stop.scheduledTime != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  stop.scheduledTime!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildStopStatusChip(
                          stop: stop,
                          isPassed: isPassed,
                          isAtStop: isAtStop,
                          isTransitApproaching: isInTransit && index == transitFrom + 1,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (isAtStop || isFuture) ...[
                              ElevatedButton(
                                onPressed: () => _showSkipStopModal(context, stop.name),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Skip Stop',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => _showAttendanceModal(context, stop.name),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.brightOrange,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Mark Attendance',
                                style: TextStyle(
                                  color: AppColors.brightOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!isLast)
                          Divider(
                            color: Colors.grey[200],
                            thickness: 1,
                            height: 1,
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  void _showSkipStopModal(BuildContext context, String stopName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Skip Stop',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please select a reason for skipping this stop. Students at this stop will be notified.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildReasonItem(
                    'No Student at this Stop',
                    _selectedSkipReason == 'No Student at this Stop',
                    () => setModalState(
                      () => _selectedSkipReason = 'No Student at this Stop',
                    ),
                  ),
                  _buildReasonItem(
                    'Road Accident / Blockage',
                    _selectedSkipReason == 'Road Accident / Blockage',
                    () => setModalState(
                      () => _selectedSkipReason = 'Road Accident / Blockage',
                    ),
                  ),
                  _buildReasonItem(
                    'Traffic Congestion',
                    _selectedSkipReason == 'Traffic Congestion',
                    () => setModalState(
                      () => _selectedSkipReason = 'Traffic Congestion',
                    ),
                  ),
                  _buildReasonItem(
                    'Weather Conditions',
                    _selectedSkipReason == 'Weather Conditions',
                    () => setModalState(
                      () => _selectedSkipReason = 'Weather Conditions',
                    ),
                  ),
                  _buildReasonItem(
                    'Emergency Situation',
                    _selectedSkipReason == 'Emergency Situation',
                    () => setModalState(
                      () => _selectedSkipReason = 'Emergency Situation',
                    ),
                  ),
                  _buildReasonItem(
                    'Other (Specify)',
                    _selectedSkipReason == 'Other (Specify)',
                    () => setModalState(
                      () => _selectedSkipReason = 'Other (Specify)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.brightOrange,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: AppColors.brightOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                              onPressed: _selectedSkipReason == null
                                  ? null
                                  : () {
                                      _socketService.skipStop(
                                        busId: _busId,
                                        stopName: stopName,
                                        reason: _selectedSkipReason ?? 'Manual Skip',
                                      );
                                      
                                      ref.read(busTrackingProvider.notifier).markStopSkipped(stopName);
                                      
                                      Navigator.pop(modalContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Stop "$stopName" skipped successfully'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Skip Stop',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCancelTripModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            bool isCancelling = false;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Cancel Trip',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This will cancel the entire trip and notify all students. Please select a reason.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildReasonItem(
                    'Vehicle Breakdown',
                    _selectedCancelReason == 'Vehicle Breakdown',
                    () => setModalState(
                      () => _selectedCancelReason = 'Vehicle Breakdown',
                    ),
                  ),
                  _buildReasonItem(
                    'Driver Medical Emergency',
                    _selectedCancelReason == 'Driver Medical Emergency',
                    () => setModalState(
                      () => _selectedCancelReason = 'Driver Medical Emergency',
                    ),
                  ),
                  _buildReasonItem(
                    'Severe Weather Conditions',
                    _selectedCancelReason == 'Severe Weather Conditions',
                    () => setModalState(
                      () => _selectedCancelReason = 'Severe Weather Conditions',
                    ),
                  ),
                  _buildReasonItem(
                    'Road Accident / Blockage',
                    _selectedCancelReason == 'Road Accident / Blockage',
                    () => setModalState(
                      () => _selectedCancelReason = 'Road Accident / Blockage',
                    ),
                  ),
                  _buildReasonItem(
                    'Fuel / Mechanical Issue',
                    _selectedCancelReason == 'Fuel / Mechanical Issue',
                    () => setModalState(
                      () => _selectedCancelReason = 'Fuel / Mechanical Issue',
                    ),
                  ),
                  _buildReasonItem(
                    'Other (Specify)',
                    _selectedCancelReason == 'Other (Specify)',
                    () => setModalState(
                      () => _selectedCancelReason = 'Other (Specify)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.brightOrange,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: AppColors.brightOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_selectedCancelReason == null || isCancelling)
                              ? null
                              : () {
                                  setModalState(() => isCancelling = true);
                                  
                                  // Wait for server acknowledgement to ensure DB is updated
                                  _socketService.on('trip_cancelled', (data) {
                                    _socketService.off('trip_cancelled');
                                    if (context.mounted) {
                                      _stopTracking();
                                      // Clear trip state before going back home
                                      ref.read(busTrackingProvider.notifier).clearActiveTrip();
                                      ref.read(busTrackingProvider.notifier).loadBusRoute(_busId);
                                      context.go(AppRouter.driverHome);
                                      Navigator.pop(modalContext);
                                    }
                                  });
                                  
                                  // Add a timeout fallback in case the event is missed
                                  Future.delayed(const Duration(seconds: 3), () {
                                    if (isCancelling && context.mounted) {
                                      _socketService.off('trip_cancelled');
                                      _stopTracking();
                                      ref.read(busTrackingProvider.notifier).clearActiveTrip();
                                      ref.read(busTrackingProvider.notifier).loadBusRoute(_busId);
                                      context.go(AppRouter.driverHome);
                                      Navigator.pop(modalContext);
                                    }
                                  });

                                  _socketService.cancelTrip(_busId, _selectedCancelReason ?? 'Manual Cancellation');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isCancelling 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Cancel Trip',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStudentListModal(BuildContext context, String title, List<Map<String, dynamic>> students) {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredStudents = students.where((s) {
            final name = (s['name'] as String? ?? '').toLowerCase();
            final stop = (s['stopName'] as String? ?? '').toLowerCase();
            final query = searchQuery.toLowerCase();
            return name.contains(query) || stop.contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Modal Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active Trip • ${students.length} Total',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setModalState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by student or stop...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        icon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Student List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? _buildEmptyStudentState(searchQuery.isNotEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isBoarded = student['isBoarded'] ?? false;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[100]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Avatar with presence indicator
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.deepBlue.withOpacity(0.1),
                                        child: Text(
                                          (student['name'] as String? ?? 'S')[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.deepBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: isBoarded ? Colors.green : Colors.orange,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'] ?? 'Unknown Student',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                                            const SizedBox(width: 4),
                                            Text(
                                              student['stopName'] ?? 'No stop',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isBoarded 
                                          ? Colors.green.withOpacity(0.1) 
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isBoarded ? 'BOARDED' : 'PENDING',
                                      style: TextStyle(
                                        color: isBoarded ? Colors.green[700] : Colors.orange[700],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStudentState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off : Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch ? 'No matching results' : 'No students found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              isSearch 
                  ? "Try checking the student's name spelling or stop location."
                  : "No students are currently tracked for this category.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue[900] : Colors.black87,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: isSelected ? 6 : 2,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceModal(BuildContext context, String stopName) async {
    // Check if driver is close enough to the stop (within 200m)
    final currentState = ref.read(busTrackingProvider);
    final stop = currentState.maybeWhen(
      loaded: (route) {
        try {
          return route.stops.firstWhere((s) => s.name == stopName);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    if (stop != null) {
      final currentPos = _lastPosition ?? await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        stop.latitude,
        stop.longitude,
      );

      if (distance > 200) {
        if (context.mounted) {
          // Changed from error/return to a warning tooltip
          UIHelpers.showWarningTooltip(
            context, 
            'Warning: You are ${distance.toInt()}m from $stopName. Please ensure you are at the correct stop.'
          );
        }
      }
    }

    setState(() {
      _isLoadingStudents = true;
      _currentStopStudents = [];
    });

    // Use reliable HTTP call instead of socket event
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(busTrackingProvider.notifier).fetchStudentsForStop(
        _busId, 
        stopName,
        onData: (students) {
          // Update local state when notifier updates
          if (mounted) {
            setState(() {
              _currentStopStudents = List<Map<String, dynamic>>.from(students);
              _isLoadingStudents = false;
            });
            // Also trigger modal's local state update if it was passed
            if (_modalSetter != null) {
              _modalSetter!(() {});
            }
          }
        },
      );
    });

    showModalBottomSheet(

      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            _modalSetter = setModalState;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await context.push<QrScanResult>(AppRouter.attendanceQrScanner);
                          if (result != null && mounted) {
                            setModalState(() {
                              // Add scanned student to list if not already present
                              final alreadyExists = _currentStopStudents.any(
                                (s) => s['id'] == result.studentId,
                              );
                              if (!alreadyExists) {
                                _currentStopStudents.add({
                                  'id': result.studentId,
                                  'name': result.studentName,
                                  'stopName': stopName,
                                  'profilePictureUrl': null,
                                });
                              }
                              // Auto-select the scanned student
                              _selectedStudents.add(result.studentId);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text('${result.studentName} added to attendance'),
                                  ],
                                ),
                                backgroundColor: Colors.green[700],
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Scan QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brightOrange,
                          side: const BorderSide(color: AppColors.brightOrange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.blue[800], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentStopStudents.length} Students',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: _isLoadingStudents
                        ? const Center(child: CircularProgressIndicator())
                        : _currentStopStudents.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No students assigned to this stop'),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: _currentStopStudents.map((student) {
                                    final isSelected =
                                        _selectedStudents.contains(student['id']);
                                    return _buildStudentItem(
                                      student['name'] ?? 'Unknown',
                                      student['id'] ?? '',
                                      isSelected,
                                      () => setModalState(() {
                                        if (isSelected) {
                                          _selectedStudents.remove(student['id']);
                                        } else {
                                          _selectedStudents.add(student['id']!);
                                        }
                                      }),
                                      profilePictureUrl: student['profilePictureUrl'],
                                    );

                                  }).toList(),
                                ),
                              ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Real logic to save attendance
                        _socketService.markAttendance(
                          busId: _busId,
                          stopName: stopName,
                          studentIds: _selectedStudents.where((id) => _currentStopStudents.any((s) => s['id'] == id)).toList(),
                        );
                        
                        // Mark the stop as reached in local state
                        final boardedStudentIds = _selectedStudents.where((id) => _currentStopStudents.any((s) => s['id'] == id)).toList();
                        final boardedAtThisStopCount = boardedStudentIds.length;
                        
                        ref.read(busTrackingProvider.notifier).markStopReached(
                          stopName, 
                          boardedCount: boardedAtThisStopCount,
                          boardedStudentIds: boardedStudentIds,
                        );
                        
                        Navigator.pop(modalContext);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Attendance marked and stop recorded at ${stopName}'),
                            backgroundColor: AppColors.brightOrange,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brightOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentItem(
      String name, String id, bool isSelected, VoidCallback onTap, {String? profilePictureUrl}) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isSelected ? Colors.blue[100] : Colors.blue[50],
              backgroundImage: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                  ? NetworkImage(profilePictureUrl)
                  : null,
              child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                  ? Text(
                      _getInitials(name),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: $id',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: isSelected ? 6 : 2,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripCompletedModal(BuildContext context, BusRoute busRoute) {
    final totalStops = busRoute.stops.length;
    final completedStops =
        busRoute.stops.where((s) => s.type == StopType.passedStop).length;
    final skippedStops =
        busRoute.stops.where((s) => s.type == StopType.skippedStop).length;

    final totalStudents =
        busRoute.stops.fold(0, (sum, s) => sum + (s.studentCount ?? 0));
    final onboardedStudents =
        busRoute.stops.fold(0, (sum, s) => sum + (s.boardedStudentCount ?? 0));
    final absentStudents = totalStudents - onboardedStudents;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Trip Completed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'You have completed all stops on this route. Would you like to end the trip?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Stops', '$totalStops', isHeader: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Completed', '$completedStops'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Skipped', '$skippedStops'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0xFFD1E5FF)),
                    ),
                    _buildSummaryRow('Total Students', '$totalStudents', isHeader: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Onboarded', '$onboardedStudents'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Absent', '$absentStudents'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReviewModal(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.brightOrange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Review Trip',
                        style: TextStyle(
                          color: AppColors.brightOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        
                        final now = DateTime.now();
                        final duration = _startTime != null 
                            ? now.difference(_startTime!) 
                            : Duration.zero;
                            
                        final summary = TripSummary(
                          duration: duration,
                          distanceKm: _totalDistanceKm,
                          busId: _busId,
                          endTime: now,
                        );
                        
                        context.push(AppRouter.endTripSummary, extra: summary);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brightOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'End Trip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  void _showReviewModal(BuildContext context) {
    final queryController = TextEditingController();
    final user = ref.read(authProvider).user;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final supportState = ref.watch(supportProvider);
            final isLoading = supportState.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Trip Review',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please share your experience or any issues encountered during this trip.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: queryController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Your feedback here...',
                      hintStyle: const TextStyle(fontSize: 13),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brightOrange, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (queryController.text.trim().isEmpty) {
                            UIHelpers.showErrorTooltip(
                              context,
                              'Please enter your review content',
                            );
                            return;
                          }

                          await ref.read(supportProvider.notifier).sendQuery(
                                query: queryController.text.trim(),
                                subject: 'Trip Review - ${_busId}',
                                email: user?.email,
                              );

                          if (context.mounted) {
                            final newState = ref.read(supportProvider);
                            newState.whenOrNull(
                              success: () {
                                Navigator.of(context).pop();
                                UIHelpers.showSuccessTooltip(
                                  context,
                                  'Review submitted successfully',
                                );
                              },
                              error: (message) {
                                UIHelpers.showErrorTooltip(context, message);
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brightOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildSummaryRow(String label, String value, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isHeader ? 4 : 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHeader ? 14 : 13,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              color: isHeader ? const Color(0xFF1E3A8A) : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHeader ? 14 : 13,
              fontWeight: FontWeight.bold,
              color: isHeader ? const Color(0xFF1E3A8A) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
