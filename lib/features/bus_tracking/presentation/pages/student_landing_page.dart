import 'dart:async';

import 'package:catchybus/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:catchybus/features/auth/domain/entities/user_entity.dart';
import '../providers/banner_provider.dart';
import '../providers/bus_tracking_provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusDetails();
    });
  }

  void _loadBusDetails() {
    final user = ref.read(authProvider).user;
    _lastLoadedUserId = user?.id;
    final busNumber = user?.busNumber ?? 'Bus No. 10';
    ref.read(busTrackingProvider.notifier).loadBusRoute(busNumber);
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

  Future<void> _selectRouteAndTrack(BuildContext context, String busNumber, String studentName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
    );

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.get(ApiConstants.busRoute(Uri.encodeComponent(busNumber)));
      
      if (!mounted) return;
      Navigator.pop(context); // close loading

      final data = response.data;
      
      // If trip is ACTIVE, just push right away since the route is decided by active trip anyway
      final trips = (data['trips'] as List?) ?? [];
      final activeTrips = trips.where((t) => t['status'] == 'STARTED').toList();
      final bool isTripActive = activeTrips.isNotEmpty;
      
      final busRoutesRaw = data['busRoutes'] as List? ?? [];
      final validRoutes = busRoutesRaw.where((br) => br is Map && br['route'] is Map).toList();

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

      // Generate Forward and Return options for every valid route
      final List<Map<String, dynamic>> routeOptions = [];
      for (var item in validRoutes) {
        final routeObj = item['route'] as Map;
        final routeId = item['routeId']?.toString();
        final routeName = routeObj['name']?.toString() ?? 'Unnamed Route';
        final start = routeObj['startPoint']?.toString() ?? 'Start';
        final end = routeObj['endPoint']?.toString() ?? 'End';

        // Forward Option
        routeOptions.add({
          'routeId': routeId,
          'title': '$routeName (Forward)',
          'subtitle': '$start ➔ $end',
          'isReverse': false,
        });

        // Return Option
        routeOptions.add({
          'routeId': routeId,
          'title': '$routeName (Return)',
          'subtitle': '$end ➔ $start',
          'isReverse': true,
        });
      }

      // Show bottom sheet with ALL available routes (Forward/Reverse)
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Select Route to Track',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: routeOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = routeOptions[index];
                      final routeId = option['routeId'];
                      final isReverse = option['isReverse'] as bool;
                      
                      return ListTile(
                        onTap: () async {
                          Navigator.pop(sheetContext); // Close sheet
                          if (routeId != null) {
                             final prefs = await SharedPreferences.getInstance();
                             await prefs.setString('last_selected_route_id', routeId);
                          }                     
                          if (mounted) {
                            context.push(
                              AppRouter.busTracking,
                              extra: {
                                'busNumber': busNumber,
                                'studentName': studentName,
                                'isReverse': isReverse,
                                'routeId': routeId,
                              },
                            );
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.lightOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isReverse ? Icons.keyboard_return : Icons.route, 
                            color: AppColors.brightOrange
                          ),
                        ),
                        title: Text(option['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(option['subtitle'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bus routes: $e')),
      );
    }
  }

  void _showTripSelectionSheet(BuildContext context, String busNumber, String studentName, List<dynamic> activeTrips) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Multiple Trips Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Please select which trip direction you would like to track.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: activeTrips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trip = activeTrips[index];
                    final isReverse = trip['isReverse'] == true || trip['is_reverse'] == true;
                    final routeName = trip['routeName'] ?? (isReverse ? 'Return Trip' : 'Morning Trip');
                    
                    return ListTile(
                      onTap: () {
                        Navigator.pop(sheetContext); // Close sheet
                        context.push(
                          AppRouter.busTracking,
                          extra: {
                            'busNumber': busNumber,
                            'studentName': studentName,
                            'isReverse': isReverse,
                          },
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isReverse ? AppColors.brightOrange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isReverse ? Icons.home : Icons.school,
                          color: isReverse ? AppColors.brightOrange : Colors.blue,
                        ),
                      ),
                      title: Text(routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        isReverse ? 'Heading towards Residential Areas' : 'Heading towards College',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
                    physics: const BouncingScrollPhysics(),
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
    final user = ref.watch(authProvider).user;
    final busNumber = user?.busNumber ?? 'Select Bus';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              size: 16,
              color: AppColors.deepBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              busNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.darkCharcoal,
          ),
        ],
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
    final busState = ref.watch(busTrackingProvider);
    final user = ref.watch(authProvider).user;

    // Using accounts list if available, otherwise just the single user
    final List<UserEntity> students =
        (user?.accounts != null && user!.accounts!.isNotEmpty)
        ? user.accounts!
        : (user != null ? [user] : []);

    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    return busState.when(
      initial: () => _buildBusDetailsShimmer(),
      loading: () => _buildBusDetailsShimmer(),
      error: (message) => _buildErrorCard(message),
      loaded: (busRoute) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: students.map((student) {
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
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkCharcoal,
                                  ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.busNumber ?? busRoute.busNumber,
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
                                        busRoute.isOnTime
                                            ? Icons.check_circle
                                            : Icons.error,
                                        size: 14,
                                        color: busRoute.isOnTime
                                            ? const Color(0xFF4CAF50)
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        busRoute.isOnTime
                                            ? 'On Time'
                                            : 'Delayed',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: busRoute.isOnTime
                                              ? const Color(0xFF4CAF50)
                                              : Colors.red,
                                        ),
                                      ),
                                      if (busRoute.isTripActive && busRoute.isReverse) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => _selectRouteAndTrack(
                                context,
                                student.busNumber ?? busRoute.busNumber,
                                student.name,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brightOrange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                              ),
                              child: const Text(
                                'Track Bus',
                                style: TextStyle(
                                  fontSize: 14,
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
              );
            }).toList(),
          ),
        );
      },
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
