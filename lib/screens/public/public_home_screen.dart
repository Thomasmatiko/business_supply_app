
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../services/auth_service.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.instance.isLoggedIn;

    return Scaffold(
      extendBodyBehindAppBar: true,

      // =========================================================
      // APP BAR
      // =========================================================

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,

        title: const Text(
          'Business Supply',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 5,
              ),
            ],
          ),
        ),

        actions: [
          if (isLoggedIn)
            IconButton(
              tooltip: 'My Account',
              icon: const Icon(
                Icons.account_circle,
                size: 30,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.dashboard,
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.login,
                  );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // =========================================================
      // BODY
      // =========================================================

      body: Stack(
        children: [
          // =====================================================
          // FULL SCREEN BACKGROUND IMAGE
          // =====================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/business_image.PNG',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  color: Colors.blueGrey.shade900,
                  child: const Center(
                    child: Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                );
              },
            ),
          ),

          // =====================================================
          // BACKGROUND DARK OVERLAY
          // =====================================================

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.48,
              ),
            ),
          ),

          // =====================================================
          // CONTENT
          // =====================================================

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                90,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // BUSINESS SUPPLY CARD
                  _buildWelcomeSection(context),

                  const SizedBox(height: 22),

                  // BROWSE PRODUCTS
                  _buildBrowseProductsCard(context),

                  const SizedBox(height: 14),

                  // BUY
                  _buildBuyCard(context),

                  const SizedBox(height: 14),

                  // SELL
                  _buildSellCard(context),

                  const SizedBox(height: 28),

                  // WHY BUSINESS SUPPLY
                  _buildWhyBusinessSupply(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUSINESS SUPPLY CARD
  // ============================================================

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withValues(
          alpha: 0.94,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.30,
            ),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ====================================================
          // CARD IMAGE
          // ====================================================

          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/business_office.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        Icons.business,
                        size: 70,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    );
                  },
                ),

                // Image overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: 0.65,
                        ),
                      ],
                    ),
                  ),
                ),

                // Image label
                const Positioned(
                  left: 20,
                  bottom: 16,
                  child: Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Business Marketplace',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // CARD CONTENT
          // ====================================================

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Supply',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Find products, connect with suppliers, and grow your business with ease.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.publicProducts,
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                    ),
                    label: const Text(
                      'Browse Products',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BROWSE PRODUCTS CARD
  // ============================================================

  Widget _buildBrowseProductsCard(
    BuildContext context,
  ) {
    return _buildActionCard(
      context,
      icon: Icons.inventory_2_outlined,
      title: 'Browse Products',
      subtitle:
          'Explore products available for business supply.',
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.publicProducts,
        );
      },
    );
  }

  // ============================================================
  // BUY PRODUCTS CARD
  // ============================================================

  Widget _buildBuyCard(BuildContext context) {
    return _buildActionCard(
      context,
      icon: Icons.shopping_cart_outlined,
      title: 'Buy Products',
      subtitle:
          'Choose products and place your order quickly.',
      onTap: () {
        _handleBuy(context);
      },
    );
  }

  // ============================================================
  // SELL PRODUCTS CARD
  // ============================================================

  Widget _buildSellCard(BuildContext context) {
    return _buildActionCard(
      context,
      icon: Icons.storefront_outlined,
      title: 'Sell Products',
      subtitle:
          'Join the platform and sell your products.',
      onTap: () {
        _handleSell(context);
      },
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 7,
      shadowColor: Colors.black.withValues(
        alpha: 0.30,
      ),
      color: Colors.white.withValues(
        alpha: 0.94,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 29,
                  color: primaryColor,
                ),
              ),

              const SizedBox(width: 15),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUY HANDLER
  // ============================================================

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

  // ============================================================
  // SELL HANDLER
  // ============================================================

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

  // ============================================================
  // LOGIN REQUIRED DIALOG
  // ============================================================

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
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
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

  // ============================================================
  // WHY BUSINESS SUPPLY
  // ============================================================

  Widget _buildWhyBusinessSupply(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.62,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Business Supply?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

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
      ),
    );
  }
}

// ================================================================
// FEATURE ITEM
// ================================================================

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
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
