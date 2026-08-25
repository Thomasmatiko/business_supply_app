import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/auth_service.dart';

import '../screens/admin/admin_management_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/orders/create_order_screen.dart';
import '../screens/public/public_home_screen.dart';
import '../screens/public/public_product_details_screen.dart';
import '../screens/public/public_products_screen.dart';
import '../screens/splash/splash_screen.dart';


class AppRoutes {
  AppRoutes._();

  // ============================================================
  // ROUTE NAMES
  // ============================================================

  /// Application starting/public page.
  static const String splash = '/';

  /// Public home page.
  static const String publicHome = '/public-home';

  /// Public product catalogue.
  static const String publicProducts =
      '/public-products';

  /// Public product details.
  static const String publicProductDetails =
      '/public-product-details';

  /// Login page.
  static const String login = '/login';

  static const String register = '/register';

  /// Authenticated main/dashboard area.
  static const String dashboard = '/dashboard';

  /// Product management.
  static const String products = '/products';



  /// Orders.
  static const String orders = '/orders';

  /// Create a new order.
  static const String createOrder = '/create-order';

  /// User profile.
  static const String profile = '/profile';

  /// Leader Admin management.
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
      //
      // NO LOGIN REQUIRED.
      //
      // Anyone can browse the application.
      // ========================================================

      case publicHome:
        return MaterialPageRoute(
          builder: (_) => const PublicHomeScreen(),
          settings: settings,
        );

      // ========================================================
      // PUBLIC PRODUCTS
      //
      // NO LOGIN REQUIRED.
      //
      // Visitors can browse and search products.
      // ========================================================

      case publicProducts:
        return MaterialPageRoute(
          builder: (_) => const PublicProductsScreen(),
          settings: settings,
        );

      // ========================================================
      // PUBLIC PRODUCT DETAILS
      //
      // NO LOGIN REQUIRED.
      //
      // The visitor can view the product.
      // Login is required only when placing an order.
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
          builder: (_) =>
              PublicProductDetailsScreen(
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
      // AUTHENTICATED DASHBOARD
      // ========================================================

      case dashboard:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      // ========================================================
      // PRODUCT MANAGEMENT
      //
      // Only authenticated users with the correct permission
      // should reach product management.
      //
      // Public users are redirected to Login.
      // ========================================================

      case products:
        if (!AuthService.instance.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginRequiredScreen(
              message:
                  'Please login to manage products.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(
            title: 'Products Screen',
          ),
          settings: settings,
        );

      // ========================================================
     
      //
      // Protected management area.
      // ========================================================

      

       
      // ========================================================
      // ORDERS
      //
      // Protected authenticated area.
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
          builder: (_) => const PlaceholderScreen(
            title: 'Orders Screen',
          ),
          settings: settings,
        );

      // ========================================================
      // CREATE ORDER
      //
      // A user must be logged in before creating an order.
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
      //
      // Protected authenticated area.
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
          builder: (_) => const PlaceholderScreen(
            title: 'Profile Screen',
          ),
          settings: settings,
        );

      // ========================================================
      // ADMIN MANAGEMENT
      //
      // ONLY LEADER ADMIN CAN ACCESS THIS ROUTE.
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
          builder: (_) => const AccessDeniedScreen(),
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
//
// Used when somebody tries to access a protected feature
// without being logged in.
//
// Public browsing does NOT use this screen.
// ============================================================

class LoginRequiredScreen extends StatelessWidget {
  final String message;

  const LoginRequiredScreen({
    super.key,
    this.message =
        'Please login to continue.',
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
                style: const TextStyle(
                  fontSize: 16,
                ),
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
                  icon: const Icon(
                    Icons.login,
                  ),
                  label: const Text(
                    'Login',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Go Back',
                  ),
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
// ACCESS DENIED
// ============================================================

class AccessDeniedScreen
    extends StatelessWidget {
  const AccessDeniedScreen({
    super.key,
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
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Only the Leader Admin can access Admin Management.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Go Back',
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
// ROUTE ERROR
// ============================================================

class RouteErrorScreen
    extends StatelessWidget {
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
                  fontWeight:
                      FontWeight.bold,
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
                child: const Text(
                  'Go Back',
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
// TEMPORARY SCREEN
// ============================================================
//
// Kept temporarily for routes whose full screens have not yet
// been connected.
//
// We can replace these one by one with your existing screens.
// ============================================================

class PlaceholderScreen
    extends StatelessWidget {
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
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}