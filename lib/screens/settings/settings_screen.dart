
import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings =
        SettingsService.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title:
                const Text('Settings'),
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

              const SizedBox(
                height: 8,
              ),

              Card(
                child:
                    RadioGroup<ThemeMode>(
                  groupValue:
                      settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      settings
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

              const SizedBox(
                height: 24,
              ),

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

              const SizedBox(
                height: 8,
              ),

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

              const SizedBox(
                height: 24,
              ),

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

              const SizedBox(
                height: 8,
              ),

              Card(
                child:
                    SwitchListTile(
                  value: settings
                      .notificationsEnabled,
                  onChanged: settings
                      .setNotificationsEnabled,
                  title: const Text(
                    'Notifications',
                  ),
                  subtitle: const Text(
                    'Enable application notifications',
                  ),
                  secondary: const Icon(
                    Icons
                        .notifications_outlined,
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

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

              const SizedBox(
                height: 8,
              ),

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

