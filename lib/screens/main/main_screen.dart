
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_management_screen.dart';
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

    final List<Widget> pages = [
      const _HomeTab(),
      const ProductsScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminDashboardScreen(),
      if (isLeaderAdmin) const AdminManagementScreen(),
    ];

    final int safeIndex =
        _currentIndex < pages.length ? _currentIndex : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Business Supply',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: pages[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          if (isLeaderAdmin)
            const NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Manage',
            ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME TAB
// ============================================================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // WELCOME
          // ----------------------------------------------------

          Text(
            user == null
                ? 'Welcome'
                : 'Welcome, ${user.name}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'What would you like to manage today?',
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // ORDERS
          // ----------------------------------------------------

          _HomeFeatureCard(
            context: context,
            icon: Icons.shopping_cart_outlined,
            title: 'Orders',
            description:
                'View and manage your orders.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrdersScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // PRODUCTS
          // ----------------------------------------------------

          _HomeFeatureCard(
            context: context,
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            description:
                'View, add and manage products.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // PROFILE
          // ----------------------------------------------------

          _HomeFeatureCard(
            context: context,
            icon: Icons.person_outline,
            title: 'Profile',
            description:
                'View and manage your profile.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME FEATURE CARD
// ============================================================

class _HomeFeatureCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HomeFeatureCard({
    required this.context,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext _) {
    final color =
        context.theme.colorScheme.primary;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,
                      style: context.theme
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: context.theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// THEME EXTENSION
// ============================================================

extension _BuildContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
}

