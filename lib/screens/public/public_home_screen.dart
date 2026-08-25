import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../services/auth_service.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.instance.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Supply'),
        actions: [
          if (isLoggedIn)
            IconButton(
              tooltip: 'My Account',
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.dashboard,
                );
              },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.login,
                );
              },
              child: const Text('Login'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context),

              const SizedBox(height: 28),

              _buildBrowseProductsCard(context),

              const SizedBox(height: 16),

              _buildBuyCard(context),

              const SizedBox(height: 16),

              _buildSellCard(context),

              const SizedBox(height: 30),

              _buildWhyBusinessSupply(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.storefront,
            size: 52,
          ),
          const SizedBox(height: 16),
          const Text(
            'Business Supply',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Find products, place orders, and grow your business.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.publicProducts,
              );
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseProductsCard(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          radius: 28,
          child: Icon(Icons.inventory_2),
        ),
        title: const Text(
          'Browse Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Explore products available for business supply.',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.publicProducts,
          );
        },
      ),
    );
  }

  Widget _buildBuyCard(BuildContext context) {
  return Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(
        radius: 28,
        child: Icon(Icons.shopping_cart),
      ),
      title: const Text(
        'Buy Products',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: const Text(
        'Choose a product and place an order.',
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        _handleBuy(context);
      },
    ),
  );
}

  Widget _buildSellCard(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          radius: 28,
          child: Icon(Icons.sell),
        ),
        title: const Text(
          'Sell Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Join the platform and sell your products.',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _handleSell(context);
        },
      ),
    );
  }

  void _handleSell(BuildContext context) {
    if (AuthService.instance.isLoggedIn) {
      Navigator.pushNamed(
        context,
        AppRoutes.dashboard,
      );
      return;
    }

    _showLoginRequired(
      context,
      title: 'Login Required',
      message:
          'Please login or create an account before selling products.',
    );
  }


void _handleBuy(BuildContext context) {
  if (AuthService.instance.isLoggedIn) {
    Navigator.pushNamed(
      context,
      AppRoutes.publicProducts,
    );
    return;
  }

  _showLoginRequired(
    context,
    title: 'Login Required',
    message:
        'Please login or create an account before placing an order.',
  );
}
  void _showLoginRequired(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushNamed(
                  context,
                  AppRoutes.register,
                );
              },
              child: const Text('Register'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushNamed(
                  context,
                  AppRoutes.login,
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWhyBusinessSupply() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why Business Supply?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const _FeatureItem(
          icon: Icons.search,
          title: 'Easy Product Discovery',
          description:
              'Browse available business products without creating an account.',
        ),
        const _FeatureItem(
          icon: Icons.shopping_cart_checkout,
          title: 'Simple Ordering',
          description:
              'Find what you need and place your order quickly.',
        ),
        const _FeatureItem(
          icon: Icons.store,
          title: 'Sell Your Products',
          description:
              'Registered users can join the selling side of the platform.',
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}