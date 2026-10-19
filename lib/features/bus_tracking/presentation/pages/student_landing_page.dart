import 'dart:async';

import 'package:url_launcher/url_launcher.dart';
import 'package:catchybus/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:catchybus/features/auth/domain/entities/user_entity.dart';
import '../providers/banner_provider.dart';
import '../providers/bus_tracking_provider.dart';
import '../../domain/entities/bus_route.dart';
import '../../domain/usecases/get_bus_route.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/ui_helpers.dart';

class StudentLandingPage extends ConsumerStatefulWidget {
  const StudentLandingPage({super.key});

  @override
  ConsumerState<StudentLandingPage> createState() => _StudentLandingPageState();
}

class _StudentLandingPageState extends ConsumerState<StudentLandingPage> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  bool isGPSTracking = true;
  int _currentPage = 0;
  Timer? _timer;
  String? _lastLoadedUserId;

  List<String> _bannerUrls = [];

  final Map<String, BusRoute> _studentBusRoutes = {};
  final Map<String, bool> _studentBusLoading = {};
  final Map<String, String?> _studentBusErrors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusDetails();
    });
  }

  Future<void> _loadBusDetails() async {
    final user = ref.read(authProvider).user;
    _lastLoadedUserId = user?.id;

    final List<UserEntity> students =
        (user?.accounts != null && user!.accounts!.isNotEmpty)
        ? user.accounts!
        : (user != null ? [user] : []);

    if (students.isEmpty) return;

    final uniqueBuses = students
        .map((s) => s.busNumber)
        .where((b) => b != null && b.isNotEmpty)
        .cast<String>()
        .toSet();

    final getBusRoute = ref.read(getBusRouteUseCaseProvider);

    for (final busNumber in uniqueBuses) {
      if (mounted) {
        setState(() {
          _studentBusLoading[busNumber] = true;
          _studentBusErrors[busNumber] = null;
        });
      }

      final result = await getBusRoute(GetBusRouteParams(busNumber: busNumber));
      
      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _studentBusErrors[busNumber] = failure.message;
            _studentBusLoading[busNumber] = false;
          });
        },
        (busRoute) {
          setState(() {
            _studentBusRoutes[busNumber] = busRoute;
            _studentBusLoading[busNumber] = false;
          });
        },
      );
    }

    final mainBusNumber = user?.busNumber ?? 'Bus No. 10';
    ref.read(busTrackingProvider.notifier).loadBusRoute(mainBusNumber);
  }

  void _startTimer(int bannerCount) {
    _timer?.cancel();
    if (bannerCount == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= bannerCount) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _selectRouteAndTrack(
    BuildContext context,
    String busNumber,
    String studentName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      ),
    );

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.get(
        ApiConstants.busRoute(Uri.encodeComponent(busNumber)),
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading

      final data = response.data;

      // If trip is ACTIVE, just push right away since the route is decided by active trip anyway
      final trips = (data['trips'] as List?) ?? [];
      final activeTrips = trips.where((t) => t['status'] == 'STARTED').toList();
      final bool isTripActive = activeTrips.isNotEmpty;

      if (isTripActive) {
        final trip = activeTrips[0];
        final bool isReverse =
            trip['isReverse'] == true || trip['is_reverse'] == true;
        String? routeId = trip['routeId']?.toString();
        if (routeId == 'null' || routeId == 'undefined' || routeId == '') {
          routeId = null;
        }
        if (!mounted) return;
        context.push(
          AppRouter.busTracking,
          extra: {
            'busNumber': busNumber,
            'studentName': studentName,
            'isReverse': isReverse,
            'routeId': routeId,
          },
        );
        return;
      }

      final busRoutesRaw = data['busRoutes'] as List? ?? [];
      final validRoutes = busRoutesRaw
          .where((br) => br is Map && br['route'] is Map)
          .toList();

      if (validRoutes.isEmpty) {
        if (!mounted) return;
        context.push(
          AppRouter.busTracking,
          extra: {
            'busNumber': busNumber,
            'studentName': studentName,
            'isReverse': false,
          },
        );
        return;
      }

      // Pick the first route option and determine the direction based on time of day
      final firstRouteItem = validRoutes.first;
      String? routeId = firstRouteItem['routeId']?.toString();
      if (routeId == 'null' || routeId == 'undefined' || routeId == '') {
        routeId = null;
      }

      // If trip is not started by driver, always default to the forward trip route (isReverse = false)
      const bool defaultIsReverse = false;

      if (routeId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_selected_route_id', routeId);
      }

      if (!mounted) return;
      context.push(
        AppRouter.busTracking,
        extra: {
          'busNumber': busNumber,
          'studentName': studentName,
          'isReverse': defaultIsReverse,
          'routeId': routeId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load bus routes: $e')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // 1. Refresh user profile
    await ref.read(authProvider.notifier).refreshProfile();

    // 2. Refresh banners
    await ref.read(bannerProvider.notifier).getBanners();

    // 3. Refresh bus route details
    await _loadBusDetails();

    // Trigger local UI refresh if needed
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Reload bus details whenever the active user switches (e.g. after switching
    // students in the profile screen). busTrackingProvider is recreated by Riverpod
    // when authProvider changes, resetting to initial state — so we must re-trigger
    // the load here rather than relying solely on initState.
    ref.listen<AuthState>(authProvider, (previous, next) {
      final newUserId = next.user?.id;
      if (newUserId != null && newUserId != _lastLoadedUserId) {
        _lastLoadedUserId = newUserId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadBusDetails();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.brightOrange,
          backgroundColor: Colors.white,
          displacement: 40,
          child: Stack(
            children: [
              // Background Ad overlay at the bottom
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildBackgroundAd(),
              ),
              // Foreground Content
              Column(
                children: [
                  Container(
                    color: Colors.white, // Ensure top bar has background
                    child: _buildTopBar(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildBannerCarousel(),
                          const SizedBox(height: 16),
                          _buildStudentCards(),
                          // const SizedBox(height: 16),
                          // _buildQRSection(),
                          // Add extra padding at bottom so user can scroll content past the background ad
                          const SizedBox(height: 140),
                        ],
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

  Widget _buildBackgroundAd() {
    return Opacity(
      opacity: 0.07,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large bus emoji as watermark
          Text('🚌', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          Text(
            'Never miss\na Bus ❤️',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.deepBlue,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart tracking. Safer rides.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.deepBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Bus Selector
          Expanded(child: _buildBusSelector()),
          const SizedBox(width: 8),

          // Tracking Mode Toggle
          _buildTopActionButton(
            isGPSTracking ? Icons.my_location : Icons.network_check,
            () => setState(() => isGPSTracking = !isGPSTracking),
            iconColor: isGPSTracking
                ? AppColors.deepBlue
                : AppColors.brightOrange,
          ),
          const SizedBox(width: 8),

          // Notification button
          _buildTopActionButton(
            Icons.notifications_none_outlined,
            () => context.push(AppRouter.notifications),
          ),
          const SizedBox(width: 8),

          // Help button
          _buildTopActionButton(
            Icons.help_outline,
            () => _showHelpSupportDialog(context, ref),
          ),
          const SizedBox(width: 8),

          // Profile button
          _buildTopActionButton(
            Icons.person,
            () => context.push(AppRouter.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildBusSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/icons/catchy_logo.png',
        height: 32,
        fit: BoxFit.contain,
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context, WidgetRef ref) {
    final queryController = TextEditingController();
    final user = ref.read(authProvider).user;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final supportState = ref.watch(supportProvider);
            final isLoading = supportState.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Help & Support',
                style: TextStyle(
                  color: AppColors.deepBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Have a question or facing an issue? Send us a message and we will get back to you.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: queryController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue details here...',
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
                        borderSide: const BorderSide(
                          color: AppColors.deepBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => _openPrivacyPolicy(),
                      child: const Text(
                        'View Privacy Policy',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.deepBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (queryController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter your query content',
                                ),
                              ),
                            );
                            return;
                          }

                          await ref
                              .read(supportProvider.notifier)
                              .sendQuery(
                                query: queryController.text.trim(),
                                subject: 'Student/Parent Support Request',
                                email: user?.email,
                              );

                          final newState = ref.read(supportProvider);
                          newState.whenOrNull(
                            success: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Support request sent successfully to college and admin',
                                  ),
                                ),
                              );
                              ref.read(supportProvider.notifier).reset();
                            },
                            error: (message) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brightOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Query',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopActionButton(
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.deepBlue, size: 20),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://catchybustrack.netlify.app/privacy-policy';
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error opening privacy policy: $e');
    }
  }

  Widget _buildBannerCarousel() {
    final bannerState = ref.watch(bannerProvider);

    return bannerState.when(
      initial: () => _buildBannerShimmer(),
      loading: () => _buildBannerShimmer(),
      error: (message) => _buildErrorBanner(),
      loaded: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Restart timer with correct count if it's the first load
        if (_bannerUrls.length != banners.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _bannerUrls = banners.map((e) => e.imageUrl).toList();
            });
            _startTimer(banners.length);
          });
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        banners[index].imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.lightOrange,
                          child: const Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildSingleShimmer();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.brightOrange
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Failed to load banners',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildStudentCards() {
    final user = ref.watch(authProvider).user;

    // Using accounts list if available, otherwise just the single user
    final List<UserEntity> students =
        (user?.accounts != null && user!.accounts!.isNotEmpty)
        ? user.accounts!
        : (user != null ? [user] : []);

    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    final uniqueBuses = students
        .map((s) => s.busNumber)
        .where((b) => b != null && b.isNotEmpty)
        .cast<String>()
        .toSet();

    final bool anyLoading = uniqueBuses.any((b) => _studentBusLoading[b] == true);
    if (anyLoading && _studentBusRoutes.isEmpty) {
      return _buildBusDetailsShimmer();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: students.map((student) {
          final bool isInactive = (student.status ?? '').toUpperCase() == 'INACTIVE';
          final String? busNumber = student.busNumber;
          final bool hasBus = busNumber != null && busNumber.isNotEmpty;
          
          final BusRoute? busRoute = hasBus ? _studentBusRoutes[busNumber] : null;
          final bool isLoading = hasBus && (_studentBusLoading[busNumber] == true);
          final String? errorMsg = hasBus ? _studentBusErrors[busNumber] : null;

          final bool studentIsBoarded = () {
            if (busRoute == null || !busRoute.isTripActive) return false;
            for (final s in busRoute.students) {
              final sName = (s['name'] as String? ?? '')
                  .toLowerCase()
                  .trim();
              final uName = (student.name as String? ?? '')
                  .toLowerCase()
                  .trim();
              if (sName == uName) {
                return (s['isBoarded'] ?? false) == true;
              }
            }
            return false;
          }();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                children: [
                  // Top section: User Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar setup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: student.avatar != null
                            ? Image.network(
                                student.avatar!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      // Names and Details
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
                                if (isInactive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Inactive',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (studentIsBoarded) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        4,
                                      ),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(
                                          0.5,
                                        ),
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
                            const SizedBox(height: 2),
                            Text(
                              student.studentId != null &&
                                      student.studentId!.isNotEmpty
                                  ? 'ID: ${student.studentId}'
                                  : (student.id.isNotEmpty
                                        ? 'ID: ${student.id}'
                                        : 'ID: Not Available'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.college ?? 'College info unavailable',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.darkCharcoal,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // QR Code Icon
                      InkWell(
                        onTap: () {
                          context.push(AppRouter.studentQr, extra: student);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.qr_code_2,
                            size: 36,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  // Bottom Section: Bus Info & Action Button
                  _buildBottomBusSection(
                    student: student,
                    isInactive: isInactive,
                    hasBus: hasBus,
                    busNumber: busNumber,
                    busRoute: busRoute,
                    isLoading: isLoading,
                    errorMsg: errorMsg,
                    studentIsBoarded: studentIsBoarded,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBusSection({
    required UserEntity student,
    required bool isInactive,
    required bool hasBus,
    required String? busNumber,
    required BusRoute? busRoute,
    required bool isLoading,
    required String? errorMsg,
    required bool studentIsBoarded,
  }) {
    if (isInactive) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                busNumber ?? 'No Bus Assigned',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildTrackButton(
            disabled: true,
            tooltip: 'Inactive student account. Please contact your college admin.',
          ),
        ],
      );
    }

    if (!hasBus) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Bus Assigned',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Not Available',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildTrackButton(
            disabled: true,
            tooltip: 'No bus assigned to this student.',
          ),
        ],
      );
    }

    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                busNumber!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brightOrange,
                ),
              ),
            ],
          ),
          _buildTrackButton(disabled: true),
        ],
      );
    }

    if (errorMsg != null || busRoute == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                busNumber!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    errorMsg ?? 'Failed to load details',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          _buildTrackButton(
            disabled: false,
            onPressed: () => _loadBusDetails(),
            label: 'Retry',
          ),
        ],
      );
    }

    // Loaded state
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              busRoute.busNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      studentIsBoarded
                          ? Icons.check_circle
                          : (!busRoute.isTripActive
                                ? (busRoute.tripStatus == 'COMPLETED'
                                      ? Icons.check_circle
                                      : Icons.info_outline)
                                : (busRoute.isOnTime
                                      ? Icons.check_circle
                                      : Icons.error)),
                      size: 14,
                      color: studentIsBoarded
                          ? const Color(0xFF4CAF50)
                          : (!busRoute.isTripActive
                                ? (busRoute.tripStatus == 'COMPLETED'
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey)
                                : (busRoute.isOnTime
                                      ? const Color(0xFF4CAF50)
                                      : Colors.red)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      studentIsBoarded
                          ? 'Onboarded'
                          : (!busRoute.isTripActive
                                ? (busRoute.tripStatus == 'COMPLETED'
                                      ? 'Completed'
                                      : 'Not Started')
                                : (busRoute.isOnTime
                                      ? 'On Time'
                                      : 'Delayed')),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: studentIsBoarded
                            ? const Color(0xFF4CAF50)
                            : (!busRoute.isTripActive
                                  ? (busRoute.tripStatus == 'COMPLETED'
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey.shade700)
                                  : (busRoute.isOnTime
                                        ? const Color(0xFF4CAF50)
                                        : Colors.red)),
                      ),
                    ),
                    if (busRoute.isTripActive && busRoute.isReverse) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brightOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RETURN TRIP',
                          style: TextStyle(
                            color: AppColors.brightOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (busRoute.isTripActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Next: ${busRoute.nextStop}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        _buildTrackButton(
          disabled: false,
          onPressed: () => _selectRouteAndTrack(
            context,
            busRoute.busNumber,
            student.name,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackButton({
    required bool disabled,
    VoidCallback? onPressed,
    String label = 'Track Bus',
    String? tooltip,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: disabled
            ? (tooltip != null
                ? () {
                    UIHelpers.showErrorTooltip(context, tooltip);
                  }
                : null)
            : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey.shade300 : AppColors.brightOrange,
          foregroundColor: disabled ? Colors.grey.shade600 : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBusDetailsShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Cannot fetch bus details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadBusDetails,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Student Digital Pass',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    Text(
                      'Scan while boarding',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.deepBlue,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  width: 200,
                  color: Colors.white,
                  child: const Icon(
                    Icons.qr_code_rounded,
                    size: 160,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryYellow.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.verified_user,
                        size: 14,
                        color: AppColors.deepBlue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Student Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBlue,
                        ),
                      ),
                    ],
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
