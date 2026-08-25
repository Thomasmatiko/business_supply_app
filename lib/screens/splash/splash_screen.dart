import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _startApp();
  }

  void _startApp() {
    Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.publicHome,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 28),

                // App name
                Text(
                  'Business Supply',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Description
                Text(
                  'Manage your business supplies\n'
                  'easily and efficiently.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Loading indicator
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}