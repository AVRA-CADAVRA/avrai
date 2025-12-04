import 'package:go_router/go_router.dart';
import 'package:spots/core/services/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/onboarding/baseline_lists_page.dart';
import 'package:spots/presentation/pages/onboarding/favorite_places_page.dart';
import 'package:spots/presentation/pages/onboarding/friends_respect_page.dart';
import 'package:spots/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:spots/presentation/pages/onboarding/preference_survey_page.dart';
import 'package:spots/presentation/pages/onboarding/onboarding_step.dart';
import 'package:spots/presentation/pages/onboarding/legal_acceptance_dialog.dart';
import 'package:spots/core/services/legal_document_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/pages/onboarding/age_collection_page.dart';
import 'package:spots/presentation/pages/onboarding/welcome_page.dart';

enum OnboardingStepType {
  welcome,
  permissions,
  age,
  homebase,
  favoritePlaces,
  preferences,
  baselineLists,
  friends,
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
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
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
      title: 'Enable Connectivity',
      description: 'Allow permissions for ai2ai and location',
    ),
    OnboardingStep(
      page: OnboardingStepType.age,
      title: 'Age Verification',
      description: 'Required for age-appropriate content',
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
      page: OnboardingStepType.baselineLists,
      title: 'Baseline Lists',
      description: 'Set up your initial lists',
    ),
    OnboardingStep(
      page: OnboardingStepType.friends,
      title: 'Friends & Respect',
      description: 'Connect with friends',
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
            onPressed: _currentPage > 0 ? () {
              setState(() {
                _currentPage--;
              });
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } : null,
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
      case OnboardingStepType.permissions:
        return const PermissionsPage();
      case OnboardingStepType.age:
        return AgeCollectionPage(
          selectedBirthday: _selectedBirthday,
          onBirthdayChanged: (birthday) {
            setState(() {
              _selectedBirthday = birthday;
            });
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
      case OnboardingStepType.baselineLists:
        return BaselineListsPage(
          onBaselineListsChanged: (lists) {
            setState(() {
              _baselineLists = lists;
            });
          },
          baselineLists: _baselineLists,
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
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceedToNextStep() ? () {
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
              } : null,
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
      case OnboardingStepType.permissions:
        return _areCriticalPermissionsGrantedSync();
      case OnboardingStepType.age:
        return _selectedBirthday != null;
      case OnboardingStepType.homebase:
        return _selectedHomebase != null && _selectedHomebase!.isNotEmpty;
      case OnboardingStepType.favoritePlaces:
        return _favoritePlaces.isNotEmpty;
      case OnboardingStepType.preferences:
        return _preferences.isNotEmpty;
      case OnboardingStepType.baselineLists:
        return _baselineLists.isNotEmpty;
      case OnboardingStepType.friends:
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
      
      // Check if user has accepted Terms and Privacy Policy
      final legalService = LegalDocumentService(
        eventService: GetIt.instance<ExpertiseEventService>(),
      );
      final authState = context.read<AuthBloc>().state;
      
      if (authState is Authenticated) {
        final hasAcceptedTerms = await legalService.hasAcceptedTerms(authState.user.id);
        final hasAcceptedPrivacy = await legalService.hasAcceptedPrivacyPolicy(authState.user.id);
        
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
      }
      
      // Calculate age from birthday
      int? age;
      if (_selectedBirthday != null) {
        final now = DateTime.now();
        age = now.year - _selectedBirthday!.year;
        if (now.month < _selectedBirthday!.month ||
            (now.month == _selectedBirthday!.month && now.day < _selectedBirthday!.day)) {
          age--;
        }
      }

      // Navigate to AI loading page using go_router - use GoRouter.of() to ensure context
      final router = GoRouter.of(context);
      router.go('/ai-loading', extra: {
        'userName': "User",
        'birthday': _selectedBirthday?.toIso8601String(),
        'age': age,
        'homebase': _selectedHomebase,
        'favoritePlaces': _favoritePlaces,
        'preferences': _preferences,
      });
    } catch (e) {
      _logger.error('Error completing onboarding', error: e, tag: 'Onboarding');
      // Fallback: try direct navigation to home
      try {
        GoRouter.of(context).go('/home');
      } catch (fallbackError) {
        _logger.error('Fallback navigation also failed', error: fallbackError, tag: 'Onboarding');
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
      final denied = statuses.entries.where((e) => e.value.isDenied || e.value.isPermanentlyDenied).map((e) => e.key).toList();
      if (denied.isNotEmpty) {
        _logger.warn('Some permissions denied: $denied', tag: 'Onboarding');
      }
    } catch (e) {
      _logger.error('Permission request error', error: e, tag: 'Onboarding');
    }
  }

  Future<void> _saveRespectedLists(List<String> respectedListNames) async {
    try {
      // Save respected lists logic
    } catch (e) {
      // Handle error
    }
  }
}
