import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../providers/bus_tracking_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationAlarmsPage extends ConsumerStatefulWidget {
  const LocationAlarmsPage({super.key});

  @override
  ConsumerState<LocationAlarmsPage> createState() => _LocationAlarmsPageState();
}

class _LocationAlarmsPageState extends ConsumerState<LocationAlarmsPage> {
  double _minutesBefore = 10;
  String? _selectedStation;
  bool _showAutostartWarning = true;


  String _calculateTriggerTime(String scheduledTime, int minutesBefore) {
    try {
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

      final triggerHour =
          triggerDateTime.hour > 12
              ? triggerDateTime.hour - 12
              : (triggerDateTime.hour == 0 ? 12 : triggerDateTime.hour);
      final triggerMinute = triggerDateTime.minute.toString().padLeft(2, '0');
      final period = triggerDateTime.hour >= 12 ? 'PM' : 'AM';

      return '${triggerHour.toString().padLeft(2, '0')}:$triggerMinute $period';
    } catch (e) {
      return '--:--';
    }
  }
  // Mutable list for upcoming alarms
  late List<Map<String, dynamic>> _upcomingAlarms;

  @override
  void initState() {
    super.initState();
    _upcomingAlarms = [];
    _loadSyncAlarms();
  }

  Future<void> _loadSyncAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmData = prefs.getString('stop_alarms');
    if (alarmData != null) {
      final Map<String, dynamic> decoded = jsonDecode(alarmData);
      final now = DateTime.now();
      setState(() {
        _upcomingAlarms = decoded.entries.map((e) {
          return {
            'id': e.key,
            'busNumber': '--', // Generic if missing
            'busName': 'College Bus',
            'minutesBefore': e.value,
            'station': e.key,
            'stationCode': e.key.length >= 3 
                ? e.key.substring(0, 3).toUpperCase()
                : e.key.toUpperCase(),
            'date': _formatDate(now),
          };
        }).toList();
      });
    }
  }

  Future<void> _saveSyncAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> syncData = {};
    for (final a in _upcomingAlarms) {
      syncData[a['station']] = a['minutesBefore'];
    }
    await prefs.setString('stop_alarms', jsonEncode(syncData));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        title: const Text(
          'Location Alarms',
          style: TextStyle(
            color: AppColors.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkCharcoal),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.darkCharcoal),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alarm Configuration Card
            _buildConfigurationCard(),
            const SizedBox(height: 20),

            // Autostart Warning
            if (_showAutostartWarning) _buildAutostartWarning(),
            const SizedBox(height: 24),

            // Upcoming Alarms Section
            const Text(
              'Upcoming Alarms',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 12),

            if (_upcomingAlarms.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No upcoming alarms set',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._upcomingAlarms
                  .map((alarm) => _buildAlarmItem(alarm))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightYellow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // When Section
                _buildSectionHeader(Icons.alarm, 'When'),
                const SizedBox(height: 8),
                Text(
                  '${_minutesBefore.toInt()} minutes before',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                Slider(
                  value: _minutesBefore,
                  min: 1,
                  max: 60,
                  activeColor: AppColors.brightOrange,
                  inactiveColor: AppColors.primaryYellow.withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _minutesBefore = value;
                    });
                  },
                ),
                const Divider(color: AppColors.primaryYellow, thickness: 0.5),
                const SizedBox(height: 8),

                // Where Section
                _buildSectionHeader(Icons.location_on_outlined, 'Where'),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showStationPicker(ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryYellow),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedStation ?? 'Select Station',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedStation == null
                                ? Colors.grey
                                : AppColors.darkCharcoal,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.deepBlue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Timing Info Helper
                if (_selectedStation != null)
                  Consumer(
                    builder: (context, ref, child) {
                      final stopsState = ref.watch(collegeStopsProvider);
                      String? scheduledTime;
                      stopsState.maybeWhen(
                        loaded: (stops) {
                          final stop = stops.firstWhere(
                            (s) => s.name == _selectedStation,
                          );
                          scheduledTime = stop.scheduledTime;
                        },
                        orElse: () {},
                      );

                      if (scheduledTime == null) return const SizedBox.shrink();

                      final triggerTime = _calculateTriggerTime(
                        scheduledTime!,
                        _minutesBefore.toInt(),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Set Alarm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                    onPressed: () {
                      if (_selectedStation != null) {
                        setState(() {
                          final user = ref.read(authProvider).user;
                          final busTrackingState = ref.read(busTrackingProvider);
                          
                          String busNumber = user?.busNumber ?? '--';
                          String busName = user?.college ?? 'College Bus';
                          
                          busTrackingState.maybeWhen(
                            loaded: (busRoute) {
                              busNumber = busRoute.busNumber;
                              busName = busRoute.collegeName ?? busName;
                            },
                            orElse: () {},
                          );

                          final now = DateTime.now();
                          
                          _upcomingAlarms.insert(0, {
                            'id': now.toString(),
                            'busNumber': busNumber,
                            'busName': busName,
                            'minutesBefore': _minutesBefore.toInt(),
                            'station': _selectedStation!,
                            'stationCode': _selectedStation!.length >= 3 
                              ? _selectedStation!.substring(0, 3).toUpperCase()
                              : _selectedStation!.toUpperCase(),
                            'date': _formatDate(now),
                          });
                          _saveSyncAlarms();
                        });
                        _showNotification('Alarm set successfully for $_selectedStation!');
                      } else {
                        UIHelpers.showErrorTooltip(context, 'Please select a station first');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brightOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              child: const Text(
                'Set Destination Alarm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.deepBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.deepBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAutostartWarning() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightOrange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brightOrange.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Left accented icon area
              Container(
                width: 70,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.brightOrange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // Right content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable Autostart for Alarms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Required for background reliability',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brightOrange,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'ALLOW',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.darkCharcoal,
              ),
              onPressed: () {
                setState(() {
                  _showAutostartWarning = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmItem(Map<String, dynamic> alarm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus,
                      size: 20,
                      color: AppColors.deepBlue,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alarm['busNumber'],
                        style: const TextStyle(
                          color: AppColors.darkCharcoal,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alarm['busName'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${alarm['minutesBefore']} minutes before arrival',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.locationRed,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              alarm['stationCode'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              alarm['station'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkCharcoal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    Text(
                      alarm['date'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Show'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.deepBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _upcomingAlarms.removeWhere((a) => a['id'] == alarm['id']);
                      _saveSyncAlarms();
                    });
                    _showNotification('Alarm deleted');
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.locationRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStationPicker(WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final stopsState = ref.watch(collegeStopsProvider);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Destination',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlue,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: stopsState.when(
                  initial: () => const Center(child: Text('Loading stops...')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err) => Center(child: Text('Error: $err')),
                  loaded: (stops) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.deepBlue,
                        ),
                        title: Text(
                          stops[index].name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStation = stops[index].name;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotification(String message) {
    UIHelpers.showSuccessTooltip(context, message);
  }
}
