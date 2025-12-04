import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/auth/login_page.dart';
import 'package:spots/presentation/pages/onboarding/onboarding_page.dart';
import 'package:spots/presentation/pages/home/home_page.dart';
import 'package:spots/data/datasources/local/onboarding_completion_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isOnboardingCompleted = false;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Wait for auth state to be available - check multiple times if needed
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        
        // If authenticated, check onboarding with user ID
        if (authState is Authenticated) {
          final isCompleted = await OnboardingCompletionService.isOnboardingCompleted(authState.user.id);
          if (mounted) {
            setState(() {
              _isOnboardingCompleted = isCompleted;
              _isCheckingOnboarding = false;
            });
          }
          return; // Exit once we have a result
        }
        
        // If not authenticated yet, continue waiting
        if (authState is AuthInitial || authState is AuthLoading) {
          continue; // Keep waiting
        }
      } catch (e) {
        // Continue trying
      }
    }
    
    // If we get here, auth state wasn't ready - default to false
    if (mounted) {
      setState(() {
        _isOnboardingCompleted = false;
        _isCheckingOnboarding = false;
      });
    }
  }

  Future<bool> _checkOnboardingCompletion() async {
    try {
      // Try to get user ID from AuthBloc if available
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        if (authState is Authenticated) {
          return await OnboardingCompletionService.isOnboardingCompleted(authState.user.id);
        }
      } catch (e) {
        // AuthBloc not available yet, return false (needs onboarding)
      }
      // No user ID available, assume onboarding not completed
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        try {
          if (state is AuthInitial || state is AuthLoading || _isCheckingOnboarding) {
            // Trigger auth check when app starts
            if (state is AuthInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AuthBloc>().add(AuthCheckRequested());
              });
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is Authenticated) {
            // Re-check onboarding status with user ID when authenticated
            // Use FutureBuilder to handle async check properly
            return FutureBuilder<bool>(
              future: OnboardingCompletionService.isOnboardingCompleted(state.user.id),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                
                // Update state if different
                if (isCompleted != _isOnboardingCompleted && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isOnboardingCompleted = isCompleted;
                      });
                    }
                  });
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (!isCompleted) {
                  return const OnboardingPage();
                } else {
                  return const HomePage();
                }
              },
            );
          }

          // User is not authenticated, show login page
          return const LoginPage();
        } catch (e) {
          // Fallback in case of any errors
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('SPOTS App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Loading...', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Force show onboarding for testing
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const OnboardingPage()),
                      );
                    },
                    child: const Text('Go to Onboarding'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
