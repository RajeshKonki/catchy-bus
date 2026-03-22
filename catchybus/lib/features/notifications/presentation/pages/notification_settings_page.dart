import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _proximityAlerts = true;
  bool _tripStartedAlerts = true;
  bool _delayAlerts = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _proximityAlerts = prefs.getBool('notify_proximity') ?? true;
        _tripStartedAlerts = prefs.getBool('notify_trip_started') ?? true;
        _delayAlerts = prefs.getBool('notify_delay') ?? true;
        _soundEnabled = prefs.getBool('notify_sound') ?? true;
        _vibrationEnabled = prefs.getBool('notify_vibration') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Update local state
    setState(() {
      if (key == 'notify_proximity') _proximityAlerts = value;
      if (key == 'notify_trip_started') _tripStartedAlerts = value;
      if (key == 'notify_delay') _delayAlerts = value;
      if (key == 'notify_sound') _soundEnabled = value;
      if (key == 'notify_vibration') _vibrationEnabled = value;
    });

    // Sync with backend
    try {
      await ref.read(authProvider.notifier).updateNotificationSettings({
        'proximity': _proximityAlerts,
        'tripStarted': _tripStartedAlerts,
        'delay': _delayAlerts,
        'sound': _soundEnabled,
      });
    } catch (e) {
      // Quietly fail or show a minor warning
      debugPrint('Failed to sync notification settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppColors.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildSectionHeader('BUS UPDATES'),
            _buildSettingsCard([
              _buildSwitchItem(
                title: 'Proximity Alerts',
                subtitle: 'Notify when bus is near your stop',
                value: _proximityAlerts,
                onChanged: (val) => _updateSetting('notify_proximity', val),
                icon: Icons.location_on_outlined,
              ),
              _buildSwitchItem(
                title: 'Trip Started',
                subtitle: 'Notify when the bus starts its trip',
                value: _tripStartedAlerts,
                onChanged: (val) => _updateSetting('notify_trip_started', val),
                icon: Icons.directions_bus_outlined,
              ),
              _buildSwitchItem(
                title: 'Delay Alerts',
                subtitle: 'Notify if the bus is running late',
                value: _delayAlerts,
                onChanged: (val) => _updateSetting('notify_delay', val),
                icon: Icons.timer_outlined,
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('ALERT PREFERENCES'),
            _buildSettingsCard([
              _buildSwitchItem(
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _soundEnabled,
                onChanged: (val) => _updateSetting('notify_sound', val),
                icon: Icons.volume_up_outlined,
              ),
              _buildSwitchItem(
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: _vibrationEnabled,
                onChanged: (val) => _updateSetting('notify_vibration', val),
                icon: Icons.vibration_outlined,
              ),
            ]),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Note: Changes are applied immediately and will affect future notifications.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.deepBlue, size: 24),
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.brightOrange,
          ),
        ],
      ),
    );
  }
}
