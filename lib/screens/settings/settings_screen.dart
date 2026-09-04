
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final SettingsService _settings =
      SettingsService.instance;

  final NotificationService _notificationService =
      NotificationService.instance;

  final AuthService _authService =
      AuthService.instance;

  @override
  void initState() {
    super.initState();

    _notificationService.addListener(
      _onNotificationSettingsChanged,
    );

    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _notificationService.removeListener(
      _onNotificationSettingsChanged,
    );

    super.dispose();
  }

  void _onNotificationSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get _userId {
    return _authService.currentUser?.id;
  }

  // ============================================================
  // LOAD NOTIFICATION SETTINGS
  // ============================================================

  Future<void> _loadNotificationSettings() async {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    await _notificationService
        .loadNotificationsEnabled(userId);

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CHANGE NOTIFICATION SETTING
  // ============================================================

  Future<void> _setNotificationsEnabled(
    bool enabled,
  ) async {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    await _notificationService
        .setNotificationsEnabled(
      userId,
      enabled,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Notifications turned on'
              : 'Notifications turned off',
        ),
        duration:
            const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Settings',
            ),
          ),
          body: ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              // ==================================================
              // APPEARANCE
              // ==================================================

              Text(
                'Appearance',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Card(
                child:
                    RadioGroup<ThemeMode>(
                  groupValue:
                      _settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _settings
                          .setThemeMode(
                        value,
                      );
                    }
                  },
                  child: Column(
                    children: [
                      const RadioListTile<
                          ThemeMode>(
                        value:
                            ThemeMode.system,
                        title: Text(
                          'System default',
                        ),
                        subtitle: Text(
                          'Follow your device theme',
                        ),
                        secondary: Icon(
                          Icons
                              .phone_android_outlined,
                        ),
                      ),
                      const Divider(
                        height: 1,
                      ),
                      const RadioListTile<
                          ThemeMode>(
                        value:
                            ThemeMode.light,
                        title: Text(
                          'Light',
                        ),
                        subtitle: Text(
                          'Use light appearance',
                        ),
                        secondary: Icon(
                          Icons
                              .light_mode_outlined,
                        ),
                      ),
                      const Divider(
                        height: 1,
                      ),
                      const RadioListTile<
                          ThemeMode>(
                        value:
                            ThemeMode.dark,
                        title: Text(
                          'Dark',
                        ),
                        subtitle: Text(
                          'Use dark appearance',
                        ),
                        secondary: Icon(
                          Icons
                              .dark_mode_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // ACCOUNT SECURITY
              // ==================================================

              Text(
                'Account Security',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                  ),
                  title: const Text(
                    'Change Password',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Update your account password',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // NOTIFICATIONS
              // ==================================================

              Text(
                'Notifications',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Card(
                child: SwitchListTile(
                  value: _userId != null
                      ? _notificationService
                          .notificationsEnabled(
                          _userId!,
                        )
                      : false,
                  onChanged: _userId == null
                      ? null
                      : _setNotificationsEnabled,
                  title: const Text(
                    'Notifications',
                  ),
                  subtitle: Text(
                    _userId == null
                        ? 'Login to manage notifications'
                        : _notificationService
                                .notificationsEnabled(
                                _userId!,
                              )
                            ? 'Notifications are enabled'
                            : 'Notifications are disabled',
                  ),
                  secondary: Icon(
                    _userId != null &&
                            _notificationService
                                .notificationsEnabled(
                              _userId!,
                            )
                        ? Icons
                            .notifications_active_outlined
                        : Icons
                            .notifications_off_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // ABOUT
              // ==================================================

              Text(
                'About',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(
                        Icons
                            .business_outlined,
                      ),
                      title: Text(
                        'Business Supply',
                      ),
                      subtitle: Text(
                        'Business supply management application',
                      ),
                    ),
                    const Divider(
                      height: 1,
                    ),
                    const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                      ),
                      title: Text(
                        'Version',
                      ),
                      subtitle: Text(
                        '1.0.0',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

