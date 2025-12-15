import 'package:spots/core/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/data/datasources/local/onboarding_completion_service.dart';
import 'package:go_router/go_router.dart';
import 'package:spots/core/ai/list_generator_service.dart';
import 'package:spots/injection_container.dart' as di;
import 'package:spots/domain/usecases/lists/create_list_usecase.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/services/personality_sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class AILoadingPage extends StatefulWidget {
  final String userName;
  final DateTime? birthday;
  final int? age;
  final String? homebase;
  final List<String> favoritePlaces;
  final Map<String, List<String>> preferences;
  final List<String> baselineLists; // Add baseline lists parameter
  final Function() onLoadingComplete;

  const AILoadingPage({
    super.key,
    required this.userName,
    this.birthday,
    this.age,
    this.homebase,
    this.favoritePlaces = const [],
    this.preferences = const {},
    this.baselineLists = const [], // Add baseline lists with default empty list
    required this.onLoadingComplete,
  });

  @override
  State<AILoadingPage> createState() => _AILoadingPageState();
}

class _AILoadingPageState extends State<AILoadingPage>
    with TickerProviderStateMixin {
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  bool _isLoading = true;
  bool _canContinue = false; // Allow users to continue after short delay
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  static const bool _isIntegrationTest =
      bool.fromEnvironment('SPOTS_INTEGRATION_TEST');

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Start loading animation
    _startLoading();
  }

  void _startLoading() async {
    _loadingController.repeat();

    // Enable continue button after 2 seconds - allows users to proceed immediately
    // as the text says "You can start exploring immediately!"
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _canContinue = true;
        });
      }
    });

    try {
      if (_isIntegrationTest) {
        _logger.info(
          '🧪 Integration test mode: skipping AI loading',
          tag: 'AILoadingPage',
        );
        // ignore: avoid_print
        print('TEST: AILoadingPage short-circuit -> /home');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _loadingController.stop();
        }
        await _markOnboardingCompleted();
        if (mounted) {
          context.go('/home');
        }
        return;
      }

      _logger.info('🚀 Starting AI loading process...', tag: 'AILoadingPage');

      // Use actual onboarding data passed to this widget
      String userName = widget.userName;
      String? homebase = widget.homebase;
      List<String> favoritePlaces = widget.favoritePlaces;
      Map<String, List<String>> preferences = widget.preferences;

      _logger.info('🎯 AI Loading Data:', tag: 'AILoadingPage');
      _logger.debug('  User: $userName', tag: 'AILoadingPage');
      _logger.debug('  Homebase: $homebase', tag: 'AILoadingPage');
      _logger.debug('  Favorite Places: $favoritePlaces', tag: 'AILoadingPage');
      _logger.debug('  Preferences: $preferences', tag: 'AILoadingPage');

      // If no data was passed, use fallback values
      if (homebase == null || homebase.isEmpty) {
        homebase = "New York";
        _logger.warn('⚠️ Using fallback homebase: $homebase',
            tag: 'AILoadingPage');
      }
      if (favoritePlaces.isEmpty) {
        favoritePlaces = [
          "Central Park",
          "Brooklyn Bridge",
          "Times Square",
          "Empire State Building",
          "Statue of Liberty"
        ];
        _logger.warn('⚠️ Using fallback favorite places: $favoritePlaces',
            tag: 'AILoadingPage');
      }
      if (preferences.isEmpty) {
        preferences = {
          'Food & Drink': ['Coffee & Tea', 'Fine Dining', 'Craft Beer'],
          'Activities': ['Live Music', 'Theaters', 'Shopping'],
          'Outdoor & Nature': ['Parks', 'Hiking Trails', 'Scenic Views']
        };
        _logger.warn('⚠️ Using fallback preferences: $preferences',
            tag: 'AILoadingPage');
      }

      // Use baseline lists if provided, otherwise generate personalized lists using AI
      List<String> generatedLists;
      if (widget.baselineLists.isNotEmpty) {
        _logger.info('📋 Using ${widget.baselineLists.length} baseline lists from onboarding',
            tag: 'AILoadingPage');
        generatedLists = widget.baselineLists;
      } else {
        _logger.info('🔄 Generating AI lists...', tag: 'AILoadingPage');
        _logger.debug('  Age: ${widget.age ?? 'not provided'}',
            tag: 'AILoadingPage');
        generatedLists =
            await AIListGeneratorService.generatePersonalizedLists(
          userName: userName,
          age: widget.age,
          homebase: homebase,
          favoritePlaces: favoritePlaces,
          preferences: preferences,
        );
      }

      _logger.info(
          '✅ Using ${generatedLists.length} lists: $generatedLists',
          tag: 'AILoadingPage');

      // Create the lists in the app - use use case directly to wait for completion
      if (mounted && generatedLists.isNotEmpty) {
        try {
          _logger.info('📝 Getting CreateListUseCase from DI...',
              tag: 'AILoadingPage');
          final createListUseCase = di.sl<CreateListUseCase>();
          final listsBloc = context.read<ListsBloc>();

          _logger.info('📝 Creating ${generatedLists.length} lists...',
              tag: 'AILoadingPage');

          int successCount = 0;
          // Create lists sequentially and wait for each to complete
          for (int i = 0; i < generatedLists.length; i++) {
            if (!mounted) break;

            final listName = generatedLists[i];
            final newList = SpotList(
              id: '${DateTime.now().millisecondsSinceEpoch}_$i',
              title: listName,
              description: 'AI-generated list based on your preferences',
              spots: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              category: 'AI Generated',
              isPublic: true,
              spotIds: [],
              respectCount: 0,
            );

            try {
              _logger.debug(
                  '📝 Creating list ${i + 1}/${generatedLists.length}: ${newList.title}',
                  tag: 'AILoadingPage');

              // Add timeout to prevent hanging
              await createListUseCase(newList)
                  .timeout(const Duration(seconds: 5), onTimeout: () {
                _logger.warn('⏱️ Timeout creating list ${newList.title}',
                    tag: 'AILoadingPage');
                throw TimeoutException(
                    'List creation timeout', const Duration(seconds: 5));
              });

              successCount++;
              _logger.debug('✅ Created list: ${newList.title}',
                  tag: 'AILoadingPage');
            } catch (e) {
              _logger.error('❌ Error creating list ${newList.title}',
                  error: e, tag: 'AILoadingPage');
              // Continue with other lists even if one fails
            }
          }

          _logger.info(
              '✅ Successfully created $successCount/${generatedLists.length} lists',
              tag: 'AILoadingPage');

          // Reload lists once after all are created
          if (mounted) {
            listsBloc.add(LoadLists());
            // Small delay to ensure UI updates
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          _logger.error('❌ Error in list creation process',
              error: e, tag: 'AILoadingPage');
          // Continue anyway - don't block onboarding completion
        }
      } else {
        _logger.warn('⚠️ No lists generated or widget not mounted',
            tag: 'AILoadingPage');
        // Still show loading animation even if no lists generated
        await Future.delayed(const Duration(seconds: 1));
      }

      // Initialize personalized agent/personality for user
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        if (authState is Authenticated) {
          final userId = authState.user.id;
          _logger.info('🤖 Initializing personalized agent for user: $userId',
              tag: 'AILoadingPage');

          final personalityLearning = di.sl<PersonalityLearning>();
          final personalityProfile =
              await personalityLearning.initializePersonality(userId);

          _logger.info(
              '✅ Personalized agent initialized (generation ${personalityProfile.evolutionGeneration})',
              tag: 'AILoadingPage');
          _logger.debug('  Archetype: ${personalityProfile.archetype}',
              tag: 'AILoadingPage');
          _logger.debug('  Authenticity: ${personalityProfile.authenticity}',
              tag: 'AILoadingPage');

          // Attempt cloud sync if enabled (password may not be available during onboarding)
          try {
            final syncService = di.sl<PersonalitySyncService>();
            final syncEnabled = await syncService.isCloudSyncEnabled(userId);

            if (syncEnabled) {
              _logger.info(
                  '☁️ Cloud sync enabled, attempting to sync profile...',
                  tag: 'AILoadingPage');

              // Try to get password from secure storage (stored during login/signup)
              const secureStorage = FlutterSecureStorage();
              final passwordHash = await secureStorage.read(
                key: 'user_password_hash_$userId',
              );

              if (passwordHash != null && passwordHash.isNotEmpty) {
                // Password hash is stored, attempt sync
                // Note: In production, we'd need to store the actual password temporarily
                // or use a different approach. For now, we'll skip sync during onboarding
                // and let user enable it later in settings where they can re-enter password
                _logger.debug(
                    '⚠️ Password hash found but sync requires actual password. '
                    'User can enable sync in settings.',
                    tag: 'AILoadingPage');
              } else {
                _logger.debug(
                    '⚠️ Password not available during onboarding. '
                    'User can enable sync in settings.',
                    tag: 'AILoadingPage');
              }
            } else {
              _logger.debug('ℹ️ Cloud sync disabled for user',
                  tag: 'AILoadingPage');
            }
          } catch (e) {
            _logger.warn('⚠️ Error checking cloud sync status: $e',
                tag: 'AILoadingPage');
            // Don't block onboarding if sync check fails
          }
        } else {
          _logger.warn('⚠️ Could not initialize agent - user not authenticated',
              tag: 'AILoadingPage');
        }
      } catch (e, stackTrace) {
        _logger.error('❌ Error initializing personalized agent',
            error: e, tag: 'AILoadingPage');
        _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
        // Continue anyway - don't block onboarding completion
      }
    } catch (e, stackTrace) {
      // Handle error - still complete onboarding
      _logger.error('❌ Error in AI loading process',
          error: e, tag: 'AILoadingPage');
      _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
    }

    // Always complete onboarding, even if there were errors
    _logger.info('🏁 Completing onboarding process...', tag: 'AILoadingPage');

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadingController.stop();

      // Call the completion callback only if still mounted
      if (mounted) {
        try {
          // Mark onboarding as completed for current user
          _logger.info('📝 [AI_LOADING] Marking onboarding as completed...',
              tag: 'AILoadingPage');
          final markStartTime = DateTime.now();
          await _markOnboardingCompleted();
          final markElapsed =
              DateTime.now().difference(markStartTime).inMilliseconds;
          _logger.info(
              '✅ [AI_LOADING] Onboarding marked as completed (took ${markElapsed}ms)',
              tag: 'AILoadingPage');

          // Verify one more time before navigation
          _logger.debug(
              '🔍 [AI_LOADING] Final verification before navigation...',
              tag: 'AILoadingPage');
          bool finalVerified = false;
          String? userId;

          // Get user ID for verification
          for (int i = 0; i < 5; i++) {
            try {
              final authBloc = context.read<AuthBloc>();
              final state = authBloc.state;
              if (state is Authenticated) {
                userId = state.user.id;
                break;
              }
            } catch (e) {
              // Continue trying
            }
            if (i < 4) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }

          if (userId != null && userId.isNotEmpty) {
            for (int i = 0; i < 3; i++) {
              await Future.delayed(const Duration(milliseconds: 200));
              finalVerified =
                  await OnboardingCompletionService.isOnboardingCompleted(
                      userId);
              if (finalVerified) {
                _logger.debug(
                    '✅ [AI_LOADING] Final verification passed on attempt ${i + 1}',
                    tag: 'AILoadingPage');
                break;
              } else {
                _logger.warn(
                    '⚠️ [AI_LOADING] Final verification failed on attempt ${i + 1}',
                    tag: 'AILoadingPage');
              }
            }
          } else {
            _logger.warn(
                '⚠️ [AI_LOADING] Could not get user ID for final verification',
                tag: 'AILoadingPage');
          }

          if (!finalVerified) {
            _logger.error(
                '❌ [AI_LOADING] Final verification failed after 3 attempts. Proceeding anyway - cache should be set.',
                tag: 'AILoadingPage');
          }

          // Navigate to home using go_router
          if (mounted) {
            _logger.info('🏠 [AI_LOADING] Navigating to home...',
                tag: 'AILoadingPage');
            context.go('/home');
            _logger.info('✅ [AI_LOADING] Navigation to home completed',
                tag: 'AILoadingPage');
          }
        } catch (e, stackTrace) {
          _logger.error('❌ [AI_LOADING] Error completing onboarding',
              error: e, tag: 'AILoadingPage');
          _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
          // Fallback: use the callback
          if (mounted) {
            try {
              widget.onLoadingComplete();
            } catch (callbackError) {
              _logger.error('❌ [AI_LOADING] Callback also failed',
                  error: callbackError, tag: 'AILoadingPage');
            }
          }
        }
      }
    } else {
      _logger.warn('⚠️ Widget not mounted, cannot complete onboarding',
          tag: 'AILoadingPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome to SPOTS!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re setting up your personalized experience',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
              const SizedBox(height: 48),

              // Loading content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AI Processing Animation
                      AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.psychology,
                              color: AppColors.white,
                              size: 40,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isLoading
                            ? 'AI is creating your personalized lists...'
                            : 'Finishing up...',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing your preferences and favorite places to curate the perfect spots just for you.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalized Lists',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on your homebase, favorite places, and preferences, we\'ll create lists tailored just for you.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Continue button - allow users to proceed immediately
              // The text says "You can start exploring immediately!" so let's honor that
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: _canContinue
                      ? () {
                          // Allow user to skip remaining processing
                          _logger.info('User chose to continue immediately',
                              tag: 'AILoadingPage');
                          // Mark onboarding as complete before navigating
                          _logger.info(
                              '🔄 [AI_LOADING_BUTTON] User clicked Continue, marking onboarding complete...',
                              tag: 'AILoadingPage');
                          _markOnboardingCompleted().then((_) {
                            _logger.info(
                                '✅ [AI_LOADING_BUTTON] Onboarding marked complete, calling onLoadingComplete...',
                                tag: 'AILoadingPage');
                            if (mounted) {
                              widget.onLoadingComplete();
                            }
                          }).catchError((e) {
                            _logger.error(
                                '❌ [AI_LOADING_BUTTON] Error marking onboarding complete: $e',
                                tag: 'AILoadingPage');
                            // Still call callback to allow navigation
                            if (mounted) {
                              widget.onLoadingComplete();
                            }
                          });
                        }
                      : null, // Disable until ready
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _canContinue ? 'Continue' : 'Setting up...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markOnboardingCompleted() async {
    try {
      // Get current user ID from AuthBloc - try multiple times if needed
      AuthBloc? authBloc;
      Authenticated? authState;

      // Try to get auth state with retries
      for (int i = 0; i < 5; i++) {
        try {
          authBloc = context.read<AuthBloc>();
          final state = authBloc.state;
          if (state is Authenticated) {
            authState = state;
            break;
          }
        } catch (e) {
          _logger.debug('Attempt ${i + 1}/5 to get auth state failed: $e',
              tag: 'AILoadingPage');
        }
        if (i < 4) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (authState != null && authState.user.id.isNotEmpty) {
        final userId = authState.user.id;
        _logger.info('📝 Marking onboarding completed for user: $userId',
            tag: 'AILoadingPage');

        try {
          final markStartTime = DateTime.now();
          final success =
              await OnboardingCompletionService.markOnboardingCompleted(userId);
          final markElapsed =
              DateTime.now().difference(markStartTime).inMilliseconds;

          if (success) {
            _logger.info(
                '✅ [AI_LOADING_MARK] Onboarding successfully marked as completed and verified for user $userId (took ${markElapsed}ms)',
                tag: 'AILoadingPage');
          } else {
            _logger.error(
                '❌ [AI_LOADING_MARK] Onboarding completion verification failed for user $userId after marking (took ${markElapsed}ms). Cache is set, but database verification failed.',
                tag: 'AILoadingPage');
            // Still continue - the write might have succeeded but verification is failing
          }
        } catch (e, stackTrace) {
          _logger.error(
              '❌ [AI_LOADING_MARK] Error during onboarding completion process',
              error: e,
              tag: 'AILoadingPage');
          _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
          // Continue anyway - don't block navigation
        }
      } else {
        _logger.error(
            '❌ Cannot mark onboarding completed: user not authenticated or user ID is empty',
            tag: 'AILoadingPage');
        _logger.debug('Auth state: ${authBloc?.state}', tag: 'AILoadingPage');
      }
    } catch (e, stackTrace) {
      _logger.error('❌ Error marking onboarding completed',
          error: e, tag: 'AILoadingPage');
      _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }
}
