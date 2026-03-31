import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/bus_tracking/presentation/providers/bus_tracking_provider.dart';

/// Represents a single route returned from the API.
class DriverRouteOption {
  final String id;
  final String name;
  final String startPoint;
  final String endPoint;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;

  const DriverRouteOption({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  factory DriverRouteOption.fromJson(Map<String, dynamic> json) {
    return DriverRouteOption(
      id: json['id'] as String,
      name: json['name'] as String,
      startPoint: json['startPoint'] as String? ?? '',
      endPoint: json['endPoint'] as String? ?? '',
      startLat: (json['startLat'] as num?)?.toDouble(),
      startLng: (json['startLng'] as num?)?.toDouble(),
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLng: (json['endLng'] as num?)?.toDouble(),
    );
  }
}

class RouteSelectionPage extends ConsumerStatefulWidget {
  const RouteSelectionPage({super.key});

  @override
  ConsumerState<RouteSelectionPage> createState() => _RouteSelectionPageState();
}

class _RouteSelectionPageState extends ConsumerState<RouteSelectionPage> {
  List<DriverRouteOption> _routes = [];
  DriverRouteOption? _selected;
  bool _loading = true;
  String? _error;
  bool _checkingLocation = false;

  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.busNumber != null) {
        ref.read(busTrackingProvider.notifier).loadBusRoute(user.busNumber!);
      }
    });
  }

  Future<void> _fetchRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.get('/drivers/me/routes');
      final List data = response.data as List;
      final routes = data
          .map(
            (e) =>
                DriverRouteOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final lastRouteId = prefs.getString('last_selected_route_id');

      if (mounted) {
        setState(() {
          _routes = routes;
          _loading = false;
        });
        if (routes.length == 1) {
          setState(() => _selected = routes.first);
        } else if (lastRouteId != null) {
          try {
            final lastRoute = routes.firstWhere((r) => r.id == lastRouteId);
            setState(() => _selected = lastRoute);
          } catch (_) {}
        }
      }
    } catch (e) {
      Log.e('RouteSelection: error fetching routes: $e');
      setState(() {
        _error = 'Failed to load routes. Please try again.';
        _loading = false;
      });
    }
  }

  /// Haversine distance in metres between two lat/lng points.
  double _haversineMetres(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> _proceedWithRoute() async {
    if (_selected == null) return;
    setState(() => _checkingLocation = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_route_id', _selected!.id);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? position;
      if (permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      // Geofence check: within 1km of start point
      if (position != null &&
          _selected!.startLat != null &&
          _selected!.startLng != null) {
        final dist = _haversineMetres(
          position.latitude,
          position.longitude,
          _selected!.startLat!,
          _selected!.startLng!,
        );
        if (dist > 1000) {
          if (mounted) {
            setState(() => _checkingLocation = false);
            _showGeofenceError(dist);
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _checkingLocation = false);
        context.go(
          AppRouter.tripTracking,
          extra: {
            'routeId': _selected!.id,
            'routeName': _selected!.name,
            'driverLat': position?.latitude,
            'driverLng': position?.longitude,
          },
        );
      }
    } catch (e) {
      Log.e('RouteSelection: location error: $e');
      if (mounted) {
        setState(() => _checkingLocation = false);
        // Proceed without geofence if location unavailable
        context.go(
          AppRouter.tripTracking,
          extra: {
            'routeId': _selected!.id,
            'routeName': _selected!.name,
            'driverLat': null,
            'driverLng': null,
          },
        );
      }
    }
  }

  void _showGeofenceError(double distMetres) {
    final km = (distMetres / 1000).toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Too Far from Start'),
          ],
        ),
        content: Text(
          'You are ${km}km away from the route start point.\n\n'
          'Please move within 1km of the starting point to begin this trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primaryYellow),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(busTrackingProvider, (previous, next) {
      if (_isRedirecting) return;

      next.whenOrNull(
        loaded: (busRoute) {
          if (busRoute.isTripActive) {
            _isRedirecting = true;
            context.go(
              AppRouter.tripTracking,
              extra: {'routeId': busRoute.id, 'routeName': 'Auto-Resumed Trip'},
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            if (_selected != null) _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(color: AppColors.primaryYellow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/catchy_logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'CatchyBus',
                  style: TextStyle(
                    color: AppColors.darkCharcoal,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showLogoutConfirmation(context, ref),
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.locationRed,
                  size: 20,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.locationRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Route',
            style: TextStyle(
              color: AppColors.darkCharcoal,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose which route you will run today',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(authProvider).user;
              if (user != null &&
                  user.busNumber != null &&
                  user.busNumber!.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCharcoal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        size: 16,
                        color: AppColors.darkCharcoal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned Bus: ${user.busNumber}',
                        style: const TextStyle(
                          color: AppColors.darkCharcoal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchRoutes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route_rounded, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No Routes Assigned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your admin has not assigned any routes to your account yet.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _routes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildRouteCard(_routes[i]),
    );
  }

  Widget _buildRouteCard(DriverRouteOption route) {
    final isSelected = _selected?.id == route.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : const Color(0xFFF1F5F9),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryYellow.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYellow.withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.route_rounded,
                color: isSelected ? AppColors.primaryYellow : Colors.grey[500],
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.darkCharcoal
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStopRow(
                    Icons.trip_origin,
                    route.startPoint,
                    Colors.green,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      width: 2,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                  _buildStopRow(Icons.location_on, route.endPoint, Colors.red),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryYellow,
                      size: 26,
                      key: ValueKey('checked'),
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey[300],
                      size: 26,
                      key: const ValueKey('unchecked'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _checkingLocation ? null : _proceedWithRoute,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkCharcoal,
          disabledBackgroundColor: AppColors.primaryYellow.withValues(
            alpha: 0.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _checkingLocation
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: AppColors.darkCharcoal,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Start Trip  ·  ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: Text(
                      _selected!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(AppRouter.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.locationRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
