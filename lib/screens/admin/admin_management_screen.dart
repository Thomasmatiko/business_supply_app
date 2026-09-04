import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState
    extends State<AdminManagementScreen> {
  final AdminService _adminService = AdminService.instance;
  final AuthService _authService = AuthService.instance;

  List<AppUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final users = await _adminService.getAllUsers();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Failed to load users: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<AppUser> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      return user.id.toLowerCase().contains(query) ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query) ||
          user.adminLevel.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  bool get _canManageUsers {
    return _authService.isAdmin;
  }

  bool _canPromoteUser(AppUser user) {
    return _authService.canPromoteToAdmin(user);
  }

  bool _canEditAdmin(AppUser user) {
    return _authService.canEditAdministrator(user);
  }

  bool _canRemoveAdmin(AppUser user) {
    return _authService.canRemoveAdminUser(user);
  }

  bool _canDeleteUser(AppUser user) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return false;
    }

    if (!currentUser.isAnyAdmin) {
      return false;
    }

    if (user.id == currentUser.id) {
      return false;
    }

    if (user.id == AdminService.leaderAdminId) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    if (currentUser.isNormalAdmin && user.isAnyAdmin) {
      return false;
    }

    return user.isBuyer ||
        user.isSeller ||
        (currentUser.isLeaderAdmin && user.isNormalAdmin);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // PROMOTE
  // ============================================================

  Future<void> _promoteUser(AppUser user) async {
    if (!_canPromoteUser(user)) {
      _showMessage(
        'You are not allowed to promote this user.',
        isError: true,
      );
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Promote User',
      message:
          'Promote ${user.name} to Normal Admin?\n\n'
          'This will give the user administrator privileges.',
      confirmText: 'Promote',
    );

    if (!confirmed) {
      return;
    }

    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Your administrator session is no longer available.',
        isError: true,
      );
      return;
    }

    try {
      await _adminService.promoteUserToAdmin(
        currentUser: currentUser,
        userId: user.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${user.name} is now a Normal Admin.',
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to promote user: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // EDIT ADMIN
  // ============================================================

  Future<void> _editAdmin(AppUser user) async {
    if (!_canEditAdmin(user)) {
      _showMessage(
        'You are not allowed to edit this administrator.',
        isError: true,
      );
      return;
    }

    final result = await Navigator.push<AppUser>(
      context,
      MaterialPageRoute<AppUser>(
        builder: (context) {
          return _EditAdminScreen(user: user);
        },
      ),
    );

    if (result == null) {
      return;
    }

    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Your administrator session is no longer available.',
        isError: true,
      );
      return;
    }

    try {
      await _adminService.updateAdmin(
        currentUser: currentUser,
        updatedAdmin: result,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Administrator updated successfully.',
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to update administrator: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // REMOVE ADMIN
  // ============================================================

  Future<void> _removeAdmin(AppUser user) async {
    if (!_canRemoveAdmin(user)) {
      _showMessage(
        'You are not allowed to remove this administrator.',
        isError: true,
      );
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Remove Admin Privileges',
      message:
          'Remove administrator privileges from ${user.name}?\n\n'
          'The account will not be deleted. '
          'The user will become a buyer.',
      confirmText: 'Remove',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Your administrator session is no longer available.',
        isError: true,
      );
      return;
    }

    try {
      await _adminService.removeAdminPrivileges(
        currentUser: currentUser,
        adminId: user.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Admin privileges removed from ${user.name}.',
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to remove admin privileges: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> _deleteUser(AppUser user) async {
    if (!_canDeleteUser(user)) {
      _showMessage(
        'You are not allowed to remove this user.',
        isError: true,
      );
      return;
    }

    String roleName;

    if (user.isNormalAdmin) {
      roleName = 'Normal Admin';
    } else if (user.isSeller) {
      roleName = 'Seller';
    } else if (user.isBuyer) {
      roleName = 'Buyer';
    } else {
      roleName = user.role;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Remove User',
      message:
          'Are you sure you want to permanently remove '
          '${user.name}?\n\n'
          'User ID: ${user.id}\n'
          'Role: $roleName\n'
          'Email: ${user.email}\n\n'
          'This account will be deleted from the system.',
      confirmText: 'Remove User',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    final performingUser = _authService.currentUser;

    if (performingUser == null) {
      _showMessage(
        'Your administrator session is no longer available.',
        isError: true,
      );
      return;
    }

    try {
      await _adminService.deleteUserAsAdmin(
        targetUserId: user.id,
        currentUser: performingUser,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${user.name} was removed successfully.',
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to remove user: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    )
                  : null,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!_canManageUsers) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to manage users.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final users = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : users.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(
                              context,
                              users[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final totalUsers = _users.length;

    final buyerCount =
        _users.where((user) => user.isBuyer).length;

    final sellerCount =
        _users.where((user) => user.isSeller).length;

    final normalAdminCount =
        _users.where((user) => user.isNormalAdmin).length;

    final leaderCount =
        _users.where((user) => user.isLeaderAdmin).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _authService.isLeaderAdmin
                ? 'Manage buyers, sellers, and administrators.'
                : 'Manage buyers and sellers. '
                    'Administrators are protected.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  icon: Icons.people_outline,
                  label: 'Total Users',
                  value: totalUsers.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  icon: Icons.person_outline,
                  label: 'Buyers',
                  value: buyerCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  icon: Icons.storefront_outlined,
                  label: 'Sellers',
                  value: sellerCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  label: 'Admins',
                  value:
                      (normalAdminCount + leaderCount).toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final color =
        Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by ID, name, email, phone, or role...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'There are no users in the system yet.'
                  : 'No users match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // USER CARD
  // ============================================================

  Widget _buildUserCard(
    BuildContext context,
    AppUser user,
  ) {
    final currentUserId =
        _authService.currentUser?.id;

    final isCurrentUser =
        user.id == currentUserId;

    final isProtected =
        user.isLeaderAdmin ||
        user.id == AdminService.leaderAdminId;

    final canPromote =
        _canPromoteUser(user);

    final canEdit =
        _canEditAdmin(user);

    final canRemoveAdmin =
        _canRemoveAdmin(user);

    final canDelete =
        _canDeleteUser(user);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            _buildBadge(
                              'You',
                              Colors.blue,
                            ),
                          ],
                        ],
                      ),

                      // ------------------------------------------------
                      // USER ID
                      // ------------------------------------------------

                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.id}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),

                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        overflow:
                            TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.phone,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoleBadge(user),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildUserActions(
              context,
              user: user,
              isCurrentUser: isCurrentUser,
              isProtected: isProtected,
              canPromote: canPromote,
              canEdit: canEdit,
              canRemoveAdmin: canRemoveAdmin,
              canDelete: canDelete,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(AppUser user) {
    final color = user.isLeaderAdmin
        ? Colors.deepPurple
        : user.isNormalAdmin
            ? Colors.blue
            : user.isSeller
                ? Colors.orange
                : Colors.grey;

    String initial = '?';

    final trimmedName =
        user.name.trim();

    if (trimmedName.isNotEmpty) {
      initial = trimmedName
          .substring(0, 1)
          .toUpperCase();
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor:
          color.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ============================================================
  // ROLE BADGE
  // ============================================================

  Widget _buildRoleBadge(AppUser user) {
    if (user.isLeaderAdmin) {
      return _buildBadge(
        'Leader Admin',
        Colors.deepPurple,
      );
    }

    if (user.isNormalAdmin) {
      return _buildBadge(
        'Normal Admin',
        Colors.blue,
      );
    }

    if (user.isSeller) {
      return _buildBadge(
        'Seller',
        Colors.orange,
      );
    }

    if (user.isBuyer) {
      return _buildBadge(
        'Buyer',
        Colors.green,
      );
    }

    return _buildBadge(
      user.role,
      Colors.grey,
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // USER ACTIONS
  // ============================================================

  Widget _buildUserActions(
    BuildContext context, {
    required AppUser user,
    required bool isCurrentUser,
    required bool isProtected,
    required bool canPromote,
    required bool canEdit,
    required bool canRemoveAdmin,
    required bool canDelete,
  }) {
    if (isProtected) {
      return Row(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 18,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Leader Admin is permanently protected.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    if (isCurrentUser) {
      return Row(
        children: [
          const Icon(
            Icons.person_outline,
            size: 18,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You cannot remove your own account.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    // ----------------------------------------------------------
    // BUYER / SELLER
    // ----------------------------------------------------------

    if (!user.isAnyAdmin) {
      final actions = <Widget>[];

      if (canPromote) {
        actions.add(
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                _promoteUser(user);
              },
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
              ),
              label: const Text(
                'Promote to Admin',
              ),
            ),
          ),
        );
      }

      if (canPromote && canDelete) {
        actions.add(
          const SizedBox(width: 10),
        );
      }

      if (canDelete) {
        actions.add(
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                _deleteUser(user);
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Remove User',
              ),
            ),
          ),
        );
      }

      if (actions.isNotEmpty) {
        return Row(
          children: actions,
        );
      }

      return _noActionMessage();
    }

    // ----------------------------------------------------------
    // NORMAL ADMIN
    // ----------------------------------------------------------

    if (user.isNormalAdmin) {
      final actions = <Widget>[];

      if (canEdit) {
        actions.add(
          OutlinedButton.icon(
            onPressed: () {
              _editAdmin(user);
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
            label: const Text('Edit'),
          ),
        );
      }

      if (canRemoveAdmin) {
        if (actions.isNotEmpty) {
          actions.add(
            const SizedBox(width: 8),
          );
        }

        actions.add(
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              _removeAdmin(user);
            },
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
            label: const Text(
              'Remove Admin',
            ),
          ),
        );
      }

      if (canDelete) {
        if (actions.isNotEmpty) {
          actions.add(
            const SizedBox(width: 8),
          );
        }

        actions.add(
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              _deleteUser(user);
            },
            icon: const Icon(
              Icons.delete_outline,
            ),
            label: const Text('Delete'),
          ),
        );
      }

      if (actions.isNotEmpty) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions,
          ),
        );
      }
    }

    return _noActionMessage();
  }

  // ============================================================
  // NO ACTION MESSAGE
  // ============================================================

  Widget _noActionMessage() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _authService.isNormalAdmin
                ? 'Normal Admins cannot manage other administrators.'
                : 'No actions available.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// EDIT ADMIN SCREEN
// ==================================================================

class _EditAdminScreen extends StatefulWidget {
  final AppUser user;

  const _EditAdminScreen({
    required this.user,
  });

  @override
  State<_EditAdminScreen> createState() =>
      _EditAdminScreenState();
}

class _EditAdminScreenState
    extends State<_EditAdminScreen> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nameController;

  late final TextEditingController
      _emailController;

  late final TextEditingController
      _phoneController;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
      text: widget.user.name,
    );

    _emailController =
        TextEditingController(
      text: widget.user.email,
    );

    _phoneController =
        TextEditingController(
      text: widget.user.phone,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedUser =
        widget.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text
          .trim()
          .toLowerCase(),
      phone: _phoneController.text.trim(),
    );

    Navigator.of(context).pop(updatedUser);
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? _validateName(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter the name';
    }

    if (value.trim().length < 2) {
      return 'Name is too short';
    }

    return null;
  }

  String? _validateEmail(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter the email';
    }

    final email = value.trim();

    final regex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? _validatePhone(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter the phone number';
    }

    if (value.trim().length < 7) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Administrator',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Normal Admin',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update the administrator account information.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ------------------------------------------------
              // USER ID - READ ONLY
              // ------------------------------------------------

              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                  ),
                ),
                child: Text(
                  widget.user.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                textInputAction:
                    TextInputAction.next,
                validator: _validateName,
                decoration:
                    const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                validator: _validateEmail,
                decoration:
                    const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType:
                    TextInputType.phone,
                textInputAction:
                    TextInputAction.done,
                validator: _validatePhone,
                decoration:
                    const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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