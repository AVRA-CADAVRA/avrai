import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_auth_service.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/pages/admin/god_mode_dashboard_page.dart';

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
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    try {
      final prefs = GetIt.instance<SharedPreferences>();
      _authService = AdminAuthService(prefs);
      
      // Check if already authenticated
      if (_authService!.isAuthenticated()) {
        _navigateToDashboard();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize authentication service';
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
          twoFactorCode: _showTwoFactor ? _twoFactorController.text.trim() : null,
        );

        if (result.success && result.session != null) {
          _navigateToDashboard();
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
    return Scaffold(
      backgroundColor: AppColors.grey50,
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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure Admin Access',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            _showPassword ? Icons.visibility : Icons.visibility_off,
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
                            Icon(Icons.error_outline, color: AppColors.error),
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
                                Icon(Icons.lock_clock, color: AppColors.warning),
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
                    if (_remainingAttempts != null && _remainingAttempts! > 0) ...[
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
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
  }
}

