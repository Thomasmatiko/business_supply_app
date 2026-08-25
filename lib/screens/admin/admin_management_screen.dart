import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState
    extends State<AdminManagementScreen> {
  final UserService _userService = UserService.instance;
  final AuthService _authService = AuthService.instance;

  List<AppUser> _users = <AppUser>[];
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
      final List<AppUser> users =
          await _userService.getUsers();

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
    final String query =
        _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _users;
    }

    return _users.where((AppUser user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // PERMISSION
  // ============================================================

  bool get _canManage {
    return _authService.isLeaderAdmin;
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

    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // CAN PROMOTE
  // ============================================================

  bool _canPromoteUser(AppUser user) {
    if (!_authService.isLeaderAdmin) {
      return false;
    }

    if (user.id == _authService.currentUser?.id) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    if (user.isAnyAdmin) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CAN EDIT
  // ============================================================

  bool _canEditAdmin(AppUser user) {
    if (!_authService.isLeaderAdmin) {
      return false;
    }

    if (user.id == _authService.currentUser?.id) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    return user.isNormalAdmin;
  }

  // ============================================================
  // CAN REMOVE
  // ============================================================

  bool _canRemoveAdmin(AppUser user) {
    if (!_authService.isLeaderAdmin) {
      return false;
    }

    if (user.id == _authService.currentUser?.id) {
      return false;
    }

    if (user.isLeaderAdmin) {
      return false;
    }

    return user.isAnyAdmin;
  }

  // ============================================================
  // PROMOTE USER
  // ============================================================

  Future<void> _promoteUser(AppUser user) async {
    if (!_canPromoteUser(user)) {
      _showMessage(
        'You are not allowed to promote this user.',
        isError: true,
      );
      return;
    }

    final bool confirmed =
        await _showConfirmationDialog(
      title: 'Promote User',
      message:
          'Promote ${user.name} to Normal Admin?\n\n'
          'This will give the user administrator privileges.',
      confirmText: 'Promote',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _userService.promoteToAdmin(user.id);

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

    final AppUser? result =
        await Navigator.push<AppUser>(
      context,
      MaterialPageRoute<AppUser>(
        builder: (BuildContext context) {
          return _EditAdminScreen(user: user);
        },
      ),
    );

    if (result == null) {
      return;
    }

    try {
      await _userService.updateUser(result);

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

    final bool confirmed =
        await _showConfirmationDialog(
      title: 'Remove Admin Privileges',
      message:
          'Remove administrator privileges from ${user.name}?\n\n'
          'The account will NOT be deleted. '
          'The user will remain in the system as a buyer.',
      confirmText: 'Remove',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _userService.removeAdminPrivileges(
        user.id,
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
  // CONFIRMATION
  // ============================================================

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) async {
    final bool? result =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
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
    if (!_canManage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to manage administrators.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final List<AppUser> users =
        _filteredUsers;

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
            onPressed:
                _isLoading ? null : _loadUsers,
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
                    child:
                        CircularProgressIndicator(),
                  )
                : users.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount: users.length,
                          itemBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) {
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
    final int leaderCount = _users
        .where(
          (AppUser user) =>
              user.isLeaderAdmin,
        )
        .length;

    final int normalAdminCount = _users
        .where(
          (AppUser user) =>
              user.isNormalAdmin,
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Administrator Accounts',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage normal administrators without deleting '
            'their accounts or business history.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  icon:
                      Icons.admin_panel_settings,
                  label: 'Normal Admins',
                  value:
                      normalAdminCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  icon: Icons.shield,
                  label: 'Leader Admins',
                  value:
                      leaderCount.toString(),
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
    final Color color =
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
                        fontWeight:
                            FontWeight.bold,
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
        onChanged: (String value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon:
              const Icon(Icons.search),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon:
                      const Icon(Icons.clear),
                ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
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
    final String? currentUserId =
        _authService.currentUser?.id;

    final bool isCurrentUser =
        user.id == currentUserId;

    final bool isProtected =
        user.isLeaderAdmin;

    final bool canPromote =
        _canPromoteUser(user);

    final bool canEdit =
        _canEditAdmin(user);

    final bool canRemove =
        _canRemoveAdmin(user);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
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
                              style:
                                  const TextStyle(
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
                      const SizedBox(height: 4),
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
              isProtected: isProtected,
              canPromote: canPromote,
              canEdit: canEdit,
              canRemove: canRemove,
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
    final Color color = user.isLeaderAdmin
        ? Colors.deepPurple
        : user.isNormalAdmin
            ? Colors.blue
            : user.isSeller
                ? Colors.orange
                : Colors.grey;

    String initial = '?';

    final String trimmedName =
        user.name.trim();

    if (trimmedName.isNotEmpty) {
      initial =
          trimmedName.substring(0, 1).toUpperCase();
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.1),
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
    required bool isProtected,
    required bool canPromote,
    required bool canEdit,
    required bool canRemove,
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
              'Leader Admin is protected.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    if (canPromote) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            _promoteUser(user);
          },
          icon: const Icon(
            Icons.admin_panel_settings_outlined,
          ),
          label: const Text(
            'Promote to Normal Admin',
          ),
        ),
      );
    }

    if (canEdit || canRemove) {
      return Row(
        children: [
          if (canEdit)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _editAdmin(user);
                },
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label:
                    const Text('Edit'),
              ),
            ),
          if (canEdit && canRemove)
            const SizedBox(width: 10),
          if (canRemove)
            Expanded(
              child: OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red,
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
            ),
        ],
      );
    }

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
            'No administrator actions available.',
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

// ============================================================
// EDIT ADMIN SCREEN
// ============================================================

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
  final GlobalKey<FormState> _formKey =
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

    final AppUser updatedUser =
        widget.user.copyWith(
      name: _nameController.text.trim(),
      email:
          _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text.trim(),
    );

    Navigator.of(context).pop(
      updatedUser,
    );
  }

  // ============================================================
  // NAME VALIDATOR
  // ============================================================

  String? _validateName(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter the name';
    }

    if (value.trim().length < 2) {
      return 'Name is too short';
    }

    return null;
  }

  // ============================================================
  // EMAIL VALIDATOR
  // ============================================================

  String? _validateEmail(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter the email';
    }

    final String email =
        value.trim();

    final RegExp regex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // ============================================================
  // PHONE VALIDATOR
  // ============================================================

  String? _validatePhone(String? value) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Administrator'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Normal Admin',
                textAlign:
                    TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update the administrator account information.',
                textAlign:
                    TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller:
                    _nameController,
                textInputAction:
                    TextInputAction.next,
                validator:
                    _validateName,
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
                controller:
                    _emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                validator:
                    _validateEmail,
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
                controller:
                    _phoneController,
                keyboardType:
                    TextInputType.phone,
                textInputAction:
                    TextInputAction.done,
                validator:
                    _validatePhone,
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
                      fontWeight:
                          FontWeight.bold,
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