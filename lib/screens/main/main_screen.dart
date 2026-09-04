import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_management_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    final bool isAdmin = user?.isAnyAdmin ?? false;
    final bool isLeaderAdmin = user?.isLeaderAdmin ?? false;

    // ============================================================
    // PAGES
    //
    // Seller / Buyer:
    // 0 = Dashboard
    // 1 = Products
    // 2 = Orders
    // 3 = Profile
    //
    // Admin:
    // 0 = Dashboard
    // 1 = Products
    // 2 = Orders
    // 3 = Profile
    // 4 = Admin
    // 5 = Manage (Leader Admin only)
    // ============================================================

    final List<Widget> pages = [
      const DashboardScreen(),
      const ProductsScreen(),
      const OrdersScreen(),
      const ProfileScreen(),

      if (isAdmin)
        const AdminDashboardScreen(),

      if (isLeaderAdmin)
        const AdminManagementScreen(),
    ];

    // Make sure the selected index can never go outside
    // the available pages.
    final int safeIndex =
        _currentIndex < pages.length ? _currentIndex : 0;

    return Scaffold(
      // DashboardScreen already has its own AppBar.
      // Other screens can provide their own AppBar.
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,

        onDestinationSelected: (index) {
          if (index >= 0 && index < pages.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },

        destinations: [
          // ------------------------------------------------------
          // HOME / DASHBOARD
          // ------------------------------------------------------

          const NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          // ------------------------------------------------------
          // PRODUCTS
          // ------------------------------------------------------

          const NavigationDestination(
            icon: Icon(
              Icons.inventory_2_outlined,
            ),
            selectedIcon: Icon(
              Icons.inventory_2,
            ),
            label: 'Products',
          ),

          // ------------------------------------------------------
          // ORDERS
          // ------------------------------------------------------

          const NavigationDestination(
            icon: Icon(
              Icons.shopping_cart_outlined,
            ),
            selectedIcon: Icon(
              Icons.shopping_cart,
            ),
            label: 'Orders',
          ),

          // ------------------------------------------------------
          // PROFILE
          // ------------------------------------------------------

          const NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),

          // ------------------------------------------------------
          // ADMIN
          // ------------------------------------------------------

          if (isAdmin)
            const NavigationDestination(
              icon: Icon(
                Icons.admin_panel_settings_outlined,
              ),
              selectedIcon: Icon(
                Icons.admin_panel_settings,
              ),
              label: 'Admin',
            ),

          // ------------------------------------------------------
          // LEADER ADMIN MANAGEMENT
          // ------------------------------------------------------

          if (isLeaderAdmin)
            const NavigationDestination(
              icon: Icon(
                Icons.manage_accounts_outlined,
              ),
              selectedIcon: Icon(
                Icons.manage_accounts,
              ),
              label: 'Manage',
            ),
        ],
      ),
    );
  }
}