import '../models/user.dart';
import 'user_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();

  AuthService._init();

  final UserService _userService = UserService.instance;

  AppUser? _currentUser;

  // ============================================================
  // CURRENT USER
  // ============================================================

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  // ============================================================
  // LOGIN SESSION
  // ============================================================

  void setCurrentUser(AppUser user) {
    _currentUser = user;
  }

  void clearCurrentUser() {
    _currentUser = null;
  }

  Future<void> logout() async {
    clearCurrentUser();
  }

  // ============================================================
  // REFRESH CURRENT USER
  //
  // Reloads the current user from SQLite.
  //
  // This is important because another administrator may have
  // changed this user's role or admin privileges.
  // ============================================================

  Future<AppUser?> refreshCurrentUser() async {
    final current = _currentUser;

    if (current == null) {
      return null;
    }

    try {
      final refreshedUser =
          await _userService.getUserById(current.id);

      if (refreshedUser == null) {
        clearCurrentUser();
        return null;
      }

      _currentUser = refreshedUser;

      return refreshedUser;
    } catch (e) {
      // Keep the existing session if the database refresh
      // temporarily fails.
      return _currentUser;
    }
  }

  // ============================================================
  // CHECK CURRENT USER
  //
  // Refreshes the session and returns the latest user.
  // ============================================================

  Future<AppUser?> getFreshCurrentUser() async {
    return refreshCurrentUser();
  }

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  bool get isBuyer {
    return _currentUser?.isBuyer ?? false;
  }

  bool get isSeller {
    return _currentUser?.isSeller ?? false;
  }

  bool get isAdmin {
    return _currentUser?.isAnyAdmin ?? false;
  }

  bool get isNormalAdmin {
    return _currentUser?.isNormalAdmin ?? false;
  }

  bool get isLeaderAdmin {
    return _currentUser?.isLeaderAdmin ?? false;
  }

  // ============================================================
  // GENERAL ACCESS
  // ============================================================

  /// Anyone can access the public part of the application.
  ///
  /// This does NOT mean that guests can access protected
  /// management features.
  bool get canAccessPublicDashboard {
    return true;
  }

  /// Authenticated users can access their account area.
  bool get canAccessAccount {
    return isLoggedIn;
  }

  // ============================================================
  // ORDER VIEW PERMISSIONS
  // ============================================================

  /// Buyers, sellers, and administrators can access the
  /// authenticated orders section.
  bool get canViewOrders {
    return isLoggedIn &&
        (isBuyer || isSeller || isAdmin);
  }

  /// Administrators can view all orders.
  ///
  /// Sellers and buyers should only see orders relevant to them.
  bool get canViewAllOrders {
    return isAdmin;
  }

  // ============================================================
  // CUSTOMER PERMISSIONS
  // ============================================================

  /// Only administrators can manage the internal customer
  /// management section.
  

  /// Only administrators can create customers manually.
  
  /// Only administrators can edit customers.
  

  /// Only administrators can delete customers.
  

  // ============================================================
  // PLATFORM PERMISSIONS
  // ============================================================

  /// Leader Admin has complete platform-level authority.
  bool get canManagePlatform {
    return isLeaderAdmin;
  }

  // ============================================================
  // USER PERMISSIONS
  // ============================================================

  /// User management is restricted to administrators.
  ///
  /// Normal Admin can manage operational users according to
  /// the screen-level restrictions.
  bool get canManageUsers {
    return isAdmin;
  }

  /// Only Leader Admin can manage administrators.
  bool get canManageAdmins {
    return isLeaderAdmin;
  }

  // ============================================================
  // ADMIN PERMISSIONS
  // ============================================================

  /// Create a new normal administrator.
  ///
  /// Only Leader Admin can do this.
  bool get canCreateAdmin {
    return isLeaderAdmin;
  }

  /// Edit a normal administrator.
  ///
  /// Only Leader Admin can do this.
  bool get canEditAdmin {
    return isLeaderAdmin;
  }

  /// Remove a normal administrator.
  ///
  /// Only Leader Admin can do this.
  bool get canDeleteAdmin {
    return isLeaderAdmin;
  }

  /// Preferred name for the new non-destructive action.
  ///
  /// This removes administrator privileges rather than deleting
  /// the user account.
  bool get canRemoveAdmin {
    return isLeaderAdmin;
  }

  // ============================================================
  // PRODUCT PERMISSIONS
  // ============================================================

  /// Sellers and administrators can manage products.
  bool get canManageProducts {
    return isAdmin || isSeller;
  }

  /// Administrators can manage products belonging to
  /// different sellers.
  bool get canManageAllProducts {
    return isAdmin;
  }

  /// Sellers and administrators can create products.
  bool get canCreateProducts {
    return isAdmin || isSeller;
  }

  /// Sellers and administrators can edit products.
  bool get canEditProducts {
    return isAdmin || isSeller;
  }

  /// Sellers and administrators can delete products.
  bool get canDeleteProducts {
    return isAdmin || isSeller;
  }

  // ============================================================
  // SELLER PERMISSIONS
  // ============================================================

  /// Sellers can manage their own seller profile/business data.
  bool get canManageSellerAccount {
    return isSeller;
  }

  /// Administrators can manage seller accounts.
  bool get canManageSellers {
    return isAdmin;
  }

  // ============================================================
  // BUYER PERMISSIONS
  // ============================================================

  /// Buyers can place orders.
  bool get canCreateOrders {
    return isBuyer;
  }

  /// Buyers can access their own order history.
  bool get canViewMyOrders {
    return isBuyer || isAdmin;
  }

  // ============================================================
  // ORDER MANAGEMENT
  // ============================================================

  /// Administrators can manage every order.
  bool get canManageOrders {
    return isAdmin;
  }

  /// Sellers can process orders associated with their products.
  bool get canProcessSellerOrders {
    return isSeller || isAdmin;
  }

  /// Administrators can update order status.
  bool get canUpdateAnyOrderStatus {
    return isAdmin;
  }

  // ============================================================
  // ADMIN AUTHORIZATION
  // ============================================================

  /// Determines whether the current user can promote another
  /// user to a NORMAL administrator.
  ///
  /// Public registration can never create an admin.
  /// Only Leader Admin can perform this operation.
  bool canPromoteToAdmin(AppUser user) {
    if (!isLeaderAdmin) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    if (user.id == currentUser?.id) {
      return false;
    }

    return !user.isAnyAdmin;
  }

  /// Determines whether the current user can edit another
  /// administrator.
  bool canEditAdministrator(AppUser user) {
    if (!isLeaderAdmin) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    if (user.id == currentUser?.id) {
      return false;
    }

    return user.isAnyAdmin;
  }

  /// Determines whether the current user can remove another
  /// administrator's privileges.
  bool canRemoveAdminUser(AppUser user) {
    if (!isLeaderAdmin) {
      return false;
    }

    // Never remove your own administrator privileges.
    if (user.id == currentUser?.id) {
      return false;
    }

    // Leader Admin cannot be removed through normal
    // administrator management.
    if (user.isLeaderAdmin) {
      return false;
    }

    return user.isAnyAdmin;
  }

  // ============================================================
  // LEADER ADMIN SECURITY
  // ============================================================

  /// Normal admin cannot become Leader Admin.
  ///
  /// We deliberately keep this disabled in the normal UI.
  /// Leader Admin ownership should be handled separately.
  bool canPromoteToLeaderAdmin(AppUser user) {
    return false;
  }

  /// Determines whether an account is protected from normal
  /// administrator actions.
  bool isProtectedAdmin(AppUser user) {
    return user.isLeaderAdmin;
  }

  // ============================================================
  // PRODUCT OWNERSHIP
  // ============================================================

  /// Determines whether the current user can modify a product.
  ///
  /// Administrators can manage all products.
  /// Sellers can manage only their own products.
  bool canManageProduct({
    required String? sellerId,
  }) {
    if (isAdmin) {
      return true;
    }

    if (!isSeller) {
      return false;
    }

    return sellerId != null &&
        sellerId == currentUser?.id;
  }

  // ============================================================
  // ORDER OWNERSHIP
  // ============================================================

  /// Determines whether the current user can view a specific
  /// order.
  bool canViewOrder({
    required String? buyerId,
    required String? sellerId,
  }) {
    if (isAdmin) {
      return true;
    }

    if (!isLoggedIn) {
      return false;
    }

    if (isBuyer &&
        buyerId != null &&
        buyerId == currentUser?.id) {
      return true;
    }

    if (isSeller &&
        sellerId != null &&
        sellerId == currentUser?.id) {
      return true;
    }

    return false;
  }

  /// Determines whether the current user can manage a specific
  /// order.
  bool canManageOrder({
    required String? buyerId,
    required String? sellerId,
  }) {
    if (isAdmin) {
      return true;
    }

    if (isSeller &&
        sellerId != null &&
        sellerId == currentUser?.id) {
      return true;
    }

    return false;
  }
}