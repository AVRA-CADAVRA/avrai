import 'package:flutter/material.dart';
import 'package:avrai/core/services/business_account_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/presentation/pages/business/business_onboarding_page.dart';
import 'package:uuid/uuid.dart';

/// Business Signup Page
///
/// Allows businesses to create accounts and set up credentials.
/// After signup, navigates to onboarding flow.
class BusinessSignupPage extends StatefulWidget {
  const BusinessSignupPage({super.key});

  @override
  State<BusinessSignupPage> createState() => _BusinessSignupPageState();
}

class _BusinessSignupPageState extends State<BusinessSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  final _businessAccountService = GetIt.instance<BusinessAccountService>();
  final _supabaseService = GetIt.instance<SupabaseService>();
  final _uuid = const Uuid();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;
  String? _selectedBusinessType;

  final List<String> _businessTypes = [
    'Restaurant',
    'Retail',
    'Service',
    'Entertainment',
    'Technology',
    'Healthcare',
    'Education',
    'Hospitality',
    'Other',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create business account
      // For signup, we create a temporary user ID (will be replaced with actual user after onboarding)
      final tempUserId = _uuid.v4();

      final businessAccount =
          await _businessAccountService.createBusinessAccount(
        creator: UnifiedUser(
          id: tempUserId,
          email: _emailController.text.trim(),
          displayName: _businessNameController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        name: _businessNameController.text.trim(),
        email: _emailController.text.trim(),
        businessType:
            _selectedBusinessType ?? _businessTypeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );

      // Step 2: Create business credentials
      // This would typically be done via Supabase Edge Function or admin tool
      // For now, we'll show a message that credentials need to be set up
      // In production, this would be automated

      if (!_supabaseService.isAvailable) {
        // If Supabase not available, show message about manual setup
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Business account created! Please contact support to set up login credentials.',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        // TODO: Automatically create credentials via Edge Function
        // For now, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Business account created! Please set up login credentials using the admin tool.',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }

      // Step 3: Navigate to onboarding
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessOnboardingPage(
              businessAccount: businessAccount,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating business account: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Create Business Account'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Get Started',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your business account to connect with experts and grow your business',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  hintText: 'Enter your business name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Business Email *',
                  hintText: 'business@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  hintText: 'Create a strong password',
                  border: const OutlineInputBorder(),
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
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  hintText: 'Re-enter your password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Business Type
              DropdownButtonFormField<String>(
                initialValue: _selectedBusinessType,
                decoration: const InputDecoration(
                  labelText: 'Business Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _businessTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Business type is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description (optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Tell us about your business',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Location (optional)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'City, State',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // Website (optional)
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Signup button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text(
                        'Create Business Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Log In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
