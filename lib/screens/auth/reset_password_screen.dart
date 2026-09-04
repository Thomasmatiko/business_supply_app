
import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../services/activity_log_service.dart';
class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  final UserService _userService =
    UserService.instance;

final ActivityLogService _activityLogService =
    ActivityLogService.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================
Future<void> _resetPassword() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final success =
        await _userService.resetPasswordByEmail(
      email: widget.email,
      newPassword: _passwordController.text,
    );

    // ============================================================
    // PASSWORD RESET FAILED
    // ============================================================

    if (!success) {
      await _activityLogService.logActivity(
        action: 'password_reset_failed',
        description:
            'Password reset could not be completed because the account was not found.',
        type: 'authentication',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to reset password. '
            'The account could not be found.',
          ),
        ),
      );

      return;
    }

    // ============================================================
    // PASSWORD RESET SUCCESSFUL
    // ============================================================

    final user =
        await _userService.getUserByEmail(
      widget.email.trim().toLowerCase(),
    );

    if (user != null) {
      await _activityLogService.logAction(
        userId: user.id,
        userName: user.name,
        action: 'password_reset',
        description:
            '${user.name} successfully reset their password.',
        type: 'authentication',
        entityType: 'user',
        entityId: user.id,
      );
    } else {
      await _activityLogService.logActivity(
        action: 'password_reset',
        description:
            'A user successfully reset their password.',
        type: 'authentication',
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password reset successfully. '
          'Please login with your new password.',
        ),
      ),
    );

    // Return to LoginScreen.
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  } catch (e) {
    await _activityLogService.logActivity(
      action: 'password_reset_failed',
      description:
          'An unexpected error occurred during password reset.',
      type: 'authentication',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to reset password: $e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.lock_reset,
                  size: 70,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Create a new password for ${widget.email}',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // ==================================================
                // NEW PASSWORD
                // ==================================================

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                    ),
                    border:
                        const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a new password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // CONFIRM PASSWORD
                // ==================================================

                TextFormField(
                  controller:
                      _confirmPasswordController,
                  obscureText:
                      _obscureConfirmPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border:
                        const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please confirm your password';
                    }

                    if (value !=
                        _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // RESET PASSWORD BUTTON
                // ==================================================

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Reset Password',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
