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

import '../../../../core/localization/app_strings.dart';

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
      final busNumber = user?.busNumber;
      if (user != null && busNumber != null) {
        ref.read(busTrackingProvider.notifier).loadBusRoute(busNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final trackingState = ref.watch(busTrackingProvider);
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildStatusCard(trackingState),
                  const SizedBox(height: 24),
                  _buildDriverCard(user),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.get('your_route'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final user = ref.read(authProvider).user;
                          if (user?.busNumber != null) {
                            ref.read(busTrackingProvider.notifier).loadBusRoute(user!.busNumber!);
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.deepBlue),
                        label: Text(
                          strings.get('retry'),
                          style: const TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRouteContent(trackingState),
                  const SizedBox(height: 120), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildStartTripFAB(context, trackingState),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final user = ref.watch(authProvider).user;

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: Text(
          'Hello, ${user?.name?.split(' ').first ?? 'Driver'}',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryYellow.withOpacity(0.06),
                Colors.white,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildLanguageToggle(ref, currentLang),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showLogoutConfirmation(context, ref),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildLanguageToggle(WidgetRef ref, AppLanguage currentLang) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangItem(ref, AppLanguage.english, 'EN', currentLang == AppLanguage.english),
          _buildLangItem(ref, AppLanguage.telugu, 'తె', currentLang == AppLanguage.telugu),
        ],
      ),
    );
  }

  Widget _buildLangItem(WidgetRef ref, AppLanguage lang, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BusTrackingState state) {
    final strings = ref.watch(stringsProvider);
    final bool isTripActive = state.maybeWhen(
      loaded: (busRoute) => busRoute.isTripActive,
      orElse: () => false,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTripActive 
            ? [const Color(0xFF10B981), const Color(0xFF059669)]
            : [AppColors.deepBlue, const Color(0xFF1A3F8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTripActive ? 'ON DUTY' : 'READY TO START',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTripActive ? 'Trip in Progress' : 'No Active Trip',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTripActive ? Icons.directions_bus_rounded : Icons.pause_circle_filled_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTripActive 
                      ? 'Currently tracking your bus location live.'
                      : 'Select a route and start your trip to begin tracking.',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(UserEntity? user) {
    final strings = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: user?.avatar != null && user!.avatar!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(user.avatar!), fit: BoxFit.cover)
                      : null,
                  color: const Color(0xFFF8FAFC),
                ),
                child: user?.avatar == null || user!.avatar!.isEmpty
                    ? const Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Driver',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${strings.get('driver_id')}: ${(user?.id ?? "").toUpperCase()}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showHelpSupportDialog(context, ref),
                icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildModernInfoTile(Icons.directions_bus_rounded, strings.get('bus_number'), user?.busNumber ?? 'N/A', const Color(0xFFF59E0B)),
              const SizedBox(width: 24),
              _buildModernInfoTile(Icons.phone_rounded, strings.get('contact'), user?.phone ?? 'N/A', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutConfirmation(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
                backgroundColor: const Color(0xFFFFF5F5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteContent(BusTrackingState state) {
    final strings = ref.watch(stringsProvider);
    return state.when(
      initial: () => _buildEmptyState(strings.get('initializing'), Icons.hourglass_empty_rounded),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(60.0),
          child: CircularProgressIndicator(color: AppColors.deepBlue, strokeWidth: 3),
        ),
      ),
      loaded: (busRoute) => _buildRouteTimeline(context, busRoute),
      error: (message) => _buildEmptyState('Error: $message', Icons.error_outline_rounded),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFCBD5E1), size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(BuildContext context, BusRoute busRoute) {
    final stops = busRoute.stops;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: List.generate(stops.length, (index) {
          final stop = stops[index];
          final isFirst = index == 0;
          final isLast = index == stops.length - 1;

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: stop.type == StopType.passedStop 
                            ? const Color(0xFF10B981) 
                            : stop.type == StopType.skippedStop 
                                ? const Color(0xFFEF4444)
                                : (isFirst || stop.type == StopType.currentLocation) 
                                    ? AppColors.deepBlue 
                                    : isLast 
                                        ? AppColors.brightOrange 
                                        : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (stop.type == StopType.passedStop || stop.type == StopType.skippedStop || isFirst || isLast || stop.type == StopType.currentLocation) 
                              ? Colors.transparent 
                              : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: stop.type == StopType.passedStop
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : stop.type == StopType.skippedStop
                            ? const Icon(Icons.close_rounded, color: Colors.white, size: 14)
                            : (isFirst || stop.type == StopType.currentLocation)
                              ? const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 14)
                              : isLast 
                                ? const Icon(Icons.location_on_rounded, color: Colors.white, size: 14)
                                : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle)),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: stop.type == StopType.passedStop 
                                ? const Color(0xFF10B981).withOpacity(0.5)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: (isFirst || isLast || stop.type == StopType.currentLocation) ? FontWeight.w800 : FontWeight.w600,
                          color: stop.type == StopType.skippedStop 
                              ? const Color(0xFF94A3B8) 
                              : (isFirst || isLast || stop.type == StopType.currentLocation) 
                                  ? const Color(0xFF1E293B) 
                                  : const Color(0xFF475569),
                          decoration: stop.type == StopType.skippedStop ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop.type == StopType.skippedStop 
                            ? 'SKIPPED' 
                            : stop.type == StopType.passedStop
                                ? 'Passed'
                                : stop.type == StopType.currentLocation
                                    ? 'Bus is here'
                                    : isFirst ? 'Starting Point' : isLast ? 'Destination' : 'Intermediate Stop',
                        style: TextStyle(
                          fontSize: 12, 
                          color: stop.type == StopType.skippedStop 
                              ? const Color(0xFFEF4444) 
                              : stop.type == StopType.passedStop
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8), 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStartTripFAB(BuildContext context, BusTrackingState state) {
    final strings = ref.watch(stringsProvider);
    final bool isTripActive = state.maybeWhen(
      loaded: (busRoute) => busRoute.isTripActive,
      orElse: () => false,
    );

    return Container(
      width: double.infinity,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isTripActive 
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFF97316), const Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ElevatedButton(
          onPressed: () => context.go(AppRouter.routeSelection),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isTripActive ? Icons.play_circle_fill_rounded : Icons.navigation_rounded),
              const SizedBox(width: 12),
              Text(
                isTripActive ? strings.get('resume_trip') : strings.get('start_trip_now'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context, WidgetRef ref) {
    final queryController = TextEditingController();
    final user = ref.read(authProvider).user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text('Help & Support', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text('Describe your issue below and we\'ll assist you.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            TextField(
              controller: queryController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your issue details here...',
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.deepBlue, width: 2)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                   if (queryController.text.trim().isEmpty) return;
                   await ref.read(supportProvider.notifier).sendQuery(
                      query: queryController.text.trim(),
                      subject: 'Driver Support Request',
                      email: user?.email,
                    );
                    Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brightOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('Are you sure you want to end your session?', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }
}
