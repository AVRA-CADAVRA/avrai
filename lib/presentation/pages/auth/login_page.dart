import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/routes/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:spots/presentation/pages/admin/god_mode_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            final router = GoRouter.maybeOf(context);
            router?.go(AppRouter.home);
          } else if (state is AuthError) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        48)
                    .clamp(0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo/Title
                      const Icon(
                        Icons.location_on,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SPOTS',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover meaningful places',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        key: const Key('email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        key: const Key('password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed:
                                state is AuthLoading ? null : _handleLogin,
                            child: state is AuthLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white),
                                    ),
                                  )
                                : const Text('Sign In'),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sign Up Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              final router = GoRouter.maybeOf(context);
                              router?.go(AppRouter.signup);
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Demo login button
                      OutlinedButton(
                        onPressed: () {
                          _emailController.text = 'demo@spots.com';
                          _passwordController.text = 'password123';
                          _handleLogin();
                        },
                        child: const Text('🧪 Demo Login'),
                      ),
                      
                      const SizedBox(height: 16),

                      // Admin Login Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GodModeLoginPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings, size: 18),
                        label: const Text('Admin Login'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      context.read<AuthBloc>().add(
            SignInRequested(
              _emailController.text.trim(),
              _passwordController.text,
            ),
          );
    }
  }
}
