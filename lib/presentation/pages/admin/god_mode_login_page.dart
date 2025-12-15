import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_auth_service.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/pages/admin/god_mode_dashboard_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/core/models/user.dart' show UserRole;

/// God-Mode Admin Login Page
/// Secure login for admin access with god-mode privileges
class GodModeLoginPage extends StatefulWidget {
  const GodModeLoginPage({super.key});

  @override
  State<GodModeLoginPage> createState() => _GodModeLoginPageState();
}

class _GodModeLoginPageState extends State<GodModeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();

  AdminAuthService? _authService;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showTwoFactor = false;
  String? _errorMessage;
  int? _remainingAttempts;
  Duration? _lockoutRemaining;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _initializeAuthService();
  }

  void _checkAdminAccess() {
    // Allow access from login page - check will happen on actual login attempt
    // Only block if user is authenticated but not an admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        if (authState.user.role != UserRole.admin) {
          // User is not an admin - show error and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied: Admin privileges required'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      }
      // If not authenticated, allow them to stay (they can try to login)
    });
  }

  Future<void> _initializeAuthService() async {
    try {
      // Get AdminAuthService directly from GetIt (already registered in injection_container.dart)
      // This avoids the SharedPreferencesCompat casting issue
      if (GetIt.instance.isRegistered<AdminAuthService>()) {
        _authService = GetIt.instance<AdminAuthService>();
      } else {
        // If not registered, show helpful error
        setState(() {
          _errorMessage =
              'AdminAuthService not available. Please ensure dependency injection is initialized.';
        });
        return;
      }

      // Check if already authenticated
      // Defer navigation to after the first frame to avoid Navigator lock errors
      if (_authService!.isAuthenticated()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToDashboard();
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize authentication service: $e';
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate() && _authService != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _authService!.authenticate(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          twoFactorCode:
              _showTwoFactor ? _twoFactorController.text.trim() : null,
        );

        if (result.success && result.session != null) {
          // Defer navigation to after the frame completes to avoid Navigator lock errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _navigateToDashboard();
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result.error ?? 'Authentication failed';
            _remainingAttempts = result.remainingAttempts;
            _lockoutRemaining = result.lockoutRemaining;

            if (result.lockedOut) {
              _showTwoFactor = false;
            }
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error during authentication: $e';
        });
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GodModeDashboardPage(),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Additional protection: Check admin access in build method
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // If user is authenticated but not an admin, show access denied
        if (authState is Authenticated &&
            authState.user.role != UserRole.admin) {
          return Scaffold(
            backgroundColor: AppColors.grey50,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textPrimary,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Access Denied',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Admin privileges required to access God Mode.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Show login form (user can be unauthenticated or authenticated admin)
        return Scaffold(
          backgroundColor: AppColors.grey50,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textPrimary,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Icon(
                          Icons.admin_panel_settings,
                          size: 64,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'God-Mode Admin',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Admin Access',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username';
                            }
                            return null;
                          },
                          enabled: !_isLoading && _lockoutRemaining == null,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                          enabled: !_isLoading && _lockoutRemaining == null,
                        ),
                        const SizedBox(height: 16),

                        // Two-factor code field (conditional)
                        if (_showTwoFactor) ...[
                          TextFormField(
                            controller: _twoFactorController,
                            decoration: InputDecoration(
                              labelText: '2FA Code',
                              prefixIcon: const Icon(Icons.security),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Lockout message
                        if (_lockoutRemaining != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock_clock,
                                        color: AppColors.warning),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Account locked',
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try again in ${_lockoutRemaining!.inMinutes} minutes',
                                  style: TextStyle(color: AppColors.warning),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Remaining attempts
                        if (_remainingAttempts != null &&
                            _remainingAttempts! > 0) ...[
                          Text(
                            '${_remainingAttempts} attempt${_remainingAttempts! > 1 ? 's' : ''} remaining',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Login button
                        ElevatedButton(
                          onPressed: (_isLoading || _lockoutRemaining != null)
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Security notice
                        Text(
                          '⚠️ This is a secure admin interface. All access is logged and monitored.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
