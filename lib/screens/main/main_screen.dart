import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../admin/admin_management_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/products_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/orders_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService =
      AuthService.instance;

  int _currentIndex = 0;

  bool _isRefreshingSession = true;

  @override
  void initState() {
    super.initState();

    _refreshSession();
  }

  // ============================================================
  // REFRESH SESSION
  // ============================================================

  Future<void> _refreshSession() async {
    try {
      await _authService.refreshCurrentUser();
    } catch (e) {
      debugPrint(
        'MainScreen session refresh error: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshingSession = false;
    });
  }

  // ============================================================
  // NAVIGATION ITEMS
  // ============================================================

  List<_NavigationItem> get _navigationItems {
    final user = _authService.currentUser;

    final items = <_NavigationItem>[
      const _NavigationItem(
        label: 'Home',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),

      const _NavigationItem(
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
      ),
    ];

    // ==========================================================
    // ORDERS
    // ==========================================================

    if (_authService.canViewOrders) {
      items.add(
        const _NavigationItem(
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
        ),
      );
    }

    // ==========================================================
    // PROFILE
    // ==========================================================

    items.add(
      const _NavigationItem(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    );

    // ==========================================================
    // ADMIN MANAGEMENT
    //
    // ONLY LEADER ADMIN
    // ==========================================================

    if (user?.isLeaderAdmin ?? false) {
      items.add(
        const _NavigationItem(
          label: 'Admin Management',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
        ),
      );
    }

    return items;
  }

  // ============================================================
  // SCREENS
  // ============================================================

  List<Widget> get _screens {
    final user = _authService.currentUser;

    final screens = <Widget>[
      const DashboardScreen(),

      const ProductsScreen(),
    ];

    // ==========================================================
    // ORDERS
    // ==========================================================

    if (_authService.canViewOrders) {
      screens.add(
        const OrdersScreen(),
      );
    }

    // ==========================================================
    // PROFILE
    // ==========================================================

    screens.add(
      const ProfileScreen(),
    );

    // ==========================================================
    // ADMIN MANAGEMENT
    //
    // ONLY LEADER ADMIN
    // ==========================================================

    if (user?.isLeaderAdmin ?? false) {
      screens.add(
        const AdminManagementScreen(),
      );
    }

    return screens;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onNavigationItemTapped(int index) {
    if (_isRefreshingSession) {
      return;
    }

    final screens = _screens;

    if (index < 0 ||
        index >= screens.length) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isRefreshingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final navigationItems =
        _navigationItems;

    final screens = _screens;

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected:
            _onNavigationItemTapped,
        destinations:
            navigationItems.map(
          (item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon:
                  Icon(item.selectedIcon),
              label: item.label,
            );
          },
        ).toList(),
      ),
    );
  }
}

// ================================================================
// NAVIGATION ITEM
// ================================================================

class _NavigationItem {
  final String label;

  final IconData icon;

  final IconData selectedIcon;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}