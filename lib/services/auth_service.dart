import '../models/user.dart';
import 'user_service.dart';
import 'activity_log_service.dart';

class AuthService {
  static final AuthService instance =
      AuthService._init();

  AuthService._init();

  final UserService _userService =
      UserService.instance;

  final ActivityLogService _activityLogService =
      ActivityLogService.instance;

  AppUser? _currentUser;

  // ============================================================
  // CURRENT USER
  // ============================================================

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn =>
      _currentUser != null;

  // ============================================================
  // LOGIN SESSION
  // ============================================================

  void setCurrentUser(AppUser user) {
    _currentUser = user;

    // Record successful authentication/session creation.
    _activityLogService.logAction(
      userId: user.id,
      userName: user.name,
      action: 'login',
      description:
          '${user.name} logged into the application.',
      type: 'authentication',
      entityType: 'user',
      entityId: user.id,
    );
  }

  void clearCurrentUser() {
    _currentUser = null;
  }

  Future<void> logout() async {
    final user = _currentUser;

    if (user != null) {
      await _activityLogService.logAction(
        userId: user.id,
        userName: user.name,
        action: 'logout',
        description:
            '${user.name} logged out of the application.',
        type: 'authentication',
        entityType: 'user',
        entityId: user.id,
      );
    }

    clearCurrentUser();
  }

  // ============================================================
  // REFRESH CURRENT USER
  // ============================================================

  Future<AppUser?> refreshCurrentUser() async {
    final current = _currentUser;

    if (current == null) {
      return null;
    }

    try {
      final refreshedUser =
          await _userService.getUserById(
        current.id,
      );

      if (refreshedUser == null) {
        clearCurrentUser();
        return null;
      }

      _currentUser = refreshedUser;

      return refreshedUser;
    } catch (_) {
      return _currentUser;
    }
  }

  Future<AppUser?> getFreshCurrentUser() async {
    return refreshCurrentUser();
  }

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  bool hasRole(String role) {
    return _currentUser?.role
            .trim()
            .toLowerCase() ==
        role.trim().toLowerCase();
  }

  bool get isBuyer =>
      _currentUser?.isBuyer ?? false;

  bool get isSeller =>
      _currentUser?.isSeller ?? false;

  bool get isAdmin =>
      _currentUser?.isAnyAdmin ?? false;

  bool get isNormalAdmin =>
      _currentUser?.isNormalAdmin ?? false;

  bool get isLeaderAdmin =>
      _currentUser?.isLeaderAdmin ?? false;

  // ============================================================
  // GENERAL ACCESS
  // ============================================================

  bool get canAccessPublicDashboard =>
      true;

  bool get canAccessAccount =>
      isLoggedIn;

  // ============================================================
  // ORDER VIEW PERMISSIONS
  // ============================================================

  bool get canViewOrders {
    return isLoggedIn &&
        (isBuyer ||
            isSeller ||
            isAdmin);
  }

  bool get canViewAllOrders =>
      isAdmin;

  // ============================================================
  // PLATFORM PERMISSIONS
  // ============================================================

  bool get canManagePlatform =>
      isLeaderAdmin;

  // ============================================================
  // USER PERMISSIONS
  // ============================================================

  bool get canManageUsers =>
      isAdmin;

  bool get canManageAdmins =>
      isLeaderAdmin;

  // ============================================================
  // ADMIN PERMISSIONS
  // ============================================================

  bool get canCreateAdmin =>
      isLeaderAdmin;

  bool get canEditAdmin =>
      isLeaderAdmin;

  bool get canDeleteAdmin =>
      isLeaderAdmin;

  bool get canRemoveAdmin =>
      isLeaderAdmin;

  // ============================================================
  // ADMIN AUTHORIZATION
  // ============================================================

  bool canPromoteToAdmin(
    AppUser user,
  ) {
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

  bool canEditAdministrator(
    AppUser user,
  ) {
    if (!isLeaderAdmin) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    if (user.id == currentUser?.id) {
      return false;
    }

    return user.isNormalAdmin;
  }

  bool canRemoveAdminUser(
    AppUser user,
  ) {
    if (!isLeaderAdmin) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    if (user.id == currentUser?.id) {
      return false;
    }

    return user.isNormalAdmin;
  }

  bool canPromoteToLeaderAdmin(
    AppUser user,
  ) {
    return false;
  }

  bool isProtectedAdmin(
    AppUser user,
  ) {
    return user.isLeaderAdmin;
  }

  // ============================================================
  // PRODUCT PERMISSIONS
  // ============================================================

  bool get canManageProducts =>
      isAdmin || isSeller;

  bool get canManageAllProducts =>
      isAdmin;

  bool get canCreateProducts =>
      isAdmin || isSeller;

  bool get canEditProducts =>
      isAdmin || isSeller;

  bool get canDeleteProducts =>
      isAdmin || isSeller;

  // ============================================================
  // SELLER PERMISSIONS
  // ============================================================

  bool get canManageSellerAccount =>
      isSeller;

  bool get canManageSellers =>
      isAdmin;

  // ============================================================
  // BUYER PERMISSIONS
  // ============================================================

  bool get canCreateOrders =>
      isBuyer;

  bool get canViewMyOrders =>
      isBuyer || isAdmin;

  // ============================================================
  // ORDER MANAGEMENT
  // ============================================================

  bool get canManageOrders =>
      isAdmin;

  bool get canProcessSellerOrders =>
      isSeller || isAdmin;

  bool get canUpdateAnyOrderStatus =>
      isAdmin;

  // ============================================================
  // PRODUCT OWNERSHIP
  // ============================================================

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