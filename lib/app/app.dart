import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class BusinessSupplyApp extends StatelessWidget {
  const BusinessSupplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Business Supply',

      theme: AppTheme.lightTheme,

      initialRoute: AppRoutes.splash,

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}