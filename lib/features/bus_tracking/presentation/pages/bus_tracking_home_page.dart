import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/routes/app_router.dart';
import '../../domain/entities/bus_route.dart';
import '../../../../core/utils/ui_helpers.dart';
import 'dart:convert';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/bus_tracking_provider.dart';
import '../../../../core/services/notification_service.dart';

class BusTrackingHomePage extends ConsumerStatefulWidget {
  final String? busNumber;
  final String? studentName;
  final bool? isReverse;
  final String? routeId;
  const BusTrackingHomePage({
    super.key,
    this.busNumber,
    this.studentName,
    this.isReverse,
    this.routeId,
  });

  @override
  ConsumerState<BusTrackingHomePage> createState() =>
      _BusTrackingHomePageState();
}

class _BusTrackingHomePageState extends ConsumerState<BusTrackingHomePage> {
  GoogleMapController? _mapController;
  String selectedBus = 'Bus No. 10';
  bool isMapView = true; // Toggle between map and route list view
  bool isGPSTracking = true; // Toggle between GPS and Mobile Network tracking
  bool _isFollowingBus = true; // Auto-follow bus location
  OverlayEntry? _notificationOverlay;
  final Map<String, dynamic> _selectedAlarms = {};
  final Set<String> _triggeredAlarms = {}; // To avoid double triggering
  BitmapDescriptor? _busIcon;

  // ── Incremental transit progress tracking ─────────────────────────────────
  // Stores the PREVIOUS GPS progress value per segment so each GPS update
  // animates FROM the last position (not from 0) — giving 4+ visible steps.
  double _prevTransitProg = 0.03;
  int _prevTransitFrom = -1;

  void _updateTransitPrev(int fromIdx, double prog) {
    if (!mounted) return;
    if (fromIdx != _prevTransitFrom) {
      // New segment: reset to beginning
      _prevTransitFrom = fromIdx;
      _prevTransitProg = 0.03;
    } else if (prog > _prevTransitProg) {
      // Only advance — never go backward
      _prevTransitProg = prog.clamp(0.03, 0.97);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _loadAlarms();
    final user = ref.read(authProvider).user;

    if (widget.busNumber != null) {
      selectedBus = widget.busNumber!;
    } else if (user?.busNumber != null) {
      selectedBus = user!.busNumber!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(busTrackingProvider.notifier).startTracking(
        selectedBus,
        initialIsReverse: widget.isReverse,
        routeId: widget.routeId,
      );
    });
  }

  Future<void> _loadCustomMarker() async {
    try {
      print('DEBUG: [BusTrackingHomePage] Loading custom bus marker icon...');
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(24, 32)),
        'assets/icons/tracker.png',
      );
      if (mounted) {
        setState(() {
          _busIcon = icon;
        });
        print(
          'DEBUG: [BusTrackingHomePage] Custom bus marker loaded successfully',
        );
      }
    } catch (e) {
      print('DEBUG: [BusTrackingHomePage] Error loading custom marker: $e');
      // Fallback is handled by using null _busIcon in _buildMarkers
    }
  }

  @override
  void dispose() {
    _notificationOverlay?.remove();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? alarmsJson = prefs.getString('stop_alarms');
      if (alarmsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(alarmsJson);
        if (mounted) {
          setState(() {
            _selectedAlarms.clear();
            _selectedAlarms.addAll(decoded);
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error loading alarms: $e');
    }
  }

  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stop_alarms', jsonEncode(_selectedAlarms));
    } catch (e) {
      print('DEBUG: Error saving alarms: $e');
    }
  }

  void _centerToUser() async {
    setState(() {
      _isFollowingBus = false;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showTopNotification('Location permissions are denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16, // Better zoom for user
        ),
      );
    } catch (e) {
      _showTopNotification('Could not get your location');
    }
  }

  void _centerToBus(BusRoute busRoute) {
    setState(() {
      _isFollowingBus = true;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(busRoute.busPosition.latitude, busRoute.busPosition.longitude),
        16, // Better zoom for bus
      ),
    );

    // Also manually fetch the latest location data from the server
    final busNo = widget.busNumber ?? '10';
    ref.read(busTrackingProvider.notifier).loadBusRoute(busNo);
    _showTopNotification('Refreshing bus location...');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _callDriver(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Set<Marker> _buildMarkers(BusRoute busRoute) {
    final markers = <Marker>{};

    // Add markers for all stops
    for (var stop in busRoute.stops) {
      double hue;
      switch (stop.type) {
        case StopType.passedStop:
          hue = BitmapDescriptor.hueGreen;
        case StopType.currentLocation:
          hue = BitmapDescriptor.hueYellow;
        case StopType.nextStop:
          hue = BitmapDescriptor.hueOrange;
        case StopType.futureStop:
          hue = BitmapDescriptor.hueRed;
        case StopType.skippedStop:
          hue = BitmapDescriptor.hueViolet;
      }

      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.name}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () =>
              _openDirections(stop.latitude, stop.longitude, stop.name),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: stop.estimatedArrivalMinutes != null
                ? 'ETA: ${stop.estimatedArrivalMinutes} min'
                : null,
          ),
        ),
      );
    }

    // Bus position marker (animated rotation)
    markers.add(
      Marker(
        markerId: const MarkerId('bus_position'),
        position: LatLng(
          busRoute.busPosition.latitude,
          busRoute.busPosition.longitude,
        ),
        rotation: busRoute.busPosition.bearing,
        anchor: const Offset(0.5, 0.5),
        flat: true, // Make it follow map rotation smoothly
        icon:
            _busIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () => _openDirections(
          busRoute.busPosition.latitude,
          busRoute.busPosition.longitude,
          'Bus ${busRoute.busNumber}',
        ),
        infoWindow: InfoWindow(
          title: 'Bus: ${busRoute.busNumber}',
          snippet: 'Current Position',
        ),
        zIndex: 2, // Keep bus on top
      ),
    );

    return markers;
  }

  Future<void> _openDirections(
    double lat,
    double lng,
    String destinationName,
  ) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showTopNotification('Could not launch directions');
    }
  }

  Set<Polyline> _buildPolylines(BusRoute busRoute) {
    List<LatLng> points;

    if (busRoute.routePath.isNotEmpty) {
      points = busRoute.routePath
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      // Fallback: use stops when explicit path is missing
      points = busRoute.stops
          .map((stop) => LatLng(stop.latitude, stop.longitude))
          .toList();
    }

    if (busRoute.isReverse) {
      points = points.reversed.toList();
    }

    if (points.isEmpty) return {};

    final polylines = <Polyline>{};

    if (!busRoute.isTripActive) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('bus_route_inactive'),
          points: points,
          color: Colors.grey[400]!,
          width: 8,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      );
      return polylines;
    }

    // ── Find the closest route-path index to the bus current position ──────
    final busLat = busRoute.busPosition.latitude;
    final busLng = busRoute.busPosition.longitude;

    int splitIndex = 0;
    double minDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final dLat = points[i].latitude - busLat;
      final dLng = points[i].longitude - busLng;
      final dist =
          dLat * dLat + dLng * dLng; // No need for sqrt — comparing only
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

    // Gray polyline for the already-traveled portion (Finished segment)
    if (passedPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('bus_route_passed'),
          points: passedPoints,
          color: const Color(0xFFE0E0E0), // Neutral gray for passed
          width: 6,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      );
    }

    // Blue polyline for the remaining route ahead
    if (aheadPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('bus_route_ahead'),
          points: aheadPoints,
          color: AppColors.navigationBlue, // Vibrant blue for upcoming
          width: 8,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      );
    }

    // Fallback: if somehow both segments are collapsed, draw full route in blue
    if (polylines.isEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('bus_route'),
          points: points,
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

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(busTrackingProvider);

    // Listen to tracking state: update map camera AND drive transit animation
    ref.listen(busTrackingProvider, (previous, next) {
      // ── Trip Completion Detection ──
      // If trip was active and is now inactive, show summary and go back
      final bool wasActive = previous?.maybeWhen(
            loaded: (r) => r.isTripActive,
            orElse: () => false,
          ) ??
          false;
      final bool isNowInactive = next.maybeWhen(
        loaded: (r) => !r.isTripActive,
        orElse: () => false,
      );

      if (wasActive && isNowInactive && mounted) {
        _showTripCompletedDialog();
      }

      next.maybeWhen(
        loaded: (busRoute) {
          if (mounted) {
            _checkAlarms(busRoute);
            // Track previous progress so animation plays FROM last position
            if (busRoute.transitProgress > 0) {
              setState(() {
                _updateTransitPrev(
                  busRoute.transitFromStopIndex,
                  busRoute.transitProgress,
                );
              });
            }
            if (_mapController != null && isMapView && _isFollowingBus) {
              try {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      busRoute.busPosition.latitude,
                      busRoute.busPosition.longitude,
                    ),
                  ),
                );
              } catch (e) {
                print('DEBUG: Map controller error (possibly disposed): $e');
              }
            }
          }
        },
        orElse: () {},
      );
    });

    return Scaffold(
      body: trackingState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final busNo = widget.busNumber ?? '10';
                    ref.read(busTrackingProvider.notifier).loadBusRoute(busNo);
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        loaded: (busRoute) => isMapView
            ? Stack(
                children: [
                  // Map View
                  _buildMapView(busRoute),

                  // Map controls
                  Positioned(
                    right: 16,
                    bottom: 220, // Above the bottom card
                    child: Column(
                      children: [
                        // Re-center/Refresh on bus button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FloatingActionButton.small(
                            onPressed: () => _centerToBus(busRoute),
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.brightOrange,
                            elevation: 0,
                            heroTag: 'refresh_bus',
                            child: const Icon(Icons.refresh),
                          ),
                        ),

                        // Re-center to user location button
                        FloatingActionButton.small(
                          onPressed: _centerToUser,
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.deepBlue,
                          elevation: 0,
                          heroTag: 'center_user',
                          child: const Icon(Icons.my_location),
                        ),
                      ],
                    ),
                  ),

                  // Top Bar
                  _buildTopBar(),

                  // Bottom Info Card
                  _buildBottomCard(busRoute),
                ],
              )
            : SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Top Bar content (without SafeArea wrapper)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            16.0,
                            16.0,
                            0.0,
                          ),
                          child: _buildTopBarContent(),
                        ),

                        // Route List View (scrollable)
                        Expanded(child: _buildRouteListView(busRoute)),

                        // Bottom Info Card (without Positioned wrapper)
                        _buildBottomCardContent(busRoute),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _toggleTrackingMode() {
    setState(() {
      isGPSTracking = !isGPSTracking;
    });

    final message = isGPSTracking
        ? 'Switched to GPS Tracking'
        : 'Switched to Mobile Network Tracking';

    _showTopNotification(message);

    // Re-center map to the current bus position, not a hardcoded location
    if (isMapView && _mapController != null) {
      final busRoute = ref
          .read(busTrackingProvider)
          .whenOrNull(loaded: (r) => r);
      if (busRoute != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              busRoute.busPosition.latitude,
              busRoute.busPosition.longitude,
            ),
          ),
        );
      }
    }
  }

  void _showTopNotification(String message) {
    _notificationOverlay?.remove();
    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: -100.0, end: 0.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(opacity: (value + 100) / 100, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.deepBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.deepBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      _notificationOverlay?.remove();
                      _notificationOverlay = null;
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_notificationOverlay!);

    Future.delayed(const Duration(seconds: 3), () {
      _notificationOverlay?.remove();
      _notificationOverlay = null;
    });
  }

  void _showBusSelectorBottomSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Bus Selector',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -1), // Start from top (off-screen)
                  end: Offset.zero, // End at normal position
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 60), // Below status bar
                child: Builder(
                  builder: (context) {
                    // Derive student's pickup stop from current busRoute
                    final currentBusRoute = ref
                        .read(busTrackingProvider)
                        .whenOrNull(loaded: (r) => r);
                    final user = ref.read(authProvider).user;
                    String? pickupStop;
                    if (currentBusRoute != null && user != null) {
                      for (final s in currentBusRoute.students) {
                        final sName = (s['name'] as String? ?? '')
                            .toLowerCase()
                            .trim();
                        if (sName == user.name.toLowerCase().trim()) {
                          pickupStop =
                              (s['stopName'] ?? s['pickupStop']) as String?;
                          break;
                        }
                      }
                    }
                    return _BusSelectorBottomSheet(
                      selectedBus: selectedBus,
                      studentPickupStop: pickupStop,
                      destinationStop: currentBusRoute?.endPoint,
                      onBusSelected: (bus) {
                        setState(() {
                          selectedBus = bus.busNumber;
                        });

                        // Immediately move camera to the new bus location
                        if (mounted && isMapView) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(
                              LatLng(bus.latitude, bus.longitude),
                            ),
                          );
                        }

                        ref
                            .read(busTrackingProvider.notifier)
                            .startTracking(bus.busNumber);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView(BusRoute busRoute) {
    final initialPosition = CameraPosition(
      target: LatLng(
        busRoute.busPosition.latitude,
        busRoute.busPosition.longitude,
      ),
      zoom: 14,
    );

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: initialPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: _buildMarkers(busRoute),
      polylines: _buildPolylines(busRoute),
    );
  }

  Widget _buildRouteListView(BusRoute busRoute) {
    final stopsData = busRoute.stops; // provider already reverses stops if isReverse is true
    final bool isInTransit =
        busRoute.isTripActive && busRoute.transitFromStopIndex >= 0;
    final int transitFrom = busRoute.transitFromStopIndex;
    final double transitProg = busRoute.transitProgress;

    int? atStopIndex;
    if (busRoute.isTripActive && !isInTransit) {
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

    // Resolve student's assigned stop once for the whole list
    final user = ref.read(authProvider).user;
    String? studentStopName;
    if (user != null) {
      for (final s in busRoute.students) {
        final sName = (s['name'] as String? ?? '').toLowerCase().trim();
        final uName = user.name.toLowerCase().trim();
        if (sName == uName) {
          studentStopName = (s['stopName'] ?? s['pickupStop']) as String?;
          break;
        }
      }
    }

    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: stopsData.length,
        itemBuilder: (context, index) {
          final stop = stopsData[index];
          final isFirst = index == 0;
          final isLast = index == stopsData.length - 1;
          final isPassed = stop.type == StopType.passedStop;
          final isAtStop = !isInTransit && index == atStopIndex;
          
          final visualSegmentIdx = busRoute.isReverse 
              ? (stopsData.length - 1 - transitFrom) 
              : transitFrom;
          final isTransitSegment = isInTransit && index == visualSegmentIdx;

          return _buildStopItem(
            stop: stop,
            isFirst: isFirst,
            isLast: isLast,
            isPassed: isPassed,
            isAtStop: isAtStop,
            isTransitSegment: isTransitSegment,
            isInTransit: isInTransit,
            transitFrom: transitFrom,
            transitProg: transitProg,
            atStopIndex: atStopIndex,
            index: index,
            studentStopName: studentStopName,
            isReverse: busRoute.isReverse,
          );
        },
      ),
    );
  }

  Widget _buildStopItem({
    required RouteStop stop,
    required bool isFirst,
    required bool isLast,
    required bool isPassed,
    required bool isAtStop,
    required bool isTransitSegment,
    required bool isInTransit,
    required int transitFrom,
    required double transitProg,
    required int? atStopIndex,
    required int index,
    String? studentStopName,
    required bool isReverse,
  }) {
    final isNext = stop.type == StopType.nextStop;

    // Use the resolved studentStopName passed from the list view
    final bool isStudentAssignedHere =
        studentStopName != null &&
        stop.name.trim().toLowerCase() == studentStopName.trim().toLowerCase();

    final bool isUpcoming = !isPassed && !isAtStop;

    // --- Build dot icon ---
    Widget iconWidget;
    if (isAtStop) {
      iconWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.1),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: SizedBox(
            width: 28,
            height: 44,
            child: Image.asset('assets/icons/tracker.png', fit: BoxFit.contain),
          ),
        ),
        onEnd: () {},
      );
    } else if (stop.type == StopType.skippedStop) {
      iconWidget = const Icon(
        Icons.cancel,
        color: Colors.red,
        size: 26,
      );
    } else if (isPassed || (isInTransit && index <= transitFrom)) {
      iconWidget = const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 26,
      );
    } else if (isStudentAssignedHere) {
      iconWidget = Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.primaryYellow,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.black, size: 18),
      );
    } else {
      iconWidget = Icon(
        isNext ? Icons.play_circle_filled : Icons.circle_outlined,
        color: Colors.grey[400]!,
        size: 26,
      );
    }

    // Alarm override
    final hasAlarm = _selectedAlarms[stop.name] != null;
    if (hasAlarm) {
      iconWidget = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.notifications_active,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    // --- Connector line color helper ---
    Color lineColor(bool topHalf) {
      if (isInTransit) {
        return index < transitFrom
            ? AppColors.deepBlue
            : Colors.grey[300]!.withOpacity(0.8);
      } else {
        return (atStopIndex != null && index < atStopIndex)
            ? AppColors.deepBlue
            : Colors.grey[300]!.withOpacity(0.8);
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 3, height: 20, color: lineColor(true)),
                iconWidget,
                if (!isLast)
                  Expanded(
                    child: isTransitSegment
                        // Bus is on this segment — animate smoothly over 3s linearly based on GPS progression
                        ? TweenAnimationBuilder<double>(
                            key: ValueKey<int>(transitFrom),
                              tween: Tween<double>(
                                // Start from the last known GPS position for this
                                // segment so each update plays an incremental step
                                // (not a big sweep from 0 every time).
                                begin: (_prevTransitFrom == transitFrom)
                                    ? _prevTransitProg
                                    : 0.03,
                                  // transitProg is already flipped by updateLocalPosition in the provider
                                  // if isReverse is true, so we just use it directly.
                                  end: transitProg.clamp(0.03, 0.97),
                              ),
                            duration: const Duration(milliseconds: 2500),
                            curve: Curves.linear,
                            builder: (context, animProg, _) {
                              return Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Expanded(
                                        flex: (animProg * 100).round().clamp(
                                          1,
                                          99,
                                        ),
                                        child: Container(
                                          width: 5,
                                          color: AppColors.deepBlue,
                                        ),
                                      ),
                                      Expanded(
                                        flex: ((1 - animProg) * 100)
                                            .round()
                                            .clamp(1, 99),
                                        child: Container(
                                          width: 3,
                                          color: Colors.grey[300]!.withOpacity(
                                            0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment(
                                        0,
                                        -1.0 + (animProg * 2.0),
                                      ),
                                      child: OverflowBox(
                                        minWidth: 0,
                                        maxWidth: 44,
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
                              );
                            },
                          )
                        // Normal solid line
                        : Container(
                            width: isPassed ? 5 : 3,
                            color: lineColor(false),
                          ),
                  ),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: InkWell(
              onTap: () => _showAlarmOptions(stop.name),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Highlight the student's own stop with a warm amber tint
                  color: isStudentAssignedHere
                      ? const Color(0xFFFFF8E1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: isStudentAssignedHere
                      ? Border.all(color: const Color(0xFFFFCA28), width: 1.5)
                      : (hasAlarm
                            ? Border.all(
                                color: AppColors.primaryYellow.withOpacity(0.5),
                              )
                            : null),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Your Stop" banner at the top of the card
                    if (isStudentAssignedHere) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCA28),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.person_pin_circle,
                              size: 13,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Your Stop',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isStudentAssignedHere
                                      ? const Color(0xFF5D4037)
                                      : AppColors.darkCharcoal,
                                ),
                              ),
                              if (stop.scheduledTime != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Scheduled: ${stop.scheduledTime}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              _buildStopStatusChip(
                                stop: stop,
                                isPassed: isPassed,
                                isAtStop: isAtStop,
                                isTransitApproaching:
                                    isInTransit && index == transitFrom + 1,
                              ),
                            ],
                          ),
                        ),

                        // Right side: ETA badge for upcoming stops
                        if (isUpcoming && stop.estimatedArrivalMinutes != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isStudentAssignedHere
                                  ? const Color(0xFFFFCA28)
                                  : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${stop.estimatedArrivalMinutes}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isStudentAssignedHere
                                        ? Colors.black87
                                        : AppColors.deepBlue,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'min',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isStudentAssignedHere
                                        ? Colors.black54
                                        : AppColors.deepBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (isAtStop)
                          _buildBadge(
                            'Bus Here',
                            AppColors.deepBlue,
                            icon: Icons.location_on,
                          ),
                        if (isNext &&
                            !isAtStop &&
                            stop.estimatedArrivalMinutes == null)
                          _buildBadge('Next', AppColors.brightOrange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

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
        final delay = _computeDelay(
          stop.actualArrivalTime!,
          stop.scheduledTime!,
        );
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
      if (stop.estimatedArrivalMinutes != null) {
        if (stop.delayMinutes > 0) {
          label =
              'ETA ${stop.estimatedArrivalMinutes} min · ${stop.delayMinutes} min delay';
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
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _computeDelay(DateTime actual, String scheduled) {
    try {
      final parts = scheduled.trim().split(RegExp(r'[\s:]+'));
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

  Widget _buildBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAlarms(BusRoute busRoute) async {
    final prefs = await SharedPreferences.getInstance();
    final proximityEnabled = prefs.getBool('notify_proximity') ?? true;

    if (!proximityEnabled) return;

    for (var stop in busRoute.stops) {
      final alarmMins = _selectedAlarms[stop.name];
      if (alarmMins != null && alarmMins is int) {
        final eta = stop.estimatedArrivalMinutes;
        if (eta != null &&
            eta <= alarmMins &&
            !_triggeredAlarms.contains(stop.name)) {
          _triggeredAlarms.add(stop.name);
          _triggerAlarm(stop.name, eta);
        }
      }
    }
  }

  void _showTripCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text('Trip Completed!'),
          ],
        ),
        content: const Text(
          'Your bus has reached its destination. The tracking for this trip has finished.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.goNamed('student-landing'); // Go back to landing page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('GO BACK'),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerAlarm(String stopName, int eta) {
    // 1. Fire a system notification so the alert works on both Android & iOS
    //    (works even when the app is backgrounded)
    showAlarmNotification(stopName: stopName, etaMinutes: eta);

    // 2. Also show an in-app dialog when the app is in the foreground
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.alarm_on, color: AppColors.brightOrange),
            SizedBox(width: 8),
            Text('ALARM!'),
          ],
        ),
        content: Text(
          'Bus will reach $stopName in approx $eta mins. Get ready!',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brightOrange,
            ),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  String _calculateTriggerTime(String scheduledTime, int minutesBefore) {
    try {
      // Handle both "08:30 AM" or "08:30" format
      final cleanTime = scheduledTime.trim().toUpperCase();
      final isPM = cleanTime.contains('PM');
      final isAM = cleanTime.contains('AM');

      final timeParts = cleanTime
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim()
          .split(':');
      if (timeParts.length < 2) return '--:--';

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      final scheduledDateTime = DateTime(2024, 1, 1, hour, minute);
      final triggerDateTime = scheduledDateTime.subtract(
        Duration(minutes: minutesBefore),
      );

      final triggerHour = triggerDateTime.hour > 12
          ? triggerDateTime.hour - 12
          : (triggerDateTime.hour == 0 ? 12 : triggerDateTime.hour);
      final triggerMinute = triggerDateTime.minute.toString().padLeft(2, '0');
      final period = triggerDateTime.hour >= 12 ? 'PM' : 'AM';

      return '${triggerHour.toString().padLeft(2, '0')}:$triggerMinute $period';
    } catch (e) {
      return '--:--';
    }
  }

  void _showAlarmOptions(String initialStopName) {
    final trackingState = ref.read(busTrackingProvider);
    List<String> stops = [];
    trackingState.maybeWhen(
      loaded: (busRoute) {
        stops = busRoute.stops.map((s) => s.name).toSet().toList();
      },
      orElse: () {},
    );

    if (stops.isEmpty) {
      if (initialStopName == 'Selected Stop' || initialStopName.isEmpty) {
        stops = ['Unknown Stop'];
      } else {
        stops = [initialStopName];
      }
    }

    String selectedStop = stops.contains(initialStopName)
        ? initialStopName
        : stops.first;
    int selectedMinutes = 5;

    if (_selectedAlarms[selectedStop] is int) {
      selectedMinutes = _selectedAlarms[selectedStop] as int;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Setup Alarm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Before Section
                    Row(
                      children: const [
                        Icon(Icons.timer, size: 18, color: AppColors.deepBlue),
                        SizedBox(width: 8),
                        Text(
                          'Before',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeOptionButton(
                            5,
                            selectedMinutes,
                            (val) => setModalState(() => selectedMinutes = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeOptionButton(
                            10,
                            selectedMinutes,
                            (val) => setModalState(() => selectedMinutes = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeOptionButton(
                            15,
                            selectedMinutes,
                            (val) => setModalState(() => selectedMinutes = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reaching Section
                    Row(
                      children: const [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppColors.deepBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reaching',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9), // Light grayish-blue
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStop,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.darkCharcoal,
                          ),
                          items: stops.map((String stop) {
                            return DropdownMenuItem<String>(
                              value: stop,
                              child: Text(stop),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setModalState(() {
                                selectedStop = newValue;
                                if (_selectedAlarms[selectedStop] is int) {
                                  selectedMinutes =
                                      _selectedAlarms[selectedStop] as int;
                                } else {
                                  selectedMinutes = 5;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Timing Info Helper
                    Builder(
                      builder: (context) {
                        String? scheduledTime;
                        trackingState.maybeWhen(
                          loaded: (busRoute) {
                            final stop = busRoute.stops.firstWhere(
                              (s) => s.name == selectedStop,
                              orElse: () => busRoute.stops.first,
                            );
                            scheduledTime = stop.scheduledTime;
                          },
                          orElse: () {},
                        );

                        if (scheduledTime == null)
                          return const SizedBox.shrink();

                        // Calculate trigger time
                        final triggerTime = _calculateTriggerTime(
                          scheduledTime!,
                          selectedMinutes,
                        );

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightYellow.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryYellow.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Scheduled Arrival:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    scheduledTime!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Scheduled Arrival:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    scheduledTime!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Alarm will trigger at:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    triggerTime,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brightOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        // Clear Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAlarms.remove(selectedStop);
                                _triggeredAlarms.remove(selectedStop);
                              });
                              _saveAlarms();
                              Navigator.pop(context);
                              _showNotification(
                                'Alarm cleared for $selectedStop',
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Save Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAlarms[selectedStop] = selectedMinutes;
                                _triggeredAlarms.remove(selectedStop);
                              });
                              _saveAlarms();
                              Navigator.pop(context);
                              _showNotification(
                                'Alarm set for $selectedMinutes min before $selectedStop',
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.brightOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeOptionButton(
    int minutes,
    int selectedMinutes,
    ValueChanged<int> onTap,
  ) {
    final isSelected = minutes == selectedMinutes;
    return GestureDetector(
      onTap: () => onTap(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Very light gray-blue
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brightOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$minutes',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold, // changed to bold
                color: AppColors.darkCharcoal,
              ),
            ),
            const Text(
              'Mins',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkCharcoal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotification(String message) {
    UIHelpers.showSuccessTooltip(context, message);
  }

  Widget _buildTopBarContent() {
    return Row(
      children: [
        // Back Button
        _buildCompactIconButton(
          icon: Icons.arrow_back,
          iconColor: AppColors.deepBlue,
          onTap: () => context.pop(),
        ),
        const SizedBox(width: 8),

        // Bus selector dropdown
        Expanded(child: _buildBusSelector()),
        const SizedBox(width: 8),

        // Removed Refresh from top bar — user wants it at bottom right of view

        // Tracking Mode Toggle
        _buildCompactIconButton(
          icon: isGPSTracking ? Icons.my_location : Icons.network_check,
          iconColor: isGPSTracking
              ? AppColors.deepBlue
              : AppColors.brightOrange,
          onTap: _toggleTrackingMode,
        ),

        const SizedBox(width: 8),

        // Notification button
        _buildCompactIconButton(
          icon: Icons.notifications,
          iconColor: AppColors.deepBlue,
          onTap: () => context.push(AppRouter.notifications),
        ),
        const SizedBox(width: 8),

        // Profile button
        _buildCompactIconButton(
          icon: Icons.person,
          iconColor: AppColors.deepBlue,
          onTap: () => context.push(AppRouter.profile),
        ),
      ],
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.darkCharcoal, size: 20),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: _buildTopBarContent(),
      ),
    );
  }

  Widget _buildBusSelector() {
    return GestureDetector(
      onTap: _showBusSelectorBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus_rounded,
              color: AppColors.brightOrange,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedBus,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ref.watch(busTrackingProvider).maybeWhen(loaded: (r) => r.isReverse, orElse: () => false))
                    Text(
                      'Return Trip',
                      style: TextStyle(
                        color: AppColors.brightOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.darkCharcoal,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(BusRoute busRoute) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _buildBottomCardContent(busRoute),
    );
  }

  Widget _buildBottomCardContent(BusRoute busRoute) {
    // ── Base route-level values (used as fallback) ────────────────────────
    final arrivalTime = busRoute.arrivalTimeMinutes;
    final distance = busRoute.distanceKm;
    final isOnTime = busRoute.isOnTime;
    final driverPhone = busRoute.driverPhone;
    final user = ref.watch(authProvider).user;

    // Support either single user or multiple-student account logic
    dynamic displayStudent = user;
    if (widget.studentName != null && user?.accounts != null) {
      displayStudent = user!.accounts!.firstWhere(
        (a) => a.name == widget.studentName,
        orElse: () => user,
      );
    }
    final List<dynamic> students = displayStudent != null
        ? [displayStudent]
        : (user != null ? [user] : []);

    // ── Student's personal pickup stop + live ETA & distance ─────────────
    // busRoute.students carries 'stopName' (from attendance) or 'pickupStop' (from API)
    final String? studentPickupStop = () {
      if (displayStudent == null) return null;
      for (final s in busRoute.students) {
        final sName = (s['name'] as String? ?? '').toLowerCase().trim();
        final uName = (displayStudent?.name as String? ?? '')
            .toLowerCase()
            .trim();
        if (sName == uName) {
          return (s['stopName'] ?? s['pickupStop']) as String?;
        }
      }
      return null;
    }();

    // Find the matching RouteStop object
    RouteStop? myStop;
    if (studentPickupStop != null && studentPickupStop.isNotEmpty) {
      try {
        myStop = busRoute.stops.firstWhere(
          (s) =>
              s.name.trim().toLowerCase() ==
              studentPickupStop.trim().toLowerCase(),
        );
      } catch (_) {
        myStop = null;
      }
    }

    // Determine target stop for display (myStop or next upcoming if passed/missing)
    final bool myStopPassed =
        myStop != null && myStop.type == StopType.passedStop;
    RouteStop? displayStop = myStop;
    bool isRouteFallback = false;

    if (myStop == null || myStopPassed) {
      final List<RouteStop> upcoming = busRoute.stops
          .where(
            (s) => s.type == StopType.nextStop || s.type == StopType.futureStop,
          )
          .toList();
      if (upcoming.isNotEmpty) {
        displayStop = upcoming.first;
        isRouteFallback = true;
      }
    }

    // Distance: cumulative route distance from bus → each stop in sequence → targetStop
    double? displayDistanceKm;
    if (displayStop != null) {
      // ── ULTRA-ACCURATE DISTANCE CALCULATION (using routePath) ────────────
      if (busRoute.routePath.isNotEmpty) {
        final busLat = busRoute.busPosition.latitude;
        final busLng = busRoute.busPosition.longitude;
        final targetLat = displayStop.latitude;
        final targetLng = displayStop.longitude;

        // 1. Find closest route-path index to the BUS
        int busPathIdx = 0;
        double minBusDist = double.infinity;
        for (int i = 0; i < busRoute.routePath.length; i++) {
          final p = busRoute.routePath[i];
          final d = Geolocator.distanceBetween(busLat, busLng, p.latitude, p.longitude);
          if (d < minBusDist) {
            minBusDist = d;
            busPathIdx = i;
          }
        }

        // 2. Find closest route-path index to the TARGET STOP
        int targetPathIdx = 0;
        double minTargetDist = double.infinity;
        for (int i = 0; i < busRoute.routePath.length; i++) {
          final p = busRoute.routePath[i];
          final d = Geolocator.distanceBetween(targetLat, targetLng, p.latitude, p.longitude);
          if (d < minTargetDist) {
            minTargetDist = d;
            targetPathIdx = i;
          }
        }

        // 3. Sum segments between busPathIdx and targetPathIdx
        double totalM = 0;
        if (busPathIdx < targetPathIdx) {
          for (int i = busPathIdx; i < targetPathIdx; i++) {
            final p1 = busRoute.routePath[i];
            final p2 = busRoute.routePath[i+1];
            totalM += Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
          }
          displayDistanceKm = totalM / 1000.0;
        } else {
          // Bus is already at or past the stop (according to polyline)
          displayDistanceKm = 0.05; // 50m minimum
        }
      } 
      
      // ── FALLBACK DISTANCE CALCULATION (waypoint-based) ────────────────────
      if (displayDistanceKm == null) {
        final targetIdx = busRoute.stops.indexWhere(
          (s) => s.name.trim().toLowerCase() == displayStop!.name.trim().toLowerCase(),
        );

        double totalM = 0;
        double prevLat = busRoute.busPosition.latitude;
        double prevLng = busRoute.busPosition.longitude;

        for (int i = 0; i <= targetIdx; i++) {
          final stop = busRoute.stops[i];
          if (stop.type == StopType.passedStop) continue;

          totalM += Geolocator.distanceBetween(prevLat, prevLng, stop.latitude, stop.longitude);
          prevLat = stop.latitude;
          prevLng = stop.longitude;
          if (i == targetIdx) break;
        }
        displayDistanceKm = totalM / 1000.0;
      }
    }

    // ETA: prefer per-stop estimatedArrivalMinutes, but calculate a dynamic one based on distance
    // Average bus speed in city ~25 km/h -> 0.416 km/min
    final int? liveEtaMin = displayDistanceKm != null 
        ? (displayDistanceKm / 0.416).ceil().clamp(1, 120) 
        : null;
        
    final int? stopEtaMin = liveEtaMin ?? displayStop?.estimatedArrivalMinutes;

    // Check if the current student is already boarded
    final bool studentIsBoarded = () {
      if (displayStudent == null) return false;
      for (final s in busRoute.students) {
        final sName = (s['name'] as String? ?? '').toLowerCase().trim();
        final uName = (displayStudent?.name as String? ?? '')
            .toLowerCase()
            .trim();
        if (sName == uName) {
          return (s['isBoarded'] ?? false) == true;
        }
      }
      return false;
    }();

    // Display values: prefer stop-specific, fallback to route-level
    final String etaText = studentIsBoarded
        ? 'Onboarded'
        : (stopEtaMin != null ? '$stopEtaMin min' : '$arrivalTime min');

    final String distText = studentIsBoarded
        ? 'Safe Journey!'
        : (displayDistanceKm != null
              ? '${UIHelpers.formatDistance(displayDistanceKm)} away'
              : '${UIHelpers.formatDistance(distance)} away');

    // Label: show which stop we're measuring to
    final String arrivalLabel = studentIsBoarded
        ? 'Status'
        : (displayStop != null
              ? 'Arriving at ${displayStop.name.split(' ').take(3).join(' ')}${isRouteFallback ? ' (next)' : ''}'
              : 'Arriving in');

    // Build the bottom action bar with ETA and Distance
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Student Profiles Section
          if (students.isNotEmpty) ...[
            Column(
              children: students.map((student) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF1F5F9,
                    ), // Light grayish-blue background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: student.avatar != null
                            ? Image.network(
                                student.avatar!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackAvatar(),
                              )
                            : _buildFallbackAvatar(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                                if (studentIsBoarded) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Onboarded',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              student.studentId != null &&
                                      student.studentId!.isNotEmpty
                                  ? 'ID: ${student.studentId}'
                                  : (student.id.isNotEmpty
                                        ? 'ID: ${student.id.substring(0, 8).toUpperCase()}'
                                        : 'ID: Not Available'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.college ?? 'College info unavailable',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Top Info Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Arrival Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            arrivalLabel,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (busRoute.isReverse) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brightOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz, color: AppColors.brightOrange, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  'RETURN TRIP',
                                  style: TextStyle(
                                    color: AppColors.brightOrange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        etaText,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkCharcoal,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      distText,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Status and Quick Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnTime ? Icons.check_circle : Icons.error,
                        size: 20,
                        color: isOnTime
                            ? const Color(0xFF4CAF50)
                            : AppColors.locationRed,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        !busRoute.isTripActive
                            ? 'Trip not started'
                            : (isOnTime
                                  ? 'On Time'
                                  : 'Delayed by ${busRoute.arrivalTimeMinutes} mins'),
                        style: TextStyle(
                          color: isOnTime || !busRoute.isTripActive
                              ? const Color(0xFF4CAF50)
                              : AppColors.locationRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Alarm Button
                      _buildSquareActionBtn(
                        icon: Icons.notifications_active_outlined,
                        hasDot: _selectedAlarms.isNotEmpty,
                        onTap: () => _showAlarmOptions('Selected Stop'),
                      ),
                      const SizedBox(width: 12),
                      // Call Button
                      _buildSquareActionBtn(
                        icon: Icons.phone_outlined,
                        onTap: () => _showCallDriverConfirmation(driverPhone),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 24),

          // Bottom Action Buttons
          Row(
            children: [
              // Refresh Button
              Expanded(
                child: _buildBottomBtn(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onTap: () {
                    final busNo = widget.busNumber ?? '10';
                    ref.read(busTrackingProvider.notifier).loadBusRoute(busNo);
                    _showTopNotification('Refreshing bus location...');
                  },
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 16),
              // View Route Button
              Expanded(
                child: _buildBottomBtn(
                  icon: isMapView
                      ? Icons.format_list_bulleted_rounded
                      : Icons.map_rounded,
                  label: isMapView ? 'View Route' : 'View Map',
                  onTap: () {
                    setState(() {
                      isMapView = !isMapView;
                      if (!isMapView) {
                        _mapController = null;
                      }
                    });
                  },
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareActionBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.brightOrange.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brightOrange, size: 24),
          ),
          if (hasDot)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.brightOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, size: 24, color: Colors.grey),
    );
  }

  Widget _buildBottomBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.brightOrange
              : AppColors.brightOrange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.brightOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppColors.brightOrange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDriverConfirmation(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showTopNotification('Driver phone number not available');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Call Driver',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The driver may be operating the vehicle. Please call only in case of emergency or urgent coordination.',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Frequent calls may delay the journey.',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFF97316)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _callDriver(phoneNumber);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Yes, Call Driver',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Bus Selector Bottom Sheet Widget
class _BusSelectorBottomSheet extends ConsumerStatefulWidget {
  final String selectedBus;
  final Function(BusSummary) onBusSelected;

  /// Pre-select the student's pickup stop as the 'From' stop.
  final String? studentPickupStop;

  /// Pre-select the route's final stop as the 'To' stop.
  final String? destinationStop;

  const _BusSelectorBottomSheet({
    required this.selectedBus,
    required this.onBusSelected,
    this.studentPickupStop,
    this.destinationStop,
  });

  @override
  ConsumerState<_BusSelectorBottomSheet> createState() =>
      _BusSelectorBottomSheetState();
}

class _BusSelectorBottomSheetState
    extends ConsumerState<_BusSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  RouteStop? _selectedOrigin;
  RouteStop? _selectedDestination;
  String _searchQuery = '';
  bool _initializedStops = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(busListProvider.notifier).loadAvailableBuses();
      ref.read(collegeStopsProvider.notifier).loadStops();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusSummary> _getFilteredBuses(List<BusSummary> buses) {
    var filtered = buses.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (bus) =>
                bus.busNumber.toLowerCase().contains(query) ||
                bus.status.toLowerCase().contains(query),
          )
          .toList();
    }

    filtered.sort((a, b) {
      // 1. Calculate relevance score (buses on route first)
      int getScore(BusSummary bus) {
        if (bus.routeStops == null || bus.routeStops!.isEmpty) return 0;

        bool hasOrigin =
            _selectedOrigin == null ||
            bus.routeStops!.any((s) => s.name == _selectedOrigin!.name);
        bool hasDest =
            _selectedDestination == null ||
            bus.routeStops!.any((s) => s.name == _selectedDestination!.name);

        if (hasOrigin && hasDest) return 3;
        if (hasOrigin) return 2;
        if (hasDest) return 1;
        return 0;
      }

      final scoreA = getScore(a);
      final scoreB = getScore(b);

      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA); // Higher score first
      }

      // 2. Sort by distance if scores are equal
      if (_selectedOrigin != null) {
        final distA = Geolocator.distanceBetween(
          _selectedOrigin!.latitude,
          _selectedOrigin!.longitude,
          a.latitude,
          a.longitude,
        );
        final distB = Geolocator.distanceBetween(
          _selectedOrigin!.latitude,
          _selectedOrigin!.longitude,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      }
      return 0;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final busListState = ref.watch(busListProvider);
    final stopsState = ref.watch(collegeStopsProvider);

    stopsState.maybeWhen(
      loaded: (stops) {
        if (!_initializedStops && stops.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _initializedStops = true;

                // Fuzzy stop finder: exact match first, then partial
                RouteStop? findStop(String? target) {
                  if (target == null || target.isEmpty) return null;
                  final t = target.trim().toLowerCase();
                  // 1. exact
                  try {
                    return stops.firstWhere(
                      (s) => s.name.trim().toLowerCase() == t,
                    );
                  } catch (_) {}
                  // 2. target contains stop name
                  try {
                    return stops.firstWhere(
                      (s) => t.contains(s.name.trim().toLowerCase()),
                    );
                  } catch (_) {}
                  // 3. stop name contains target words
                  try {
                    return stops.firstWhere(
                      (s) => s.name.trim().toLowerCase().contains(t),
                    );
                  } catch (_) {}
                  return null;
                }

                // Pre-select From: student's pickup stop
                _selectedOrigin =
                    findStop(widget.studentPickupStop) ?? stops.first;

                // Pre-select To: route end point, fall back to college stop
                _selectedDestination =
                    findStop(widget.destinationStop) ??
                    (() {
                      try {
                        return stops.firstWhere(
                          (s) =>
                              s.name.toLowerCase().contains('college') ||
                              s.name.toLowerCase().contains('jntu') ||
                              s.name.toLowerCase().contains('university'),
                        );
                      } catch (_) {
                        return stops.last;
                      }
                    }());
              });
            }
          });
        }
      },
      orElse: () {},
    );

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and subtitle
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch Bus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose a different bus to track',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Route information
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Row(
                        children: [
                          // Left Icons Column
                          Column(
                            children: [
                              const Icon(
                                Icons.my_location,
                                color: Colors.grey,
                                size: 20,
                              ),
                              Column(
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    width: 3,
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: AppColors.locationRed,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // TextFields Column
                          Expanded(
                            child: Column(
                              children: [
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<RouteStop>(
                                    isDense: true,
                                    isExpanded: true,
                                    value: _selectedOrigin,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    hint: stopsState.maybeWhen(
                                      loading: () => const Text(
                                        'Loading stops...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      error: (msg) => Text(
                                        'Error: $msg',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                      orElse: () => const Text(
                                        'No stops available',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    items: stopsState.maybeWhen(
                                      loaded: (stops) => stops.map((stop) {
                                        return DropdownMenuItem<RouteStop>(
                                          value: stop,
                                          child: Text(
                                            stop.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      orElse: () => [],
                                    ),
                                    onChanged: (RouteStop? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedOrigin = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<RouteStop>(
                                    isDense: true,
                                    isExpanded: true,
                                    value: _selectedDestination,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    hint: stopsState.maybeWhen(
                                      loading: () => const Text(
                                        'Loading stops...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      error: (msg) => Text(
                                        'Error: $msg',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                      orElse: () => const Text(
                                        'No stops available',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    items: stopsState.maybeWhen(
                                      loaded: (stops) => stops.map((stop) {
                                        return DropdownMenuItem<RouteStop>(
                                          value: stop,
                                          child: Text(
                                            stop.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      orElse: () => [],
                                    ),
                                    onChanged: (RouteStop? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedDestination = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48), // Space for button
                        ],
                      ),

                      // Swap Button
                      InkWell(
                        onTap: () {
                          if (_selectedOrigin != null &&
                              _selectedDestination != null) {
                            final temp = _selectedOrigin;
                            setState(() {
                              _selectedOrigin = _selectedDestination;
                              _selectedDestination = temp;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.deepBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.swap_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search bus or route...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bus list
          Flexible(
            child: busListState.when(
              initial: () => const SizedBox(height: 100),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error: $message'),
                ),
              ),
              loaded: (buses) {
                final filteredBuses = _getFilteredBuses(buses);

                if (filteredBuses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No buses found'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredBuses.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final bus = filteredBuses[index];
                    final isSelected = bus.busNumber == widget.selectedBus;

                    return InkWell(
                      onTap: () => widget.onBusSelected(bus),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lightYellow.withOpacity(0.3)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryYellow
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Bus icon
                            Container(
                              width: 50,
                              height: 50,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: AppColors.deepBlue,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Bus info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bus.busNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        bus.isDelayed
                                            ? Icons.schedule
                                            : Icons.check_circle,
                                        size: 16,
                                        color: bus.isDelayed
                                            ? AppColors.locationRed
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        bus.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: bus.isDelayed
                                              ? AppColors.locationRed
                                              : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (bus.distance != null &&
                                          bus.distance! < 500 &&
                                          (bus.latitude != 0.0 ||
                                              bus.longitude != 0.0)) ...[
                                        const SizedBox(width: 8),
                                        const Text(
                                          '•',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${UIHelpers.formatDistance(bus.distance)} away',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Radio button
                            Radio<String>(
                              value: bus.busNumber,
                              groupValue: widget.selectedBus,
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onBusSelected(bus);
                                }
                              },
                              activeColor: AppColors.brightOrange,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
