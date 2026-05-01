import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/maps_service.dart';

class TripTrackingPage extends ConsumerStatefulWidget {
  final String? routeId;
  final String? routeName;
  final double? driverLat;
  final double? driverLng;
  final bool isReverse;

  const TripTrackingPage({
    super.key,
    this.routeId,
    this.routeName,
    this.driverLat,
    this.driverLng,
    this.isReverse = false,
  });

  @override
  ConsumerState<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends ConsumerState<TripTrackingPage> {
  final SocketService _socketService = getIt<SocketService>();
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _refreshTimer;
  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;
  bool isMapView = false;
  String _busId = "Bus No. 10";
  String? _activeRouteId; 
  bool _isTracking = false;
  bool _isReverseTrip = false; 
  String? _selectedCancelReason;
  String? _selectedSkipReason;
  final Set<String> _selectedStudents = {};
  List<Map<String, dynamic>> _currentStopStudents = [];
  bool _isLoadingStudents = false;
  Function(void Function())? _modalSetter;
  DateTime? _startTime;
  double _totalDistanceKm = 0.0;
  Position? _lastPosition;
  int _stationaryCount = 0; 

  List<RouteStop> get _routeStops {
    return ref
        .read(busTrackingProvider)
        .maybeWhen(loaded: (r) => r.stops, orElse: () => []);
  }

  List<RoutePoint> get _routePath {
    return ref
        .read(busTrackingProvider)
        .maybeWhen(loaded: (r) => r.routePath, orElse: () => []);
  }


  double _prevTransitProg = 0.03;
  int _prevTransitFrom = -1;

  void _updateTransitPrev(int fromIdx, double displayProg) {
    if (fromIdx != _prevTransitFrom) {
      _prevTransitFrom = fromIdx;
      _prevTransitProg = displayProg.clamp(0.03, 0.97);
    } else {
      // Keep updating so TweenAnimationBuilder always starts from the last real value.
      _prevTransitProg = displayProg.clamp(0.03, 0.97);
    }
  }

  @override
  void initState() {
    super.initState();
    _activeRouteId = widget.routeId;
    _isReverseTrip = widget.isReverse;
    _loadCustomMarker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadCustomMarker() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(24, 32)),
        'assets/icons/tracker.png',
      );
      if (mounted) {
        setState(() {
          _busIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom marker: $e');
    }
  }

  void _loadInitialData() {
    final user = ref.read(authProvider).user;
    if (user?.busNumber != null) {
      if (mounted) {
        setState(() {
          _busId = user!.busNumber ?? _busId;
          _activeRouteId = widget.routeId; 
        });
      }
      // startTracking already calls loadBusRoute internally via socket.getRoute,
      // so we don't need to call it separately here. Calling both can cause 
      // race conditions where the non-reversed route overwrites the reversed one.
      ref.read(busTrackingProvider.notifier).startTracking(_busId, initialIsReverse: _isReverseTrip, routeId: _activeRouteId);
    }
    _startTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _refreshTimer?.cancel();
    _socketService.off('students_list');
    super.dispose();
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    _refreshTimer?.cancel();
    setState(() => _isTracking = false);
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        UIHelpers.showErrorTooltip(context, 'Location services are disabled.');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          UIHelpers.showErrorTooltip(context, 'Location permissions are denied.');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        UIHelpers.showErrorTooltip(
          context,
          'Location permissions are permanently denied. Please enable them in settings.',
        );
      }
      return;
    }

    final authState = ref.read(authProvider);
    _socketService.connect(token: authState.lastIdToken);
    _socketService.joinBus(_busId);

    Position? currentPos;
    try {
      currentPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      currentPos = await Geolocator.getLastKnownPosition();
    }

    _socketService.startTrip(
      _busId,
      routeId: _activeRouteId,
      driverLat: currentPos?.latitude ?? widget.driverLat,
      driverLng: currentPos?.longitude ?? widget.driverLng,
      isReverse: _isReverseTrip,
    );

    _socketService.on('trip_start_error', (data) {
      final msg = data['message'] as String? ?? 'Cannot start trip.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    });

    _socketService.on('students_list', (data) {
      if (mounted) {
        setState(() {
          final rawStudents = data['students'] as List?;
          _currentStopStudents = rawStudents?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
          _isLoadingStudents = false;
        });
        _modalSetter?.call(() {});
      }
    });

    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        intervalDuration: const Duration(milliseconds: 1000),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Tracking bus location in background",
          notificationTitle: "CatchyBus Driver",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      final lastPos = _lastPosition;
      if (lastPos != null) {
        final distance = Geolocator.distanceBetween(lastPos.latitude, lastPos.longitude, position.latitude, position.longitude);
        _totalDistanceKm += distance / 1000;
      }
      _lastPosition = position;

      _socketService.updateLocation(
        busId: _busId,
        latitude: position.latitude,
        longitude: position.longitude,
        bearing: position.heading,
      );

      ref.read(busTrackingProvider.notifier).updateLocalPosition(
        BusPosition(latitude: position.latitude, longitude: position.longitude, bearing: position.heading),
      );
    });

    if (mounted) {
      setState(() {
        _isTracking = true;
        _startTime = DateTime.now();
      });

      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        try {
          final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
          final lastPos = _lastPosition;
          final movedM = lastPos == null ? 0.0 : Geolocator.distanceBetween(lastPos.latitude, lastPos.longitude, position.latitude, position.longitude);
          final bool nowStationary = movedM < 10.0;
          final bool nowMoving = movedM > 50.0;

          if (nowStationary) {
            _stationaryCount++;
          } else if (nowMoving) {
            _stationaryCount = 0;
            _lastPosition = position;
            _socketService.updateLocation(busId: _busId, latitude: position.latitude, longitude: position.longitude, bearing: position.heading);
            ref.read(busTrackingProvider.notifier).updateLocalPosition(BusPosition(latitude: position.latitude, longitude: position.longitude, bearing: position.heading));
          }
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);
    final busState = ref.watch(busTrackingProvider);
    final busRoute = busState.maybeWhen(loaded: (route) => route, orElse: () => null);

    // Sync local isReverse with provider state (server authority)
    // We only flip if the trip is active, otherwise we trust the driver's intention from navigation
    if (busRoute != null && busRoute.isTripActive && busRoute.isReverse != _isReverseTrip) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isReverseTrip = busRoute.isReverse);
      });
    }

    // Auto-follow bus on map
    ref.listen(busTrackingProvider, (previous, next) {
      next.maybeWhen(
        loaded: (route) {
          if (_mapController != null && isMapView) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(route.busPosition.latitude, route.busPosition.longitude),
              ),
            );
          }
        },
        orElse: () {},
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final strings = ref.read(stringsProvider);
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(strings.get('exit_app_title') ?? 'Exit Trip?'),
            content: Text(strings.get('exit_app_message') ?? 'The trip is still active. Do you want to close the app? Tracking will continue in the background.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.get('cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(strings.get('exit') ?? 'Exit', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (shouldPop == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.deepBlue,
        body: SafeArea(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      (_isTracking || (busRoute?.isTripActive ?? false)) ? Icons.sensors : Icons.sensors_off,
                      color: (_isTracking || (busRoute?.isTripActive ?? false)) ? AppColors.primaryYellow : Colors.white70,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (_isTracking || (busRoute?.isTripActive ?? false)) ? strings.get('tracking_on').toUpperCase() : strings.get('tracking_off').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        if (_isReverseTrip)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.swap_horiz, color: AppColors.primaryYellow.withOpacity(0.9), size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    strings.get('start_return_trip'),
                                    style: TextStyle(color: AppColors.primaryYellow.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildLanguageToggleChip(currentLang),
                  const SizedBox(width: 8),
                  _buildCancelButton(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildStatCard(icon: Icons.people, iconColor: Colors.blue[700] ?? Colors.blue, value: busRoute != null ? busRoute.students.length.toString() : '...', label: strings.get('total'), onTap: () {
                    if (busRoute != null) _showStudentListModal(context, strings.get('total_students'), busRoute.students);
                  }),
                  const SizedBox(width: 12),
                  _buildStatCard(icon: Icons.check_circle, iconColor: Colors.orange[700] ?? Colors.orange, value: busRoute != null ? busRoute.students.where((s) => s['isBoarded'] == true).length.toString() : '...', label: strings.get('boarded'), onTap: () {
                    if (busRoute != null) _showStudentListModal(context, strings.get('boarded_students'), busRoute.students.where((s) => s['isBoarded'] == true).toList());
                  }),
                  const SizedBox(width: 12),
                  _buildStatCard(icon: Icons.access_time_filled, iconColor: Colors.red[700] ?? Colors.red, value: busRoute != null ? (busRoute.students.length - busRoute.students.where((s) => s['isBoarded'] == true).length).toString() : '...', label: strings.get('pending'), onTap: () {
                    if (busRoute != null) _showStudentListModal(context, strings.get('pending_students'), busRoute.students.where((s) => s['isBoarded'] == false || s['isBoarded'] == null).toList());
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  child: Stack(
                    children: [
                      if (!isMapView)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(children: [_buildRouteTimeline(), const SizedBox(height: 100)])),
                        )
                      else
                        _buildMap(busRoute),
                      if (busRoute != null) ...[
                        Positioned(
                          bottom: 110,
                          right: 20,
                          child: GestureDetector(
                            onTap: () => setState(() => isMapView = !isMapView),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isMapView ? AppColors.primaryYellow : AppColors.deepBlue,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Icon(
                                isMapView ? Icons.list : Icons.map,
                                color: isMapView ? AppColors.deepBlue : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          right: 20,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                            child: IconButton(onPressed: () => _showTripCompletedModal(context, busRoute), icon: const Icon(Icons.check, color: Colors.white, size: 30)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStopStatusChip({required RouteStop stop, required bool isPassed, required bool isAtStop, required bool isTransitApproaching}) {
    final strings = ref.read(stringsProvider);
    String label;
    Color bg;
    Color fg;
    IconData icon;

    if (isPassed) {
      final actual = stop.actualArrivalTime;
      final scheduled = stop.scheduledTime;
      if (actual != null && scheduled != null) {
        final delay = _computeDelay(actual, scheduled);
        if (delay <= 0) {
          label = '${strings.get('reached')} · ${strings.get('on_time')}';
          bg = const Color(0xFFE8F5E9);
          fg = const Color(0xFF2E7D32);
          icon = Icons.check_circle_outline;
        } else {
          label = '${strings.get('reached')} · $delay ${strings.get('min_late')}';
          bg = const Color(0xFFFFF3E0);
          fg = const Color(0xFFE65100);
          icon = Icons.schedule;
        }
      } else {
        label = strings.get('reached');
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.check_circle_outline;
      }
    } else if (isAtStop || stop.type == StopType.currentLocation) {
      // Explicitly check for both local state isAtStop and model state StopType.currentLocation
      if (stop.delayMinutes > 0) {
        label = '${strings.get('arrived')} · ${stop.delayMinutes} ${strings.get('min_late')}';
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        icon = Icons.sports_score;
      } else {
        label = '${strings.get('arrived')} · ${strings.get('on_time')}';
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        icon = Icons.sports_score;
      }
    } else if (isTransitApproaching || stop.type == StopType.nextStop) {
      label = strings.get('bus_approaching');
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
      icon = Icons.directions_bus;
    } else {
      if (stop.estimatedArrivalMinutes != null && stop.estimatedArrivalMinutes! > 0) {
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
        label = strings.get('upcoming');
        bg = Colors.grey[100] ?? const Color(0xFFF5F5F5);
        fg = Colors.grey[600] ?? const Color(0xFF757575);
        icon = Icons.radio_button_unchecked;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: fg), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600))]),
    );
  }

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

  Widget _buildLanguageToggleChip(AppLanguage currentLang) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          value: currentLang,
          dropdownColor: AppColors.deepBlue,
          icon: const Icon(Icons.language, color: Colors.white, size: 16),
          onChanged: (AppLanguage? newLang) {
            if (newLang != null) ref.read(languageProvider.notifier).setLanguage(newLang);
          },
          items: const [
            DropdownMenuItem(value: AppLanguage.english, child: Text('Eng', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
            DropdownMenuItem(value: AppLanguage.telugu, child: Text('తెలుగు', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    final strings = ref.watch(stringsProvider);
    return TextButton(
      onPressed: () => _showCancelTripModal(context),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.95),
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(strings.get('cancel_trip'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.redAccent)),
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: iconColor, size: 24), const SizedBox(width: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))]), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500))]),
        ),
      ),
    );
  }

  Widget _buildRouteTimeline() {
    final busState = ref.watch(busTrackingProvider);
    final outerContext = context;
    final strings = ref.read(stringsProvider);

    return busState.when(
      initial: () => const Center(child: CircularProgressIndicator()),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                '${strings.get('error')}: $message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final user = ref.read(authProvider).user;
                  if (user?.busNumber != null) {
                    ref.read(busTrackingProvider.notifier).loadBusRoute(user!.busNumber!);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: Text(strings.get('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.deepBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      loaded: (busRoute) {
        // Use the server's direction if trip is active, otherwise fallback to widget/local flag
        final bool currentIsReverse = busRoute.isTripActive ? busRoute.isReverse : _isReverseTrip;
        final stopsData = busRoute.stops;
        final bool isInTransit = busRoute.transitFromStopIndex >= 0;
        final int transitFrom = busRoute.transitFromStopIndex;
        final double transitProg = busRoute.transitProgress;

        // Update transit prev tracking synchronously (no setState/postFrameCallback
        // to avoid cascading rebuild loops that cause flickering).
        if (transitProg > 0) {
          final displayProg = currentIsReverse ? (1.0 - transitProg) : transitProg;
          _updateTransitPrev(transitFrom, displayProg);
        }

        int? atStopIndex;
        if (!isInTransit) {
          for (int i = 0; i < stopsData.length; i++) {
            if (stopsData[i].type == StopType.currentLocation) {
              atStopIndex = i;
              break;
            }
          }
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
            final int originalIndex = currentIsReverse ? (stopsData.length - 1 - index) : index;
            final isLast = index == stopsData.length - 1;
            final isPassed = stop.type == StopType.passedStop;
            final isSkipped = stop.type == StopType.skippedStop;
            final isAtStop = !isInTransit && index == atStopIndex;
            
            // Note: server's transitFromStopIndex is in original list order.
            // We need to compare display index with a correctly mapped transitFrom index.
            // Let's re-calculate transitFrom for display index:
            // If forward: bus is between index and index+1 -> display index matches transitFrom.
            // If reverse: bus is between index and index+1 in stopsData (e.g. Stop 4 and 3)
            // -> Stop 4 was transitFrom (index 4). Its display index is 0.
            final int displayTransitFrom = currentIsReverse 
                ? (stopsData.length - 1 - transitFrom) 
                : transitFrom;
            
            final bool isTransitBelowThis = isInTransit && (index == displayTransitFrom);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        if (isAtStop)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1.05),
                            duration: const Duration(seconds: 1),
                            builder: (context, value, child) => Transform.scale(scale: value, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(width: 28, height: 44, child: Image.asset('assets/icons/tracker.png', fit: BoxFit.contain)))),
                          )
                        else if (isPassed || (isInTransit && index <= displayTransitFrom))
                          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 16))
                        else if (isSkipped)
                          Container(width: 26, height: 26, decoration: const BoxDecoration(color: Color(0xFFEF5350), shape: BoxShape.circle), child: const Center(child: Text('!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))
                        else
                          Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400 ?? Colors.grey, width: 2))),
                        if (!isLast)
                          Expanded(
                            child: isTransitBelowThis
                                ? TweenAnimationBuilder<double>(
                                    key: ValueKey<int>(transitFrom),
                                    tween: Tween<double>(
                                      begin: _prevTransitProg,
                                      end: (currentIsReverse ? (1.0 - transitProg) : transitProg).clamp(0.03, 0.97)
                                    ),
                                    duration: const Duration(milliseconds: 2500),
                                    curve: Curves.linear,
                                    builder: (context, animProg, _) {
                                      return SizedBox(
                                        width: 40,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.center,
                                          children: [
                                            // Progress Line
                                            Column(children: [
                                              Expanded(flex: (animProg * 100).round().clamp(1, 99), child: Container(width: 8, color: AppColors.navigationBlue)),
                                              Expanded(flex: ((1 - animProg) * 100).round().clamp(1, 99), child: Container(width: 4, color: const Color(0xFFE0E0E0))),
                                            ]),
                                            // Animated Bus Icon
                                            Positioned.fill(
                                              child: Align(
                                                alignment: Alignment(0, -1.0 + (animProg * 2.0)),
                                                child: FractionalTranslation(
                                                  translation: const Offset(0, -0.5),
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
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: isPassed ? 4 : 8, 
                                    margin: const EdgeInsets.symmetric(vertical: 4), 
                                    decoration: BoxDecoration(
                                      color: isInTransit 
                                          ? (index < displayTransitFrom ? AppColors.navigationBlue : const Color(0xFFE0E0E0)) 
                                          : (atStopIndex != null && index < atStopIndex ? AppColors.navigationBlue : const Color(0xFFE0E0E0)), 
                                      borderRadius: BorderRadius.circular(2)
                                    )
                                  ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(stop.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                          if (stop.scheduledTime != null) Padding(padding: const EdgeInsets.only(left: 8.0), child: Text(stop.scheduledTime ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
                        ]),
                        const SizedBox(height: 6),
                        _buildStopStatusChip(
                          stop: stop, 
                          isPassed: isPassed, 
                          isAtStop: isAtStop, 
                          isTransitApproaching: isInTransit && (index == displayTransitFrom + 1)
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          if (isAtStop || (!isPassed && !isSkipped && !isTransitBelowThis)) ...[
                            ElevatedButton(onPressed: () => _showSkipStopModal(context, stop.name), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200 ?? Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(strings.get('skip_stop'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          OutlinedButton(onPressed: () => _showAttendanceModal(outerContext, stop.name), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brightOrange, width: 1.5), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(strings.get('mark_attendance'), style: const TextStyle(color: AppColors.brightOrange, fontWeight: FontWeight.bold, fontSize: 13))),
                        ]),
                        const SizedBox(height: 24),
                        if (!isLast) Divider(color: Colors.grey.shade200 ?? Colors.grey.shade200, thickness: 1, height: 1),
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
    final strings = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(builder: (modalContext, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(strings.get('skip_stop'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 12),
                Text(strings.get('skip_stop_hint'), style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                const SizedBox(height: 24),
                _buildReasonItem(strings.get('reason_no_student'), _selectedSkipReason == 'No Student at this Stop', () => setModalState(() => _selectedSkipReason = 'No Student at this Stop')),
                _buildReasonItem(strings.get('reason_road_accident'), _selectedSkipReason == 'Road Accident / Blockage', () => setModalState(() => _selectedSkipReason = 'Road Accident / Blockage')),
                _buildReasonItem(strings.get('reason_traffic'), _selectedSkipReason == 'Traffic Congestion', () => setModalState(() => _selectedSkipReason = 'Traffic Congestion')),
                _buildReasonItem(strings.get('reason_weather'), _selectedSkipReason == 'Weather Conditions', () => setModalState(() => _selectedSkipReason = 'Weather Conditions')),
                _buildReasonItem(strings.get('reason_emergency'), _selectedSkipReason == 'Emergency Situation', () => setModalState(() => _selectedSkipReason = 'Emergency Situation')),
                _buildReasonItem(strings.get('reason_other'), _selectedSkipReason == 'Other (Specify)', () => setModalState(() => _selectedSkipReason = 'Other (Specify)')),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(modalContext), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brightOrange), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(strings.get('close'), style: const TextStyle(color: AppColors.brightOrange, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: _selectedSkipReason == null ? null : () {
                    _socketService.skipStop(busId: _busId, stopName: stopName, reason: _selectedSkipReason ?? 'Manual Skip');
                    ref.read(busTrackingProvider.notifier).markStopSkipped(stopName);
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stop "$stopName" skipped successfully'), backgroundColor: Colors.orange));
                  }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text(strings.get('skip_stop'), style: const TextStyle(fontWeight: FontWeight.bold)))),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCancelTripModal(BuildContext context) {
    final strings = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(builder: (modalContext, setModalState) {
          bool isCancelling = false;
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(strings.get('cancel_trip'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 12),
                Text(strings.get('cancel_trip_hint'), style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                const SizedBox(height: 24),
                _buildReasonItem(strings.get('reason_breakdown'), _selectedCancelReason == 'Vehicle Breakdown', () => setModalState(() => _selectedCancelReason = 'Vehicle Breakdown')),
                _buildReasonItem(strings.get('reason_medical'), _selectedCancelReason == 'Driver Medical Emergency', () => setModalState(() => _selectedCancelReason = 'Driver Medical Emergency')),
                _buildReasonItem(strings.get('reason_weather'), _selectedCancelReason == 'Severe Weather Conditions', () => setModalState(() => _selectedCancelReason = 'Severe Weather Conditions')),
                _buildReasonItem(strings.get('reason_road_accident'), _selectedCancelReason == 'Road Accident / Blockage', () => setModalState(() => _selectedCancelReason = 'Road Accident / Blockage')),
                _buildReasonItem(strings.get('reason_mechanical'), _selectedCancelReason == 'Fuel / Mechanical Issue', () => setModalState(() => _selectedCancelReason = 'Fuel / Mechanical Issue')),
                _buildReasonItem(strings.get('reason_other'), _selectedCancelReason == 'Other (Specify)', () => setModalState(() => _selectedCancelReason = 'Other (Specify)')),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(modalContext), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brightOrange), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(strings.get('close'), style: const TextStyle(color: AppColors.brightOrange, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: (_selectedCancelReason == null || isCancelling) ? null : () {
                    setModalState(() => isCancelling = true);
                    _socketService.on('trip_cancelled', (data) {
                      _socketService.off('trip_cancelled');
                      if (context.mounted) {
                        _stopTracking();
                        ref.read(busTrackingProvider.notifier).clearActiveTrip();
                        ref.read(busTrackingProvider.notifier).loadBusRoute(_busId);
                        context.go(AppRouter.routeSelection);
                        Navigator.pop(modalContext);
                      }
                    });
                    Future.delayed(const Duration(seconds: 3), () {
                      if (isCancelling && context.mounted) {
                        _socketService.off('trip_cancelled');
                        _stopTracking();
                        ref.read(busTrackingProvider.notifier).clearActiveTrip();
                        ref.read(busTrackingProvider.notifier).loadBusRoute(_busId);
                        context.go(AppRouter.routeSelection);
                        Navigator.pop(modalContext);
                      }
                    });
                    _socketService.cancelTrip(_busId, _selectedCancelReason ?? 'Manual Cancellation');
                  }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: isCancelling ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(strings.get('cancel_trip'), style: const TextStyle(fontWeight: FontWeight.bold)))),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  void _showStudentListModal(BuildContext context, String title, List<Map<String, dynamic>> students) {
    final strings = ref.read(stringsProvider);
    String searchQuery = '';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (context, setModalState) {
      final filteredStudents = students.where((s) {
        final name = (s['name'] as String? ?? '').toLowerCase();
        final stop = (s['pickupStop'] as String? ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || stop.contains(query);
      }).toList();
      return Container(height: MediaQuery.of(context).size.height * 0.85, decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text('${strings.get('active_trip')} • ${students.length} ${strings.get('total')}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey.shade200 ?? Colors.grey.shade200, shape: BoxShape.circle), child: const Icon(Icons.close, size: 20, color: Colors.grey))),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200 ?? Colors.grey.shade200)), child: TextField(onChanged: (value) => setModalState(() => searchQuery = value), decoration: InputDecoration(hintText: strings.get('search_student_hint'), hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14), icon: Icon(Icons.search, color: Colors.grey.shade400, size: 20), border: InputBorder.none)))),
        const SizedBox(height: 20),
        Expanded(child: filteredStudents.isEmpty ? _buildEmptyStudentState(searchQuery.isNotEmpty) : ListView.builder(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), itemCount: filteredStudents.length, itemBuilder: (context, index) {
          final student = filteredStudents[index];
          final isBoarded = student['isBoarded'] ?? false;
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100] ?? Colors.grey.shade100)), child: Row(children: [
            Stack(children: [
              CircleAvatar(radius: 24, backgroundColor: AppColors.deepBlue.withOpacity(0.1), child: Text((student['name'] as String? ?? 'S')[0].toUpperCase(), style: const TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.bold, fontSize: 18))),
              Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: isBoarded ? Colors.green : Colors.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.location_on, size: 12, color: Colors.grey.shade400), const SizedBox(width: 4), Text(student['pickupStop'] ?? 'No stop', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))]),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isBoarded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(isBoarded ? strings.get('boarded').toUpperCase() : strings.get('pending').toUpperCase(), style: TextStyle(color: isBoarded ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
          ]));
        })),
      ]));
    }));
  }

  Widget _buildEmptyStudentState(bool isSearch) {
    final strings = ref.read(stringsProvider);
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(isSearch ? Icons.search_off : Icons.people_outline, size: 48, color: Colors.grey.shade400)),
      const SizedBox(height: 24),
      Text(isSearch ? strings.get('no_results') : strings.get('no_students'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 48), child: Text(isSearch ? strings.get('search_no_results_hint') : strings.get('no_students_hint'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5))),
    ]));
  }

  Widget _buildReasonItem(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: isSelected ? AppColors.lightYellow : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.primaryYellow.withOpacity(0.6) : Colors.transparent, width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? AppColors.deepBlue : Colors.black87)), Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.deepBlue : (Colors.grey.shade400 ?? Colors.grey), width: isSelected ? 6 : 2), color: Colors.white))])));
  }

  void _showAttendanceModal(BuildContext context, String stopName) async {
    final strings = ref.read(stringsProvider);
    final currentState = ref.read(busTrackingProvider);
    final stop = currentState.maybeWhen(loaded: (route) { try { return route.stops.firstWhere((s) => s.name == stopName); } catch (_) { return null; } }, orElse: () => null);
    if (stop != null) {
      final currentPos = _lastPosition ?? await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final distance = Geolocator.distanceBetween(currentPos.latitude, currentPos.longitude, stop.latitude, stop.longitude);
      if (distance > 200 && context.mounted) UIHelpers.showWarningTooltip(context, '${strings.get('warning')}: ${strings.get('far_from_stop').replaceAll('{distance}', UIHelpers.formatDistance(distance / 1000)).replaceAll('{stop}', stopName)}');
    }
    if (!mounted) return;
    setState(() { _isLoadingStudents = true; _currentStopStudents = []; });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(busTrackingProvider.notifier).fetchStudentsForStop(_busId, stopName, onData: (students) {
        if (mounted) { setState(() { _currentStopStudents = List<Map<String, dynamic>>.from(students); _isLoadingStudents = false; }); _modalSetter?.call(() {}); }
      });
    });
    if (!context.mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (modalContext) {
      return StatefulBuilder(builder: (modalContext, setModalState) {
        _modalSetter = setModalState;
        return Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(strings.get('attendance'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            OutlinedButton.icon(onPressed: () async {
              final result = await context.push<QrScanResult>(AppRouter.attendanceQrScanner);
              if (result != null && mounted) {
                setModalState(() {
                  final alreadyExists = _currentStopStudents.any((s) => s['id'] == result.studentId);
                  if (!alreadyExists) _currentStopStudents.add({'id': result.studentId, 'name': result.studentName, 'stopName': stopName, 'profilePictureUrl': null});
                  _selectedStudents.add(result.studentId);
                });
                ref.read(busTrackingProvider.notifier).markStudentAsBoarded({'id': result.studentId, 'name': result.studentName, 'stopName': stopName});
                _socketService.markAttendance(busId: _busId, stopName: stopName, studentIds: _selectedStudents.toList());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 18), const SizedBox(width: 8), Text('${result.studentName} ${strings.get('added_to_attendance')}')]), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 2)));
              }
            }, icon: const Icon(Icons.qr_code_scanner, size: 18), label: Text(strings.get('scan_qr')), style: OutlinedButton.styleFrom(foregroundColor: AppColors.brightOrange, side: const BorderSide(color: AppColors.brightOrange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
          ]),
          const SizedBox(height: 16),
          Row(children: [Icon(Icons.people, color: AppColors.deepBlue, size: 20), const SizedBox(width: 8), Text('${_currentStopStudents.length} ${strings.get('students')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.deepBlue))]),
          const SizedBox(height: 20),
          ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5), child: _isLoadingStudents ? const Center(child: CircularProgressIndicator()) : _currentStopStudents.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(strings.get('no_students_at_stop')))) : SingleChildScrollView(child: Column(children: _currentStopStudents.map((student) {
            final isSelected = _selectedStudents.contains(student['id']);
            return _buildStudentItem(student['name'] ?? 'Unknown', student['id'] ?? '', isSelected, () => setModalState(() { if (isSelected) { _selectedStudents.remove(student['id']); } else if (student['id'] != null) { _selectedStudents.add(student['id']!); } }), profilePictureUrl: student['profilePictureUrl']);
          }).toList()))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
            _socketService.markAttendance(busId: _busId, stopName: stopName, studentIds: _selectedStudents.where((id) => _currentStopStudents.any((s) => s['id'] == id)).toList());
            final boardedStudentIds = _selectedStudents.where((id) => _currentStopStudents.any((s) => s['id'] == id)).toList();
            ref.read(busTrackingProvider.notifier).markStopReached(stopName, boardedCount: boardedStudentIds.length, boardedStudentIds: boardedStudentIds);
            Navigator.pop(modalContext);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${strings.get('attendance_marked_at')} $stopName'), backgroundColor: AppColors.brightOrange));
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.brightOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text(strings.get('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 16),
        ]));
      });
    });
  }

  Widget _buildStudentItem(String name, String id, bool isSelected, VoidCallback onTap, {String? profilePictureUrl}) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isSelected ? AppColors.lightYellow : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.primaryYellow.withOpacity(0.6) : Colors.transparent, width: 1.5)), child: Row(children: [
      CircleAvatar(radius: 24, backgroundColor: isSelected ? AppColors.primaryYellow.withOpacity(0.3) : AppColors.lightBlue, backgroundImage: (profilePictureUrl != null && profilePictureUrl.isNotEmpty) ? NetworkImage(profilePictureUrl) : null, child: (profilePictureUrl == null || profilePictureUrl.isEmpty) ? Text(_getInitials(name), style: const TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.bold, fontSize: 14)) : null),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 2), Text('ID: $id', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))])),
      Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.deepBlue : Colors.grey.shade400, width: isSelected ? 6 : 2), color: Colors.white)),
    ])));
  }

  void _beginReverseTrip() {
    _stopTracking();
    setState(() { _isReverseTrip = true; _totalDistanceKm = 0.0; _lastPosition = null; _prevTransitProg = 0.03; _prevTransitFrom = -1; });
    ref.read(busTrackingProvider.notifier).loadBusRoute(_busId);
    _startTracking();
  }

  void _showTripCompletedModal(BuildContext context, BusRoute busRoute) {
    final strings = ref.read(stringsProvider);
    final totalStops = busRoute.stops.length;
    final completedStops = busRoute.stops.where((s) => s.type == StopType.passedStop).length;
    final skippedStops = busRoute.stops.where((s) => s.type == StopType.skippedStop).length;
    final totalStudents = busRoute.stops.fold(0, (sum, s) => sum + (s.studentCount ?? 0));
    final onboardedStudents = busRoute.stops.fold(0, (sum, s) => sum + (s.boardedStudentCount ?? 0));
    final absentStudents = totalStudents - onboardedStudents;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
      bool isCheckingLocation = false;
      return StatefulBuilder(builder: (context, setModalState) {
        return Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 24),
        Row(children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.primaryYellow.withOpacity(0.15), shape: BoxShape.circle), child: Icon(Icons.check_circle, color: AppColors.deepBlue, size: 32)),
          const SizedBox(width: 12),
          Text(strings.get('trip_completed'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.deepBlue)),
        ]),
        const SizedBox(height: 16),
        Text(strings.get('trip_completed_hint'), style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.lightYellow, borderRadius: BorderRadius.circular(16)), child: Column(children: [
          _buildSummaryRow(strings.get('total_stops'), '$totalStops', isHeader: true),
          const SizedBox(height: 12),
          _buildSummaryRow(strings.get('completed'), '$completedStops'),
          const SizedBox(height: 8),
          _buildSummaryRow(strings.get('skipped'), '$skippedStops'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.lightBlue)),
          _buildSummaryRow(strings.get('total_students'), '$totalStudents', isHeader: true),
          const SizedBox(height: 12),
          _buildSummaryRow(strings.get('onboarded'), '$onboardedStudents'),
          const SizedBox(height: 8),
          _buildSummaryRow(strings.get('absent'), '$absentStudents'),
        ])),
        const SizedBox(height: 24),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(context); _showReviewModal(context); }, style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brightOrange), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(strings.get('review_trip'), style: const TextStyle(color: AppColors.brightOrange, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 16),
          Expanded(child: ElevatedButton(onPressed: isCheckingLocation ? null : () async {
            setModalState(() => isCheckingLocation = true);
            try {
              // Get current position with timeout
              final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10),
              );
              
              // Determine destination based on trip direction
              if (busRoute.stops.isEmpty) {
                setModalState(() => isCheckingLocation = false);
                return;
              }
              final destination = busRoute.stops.last;
              
              final distanceM = Geolocator.distanceBetween(
                pos.latitude, pos.longitude,
                destination.latitude, destination.longitude
              );
              
              if (distanceM > 1000) {
                if (mounted) {
                  final kms = (distanceM / 1000).floor();
                  final meters = (distanceM % 1000).round();
                  final distStr = kms > 0 ? '${kms}km ${meters}m' : '${meters}m';
                  
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 10),
                          const Text('Too Far to End', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Text(
                        strings.get('too_far_to_end').replaceAll('{dist}', distStr),
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  );
                }
                setModalState(() => isCheckingLocation = false);
                return;
              }

              if (!mounted) return;
              Navigator.pop(context);
              final now = DateTime.now();
              final start = _startTime;
              final duration = start != null ? now.difference(start) : Duration.zero;
              
              final summary = TripSummary(
                duration: duration, 
                distanceKm: _totalDistanceKm, 
                busId: _busId, 
                endTime: now, 
                driverLat: pos.latitude, 
                driverLng: pos.longitude,
                routeId: widget.routeId,
                routeName: widget.routeName,
                isReverse: _isReverseTrip,
              );
              context.push(AppRouter.endTripSummary, extra: summary);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not verify location: $e'), backgroundColor: Colors.red),
                );
              }
              setModalState(() => isCheckingLocation = false);
            }
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.brightOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: isCheckingLocation 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(strings.get('end_trip'), style: const TextStyle(fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(height: 16),
      ]));
      });
    });
  }

  void _showReviewModal(BuildContext context) {
    final strings = ref.read(stringsProvider);
    final queryController = TextEditingController();
    final user = ref.read(authProvider).user;
    showDialog(context: context, builder: (BuildContext context) {
      return Consumer(builder: (context, ref, child) {
        final supportState = ref.watch(supportProvider);
        final isLoading = supportState.maybeWhen(loading: () => true, orElse: () => false);
        return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Text(strings.get('trip_review'), style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 20)), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(strings.get('trip_review_hint'), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          TextField(controller: queryController, maxLines: 4, style: const TextStyle(fontSize: 14), decoration: InputDecoration(hintText: strings.get('feedback_hint'), hintStyle: const TextStyle(fontSize: 13), fillColor: const Color(0xFFF8FAFC), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brightOrange, width: 1.5)))),
        ]), actions: [
          TextButton(onPressed: isLoading ? null : () => Navigator.of(context).pop(), child: Text(strings.get('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
          ElevatedButton(onPressed: isLoading ? null : () async {
            if (queryController.text.trim().isEmpty) { UIHelpers.showErrorTooltip(context, strings.get('enter_review_error')); return; }
            await ref.read(supportProvider.notifier).sendQuery(query: queryController.text.trim(), subject: 'Trip Review - ${_busId}', email: user?.email);
            if (context.mounted) {
              final newState = ref.read(supportProvider);
              newState.whenOrNull(success: () { Navigator.of(context).pop(); UIHelpers.showSuccessTooltip(context, strings.get('review_success')); }, error: (message) { UIHelpers.showErrorTooltip(context, message); });
            }
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.brightOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), child: isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text(strings.get('submit'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ]);
      });
    });
  }

  Widget _buildSummaryRow(String label, String value, {bool isHeader = false}) {
    return Padding(padding: EdgeInsets.symmetric(vertical: isHeader ? 4 : 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: isHeader ? 14 : 13, fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, color: isHeader ? AppColors.deepBlue : Colors.grey[700])), Text(value, style: TextStyle(fontSize: isHeader ? 14 : 13, fontWeight: FontWeight.bold, color: isHeader ? AppColors.deepBlue : Colors.black87))]));
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Widget _buildMap(BusRoute? busRoute) {
    if (busRoute == null) return const Center(child: CircularProgressIndicator());
    
    final busPos = busRoute.busPosition;
    final initialCameraPosition = CameraPosition(
      target: LatLng(busPos.latitude, busPos.longitude),
      zoom: 15,
    );

    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      onMapCreated: (controller) {
        _mapController = controller;
        controller.setMapStyle(MapsService.cleanMapStyle);
      },
      markers: _buildMarkers(busRoute),
      polylines: _buildPolylines(busRoute),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Set<Marker> _buildMarkers(BusRoute busRoute) {
    final markers = <Marker>{};
    
    // Bus Marker
    markers.add(
      Marker(
        markerId: const MarkerId('driver_bus'),
        position: LatLng(busRoute.busPosition.latitude, busRoute.busPosition.longitude),
        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        rotation: busRoute.busPosition.bearing,
        anchor: const Offset(0.5, 0.5),
        zIndex: 10,
      ),
    );

    // Stop Markers
    for (var stop in busRoute.stops) {
      double hue;
      switch (stop.type) {
        case StopType.passedStop:
          hue = BitmapDescriptor.hueGreen;
        case StopType.currentLocation:
          hue = BitmapDescriptor.hueYellow;
        case StopType.nextStop:
          hue = BitmapDescriptor.hueOrange;
        default:
          hue = BitmapDescriptor.hueBlue;
      }

      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.name}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: stop.name),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(BusRoute busRoute) {
    final polylines = <Polyline>{};
    List<LatLng> points;

    if (busRoute.routePath.isNotEmpty) {
      points = busRoute.routePath.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } else {
      points = busRoute.stops.map((s) => LatLng(s.latitude, s.longitude)).toList();
    }


    if (points.isEmpty) return polylines;

    // Find the closest route-path index to the bus current position
    final busLat = busRoute.busPosition.latitude;
    final busLng = busRoute.busPosition.longitude;

    int splitIndex = 0;
    double minDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final dLat = points[i].latitude - busLat;
      final dLng = points[i].longitude - busLng;
      final dist = dLat * dLat + dLng * dLng;
      if (dist < minDist) {
        minDist = dist;
        splitIndex = i;
      }
    }

    // Passed segment: start → bus position (gray)
    final passedPoints = [
      ...points.sublist(0, splitIndex + 1),
      LatLng(busLat, busLng),
    ];
    // Remaining segment: bus position → end (blue)
    final aheadPoints = [
      LatLng(busLat, busLng),
      ...points.sublist(splitIndex + 1),
    ];

    // Gray polyline for the finished segment
    if (passedPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_route_passed'),
          points: passedPoints,
          color: const Color(0xFFE0E0E0), // Neutral gray
          width: 6,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      );
    }

    // Blue polyline for the upcoming route
    if (aheadPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_route_ahead'),
          points: aheadPoints,
          color: AppColors.navigationBlue,
          width: 8,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      );
    }

    return polylines;
  }
}
