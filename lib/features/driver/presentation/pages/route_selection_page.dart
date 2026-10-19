import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/ui_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/bus_tracking/presentation/providers/bus_tracking_provider.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_strings.dart';

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

class _RouteSelectionPageState extends ConsumerState<RouteSelectionPage>
    with TickerProviderStateMixin, RouteAware {
  List<DriverRouteOption> _routes = [];
  DriverRouteOption? _selected;
  bool _loading = true;
  String? _error;
  bool _checkingLocation = false;
  bool _isRedirecting = false;
  bool _checkingActiveTrip =
      true; // Shows loading while we check for an active trip

  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();

    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // First, check if there's already an active trip on the server.
    // We do this BEFORE fetching routes so the driver is taken straight
    // to the active trip without ever seeing the route selection UI.
    _checkAndRedirectActiveTrip();
  }

  Future<void> _checkAndRedirectActiveTrip() async {
    final user = ref.read(authProvider).user;
    final busNumber = user?.busNumber;

    if (busNumber == null) {
      if (mounted) setState(() => _checkingActiveTrip = false);
      _fetchRoutes();
      return;
    }

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.get(
        'buses/number/${Uri.encodeComponent(busNumber)}',
      );
      final json = response.data as Map<String, dynamic>?;
      if (json != null) {
        final isTripActive = json['isTripActive'] == true || 
            json['isTripActive']?.toString().toLowerCase() == 'true' || 
            json['is_trip_active'] == true || 
            json['is_trip_active']?.toString().toLowerCase() == 'true';
            
        final trips = json['trips'] as List? ?? [];
        Map<String, dynamic>? activeTrip;
        for (var t in trips) {
          if (t != null && t['status']?.toString().toUpperCase() == 'STARTED') {
            activeTrip = t as Map<String, dynamic>?;
            break;
          }
        }

        if ((isTripActive || activeTrip != null) && mounted && !_isRedirecting) {
          final routeId = activeTrip?['routeId']?.toString() ?? json['routeId']?.toString() ?? '';
          
          String? matchedRouteName;
          if (activeTrip != null && activeTrip['routeName'] != null) {
            matchedRouteName = activeTrip['routeName'].toString();
          } else {
            final routes = json['routes'] as List? ?? [];
            for (var r in routes) {
              if (r != null && r['id']?.toString() == routeId) {
                matchedRouteName = r['name']?.toString();
                break;
              }
            }
          }
          final routeName = matchedRouteName ?? json['route']?['name']?.toString() ?? 'Active Trip';
          
          final isReverse =
              activeTrip?['direction']?.toString().toUpperCase() == 'REVERSE' ||
              activeTrip?['direction']?.toString().toUpperCase() == 'RETURN' ||
              activeTrip?['isReverse'] == true ||
              activeTrip?['is_reverse'] == true ||
              json['isReverse'] == true || 
              json['is_reverse'] == true;

          Log.i(
            'Found active trip on restart: routeId=$routeId, isReverse=$isReverse',
          );
          _isRedirecting = true;
          await context.push(
            AppRouter.tripTracking,
            extra: {
              'routeId': routeId,
              'routeName': routeName,
              'isReverse': isReverse,
              'isResuming': true,
            },
          );
          if (mounted) {
            setState(() {
              _isRedirecting = false;
              _checkingActiveTrip = false;
            });
            _fetchRoutes();
          }
          return;
        }
      }
    } catch (e) {
      Log.w('Could not check for active trip on startup: $e');
    }

    if (mounted) {
      setState(() => _checkingActiveTrip = false);
    }
    _fetchRoutes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final busNumber2 = ref.read(authProvider).user?.busNumber;
      if (busNumber2 != null && !_isRedirecting) {
        ref.read(busTrackingProvider.notifier).loadBusRoute(busNumber2);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    Log.i(
      'Returning to RouteSelectionPage - refreshing routes and resetting state',
    );
    _fetchRoutes();
    if (mounted) {
      setState(() {
        _checkingLocation = false;
        _isRedirecting = false;
        _checkingActiveTrip =
            false; // No active trip if the driver just came back
      });
    }
  }

  Future<void> _proceedToActiveTrip(
    String routeId,
    String routeName,
    bool isReverse,
  ) async {
    if (_isRedirecting || !mounted) return;

    Log.i('Redirecting to existing active trip: $routeId ($routeName)');
    _isRedirecting = true;

    try {
      await context.push(
        AppRouter.tripTracking,
        extra: {
          'routeId': routeId,
          'routeName': routeName,
          'isReverse': isReverse,
          'isResuming': true,
        },
      );
    } catch (e) {
      Log.e('Failed to redirect to active trip: $e');
    } finally {
      if (mounted) setState(() => _isRedirecting = false);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _listAnimController.dispose();
    super.dispose();
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
      String? lastRouteId = prefs.getString('last_selected_route_id');
      if (lastRouteId == 'null' ||
          lastRouteId == 'undefined' ||
          lastRouteId == '') {
        lastRouteId = null;
      }

      if (mounted) {
        setState(() {
          _routes = routes;
          if (lastRouteId != null) {
            _selected = routes.firstWhere(
              (r) => r.id == lastRouteId,
              orElse: () => routes.isNotEmpty ? routes.first : routes[0],
            );
          } else if (routes.isNotEmpty) {
            _selected = routes.first;
          }
          _loading = false;
        });
        _listAnimController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleStartTrip() async {
    if (_selected == null) return;
    _showDirectionSelection(_selected!);
  }

  void _showDirectionSelection(DriverRouteOption route) {
    final strings = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              strings.get('select_direction') ?? 'Select Direction',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.get('direction_hint') ??
                  'Choose your journey direction to start tracking.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _buildDirectionOption(
              icon: Icons.east_rounded,
              title: strings.get('forward_trip') ?? 'Forward Trip',
              subtitle: '${route.startPoint} → ${route.endPoint}',
              color: AppColors.deepBlue,
              onTap: () {
                Navigator.pop(context);
                _verifyAndStartTrip(route, false);
              },
            ),
            const SizedBox(height: 16),
            _buildDirectionOption(
              icon: Icons.west_rounded,
              title: strings.get('return_trip') ?? 'Return Trip',
              subtitle: '${route.endPoint} → ${route.startPoint}',
              color: AppColors.brightOrange,
              onTap: () {
                Navigator.pop(context);
                _verifyAndStartTrip(route, true);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        UIHelpers.showErrorTooltip(context, 'Location services are disabled.');
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // PROMINENT DISCLOSURE: Required by Google Play for background location usage.
      final bool disclosureAccepted = await UIHelpers.showLocationDisclosure(
        context,
        title: 'Background Location Access',
        message:
            'CatchyBus collects location data to track the bus and provide real-time ETA to students, even when the app is closed or not in use. This data is essential for the bus tracking feature to work reliably.',
      );

      if (!disclosureAccepted) {
        if (mounted) {
          UIHelpers.showWarningTooltip(
            context,
            'Location access is required for trip tracking.',
          );
        }
        return false;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          UIHelpers.showErrorTooltip(
            context,
            'Location permissions are denied.',
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        UIHelpers.showErrorTooltip(
          context,
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _verifyAndStartTrip(
    DriverRouteOption route,
    bool isReverse,
  ) async {
    if (!(await _checkPermission())) return;

    setState(() => _checkingLocation = true);

    try {
      Log.i(
        'Starting distance check for ${isReverse ? "RETURN" : "FORWARD"} trip on route ${route.name}',
      );

      // Add a timeout to prevent infinite loading if GPS is struggling
      final position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          ).catchError((e) async {
            Log.w(
              'GPS timeout or error: $e. Falling back to last known position.',
            );
            return await Geolocator.getLastKnownPosition() ??
                Position(
                  latitude: 0,
                  longitude: 0,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0,
                  altitudeAccuracy: 0,
                  headingAccuracy: 0,
                );
          });

      final targetLat = isReverse ? route.endLat : route.startLat;
      final targetLng = isReverse ? route.endLng : route.startLng;

      if (targetLat == null || targetLng == null) {
        Log.w(
          'Route coordinates are missing for ${isReverse ? "end" : "start"} point. Proceeding without geofence.',
        );
        if (mounted) setState(() => _checkingLocation = false);
        await _proceedToTracking(
          position,
          isReverse,
          routeId: route.id,
          routeName: route.name,
        );
        return;
      }

      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      Log.i('Driver distance from target: ${distance.round()}m');

      // 1000m geofence
      if (distance > 1000) {
        if (mounted) {
          setState(() => _checkingLocation = false);
          _showGeofenceError(distance, isReverse, targetLat, targetLng);
        }
      } else {
        Log.i('Distance check passed. Proceeding to tracking...');
        if (mounted) setState(() => _checkingLocation = false);
        await _proceedToTracking(
          position,
          isReverse,
          routeId: route.id,
          routeName: route.name,
        );
      }
    } catch (e) {
      Log.e('Geofence verification error: $e');
      if (mounted) {
        setState(() => _checkingLocation = false);
        UIHelpers.showErrorTooltip(context, 'Error: $e');
      }
    }
  }

  void _showGeofenceError(
    double distance,
    bool isReverse,
    double targetLat,
    double targetLng,
  ) {
    final strings = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.get('too_far') ?? 'Too Far From Start',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isReverse
                    ? 'You are currently ${UIHelpers.formatDistance(distance / 1000)} (${distance.round()}m) away from the return journey starting point.'
                    : 'You are currently ${UIHelpers.formatDistance(distance / 1000)} (${distance.round()}m) away from the trip starting point.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        strings.get('close') ?? 'Close',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _proceedToTracking(
    Position position,
    bool isReverse, {
    String? routeId,
    String? routeName,
  }) async {
    final targetRouteId = routeId ?? _selected?.id;
    final targetRouteName = routeName ?? _selected?.name;

    if (targetRouteId == null || _isRedirecting) {
      Log.w(
        'Cannot proceed to tracking: routeId=$targetRouteId, isRedirecting=$_isRedirecting',
      );
      return;
    }

    _isRedirecting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_route_id', targetRouteId);

      if (!mounted) return;

      await context.push(
        AppRouter.tripTracking,
        extra: {
          'routeId': targetRouteId,
          'routeName': targetRouteName ?? '',
          'driverLat': position.latitude,
          'driverLng': position.longitude,
          'isReverse': isReverse,
        },
      );
    } catch (e) {
      Log.e('Navigation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRedirecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    ref.listen(busTrackingProvider, (previous, next) {
      next.maybeWhen(
        loaded: (route) {
          if (route.isTripActive && !_isRedirecting && mounted) {
            _proceedToActiveTrip(
              route.id,
              route.routeName ?? 'Active Trip',
              route.isReverse,
            );
          }
        },
        orElse: () {},
      );
    });

    final currentLang = ref.watch(languageProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _checkingActiveTrip
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.deepBlue,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isRedirecting
                          ? 'Resuming trip...'
                          : 'Checking status...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  _buildSliverHeader(strings, currentLang),
                  if (_loading)
                    SliverFillRemaining(child: _buildLoadingState(strings))
                  else if (_error != null)
                    SliverFillRemaining(child: _buildErrorState(strings))
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.get('select_route'),
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.get('select_route_hint'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildRouteCard(_routes[index], index),
                          childCount: _routes.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _loading || _error != null || _checkingActiveTrip
            ? null
            : _buildStartButton(strings),
      ),
    );
  }

  Widget _buildSliverHeader(AppStrings strings, AppLanguage currentLang) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFFF8FAFC),
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Image.asset(
        'assets/icons/catchy_logo.png',
        height: 32,
        fit: BoxFit.contain,
      ),
      actions: [
        _buildLangToggle(currentLang),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showLogoutConfirmation(context, ref),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildLangToggle(AppLanguage currentLang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangChip(
            AppLanguage.english,
            'EN',
            currentLang == AppLanguage.english,
          ),
          _buildLangChip(
            AppLanguage.telugu,
            'తె',
            currentLang == AppLanguage.telugu,
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(AppLanguage lang, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppStrings strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.deepBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.get('loading_routes'),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppStrings strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Could not load routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRoutes,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                strings.get('retry'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brightOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(DriverRouteOption route, int index) {
    final isSelected = _selected?.id == route.id;

    return AnimatedBuilder(
      animation: _listAnimController,
      builder: (context, child) {
        final delay = (index * 0.15).clamp(0.0, 0.9);
        final progress = (((_listAnimController.value - delay) / (1.0 - delay))
            .clamp(0.0, 1.0));
        final curvedProgress = Curves.easeOutCubic.transform(progress);
        return Opacity(
          opacity: curvedProgress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curvedProgress)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => setState(() => _selected = route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.deepBlue : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.deepBlue.withOpacity(0.06)
                    : Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.deepBlue.withOpacity(0.1)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: isSelected
                        ? AppColors.deepBlue
                        : const Color(0xFF64748B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.deepBlue
                              : const Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRouteStops(route),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.deepBlue
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.deepBlue
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteStops(DriverRouteOption route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                route.startPoint,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 3.5),
          child: Container(
            width: 1,
            height: 14,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                route.endPoint,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartButton(AppStrings strings) {
    final canStart = _selected != null && !_checkingLocation;
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: canStart
            ? [
                BoxShadow(
                  color: AppColors.deepBlue.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canStart ? _handleStartTrip : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart
              ? AppColors.deepBlue
              : const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _checkingLocation
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    color: canStart ? Colors.white : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    strings.get('start_trip'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: canStart ? Colors.white : const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to end your session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go(AppRouter.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
