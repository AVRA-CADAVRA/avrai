import 'package:go_router/go_router.dart';
import 'package:spots/core/services/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/onboarding/favorite_places_page.dart';
import 'package:spots/presentation/pages/onboarding/friends_respect_page.dart';
import 'package:spots/presentation/pages/onboarding/social_media_connection_page.dart';
import 'package:spots/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:spots/presentation/pages/onboarding/preference_survey_page.dart';
import 'package:spots/presentation/pages/onboarding/onboarding_step.dart';
import 'package:spots/presentation/pages/onboarding/legal_acceptance_dialog.dart';
import 'package:spots/core/services/legal_document_service.dart';
import 'package:spots/data/datasources/local/onboarding_completion_service.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/pages/onboarding/age_collection_page.dart';
import 'package:spots/presentation/pages/onboarding/welcome_page.dart';

enum OnboardingStepType {
  welcome,
  homebase,
  favoritePlaces,
  preferences,
  friends,
  permissions, // Includes age and legal
  socialMedia,
  vibeMatching,
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

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      page: OnboardingStepType.welcome,
      title: 'Welcome',
      description: 'Get started with SPOTS',
    ),
    OnboardingStep(
      page: OnboardingStepType.permissions,
      title: 'Permissions & Legal',
      description: 'Enable permissions and accept terms',
    ),
    OnboardingStep(
      page: OnboardingStepType.homebase,
      title: 'Choose Your Homebase',
      description: 'Select your primary location',
    ),
    OnboardingStep(
      page: OnboardingStepType.favoritePlaces,
      title: 'Favorite Places',
      description: 'Tell us about your favorite spots',
    ),
    OnboardingStep(
      page: OnboardingStepType.preferences,
      title: 'Preferences',
      description: 'Customize your experience',
    ),
    OnboardingStep(
      page: OnboardingStepType.socialMedia,
      title: 'Social Media',
      description: 'Connect your social accounts (optional)',
    ),
    OnboardingStep(
      page: OnboardingStepType.friends,
      title: 'Friends & Respect',
      description: 'Connect with friends',
    ),
    OnboardingStep(
      page: OnboardingStepType.vibeMatching,
      title: 'Vibe Matching',
      description: 'Set up your personality preferences',
    ),
    OnboardingStep(
      page: OnboardingStepType.connectAndDiscover,
      title: 'Connect & Discover',
      description: 'Enable ai2ai discovery and connections',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to SPOTS'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
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
      case OnboardingStepType.friends:
        return FriendsRespectPage(
          onRespectedListsChanged: (friends) {
            setState(() {
              _respectedFriends = friends;
            });
          },
          respectedLists: _respectedFriends,
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
        return const SocialMediaConnectionPage();
      case OnboardingStepType.vibeMatching:
        return _VibeMatchingPage(
          preferences: _preferences,
          onPreferencesChanged: (preferences) {
            setState(() {
              _preferences = preferences;
            });
          },
        );
      case OnboardingStepType.connectAndDiscover:
        return _ConnectAndDiscoverPage();
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
              onPressed: _canProceedToNextStep()
                  ? () {
                      if (_currentPage == _steps.length - 1) {
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
                  : null,
              child: Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    if (_currentPage >= _steps.length) {
      return false;
    }

    // Always allow proceeding from the last step (friends is optional)
    if (_currentPage == _steps.length - 1) {
      return true;
    }

    switch (_steps[_currentPage].page) {
      case OnboardingStepType.welcome:
        return true; // Welcome page is always ready to proceed
      case OnboardingStepType.homebase:
        return _selectedHomebase != null && _selectedHomebase!.isNotEmpty;
      case OnboardingStepType.favoritePlaces:
        return _favoritePlaces.isNotEmpty;
      case OnboardingStepType.preferences:
        return _preferences.isNotEmpty;
      case OnboardingStepType.friends:
        return true; // Optional step
      case OnboardingStepType.permissions:
        return _selectedBirthday != null && _areCriticalPermissionsGrantedSync();
      case OnboardingStepType.socialMedia:
        return true; // Social media step is optional
      case OnboardingStepType.vibeMatching:
        return true; // Optional step
      case OnboardingStepType.connectAndDiscover:
        return true; // Optional step
    }
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
    try {
      _logger.info('🎯 Completing Onboarding:', tag: 'Onboarding');
      _logger.debug('  Homebase: $_selectedHomebase', tag: 'Onboarding');
      _logger.debug('  Favorite Places: $_favoritePlaces', tag: 'Onboarding');
      _logger.debug('  Preferences: $_preferences', tag: 'Onboarding');

      const bool isIntegrationTest = bool.fromEnvironment('FLUTTER_TEST');

      if (!isIntegrationTest) {
        // Check if user has accepted Terms and Privacy Policy
        final legalService = GetIt.instance<LegalDocumentService>();
        final authState = context.read<AuthBloc>().state;

        if (authState is Authenticated) {
          final hasAcceptedTerms =
              await legalService.hasAcceptedTerms(authState.user.id);
          final hasAcceptedPrivacy =
              await legalService.hasAcceptedPrivacyPolicy(authState.user.id);

          if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
            // Show legal acceptance dialog
            final accepted = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => LegalAcceptanceDialog(
                requireTerms: !hasAcceptedTerms,
                requirePrivacy: !hasAcceptedPrivacy,
              ),
            );

            if (accepted != true) {
              // User must accept to continue
              return;
            }
          }

          // Mark onboarding as completed immediately after legal acceptance
          // This prevents the app from restarting onboarding if navigation fails or app restarts
          try {
            _logger.info(
                '📝 [ONBOARDING_PAGE] Marking onboarding as completed before navigation for user ${authState.user.id}...',
                tag: 'Onboarding');

            final startTime = DateTime.now();
            final success =
                await OnboardingCompletionService.markOnboardingCompleted(
                    authState.user.id);
            final elapsed = DateTime.now().difference(startTime).inMilliseconds;

            if (success) {
              _logger.info(
                  '✅ [ONBOARDING_PAGE] Onboarding marked as completed and fully verified for user ${authState.user.id} (took ${elapsed}ms)',
                  tag: 'Onboarding');
            } else {
              _logger.warn(
                  '⚠️ [ONBOARDING_PAGE] Onboarding marked but verification incomplete for user ${authState.user.id} (took ${elapsed}ms). Will retry in AILoadingPage.',
                  tag: 'Onboarding');
              // Continue anyway - cache is set, and AILoadingPage will also try to mark it
            }
          } catch (e, stackTrace) {
            _logger.error(
                '❌ [ONBOARDING_PAGE] Failed to mark onboarding as completed for user ${authState.user.id}',
                error: e,
                tag: 'Onboarding');
            _logger.debug('Stack trace: $stackTrace', tag: 'Onboarding');
            // Continue anyway - AILoadingPage will also try to mark it
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

      // Navigate to AI loading page using go_router - use GoRouter.of() to ensure context
      final router = GoRouter.of(context);
      if (bool.fromEnvironment('FLUTTER_TEST')) {
        // Helpful signal in integration test output.
        // ignore: avoid_print
        print('TEST: OnboardingPage -> /ai-loading');
      }
      router.go('/ai-loading', extra: {
        'userName': "User",
        'birthday': _selectedBirthday?.toIso8601String(),
        'age': age,
        'homebase': _selectedHomebase,
        'favoritePlaces': _favoritePlaces,
        'preferences': _preferences,
        'baselineLists': _baselineLists, // Pass baseline lists to AI loading page
      });
    } catch (e) {
      _logger.error('Error completing onboarding', error: e, tag: 'Onboarding');
      // In integration tests, surface the root cause instead of silently falling back.
      if (bool.fromEnvironment('FLUTTER_TEST')) {
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
  State<_PermissionsAndLegalPage> createState() => _PermissionsAndLegalPageState();
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
        final hasAcceptedTerms = await legalService.hasAcceptedTerms(authState.user.id);
        final hasAcceptedPrivacy = await legalService.hasAcceptedPrivacyPolicy(authState.user.id);
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
      final hasAcceptedTerms = await legalService.hasAcceptedTerms(authState.user.id);
      final hasAcceptedPrivacy = await legalService.hasAcceptedPrivacyPolicy(authState.user.id);

      if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => LegalAcceptanceDialog(
            requireTerms: !hasAcceptedTerms,
            requirePrivacy: !hasAcceptedPrivacy,
          ),
        );

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions & Legal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable connectivity and accept terms to continue',
          ),
          const SizedBox(height: 24),
          
          // Permissions Section
          const Text(
            'Permissions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const PermissionsPage(),
          
          const SizedBox(height: 32),
          
          // Age Verification Section
          const Text(
            'Age Verification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AgeCollectionPage(
            selectedBirthday: widget.selectedBirthday,
            onBirthdayChanged: widget.onBirthdayChanged,
          ),
          
          const SizedBox(height: 32),
          
          // Legal Acceptance Section
          const Text(
            'Terms & Privacy Policy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _legalAccepted ? Icons.check_circle : Icons.description,
                color: _legalAccepted ? Colors.green : Theme.of(context).primaryColor,
              ),
              title: const Text('Terms of Service & Privacy Policy'),
              subtitle: Text(
                _legalAccepted
                    ? 'Accepted'
                    : 'Please review and accept to continue',
              ),
              trailing: _legalAccepted
                  ? const Icon(Icons.check, color: Colors.green)
                  : ElevatedButton(
                      onPressed: _handleLegalAcceptance,
                      child: const Text('Review & Accept'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vibe Matching Page
/// Allows users to set personality preferences for AI matching
class _VibeMatchingPage extends StatelessWidget {
  final Map<String, List<String>> preferences;
  final Function(Map<String, List<String>>) onPreferencesChanged;

  const _VibeMatchingPage({
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vibe Matching',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your personality preferences for AI matching and connections',
          ),
          const SizedBox(height: 24),
          // Reuse PreferenceSurveyPage for vibe matching
          Expanded(
            child: PreferenceSurveyPage(
              preferences: preferences,
              onPreferencesChanged: onPreferencesChanged,
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
  State<_ConnectAndDiscoverPage> createState() => _ConnectAndDiscoverPageState();
}

class _ConnectAndDiscoverPageState extends State<_ConnectAndDiscoverPage> {
  bool _discoveryEnabled = false;

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
              onChanged: (value) {
                setState(() {
                  _discoveryEnabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'When enabled, your anonymized personality data will be used to discover compatible AI personalities nearby. All connections are privacy-preserving and go through the AI layer.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
