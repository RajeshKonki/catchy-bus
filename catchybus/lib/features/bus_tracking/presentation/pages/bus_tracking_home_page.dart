import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../domain/entities/bus_route.dart';

class BusTrackingHomePage extends ConsumerStatefulWidget {
  const BusTrackingHomePage({super.key});

  @override
  ConsumerState<BusTrackingHomePage> createState() =>
      _BusTrackingHomePageState();
}

class _BusTrackingHomePageState extends ConsumerState<BusTrackingHomePage> {
  GoogleMapController? _mapController;
  String selectedBus = 'Bus No. 10';
  bool isMapView = true; // Toggle between map and route list view
  bool isGPSTracking = true; // Toggle between GPS and Mobile Network tracking
  OverlayEntry? _notificationOverlay;

  @override
  void initState() {
    super.initState();
    // Load initial bus route
    // TODO: Call provider to load bus route
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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

    // Current location marker (yellow circle)
    final currentStop = busRoute.stops.firstWhere(
      (stop) => stop.type == StopType.currentLocation,
      orElse: () => busRoute.stops.first,
    );
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentStop.latitude, currentStop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: currentStop.name),
      ),
    );

    // Next stop marker (red pin)
    final nextStop = busRoute.stops.firstWhere(
      (stop) => stop.type == StopType.nextStop,
      orElse: () => busRoute.stops.last,
    );
    markers.add(
      Marker(
        markerId: const MarkerId('next_stop'),
        position: LatLng(nextStop.latitude, nextStop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: nextStop.name),
      ),
    );

    // Bus position marker
    markers.add(
      Marker(
        markerId: const MarkerId('bus_position'),
        position: LatLng(
          busRoute.busPosition.latitude,
          busRoute.busPosition.longitude,
        ),
        rotation: busRoute.busPosition.bearing,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: busRoute.busNumber),
      ),
    );

    return markers;
  }

  Set<Polyline> _buildPolylines(BusRoute busRoute) {
    final points = busRoute.routePath
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('bus_route'),
        points: points,
        color: AppColors.deepBlue,
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Watch the bus tracking state from provider
    // For now, using mock data
    return Scaffold(
      body: isMapView
          ? Stack(
              children: [
                // Map View
                _buildMapView(),

                // Top Bar
                _buildTopBar(),

                // Bottom Info Card
                _buildBottomCard(),
              ],
            )
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Bar content (without SafeArea wrapper)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                    child: _buildTopBarContent(),
                  ),

                  // Route List View (scrollable)
                  Expanded(child: _buildRouteListView()),

                  // Bottom Info Card (without Positioned wrapper)
                  _buildBottomCardContent(),
                ],
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

    // If in map view, re-center or update behavior
    if (isMapView) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(const LatLng(40.7589, -73.9851)),
      );
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                child: _BusSelectorBottomSheet(
                  selectedBus: selectedBus,
                  onBusSelected: (busNumber) {
                    setState(() {
                      selectedBus = busNumber;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    // Placeholder for map until API keys are configured
    return Container(
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Map placeholder background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Configure Google Maps API keys to see the live bus location',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          // Mock route visualization
          Positioned(
            top: 200,
            left: 100,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.deepBlue, width: 2),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: AppColors.deepBlue,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );

    /* Uncomment this when Google Maps API keys are configured:
    
    const initialPosition = CameraPosition(
      target: LatLng(40.7589, -73.9851),
      zoom: 14,
    );

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: initialPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // TODO: Add markers and polylines from state
      // markers: _buildMarkers(busRoute),
      // polylines: _buildPolylines(busRoute),
    );
    */
  }

  Widget _buildRouteListView() {
    // Mock route data
    final List<Map<String, dynamic>> stops = [
      {'name': 'MG Road', 'time': '7:12 AM', 'status': 'completed'},
      {'name': 'MG Road', 'time': '7:12 AM', 'status': 'completed'},
      {'name': 'MG Road', 'time': '7:12 AM', 'status': 'current'},
      {
        'name': 'MG Road',
        'time': '7:12 AM',
        'status': 'upcoming',
        'eta': 'in 3 min',
      },
      {
        'name': 'MG Road',
        'time': '7:12 AM',
        'status': 'user_location',
        'eta': 'in 3 min',
      },
      {
        'name': 'MG Road',
        'time': '7:12 AM',
        'status': 'upcoming',
        'eta': 'in 3 min',
      },
    ];

    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 16,
        ),
        itemCount: stops.length,
        itemBuilder: (context, index) {
          final stop = stops[index];
          final isFirst = index == 0;
          final isLast = index == stops.length - 1;

          return _buildStopItem(stop: stop, isFirst: isFirst, isLast: isLast);
        },
      ),
    );
  }

  Widget _buildStopItem({
    required Map<String, dynamic> stop,
    required bool isFirst,
    required bool isLast,
  }) {
    final status = stop['status'];
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';
    final isUserLocation = status == 'user_location';

    Color iconColor;
    IconData iconData;
    Widget iconWidget;

    if (isCompleted) {
      iconColor = Colors.green;
      iconData = Icons.check_circle;
      iconWidget = Icon(iconData, color: iconColor, size: 24);
    } else if (isCurrent) {
      iconColor = AppColors.brightOrange;
      iconWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primaryYellow,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.directions_bus,
          color: AppColors.deepBlue,
          size: 16,
        ),
      );
    } else if (isUserLocation) {
      iconColor = AppColors.primaryYellow;
      iconWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primaryYellow,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 16),
      );
    } else {
      iconColor = Colors.grey[400]!;
      iconData = Icons.circle_outlined;
      iconWidget = Icon(iconData, color: iconColor, size: 24);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                // Icon
                iconWidget,
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? Colors.green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),

          // Stop details
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              stop['time'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (stop['eta'] != null) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stop['eta'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.deepBlue, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.deepBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isUserLocation)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.deepBlue, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.navigation,
                            size: 14,
                            color: AppColors.deepBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Your Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTopBarContent() {
    return Row(
      children: [
        // Bus selector dropdown
        _buildBusSelector(),
        const SizedBox(width: 12),

        // Tracking Mode Toggle (GPS / Mobile Network)
        _buildIconButton(
          icon: isGPSTracking ? Icons.my_location : Icons.network_check,
          iconColor: isGPSTracking
              ? AppColors.deepBlue
              : AppColors.brightOrange,
          onTap: _toggleTrackingMode,
        ),

        const Spacer(),

        // Notification button
        _buildIconButton(
          icon: Icons.notifications,
          onTap: () => context.push(AppRouter.notifications),
        ),
        const SizedBox(width: 12),

        // Profile button
        _buildIconButton(
          icon: Icons.person,
          onTap: () => context.push(AppRouter.profile),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Bus selector dropdown
            _buildBusSelector(),
            const SizedBox(width: 12),

            // Tracking Mode Toggle (GPS / Mobile Network)
            _buildIconButton(
              icon: isGPSTracking ? Icons.my_location : Icons.network_check,
              iconColor: isGPSTracking
                  ? AppColors.deepBlue
                  : AppColors.brightOrange,
              onTap: _toggleTrackingMode,
            ),

            const Spacer(),

            // Notification button
            _buildIconButton(
              icon: Icons.notifications,
              onTap: () => context.push(AppRouter.notifications),
            ),
            const SizedBox(width: 12),

            // Profile button
            _buildIconButton(
              icon: Icons.person,
              onTap: () => context.push(AppRouter.profile),
            ),
          ],
        ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 20,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedBus,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.darkCharcoal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? AppColors.darkCharcoal, size: 24),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _buildBottomCardContent(),
    );
  }

  Widget _buildBottomCardContent({bool includeMargin = true}) {
    // Mock data for now
    const currentLocation = 'MG Road';
    const nextStop = 'Hostel Gate';
    const arrivalTime = 8;
    const distance = 4.2;
    const isOnTime = true;
    const driverPhone = '+1234567890';

    return Container(
      margin: includeMargin
          ? const EdgeInsets.all(16)
          : const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current Location and Next Stop
          Row(
            children: [
              Expanded(
                child: _buildLocationInfo(
                  icon: Icons.location_on,
                  iconColor: AppColors.deepBlue,
                  label: 'Current Location',
                  location: currentLocation,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLocationInfo(
                  icon: Icons.navigation,
                  iconColor: AppColors.deepBlue,
                  label: 'Next Stop',
                  location: nextStop,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Arrival Time and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arriving in',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$arrivalTime min',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$distance km away',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // On Time Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOnTime
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isOnTime ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnTime ? 'On Time' : 'Delayed',
                      style: TextStyle(
                        color: isOnTime ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Call Driver Button and View Route
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callDriver(driverPhone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brightOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text(
                    'Call Driver',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // View Route Link
          TextButton(
            onPressed: () {
              setState(() {
                isMapView = !isMapView;
              });
            },
            child: Text(
              isMapView ? 'View Route' : 'View Map',
              style: const TextStyle(
                color: AppColors.brightOrange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String location,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          location,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkCharcoal,
          ),
        ),
      ],
    );
  }
}

// Bus Selector Bottom Sheet Widget
class _BusSelectorBottomSheet extends StatefulWidget {
  final String selectedBus;
  final Function(String) onBusSelected;

  const _BusSelectorBottomSheet({
    required this.selectedBus,
    required this.onBusSelected,
  });

  @override
  State<_BusSelectorBottomSheet> createState() =>
      _BusSelectorBottomSheetState();
}

class _BusSelectorBottomSheetState extends State<_BusSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock bus data
  final List<Map<String, dynamic>> _buses = [
    {
      'number': 'Bus No. 10',
      'status': 'On Time',
      'isDelayed': false,
      'delayMinutes': 0,
    },
    {
      'number': 'Bus No. 11',
      'status': 'Delayed by 5 min',
      'isDelayed': true,
      'delayMinutes': 5,
    },
    {
      'number': 'Bus No. 12',
      'status': 'On Time',
      'isDelayed': false,
      'delayMinutes': 0,
    },
    {
      'number': 'Bus No. 13',
      'status': 'On Time',
      'isDelayed': false,
      'delayMinutes': 0,
    },
    {
      'number': 'Bus No. 14',
      'status': 'On Time',
      'isDelayed': false,
      'delayMinutes': 0,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredBuses {
    if (_searchQuery.isEmpty) {
      return _buses;
    }
    return _buses
        .where(
          (bus) =>
              bus['number'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Start location
                      const Icon(
                        Icons.trip_origin,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mandapeta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Route indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      // End location
                      const Text(
                        'Kakinada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on,
                        color: AppColors.locationRed,
                        size: 20,
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
                    hintText: 'Search bus number...',
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredBuses.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final bus = _filteredBuses[index];
                final isSelected = bus['number'] == widget.selectedBus;

                return InkWell(
                  onTap: () => widget.onBusSelected(bus['number']),
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
                          child: Image.asset(
                            'assets/images/bus_icon.png',
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.directions_bus,
                                  color: AppColors.deepBlue,
                                  size: 30,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Bus info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus['number'],
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
                                    bus['isDelayed']
                                        ? Icons.schedule
                                        : Icons.check_circle,
                                    size: 16,
                                    color: bus['isDelayed']
                                        ? AppColors.locationRed
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    bus['status'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: bus['isDelayed']
                                          ? AppColors.locationRed
                                          : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Radio button
                        Radio<String>(
                          value: bus['number'],
                          groupValue: widget.selectedBus,
                          onChanged: (value) {
                            if (value != null) {
                              widget.onBusSelected(value);
                            }
                          },
                          activeColor: AppColors.brightOrange,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
