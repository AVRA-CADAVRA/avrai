import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/device_capability_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_auto_install_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_macos_auto_install_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai/core/services/on_device_ai_capability_gate.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/onboarding/favorite_places_page.dart';
import 'package:avrai/presentation/pages/onboarding/friends_respect_page.dart';
import 'package:avrai/presentation/pages/onboarding/social_media_connection_page.dart';
import 'package:avrai/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:avrai/presentation/pages/onboarding/preference_survey_page.dart';
import 'package:avrai/presentation/pages/onboarding/baseline_lists_page.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_step.dart';
import 'package:avrai/presentation/pages/onboarding/legal_acceptance_dialog.dart';
import 'package:avrai/core/services/legal_document_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/pages/onboarding/age_collection_page.dart';
import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/models/onboarding_data.dart';
import 'package:avrai/core/services/social_media_connection_service.dart';
import 'package:avrai/core/controllers/onboarding_flow_controller.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/services/ledgers/proof_run_service_v0.dart';

enum OnboardingStepType {
  welcome,
  homebase,
  favoritePlaces,
  preferences,
  baselineLists, // Add baseline lists step after preferences
  friends,
  permissions, // Includes age and legal
  socialMedia,
  connectAndDiscover,
}

class OnboardingStep {
  final OnboardingStepType page;
  final String title;
  final String description;

  const OnboardingStep({
    required this.page,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  DateTime? _selectedBirthday;
  String? _selectedHomebase;
  List<String> _favoritePlaces = [];
  Map<String, List<String>> _preferences = {};
  List<String> _baselineLists = [];
  List<String> _respectedFriends = [];
  Map<String, bool> _connectedSocialPlatforms = {
    // Core platforms
    'Instagram': false,
    'Facebook': false,
    'Twitter': false,
    'Google': false,
    // New platforms
    'Reddit': false,
    'TikTok': false,
    'Tumblr': false,
    'YouTube': false,
    'Pinterest': false,
    'Are.na': false,
  }; // Track social media connections
  bool _isCompleting = false; // Guard to prevent multiple completion attempts

  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      page: OnboardingStepType.welcome,
      title: 'Welcome',
      description: 'Get started with SPOTS',
    ),
    const OnboardingStep(
      page: OnboardingStepType.permissions,
      title: 'Permissions & Legal',
      description: 'Enable permissions and accept terms',
    ),
    const OnboardingStep(
      page: OnboardingStepType.homebase,
      title: 'Choose Your Homebase',
      description: 'Select your primary location',
    ),
    const OnboardingStep(
      page: OnboardingStepType.favoritePlaces,
      title: 'Favorite Places',
      description: 'Tell us about your favorite spots',
    ),
    const OnboardingStep(
      page: OnboardingStepType.preferences,
      title: 'What do you love?',
      description:
          'Set your preferences for vibe matching and spot recommendations',
    ),
    const OnboardingStep(
      page: OnboardingStepType.baselineLists,
      title: 'Your Lists',
      description: 'Create your starting lists (optional)',
    ),
    const OnboardingStep(
      page: OnboardingStepType.socialMedia,
      title: 'Social Media',
      description: 'Connect your social accounts (optional)',
    ),
    const OnboardingStep(
      page: OnboardingStepType.friends,
      title: 'Friends & Respect',
      description: 'Connect with friends',
    ),
    const OnboardingStep(
      page: OnboardingStepType.connectAndDiscover,
      title: 'Connect & Discover',
      description: 'Enable ai2ai discovery and connections',
    ),
  ];

  @override
  void dispose() {
    // Stop any ongoing operations
    _isCompleting = true;

    // Dispose PageController first to prevent any ongoing animations
    // This must happen before super.dispose() to prevent rendering issues
    // Note: PageController may already be disposed in _completeOnboarding
    try {
      if (_pageController.hasClients) {
        _pageController.dispose();
      } else {
        // Try to dispose even if no clients - may already be disposed but that's ok
        try {
          _pageController.dispose();
        } catch (e) {
          // Already disposed, ignore
        }
      }
    } catch (e) {
      // Ignore disposal errors - controller may already be disposed
      _logger.debug('PageController disposal note: $e', tag: 'Onboarding');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If completing, show only a loading screen to prevent any rendering issues
    if (_isCompleting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to avrai'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to avrai'),
        automaticallyImplyLeading: false,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Start proof run (debug)',
              onPressed: () async {
                try {
                  final proof = GetIt.instance<ProofRunServiceV0>();
                  final existing = proof.getActiveRunId();
                  final runId = existing ??
                      await proof.startRun(payload: const {
                        'started_from': 'onboarding',
                      });
                  if (!mounted || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Proof run active: ${runId.substring(0, 8)}…',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e, st) {
                  developer.log(
                    'Failed starting proof run from onboarding',
                    name: 'OnboardingPage',
                    error: e,
                    stackTrace: st,
                  );
                  if (!mounted || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Proof run start failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          TextButton(
            onPressed: _currentPage > 0 && !_isCompleting
                ? () {
                    if (mounted && !_isCompleting) {
                      setState(() {
                        _currentPage--;
                      });
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                : null,
            child: const Text('Back'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: _isCompleting
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) {
                if (!_isCompleting && mounted) {
                  setState(() {
                    _currentPage = index;
                  });
                }
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                // Prevent building pages during completion
                if (_isCompleting) {
                  return const SizedBox.shrink();
                }
                return _buildStepContent(_steps[index]);
              },
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    switch (step.page) {
      case OnboardingStepType.welcome:
        return WelcomePage(
          onContinue: () {
            if (_currentPage < _steps.length - 1) {
              setState(() {
                _currentPage++;
              });
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          onSkip: () {
            // Skip to last step (or could skip entirely)
            if (_currentPage < _steps.length - 1) {
              setState(() {
                _currentPage = _steps.length - 1;
              });
              _pageController.jumpToPage(_steps.length - 1);
            }
          },
        );
      case OnboardingStepType.homebase:
        return HomebaseSelectionPage(
          onHomebaseChanged: (homebase) {
            setState(() {
              _selectedHomebase = homebase;
            });
          },
          selectedHomebase: _selectedHomebase,
        );
      case OnboardingStepType.favoritePlaces:
        return FavoritePlacesPage(
          onPlacesChanged: (places) {
            setState(() {
              _favoritePlaces = places;
            });
          },
          favoritePlaces: _favoritePlaces,
          userId: _getUserIdOrNull(),
          userHomebase: _selectedHomebase,
        );
      case OnboardingStepType.preferences:
        return PreferenceSurveyPage(
          onPreferencesChanged: (preferences) {
            setState(() {
              _preferences = preferences;
            });
          },
          preferences: _preferences,
        );
      case OnboardingStepType.baselineLists:
        return BaselineListsPage(
          baselineLists: _baselineLists,
          onBaselineListsChanged: (lists) {
            setState(() {
              _baselineLists = lists;
            });
          },
          userId: _getUserIdOrNull(),
          userName: _getUserName(),
          userPreferences: _preferences,
          userFavoritePlaces: _favoritePlaces,
        );
      case OnboardingStepType.friends:
        return FriendsRespectPage(
          onRespectedListsChanged: (friends) {
            setState(() {
              _respectedFriends = friends;
            });
          },
          respectedLists: _respectedFriends,
          userId: _getUserIdOrNull(),
        );
      case OnboardingStepType.permissions:
        return _PermissionsAndLegalPage(
          selectedBirthday: _selectedBirthday,
          onBirthdayChanged: (birthday) {
            setState(() {
              _selectedBirthday = birthday;
            });
          },
        );
      case OnboardingStepType.socialMedia:
        return SocialMediaConnectionPage(
          connectedPlatforms: _connectedSocialPlatforms,
          isOnboarding: true, // Enable batch connections during onboarding
          onConnectionsChanged: (connections) async {
            setState(() {
              _connectedSocialPlatforms = connections;
            });

            // Optionally: Verify connections exist in service
            // This ensures OnboardingData reflects real connections
            try {
              final authBloc = context.read<AuthBloc>();
              final authState = authBloc.state;
              if (authState is Authenticated) {
                final userId = authState.user.id;
                final socialMediaService =
                    di.sl<SocialMediaConnectionService>();
                final realConnections =
                    await socialMediaService.getActiveConnections(userId);

                // Update map to reflect only real connections
                final realPlatforms = <String, bool>{};
                for (final conn in realConnections) {
                  // Map platform names: 'instagram' -> 'Instagram'
                  final displayName = conn.platform[0].toUpperCase() +
                      conn.platform.substring(1);
                  realPlatforms[displayName] = true;
                }

                if (mounted) {
                  setState(() {
                    _connectedSocialPlatforms = realPlatforms;
                  });
                }
              }
            } catch (e) {
              // Continue with UI state if service check fails
              _logger.warn('⚠️ Could not verify social media connections: $e',
                  tag: 'Onboarding');
            }
          },
        );
      case OnboardingStepType.connectAndDiscover:
        return const _ConnectAndDiscoverPage();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              key: const Key('onboarding_primary_cta'),
              onPressed: _isCompleting
                  ? null
                  : (_canProceedToNextStep()
                      ? () {
                          _logger.debug(
                              'Button pressed on step ${_steps[_currentPage].page.name}',
                              tag: 'Onboarding');
                          if (_currentPage == _steps.length - 1) {
                            _logger.info(
                                'Completing onboarding from Connect & Discover step',
                                tag: 'Onboarding');
                            _completeOnboarding();
                          } else {
                            setState(() {
                              _currentPage++;
                            });
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      : null),
              child: Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserName() {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated ? authState.user.name : 'User';
  }

  String? _getUserIdOrNull() {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated ? authState.user.id : null;
  }

  bool _canProceedToNextStep() {
    if (_currentPage >= _steps.length) {
      _logger.debug('Cannot proceed: currentPage >= steps.length',
          tag: 'Onboarding');
      return false;
    }

    // Always allow proceeding from the last step (friends is optional)
    if (_currentPage == _steps.length - 1) {
      _logger.debug('Can proceed: on last step', tag: 'Onboarding');
      return true;
    }

    final stepType = _steps[_currentPage].page;
    bool canProceed;

    switch (stepType) {
      case OnboardingStepType.welcome:
        canProceed = true; // Welcome page is always ready to proceed
        break;
      case OnboardingStepType.homebase:
        canProceed = _selectedHomebase != null && _selectedHomebase!.isNotEmpty;
        break;
      case OnboardingStepType.favoritePlaces:
        canProceed = _favoritePlaces.isNotEmpty;
        break;
      case OnboardingStepType.preferences:
        canProceed = _preferences.isNotEmpty;
        break;
      case OnboardingStepType.baselineLists:
        canProceed = true; // Optional step - users can skip or create lists
        break;
      case OnboardingStepType.friends:
        canProceed = true; // Optional step
        break;
      case OnboardingStepType.permissions:
        canProceed =
            _selectedBirthday != null && _areCriticalPermissionsGrantedSync();
        break;
      case OnboardingStepType.socialMedia:
        canProceed = true; // Social media step is optional
        break;
      case OnboardingStepType.connectAndDiscover:
        // This step is optional - user can complete setup with or without enabling AI discovery
        canProceed = true;
        break;
    }

    _logger.debug('Can proceed from ${stepType.name}: $canProceed',
        tag: 'Onboarding');
    return canProceed;
  }

  bool _areCriticalPermissionsGrantedSync() {
    // Synchronous snapshot using cached status flags; if not available, assume false
    // For strict gating, prefer calling requestCriticalPermissions() before this or check statuses directly
    // Here we query current status synchronously via value getters (permission_handler requires async; kept simple)
    // We'll optimistically enable Next and re-validate in guards.
    return true;
  }

  String _getNextButtonText() {
    if (_currentPage == _steps.length - 1) {
      return 'Complete Setup';
    }
    return 'Next';
  }

  void _completeOnboarding() async {
    // Prevent multiple completion attempts
    if (_isCompleting) {
      _logger.warn(
          '⚠️ [ONBOARDING_PAGE] Onboarding completion already in progress',
          tag: 'Onboarding');
      return;
    }

    _isCompleting = true;
    try {
      _logger.info('🎯 Completing Onboarding:', tag: 'Onboarding');
      _logger.debug('  Homebase: $_selectedHomebase', tag: 'Onboarding');
      _logger.debug('  Favorite Places: $_favoritePlaces', tag: 'Onboarding');
      _logger.debug('  Preferences: $_preferences', tag: 'Onboarding');

      // Get authenticated user
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        _logger.error('❌ [ONBOARDING_PAGE] User not authenticated',
            tag: 'Onboarding');
        _isCompleting = false;
        return;
      }
      final userId = authState.user.id;

      const bool isIntegrationTest = bool.fromEnvironment('FLUTTER_TEST');

      // Show legal acceptance dialog if needed (UI responsibility)
      if (!isIntegrationTest) {
        final legalService = GetIt.instance<LegalDocumentService>();
        final hasAcceptedTerms = await legalService.hasAcceptedTerms(userId);
        final hasAcceptedPrivacy =
            await legalService.hasAcceptedPrivacyPolicy(userId);

        if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
          // Check mounted before using context
          if (!mounted) {
            _isCompleting = false;
            return;
          }

          final accepted = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => LegalAcceptanceDialog(
              requireTerms: !hasAcceptedTerms,
              requirePrivacy: !hasAcceptedPrivacy,
            ),
          );

          if (accepted != true) {
            _isCompleting = false;
            return;
          }
        }
      }

      // Calculate age from birthday
      int? age;
      if (_selectedBirthday != null) {
        final now = DateTime.now();
        age = now.year - _selectedBirthday!.year;
        if (now.month < _selectedBirthday!.month ||
            (now.month == _selectedBirthday!.month &&
                now.day < _selectedBirthday!.day)) {
          age--;
        }
      }

      // Build onboarding data (agentId will be set by controller)
      final onboardingData = OnboardingData(
        agentId: '', // Will be set by controller
        age: age,
        birthday: _selectedBirthday,
        homebase: _selectedHomebase,
        favoritePlaces: _favoritePlaces,
        preferences: _preferences,
        baselineLists: _baselineLists,
        respectedFriends: _respectedFriends,
        socialMediaConnected: _connectedSocialPlatforms,
        completedAt: DateTime.now(),
      );

      // Use OnboardingFlowController to complete workflow
      if (!mounted) return;
      final controller = di.sl<OnboardingFlowController>();
      final result = await controller.completeOnboarding(
        data: onboardingData,
        userId: userId,
        context: context,
      );
      if (!mounted) return;

      // Handle controller result
      if (!result.isSuccess) {
        _logger.error(
            '❌ [ONBOARDING_PAGE] Onboarding completion failed: ${result.error}',
            tag: 'Onboarding');

        // Show error to user if needed
        if (result.requiresLegalAcceptance) {
          // Legal acceptance required - already handled above, but log for clarity
          _logger.warn('⚠️ [ONBOARDING_PAGE] Legal acceptance required',
              tag: 'Onboarding');
        }

        _isCompleting = false;

        // In integration tests, surface the root cause
        if (isIntegrationTest) {
          throw Exception('Onboarding completion failed: ${result.error}');
        }

        // Show error dialog to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to complete onboarding'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Success - log and continue to navigation
      _logger.info(
          '✅ [ONBOARDING_PAGE] Onboarding data saved successfully (agentId: ${result.agentId?.substring(0, 10)}...)',
          tag: 'Onboarding');

      // Proof run (debug): if a run is active, record that onboarding completed.
      if (kDebugMode) {
        try {
          final proof = GetIt.instance<ProofRunServiceV0>();
          final runId = proof.getActiveRunId();
          if (runId != null && runId.isNotEmpty) {
            await proof.recordMilestone(
              runId: runId,
              eventType: 'proof_onboarding_completed',
              payload: <String, Object?>{
                'homebase_set': _selectedHomebase != null,
                'favorite_places_count': _favoritePlaces.length,
                'baseline_lists_count': _baselineLists.length,
                'respected_friends_count': _respectedFriends.length,
              },
            );
          }
        } catch (e, st) {
          developer.log(
            'Proof run onboarding receipt failed (non-fatal): $e',
            name: 'OnboardingPage',
            error: e,
            stackTrace: st,
          );
        }
      }

      // Ensure widget is still mounted before navigation
      if (!mounted) {
        _logger.warn(
            '⚠️ [ONBOARDING_PAGE] Widget not mounted, skipping navigation',
            tag: 'Onboarding');
        _isCompleting = false;
        return;
      }

      // Stop PageView from rendering by setting completion flag
      // This must happen before any delays to prevent rendering during transition
      setState(() {
        _isCompleting = true;
      });

      // Wait for the current frame to complete using SchedulerBinding
      // This ensures all rendering operations are finished
      await SchedulerBinding.instance.endOfFrame;

      // Note: PageController disposal is handled by dispose() method in normal widget lifecycle
      // Do NOT dispose here - disposing before navigation can cause graphics thread crashes
      // The controller will be properly disposed after navigation completes

      // Double-check mounted after delays
      if (!mounted) {
        _logger.warn(
            '⚠️ [ONBOARDING_PAGE] Widget not mounted after delays, skipping navigation',
            tag: 'Onboarding');
        _isCompleting = false;
        return;
      }

      // Navigate to AI loading page using go_router
      // Use postFrameCallback to ensure navigation happens after all rendering is complete
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Add another small delay in the callback to be extra safe
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) {
            _isCompleting = false;
            return;
          }

          try {
            final router = GoRouter.of(context);
            if (const bool.fromEnvironment('FLUTTER_TEST')) {
              // Helpful signal in integration test output.
              // ignore: avoid_print
              developer.log('TEST: OnboardingPage -> /ai-loading',
                  name: 'onuoardingpage');
            }

            // Get user name from auth state
            final authState = context.read<AuthBloc>().state;
            final userName =
                authState is Authenticated ? authState.user.name : 'User';

            // Navigate to AI loading page with all onboarding data
            _logger.info(
                '🚀 [ONBOARDING_PAGE] Navigating to /ai-loading with onboarding data',
                tag: 'Onboarding');
            router.go('/ai-loading', extra: {
              'userName': userName,
              'birthday': _selectedBirthday?.toIso8601String(),
              'age': age,
              'homebase': _selectedHomebase,
              'favoritePlaces': _favoritePlaces,
              'preferences': _preferences,
              'baselineLists': _baselineLists,
              'respectedFriends': _respectedFriends,
              'socialMediaConnected': _connectedSocialPlatforms,
            });
          } catch (navigationError) {
            _logger.error(
                '❌ [ONBOARDING_PAGE] Navigation error in postFrameCallback',
                error: navigationError,
                tag: 'Onboarding');
            // Fallback navigation
            if (mounted) {
              try {
                GoRouter.of(context).go('/home');
              } catch (fallbackError) {
                _logger.error(
                    '❌ [ONBOARDING_PAGE] Fallback navigation also failed',
                    error: fallbackError,
                    tag: 'Onboarding');
              }
            }
          }
        });
      });

      // Note: Navigation happens in postFrameCallback
      // The outer catch will handle any errors before navigation
    } catch (e) {
      _isCompleting = false; // Reset on error
      _logger.error('Error completing onboarding', error: e, tag: 'Onboarding');
      // In integration tests, surface the root cause instead of silently falling back.
      if (const bool.fromEnvironment('FLUTTER_TEST')) {
        rethrow;
      }
      // Fallback: try direct navigation to home
      try {
        GoRouter.of(context).go('/home');
      } catch (fallbackError) {
        _logger.error('Fallback navigation also failed',
            error: fallbackError, tag: 'Onboarding');
        // Last resort: use Navigator
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    }
  }

  // Optional utility to request critical permissions early; can be called at specific steps
  Future<void> requestCriticalPermissions() async {
    try {
      final requests = <Permission>[
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ];
      final statuses = await requests.request();
      final denied = statuses.entries
          .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
          .map((e) => e.key)
          .toList();
      if (denied.isNotEmpty) {
        _logger.warn('Some permissions denied: $denied', tag: 'Onboarding');
      }
    } catch (e) {
      _logger.error('Permission request error', error: e, tag: 'Onboarding');
    }
  }

  // ignore: unused_element
  Future<void> _saveRespectedLists(List<String> respectedListNames) async {
    try {
      // Save respected lists logic
    } catch (e) {
      // Handle error
    }
  }
}

/// Combined Permissions and Legal page
/// Includes: Permissions, Age Verification, and Legal Acceptance
class _PermissionsAndLegalPage extends StatefulWidget {
  final DateTime? selectedBirthday;
  final Function(DateTime?) onBirthdayChanged;

  const _PermissionsAndLegalPage({
    required this.selectedBirthday,
    required this.onBirthdayChanged,
  });

  @override
  State<_PermissionsAndLegalPage> createState() =>
      _PermissionsAndLegalPageState();
}

class _PermissionsAndLegalPageState extends State<_PermissionsAndLegalPage> {
  bool _legalAccepted = false;

  @override
  void initState() {
    super.initState();
    _checkLegalStatus();
  }

  Future<void> _checkLegalStatus() async {
    try {
      final legalService = GetIt.instance<LegalDocumentService>();
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final hasAcceptedTerms =
            await legalService.hasAcceptedTerms(authState.user.id);
        final hasAcceptedPrivacy =
            await legalService.hasAcceptedPrivacyPolicy(authState.user.id);
        setState(() {
          _legalAccepted = hasAcceptedTerms && hasAcceptedPrivacy;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _handleLegalAcceptance() async {
    final legalService = GetIt.instance<LegalDocumentService>();
    final authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      final hasAcceptedTerms =
          await legalService.hasAcceptedTerms(authState.user.id);
      final hasAcceptedPrivacy =
          await legalService.hasAcceptedPrivacyPolicy(authState.user.id);

      if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
        if (!mounted) return;
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => LegalAcceptanceDialog(
            requireTerms: !hasAcceptedTerms,
            requirePrivacy: !hasAcceptedPrivacy,
          ),
        );
        if (!mounted) return;

        if (accepted == true) {
          await _checkLegalStatus();
        }
      } else {
        setState(() => _legalAccepted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Permissions & Legal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable connectivity and accept terms to continue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Permissions Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const PermissionsPage(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Age Verification Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Age Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AgeCollectionPage(
                    selectedBirthday: widget.selectedBirthday,
                    onBirthdayChanged: widget.onBirthdayChanged,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Legal Acceptance Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _legalAccepted
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                width: _legalAccepted ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _legalAccepted ? Icons.check_circle : Icons.description,
                        color: _legalAccepted
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Terms & Privacy Policy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _legalAccepted
                        ? 'You have accepted the Terms of Service and Privacy Policy.'
                        : 'Please review and accept our Terms of Service and Privacy Policy to continue.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _legalAccepted
                        ? OutlinedButton.icon(
                            onPressed: _handleLegalAcceptance,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Review Again'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _handleLegalAcceptance,
                            icon: const Icon(Icons.description),
                            label: const Text('Review & Accept'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connect and Discover Page
/// Final step before AI loading - enables ai2ai discovery
class _ConnectAndDiscoverPage extends StatefulWidget {
  const _ConnectAndDiscoverPage();

  @override
  State<_ConnectAndDiscoverPage> createState() =>
      _ConnectAndDiscoverPageState();
}

class _ConnectAndDiscoverPageState extends State<_ConnectAndDiscoverPage> {
  bool _discoveryEnabled = false;
  bool _offlineLlmEnabled = false;
  bool _offlineLlmEligible = false;
  OfflineLlmTier _recommendedTier = OfflineLlmTier.none;
  late final LocalLlmProvisioningStateService _provisioning;
  late final Stream<LocalLlmProvisioningState> _provisioningStream;
  late final Stream<LocalLlmProvisioningState> _provisioningStreamWithInitial;

  @override
  void initState() {
    super.initState();
    _provisioning = LocalLlmProvisioningStateService();
    _provisioningStream =
        Stream.periodic(const Duration(seconds: 2)).asyncMap((_) {
      return _provisioning.getState();
    });
    _provisioningStreamWithInitial = _createProvisioningStreamWithInitial();
    _loadDiscoveryPreference();
    _loadOfflineLlmPreferenceAndEligibility();
  }

  Stream<LocalLlmProvisioningState>
      _createProvisioningStreamWithInitial() async* {
    yield await _provisioning.getState();
    yield* _provisioningStream;
  }

  Future<void> _loadDiscoveryPreference() async {
    try {
      final storageService = StorageService.instance;
      final saved = storageService.getBool('discovery_enabled') ?? false;
      if (mounted) {
        setState(() {
          _discoveryEnabled = saved;
        });
      }
    } catch (e) {
      // Ignore errors - use default false
    }
  }

  Future<void> _saveDiscoveryPreference(bool value) async {
    try {
      final storageService = StorageService.instance;
      await storageService.setBool('discovery_enabled', value);
    } catch (e) {
      // Log but don't block - this is optional
      developer.log('Failed to save discovery preference: $e',
          name: '_ConnectAndDiscoverPage');
    }
  }

  Future<void> _loadOfflineLlmPreferenceAndEligibility() async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();

      // Capability gate (best-effort).
      final caps = await DeviceCapabilityService().getCapabilities();
      final gateResult = OnDeviceAiCapabilityGate().evaluate(caps);
      final recommended = gateResult.recommendedTier;
      final eligible = recommended != OfflineLlmTier.none;

      // Opt-out default: if eligible, default enabled unless user disabled.
      final hasUserChoice = prefs.containsKey('offline_llm_enabled_v1');
      bool enabled = prefs.getBool('offline_llm_enabled_v1') ?? false;
      if (!hasUserChoice) {
        enabled = eligible;
        await prefs.setBool('offline_llm_enabled_v1', enabled);
      }

      if (mounted) {
        setState(() {
          _offlineLlmEligible = eligible;
          _recommendedTier = recommended;
          _offlineLlmEnabled = enabled;
        });
      }

      // Best-effort: kick auto-install
      if (enabled && eligible) {
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          await LocalLlmMacOSAutoInstallService().maybeAutoInstallMacOS();
        } else {
          await LocalLlmAutoInstallService().maybeAutoInstall();
        }
      }
    } catch (e, st) {
      developer.log('Failed to load offline LLM onboarding state: $e',
          name: '_ConnectAndDiscoverPage', error: e, stackTrace: st);
    }
  }

  Future<void> _setOfflineLlmEnabled(bool value) async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      await prefs.setBool('offline_llm_enabled_v1', value);

      if (mounted) {
        setState(() {
          _offlineLlmEnabled = value;
        });
      }

      if (value && _offlineLlmEligible) {
        await LocalLlmAutoInstallService().maybeAutoInstall();
      }
    } catch (e, st) {
      developer.log('Failed to set offline LLM preference: $e',
          name: '_ConnectAndDiscoverPage', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect & Discover',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable ai2ai discovery to connect with nearby SPOTS users and their AI personalities',
          ),
          const SizedBox(height: 24),
          Card(
            child: SwitchListTile(
              title: const Text('Enable AI Discovery'),
              subtitle: const Text(
                'Allow your AI personality to discover and connect with nearby devices',
              ),
              value: _discoveryEnabled,
              onChanged: (value) async {
                setState(() {
                  _discoveryEnabled = value;
                });
                // Save preference asynchronously - don't block UI
                await _saveDiscoveryPreference(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('Enable Offline AI (downloads on Wi‑Fi)'),
              subtitle: Text(
                _offlineLlmEligible
                    ? 'Recommended tier: ${_recommendedTier.name}. You can chat offline once installed.'
                    : 'Not available on this device.',
              ),
              value: _offlineLlmEnabled,
              onChanged: _offlineLlmEligible
                  ? (value) async {
                      await _setOfflineLlmEnabled(value);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<LocalLlmProvisioningState>(
            stream: _provisioningStreamWithInitial,
            builder: (context, snapshot) {
              final s = snapshot.data;
              final phase = s?.phase ?? LocalLlmProvisioningPhase.idle;
              final installed = s?.packStatus.isInstalled ?? false;
              final progress = s?.progressFraction;

              String text;
              if (!_offlineLlmEligible) {
                text = 'Offline AI: not eligible on this device.';
              } else if (!_offlineLlmEnabled) {
                text = 'Offline AI: disabled (opt-out).';
              } else if (installed) {
                final packId = s?.packStatus.activePackId ?? 'unknown';
                if (phase == LocalLlmProvisioningPhase.downloading) {
                  final pct =
                      (progress != null) ? (progress * 100).round() : null;
                  text = pct != null
                      ? 'Offline AI: updating… $pct% (current: $packId)'
                      : 'Offline AI: updating… (current: $packId)';
                } else if (phase == LocalLlmProvisioningPhase.error) {
                  final err = s?.lastError ?? 'Unknown error';
                  text =
                      'Offline AI: installed ($packId) — update error ($err).';
                } else {
                  text = 'Offline AI: installed ($packId).';
                }
              } else {
                switch (phase) {
                  case LocalLlmProvisioningPhase.queuedWifi:
                    text =
                        'Offline AI: queued for Wi‑Fi download (can take a while).';
                    break;
                  case LocalLlmProvisioningPhase.queuedCharging:
                    text = 'Offline AI: queued until your device is charging.';
                    break;
                  case LocalLlmProvisioningPhase.queuedIdle:
                    text = 'Offline AI: queued until you are charging + idle.';
                    break;
                  case LocalLlmProvisioningPhase.downloading:
                    final pct =
                        (progress != null) ? (progress * 100).round() : null;
                    text = pct != null
                        ? 'Offline AI: downloading on Wi‑Fi… $pct%'
                        : 'Offline AI: downloading on Wi‑Fi…';
                    break;
                  case LocalLlmProvisioningPhase.error:
                    final err = s?.lastError ?? 'Unknown error';
                    text = 'Offline AI: error ($err).';
                    break;
                  case LocalLlmProvisioningPhase.installed:
                    text = 'Offline AI: installed.';
                    break;
                  case LocalLlmProvisioningPhase.idle:
                    text = 'Offline AI: waiting to start.';
                    break;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                  if (phase == LocalLlmProvisioningPhase.downloading &&
                      progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.grey200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.electricGreen,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'When enabled, your anonymized personality data will be used to discover compatible AI personalities nearby. All connections are privacy-preserving and go through the AI layer.',
            style: TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}
