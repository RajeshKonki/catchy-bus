import 'package:catchybus/features/auth/domain/entities/user_entity.dart';
import 'package:catchybus/features/auth/presentation/providers/auth_provider.dart';
import 'package:catchybus/features/bus_tracking/domain/entities/bus_route.dart';
import 'package:catchybus/features/bus_tracking/presentation/providers/bus_tracking_provider.dart';
import 'package:catchybus/features/bus_tracking/presentation/state/bus_tracking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/utils/ui_helpers.dart';

class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.busNumber != null) {
        ref.read(busTrackingProvider.notifier).loadBusRoute(user.busNumber!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final trackingState = ref.watch(busTrackingProvider);

    // We removed the Auto-Resume redirect to allow the driver to actually see the 
    // Driver Home page after login or when canceling a trip.
    // Instead, the "Start Trip" button will show "Resume Active Trip" if a trip is already running.

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _buildHeader(context, ref),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildDriverProfile(user),
                  const SizedBox(height: 30),
                  const Text(
                    'YOUR ROUTE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRouteContent(trackingState),
                ],
              ),
            ),
          ),
          _buildStartTripButton(context, trackingState),
        ],
      ),
    );
  }

  Widget _buildRouteContent(BusTrackingState state) {
    return state.when(
      initial: () => const Center(child: Text('Initializing route...')),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      ),
      loaded: (busRoute) => _buildRouteTimeline(context, busRoute),
      error: (message) => Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text('Error: $message', style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () {
                final user = ref.read(authProvider).user;
                if (user?.busNumber != null) {
                  ref
                      .read(busTrackingProvider.notifier)
                      .loadBusRoute(user!.busNumber!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/catchy_logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'CatchyBus',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showHelpSupportDialog(context, ref),
              icon: const Icon(Icons.help_outline, color: Color(0xFF2563EB), size: 24),
              label: const Text(
                'Help',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 20),
            TextButton.icon(
              onPressed: () => _showLogoutConfirmation(context, ref),
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context, WidgetRef ref) {
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
                'Help & Support',
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
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (queryController.text.trim().isEmpty) {
                            UIHelpers.showErrorTooltip(
                              context,
                              'Please enter your query content',
                            );
                            return;
                          }

                          await ref.read(supportProvider.notifier).sendQuery(
                            query: queryController.text.trim(),
                            subject: 'Driver Support Request',
                            email: user?.email,
                          );

                          final newState = ref.read(supportProvider);
                          newState.whenOrNull(
                            success: () {
                              Navigator.of(context).pop();
                              UIHelpers.showSuccessTooltip(
                                context,
                                'Support request sent successfully to college and admin',
                              );
                              ref.read(supportProvider.notifier).reset();
                            },
                            error: (message) {
                              UIHelpers.showErrorTooltip(context, message);
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316), // BrightOrange
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      : const Text('Submit Query', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go(AppRouter.login);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.locationRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverProfile(UserEntity? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
              image: user?.avatar != null && user!.avatar!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.avatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: const Color(0xFFF8FAFC),
            ),
            child: user?.avatar == null || user!.avatar!.isEmpty
                ? const Icon(Icons.person, color: Color(0xFF94A3B8), size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Gunther',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Driver ID: ${user?.id.substring(0, 8).toUpperCase() ?? "DRV-1847"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn('Bus Number', user?.busNumber ?? 'KA-2847'),
                    ),
                    Expanded(
                      child: _buildInfoColumn('Contact', user?.phone ?? '9876543210'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteTimeline(BuildContext context, BusRoute busRoute) {
    final stops = busRoute.stops;

    return Column(
      children: List.generate(stops.length, (index) {
        final stop = stops[index];
        final isLast = index == stops.length - 1;

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index == 0 ? const Color(0xFF2563EB) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == 0 ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: index == 0 ? 0 : 2,
                      ),
                      boxShadow: index == 0 ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                    child: index == 0 
                      ? const Center(child: Icon(Icons.location_on, color: Colors.white, size: 16))
                      : Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 4,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      stop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isLast)
                      const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                    if (!isLast) const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStartTripButton(BuildContext context, BusTrackingState state) {
    // Determine the button text based on whether a trip is already active
    final bool isTripActive = state.maybeWhen(
      loaded: (busRoute) => busRoute.isTripActive,
      orElse: () => false,
    );

    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => context.go(AppRouter.tripTracking),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            isTripActive ? 'Resume Active Trip' : 'Start Trip Now',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
