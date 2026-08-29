import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import 'routes.dart';
import 'theme.dart';

class BusinessSupplyApp extends StatefulWidget {
  const BusinessSupplyApp({super.key});

  @override
  State<BusinessSupplyApp> createState() => _BusinessSupplyAppState();
}

class _BusinessSupplyAppState extends State<BusinessSupplyApp> {
  @override
  void initState() {
    super.initState();

    SettingsService.instance.addListener(_settingsChanged);

    SettingsService.instance.loadSettings();
  }

  void _settingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_settingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Business Supply',

      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: settings.themeMode,

      initialRoute: AppRoutes.splash,

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}