import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSelectingImage = false;

  // ============================================================
  // SELECT PROFILE IMAGE
  // ============================================================

  Future<void> _selectProfileImage() async {
    if (_isSelectingImage) {
      return;
    }

    setState(() {
      _isSelectingImage = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;

      if (path == null || path.trim().isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access the selected image.',
            ),
          ),
        );

        return;
      }

      final authService = AuthService.instance;
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        return;
      }

      final updatedUser = currentUser.copyWith(
        profileImage: path,
      );

      await UserService.instance.updateUser(
        updatedUser,
      );

      authService.setCurrentUser(
        updatedUser,
      );

      if (!mounted) {
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile picture updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update profile picture: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingImage = false;
        });
      }
    }
  }

  // ============================================================
  // REMOVE PROFILE IMAGE
  // ============================================================

  Future<void> _removeProfileImage() async {
    final currentUser =
        AuthService.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final shouldRemove =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Remove Profile Picture',
          ),
          content: const Text(
            'Are you sure you want to remove your profile picture?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    try {
      final updatedUser = currentUser.copyWith(
        profileImage: '',
      );

      await UserService.instance.updateUser(
        updatedUser,
      );

      AuthService.instance.setCurrentUser(
        updatedUser,
      );

      if (!mounted) {
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile picture removed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove profile picture: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PROFILE IMAGE MENU
  // ============================================================

  Future<void> _showProfileImageOptions() async {
    final user =
        AuthService.instance.currentUser;

    if (user == null) {
      return;
    }

    final hasImage =
        user.profileImage != null &&
        user.profileImage!.trim().isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                ),
                title: Text(
                  hasImage
                      ? 'Change profile picture'
                      : 'Choose profile picture',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectProfileImage();
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                  ),
                  title: const Text(
                    'Remove profile picture',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.close,
                ),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AuthService.instance.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // ============================================================
  // PROFILE IMAGE WIDGET
  // ============================================================

  Widget _buildProfileImage() {
    final user =
        AuthService.instance.currentUser;

    if (user == null) {
      return const CircleAvatar(
        radius: 55,
        child: Icon(
          Icons.person,
          size: 60,
        ),
      );
    }

    final imagePath = user.profileImage;

    final hasImage =
        imagePath != null &&
        imagePath.trim().isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: 55,
        child: Icon(
          Icons.person,
          size: 60,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
      );
    }

    final file = File(imagePath);

    if (!file.existsSync()) {
      return CircleAvatar(
        radius: 55,
        child: Icon(
          Icons.person,
          size: 60,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
      );
    }

    return CircleAvatar(
      radius: 55,
      backgroundImage: FileImage(file),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No user is currently logged in.',
          ),
        ),
      );
    }

    final hasProfileImage =
        user.profileImage != null &&
        user.profileImage!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==================================================
            // PROFILE PHOTO
            // ==================================================

            GestureDetector(
              onTap: _showProfileImageOptions,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildProfileImage(),

                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: _isSelectingImage
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            TextButton.icon(
              onPressed: _isSelectingImage
                  ? null
                  : _showProfileImageOptions,
              icon: const Icon(
                Icons.camera_alt_outlined,
              ),
              label: Text(
                hasProfileImage
                    ? 'Change Profile Picture'
                    : 'Add Profile Picture',
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // NAME
            // ==================================================

            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ==================================================
            // ROLE
            // ==================================================

            Text(
              user.role.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // USER ID
            // ==================================================

            _ProfileItem(
              icon: Icons.badge_outlined,
              title: 'User ID',
              value: user.id,
            ),

            // ==================================================
            // EMAIL
            // ==================================================

            _ProfileItem(
              icon: Icons.email_outlined,
              title: 'Email',
              value: user.email,
            ),

            // ==================================================
            // PHONE
            // ==================================================

            _ProfileItem(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: user.phone,
            ),

            // ==================================================
            // ROLE
            // ==================================================

            _ProfileItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Role',
              value: user.role,
            ),

            const SizedBox(height: 8),

            // ==================================================
            // SETTINGS
            // ==================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Appearance and application settings',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // LOGOUT
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Logout',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE ITEM
// ============================================================

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }
}