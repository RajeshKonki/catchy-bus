import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/bus_route.dart';
import '../../domain/entities/trip_direction.dart';
import 'bus_tracking_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AlarmManager extends StateNotifier<void> {
  final Ref ref;
  final Set<String> _triggeredAlarms = {};
  // New format: { stopName: { 'mins': int, 'direction': 'forward'|'reverse' } }
  // Legacy format: { stopName: int } — migrated on load
  Map<String, Map<String, dynamic>> _activeAlarms = {};

  AlarmManager(this.ref) : super(null) {
    loadAlarms();
  }

  bool get hasActiveAlarms => _activeAlarms.isNotEmpty;

  void clearTriggeredAlarms() {
    _triggeredAlarms.clear();
  }

  void checkAlarms(BusRoute busRoute) {
    _checkAlarms(busRoute);
  }

  void loadAlarms() {
    try {
      final prefs = getIt<SharedPreferences>();
      final String? alarmsJson = prefs.getString('stop_alarms');
      if (alarmsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(alarmsJson);
        _activeAlarms = {};
        decoded.forEach((key, value) {
          if (value is int) {
            // Migrate legacy format: assume forward direction
            _activeAlarms[key] = {'mins': value, 'direction': 'forward'};
          } else if (value is Map) {
            _activeAlarms[key] = Map<String, dynamic>.from(value);
          }
        });
      } else {
        _activeAlarms = {};
      }

      // If alarms were added and we aren't tracking, trigger tracking
      if (_activeAlarms.isNotEmpty) {
        final user = ref.read(authProvider).user;
        if (user != null && user.busNumber != null) {
          ref.read(busTrackingProvider.notifier).startTracking(user.busNumber!);
        }
      }
    } catch (e) {
      debugPrint('Error loading alarms globally: $e');
    }
  }

  void _checkAlarms(BusRoute busRoute) {
    final prefs = getIt<SharedPreferences>();
    final proximityEnabled = prefs.getBool('notify_proximity') ?? true;
    if (!proximityEnabled) return;

    final String currentDirection = busRoute.tripDirection.isReverse ? 'reverse' : 'forward';

    debugPrint('[AlarmManager] _checkAlarms: stops=${busRoute.stops.length}, direction=$currentDirection, alarms=${_activeAlarms.keys.toList()}');

    for (var stop in busRoute.stops) {
      // ── Guard: Never alarm for a stop the bus has already passed or skipped ──
      if (stop.type == StopType.passedStop || stop.type == StopType.skippedStop) {
        continue;
      }

      // Normalize stop name for matching
      final stopNameNormalized = stop.name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      // Find matching alarm entry
      Map<String, dynamic>? alarmEntry;
      for (var entry in _activeAlarms.entries) {
        final keyNormalized = entry.key.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (keyNormalized == stopNameNormalized) {
          alarmEntry = entry.value;
          break;
        }
      }

      if (alarmEntry == null) continue;

      final int? alarmMins = alarmEntry['mins'] as int?;
      final String? alarmDirection = alarmEntry['direction'] as String?;

      // ── Guard: Only fire if direction matches ──
      if (alarmMins == null || alarmDirection != currentDirection) {
        debugPrint('[AlarmManager] Skipping "${stop.name}": alarm direction ($alarmDirection) != current ($currentDirection)');
        continue;
      }

      final eta = stop.estimatedArrivalMinutes;
      debugPrint('[AlarmManager] Checking "${stop.name}": ETA=$eta, threshold=$alarmMins, type=${stop.type}');
      if (eta != null &&
          eta <= alarmMins &&
          !_triggeredAlarms.contains(stop.name)) {
        _triggeredAlarms.add(stop.name);
        debugPrint('[AlarmManager] 🔔 Alarm triggered for "${stop.name}" (ETA $eta <= $alarmMins mins)');
        showAlarmNotification(stopName: stop.name, etaMinutes: eta);
      }
    }
  }
}

final alarmManagerProvider = StateNotifierProvider<AlarmManager, void>((ref) {
  final manager = AlarmManager(ref);

  // Listen to authentication changes to start tracking if user changes
  ref.listen(authProvider, (previous, next) {
    final user = next.user;
    if (user != null && user.busNumber != null && manager.hasActiveAlarms) {
      ref.read(busTrackingProvider.notifier).startTracking(user.busNumber!);
    }
  }, fireImmediately: true);

  return manager;
});
