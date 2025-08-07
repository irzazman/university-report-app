import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _reportStatusUpdates = true;
  bool _systemAnnouncements = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Time settings
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
  bool _quietHoursEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _reportStatusUpdates = prefs.getBool('report_status_updates') ?? true;
      _systemAnnouncements = prefs.getBool('system_announcements') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      
      // Load quiet hours
      final startHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
      final startMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
      final endHour = prefs.getInt('quiet_hours_end_hour') ?? 8;
      final endMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;
      
      _quietHoursStart = TimeOfDay(hour: startHour, minute: startMinute);
      _quietHoursEnd = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('report_status_updates', _reportStatusUpdates);
    await prefs.setBool('system_announcements', _systemAnnouncements);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('quiet_hours_enabled', _quietHoursEnabled);
    
    // Save quiet hours
    await prefs.setInt('quiet_hours_start_hour', _quietHoursStart.hour);
    await prefs.setInt('quiet_hours_start_minute', _quietHoursStart.minute);
    await prefs.setInt('quiet_hours_end_hour', _quietHoursEnd.hour);
    await prefs.setInt('quiet_hours_end_minute', _quietHoursEnd.minute);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notification_settings.saved'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('notification_settings.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'common.save'.tr(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Settings
          _buildSectionCard(
            'notification_settings.general'.tr(),
            [
              _buildSwitchTile(
                title: 'notification_settings.push_notifications'.tr(),
                subtitle: 'notification_settings.push_notifications_desc'.tr(),
                icon: Icons.notifications,
                value: _pushNotifications,
                onChanged: (value) => setState(() => _pushNotifications = value),
              ),
              _buildSwitchTile(
                title: 'notification_settings.email_notifications'.tr(),
                subtitle: 'notification_settings.email_notifications_desc'.tr(),
                icon: Icons.email,
                value: _emailNotifications,
                onChanged: (value) => setState(() => _emailNotifications = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content Settings
          _buildSectionCard(
            'notification_settings.content'.tr(),
            [
              _buildSwitchTile(
                title: 'notification_settings.report_updates'.tr(),
                subtitle: 'notification_settings.report_updates_desc'.tr(),
                icon: Icons.assignment,
                value: _reportStatusUpdates,
                onChanged: (value) => setState(() => _reportStatusUpdates = value),
              ),
              _buildSwitchTile(
                title: 'notification_settings.system_announcements'.tr(),
                subtitle: 'notification_settings.system_announcements_desc'.tr(),
                icon: Icons.campaign,
                value: _systemAnnouncements,
                onChanged: (value) => setState(() => _systemAnnouncements = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sound & Vibration Settings
          _buildSectionCard(
            'notification_settings.sound_vibration'.tr(),
            [
              _buildSwitchTile(
                title: 'notification_settings.sound'.tr(),
                subtitle: 'notification_settings.sound_desc'.tr(),
                icon: Icons.volume_up,
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              _buildSwitchTile(
                title: 'notification_settings.vibration'.tr(),
                subtitle: 'notification_settings.vibration_desc'.tr(),
                icon: Icons.vibration,
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quiet Hours Settings
          _buildSectionCard(
            'notification_settings.quiet_hours'.tr(),
            [
              _buildSwitchTile(
                title: 'notification_settings.enable_quiet_hours'.tr(),
                subtitle: 'notification_settings.enable_quiet_hours_desc'.tr(),
                icon: Icons.bedtime,
                value: _quietHoursEnabled,
                onChanged: (value) => setState(() => _quietHoursEnabled = value),
              ),
              if (_quietHoursEnabled) ...[
                const SizedBox(height: 8),
                _buildTimeTile(
                  title: 'notification_settings.quiet_start'.tr(),
                  time: _quietHoursStart,
                  onTap: () => _selectTime(true),
                ),
                _buildTimeTile(
                  title: 'notification_settings.quiet_end'.tr(),
                  time: _quietHoursEnd,
                  onTap: () => _selectTime(false),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        secondary: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        time.format(context),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
      });
    }
  }
}