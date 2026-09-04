
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/auth_service.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_management_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/orders/create_order_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/public/public_home_screen.dart';
import '../screens/public/public_product_details_screen.dart';
import '../screens/public/public_products_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  // ============================================================
  // ROUTE NAMES
  // ============================================================

  static const String splash = '/';

  static const String publicHome = '/public-home';

  static const String publicProducts = '/public-products';

  static const String publicProductDetails =
      '/public-product-details';

  static const String login = '/login';

  static const String register = '/register';

  static const String dashboard = '/dashboard';

  static const String products = '/products';

  static const String orders = '/orders';

  static const String createOrder = '/create-order';

  static const String profile = '/profile';

  // ============================================================
  // REPORTS
  // ============================================================

  static const String reports = '/reports';

  // ============================================================
  // ADMIN ROUTES
  // ============================================================

  static const String adminDashboard =
      '/admin-dashboard';

  static const String adminManagement =
      '/admin-management';

  // ============================================================
  // ROUTE GENERATOR
  // ============================================================

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      // ========================================================
      // SPLASH
      // ========================================================

      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      // ========================================================
      // PUBLIC HOME
      // ========================================================

      case publicHome:
        return MaterialPageRoute(
          builder: (_) => const PublicHomeScreen(),
          settings: settings,
        );

      // ========================================================
      // PUBLIC PRODUCTS
      // ========================================================

      case publicProducts:
        return MaterialPageRoute(
          builder: (_) => const PublicProductsScreen(),
          settings: settings,
        );

      // ========================================================
      // PUBLIC PRODUCT DETAILS
      // ========================================================

      case publicProductDetails:
        final arguments = settings.arguments;

        if (arguments is! Product) {
          return MaterialPageRoute(
            builder: (_) => const RouteErrorScreen(
              title: 'Product Not Found',
              message:
                  'The selected product could not be loaded.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => PublicProductDetailsScreen(
            product: arguments,
          ),
          settings: settings,
        );

      // ========================================================
      // LOGIN
      // ========================================================

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      // ========================================================
      // DASHBOARD
      // ========================================================

      case dashboard:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access the dashboard.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      // ========================================================
      // PRODUCTS
      // ========================================================

      case products:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access products.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const ProductsScreen(),
          settings: settings,
        );

      // ========================================================
      // ORDERS
      // ========================================================

      case orders:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access your orders.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const OrdersScreen(),
          settings: settings,
        );

      // ========================================================
      // CREATE ORDER
      // ========================================================

      case createOrder:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to place an order.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const CreateOrderScreen(),
          settings: settings,
        );

      // ========================================================
      // PROFILE
      // ========================================================

      case profile:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access your profile.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      // ========================================================
      // REPORTS
      //
      // SELLER + BUYER
      //
      // Admins can also access the same route, but their
      // dedicated Admin Dashboard remains separate.
      // ========================================================

      case reports:
        final user =
            AuthService.instance.currentUser;

        if (user == null) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access reports.',
            ),
            settings: settings,
          );
        }

        if (user.isSeller || user.isBuyer || user.isAnyAdmin) {
          return MaterialPageRoute(
            builder: (_) => const ReportsScreen(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const AccessDeniedScreen(
            message:
                'You do not have permission to access reports.',
          ),
          settings: settings,
        );

      // ========================================================
      // ADMIN DASHBOARD
      //
      // LEADER ADMIN + NORMAL ADMIN
      // ========================================================

      case adminDashboard:
        final user =
            AuthService.instance.currentUser;

        if (user == null) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access the Admin Dashboard.',
            ),
            settings: settings,
          );
        }

        if (user.isAnyAdmin) {
          return MaterialPageRoute(
            builder: (_) =>
                const AdminDashboardScreen(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const AccessDeniedScreen(
            message:
                'Only administrators can access the Admin Dashboard.',
          ),
          settings: settings,
        );

      // ========================================================
      // ADMIN MANAGEMENT
      //
      // LEADER ADMIN ONLY
      // ========================================================

      case adminManagement:
        final user =
            AuthService.instance.currentUser;

        if (user == null) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to access Admin Management.',
            ),
            settings: settings,
          );
        }

        if (user.isLeaderAdmin) {
          return MaterialPageRoute(
            builder: (_) =>
                const AdminManagementScreen(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const AccessDeniedScreen(
            message:
                'Only the Leader Admin can access Admin Management.',
          ),
          settings: settings,
        );

      // ========================================================
      // UNKNOWN ROUTE
      // ========================================================

      default:
        return MaterialPageRoute(
          builder: (_) => const RouteErrorScreen(
            title: 'Page Not Found',
            message:
                'The page you are looking for does not exist.',
          ),
          settings: settings,
        );
    }
  }
}

// ============================================================
// LOGIN REQUIRED SCREEN
// ============================================================

class LoginRequiredScreen extends StatelessWidget {
  final String message;

  const LoginRequiredScreen({
    super.key,
    this.message = 'Please login to continue.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Required'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.login,
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACCESS DENIED SCREEN
// ============================================================

class AccessDeniedScreen extends StatelessWidget {
  final String message;

  const AccessDeniedScreen({
    super.key,
    this.message =
        'You do not have permission to access this page.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ROUTE ERROR SCREEN
// ============================================================

class RouteErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const RouteErrorScreen({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .error,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TEMPORARY PLACEHOLDER
// ============================================================

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
