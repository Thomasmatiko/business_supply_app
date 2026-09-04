
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../dashboard/user_reports_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
        ),
        body: const Center(
          child: Text(
            'Please login to view reports.',
          ),
        ),
      );
    }

    return const UserReportsScreen();
  }
}

