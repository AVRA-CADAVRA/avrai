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
import 'dart:async';

class AILoadingPage extends StatefulWidget {
  final String userName;
  final DateTime? birthday;
  final int? age;
  final String? homebase;
  final List<String> favoritePlaces;
  final Map<String, List<String>> preferences;
  final Function() onLoadingComplete;

  const AILoadingPage({
    super.key,
    required this.userName,
    this.birthday,
    this.age,
    this.homebase,
    this.favoritePlaces = const [],
    this.preferences = const {},
    required this.onLoadingComplete,
  });

  @override
  State<AILoadingPage> createState() => _AILoadingPageState();
}

class _AILoadingPageState extends State<AILoadingPage>
    with TickerProviderStateMixin {
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  bool _isLoading = true;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

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

    try {
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
        _logger.warn('⚠️ Using fallback homebase: $homebase', tag: 'AILoadingPage');
      }
      if (favoritePlaces.isEmpty) {
        favoritePlaces = [
          "Central Park",
          "Brooklyn Bridge",
          "Times Square",
          "Empire State Building",
          "Statue of Liberty"
        ];
        _logger.warn('⚠️ Using fallback favorite places: $favoritePlaces', tag: 'AILoadingPage');
      }
      if (preferences.isEmpty) {
        preferences = {
          'Food & Drink': ['Coffee & Tea', 'Fine Dining', 'Craft Beer'],
          'Activities': ['Live Music', 'Theaters', 'Shopping'],
          'Outdoor & Nature': ['Parks', 'Hiking Trails', 'Scenic Views']
        };
        _logger.warn('⚠️ Using fallback preferences: $preferences', tag: 'AILoadingPage');
      }

      // Generate personalized lists using AI with age consideration
      _logger.info('🔄 Generating AI lists...', tag: 'AILoadingPage');
      _logger.debug('  Age: ${widget.age ?? 'not provided'}', tag: 'AILoadingPage');
      final generatedLists = await AIListGeneratorService.generatePersonalizedLists(
        userName: userName,
        age: widget.age,
        homebase: homebase,
        favoritePlaces: favoritePlaces,
        preferences: preferences,
      );

      _logger.info('✅ Generated ${generatedLists.length} lists: $generatedLists', tag: 'AILoadingPage');

      // Create the lists in the app - use use case directly to wait for completion
      if (mounted && generatedLists.isNotEmpty) {
        try {
          _logger.info('📝 Getting CreateListUseCase from DI...', tag: 'AILoadingPage');
          final createListUseCase = di.sl<CreateListUseCase>();
          final listsBloc = context.read<ListsBloc>();
          
          _logger.info('📝 Creating ${generatedLists.length} lists...', tag: 'AILoadingPage');
          
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
              _logger.debug('📝 Creating list ${i + 1}/${generatedLists.length}: ${newList.title}', tag: 'AILoadingPage');
              
              // Add timeout to prevent hanging
              await createListUseCase(newList)
                  .timeout(const Duration(seconds: 5), onTimeout: () {
                _logger.warn('⏱️ Timeout creating list ${newList.title}', tag: 'AILoadingPage');
                throw TimeoutException('List creation timeout', const Duration(seconds: 5));
              });
              
              successCount++;
              _logger.debug('✅ Created list: ${newList.title}', tag: 'AILoadingPage');
            } catch (e) {
              _logger.error('❌ Error creating list ${newList.title}', error: e, tag: 'AILoadingPage');
              // Continue with other lists even if one fails
            }
          }
          
          _logger.info('✅ Successfully created $successCount/${generatedLists.length} lists', tag: 'AILoadingPage');
          
          // Reload lists once after all are created
          if (mounted) {
            listsBloc.add(LoadLists());
            // Small delay to ensure UI updates
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          _logger.error('❌ Error in list creation process', error: e, tag: 'AILoadingPage');
          // Continue anyway - don't block onboarding completion
        }
      } else {
        _logger.warn('⚠️ No lists generated or widget not mounted', tag: 'AILoadingPage');
        // Still show loading animation even if no lists generated
        await Future.delayed(const Duration(seconds: 1));
      }

    } catch (e, stackTrace) {
      // Handle error - still complete onboarding
      _logger.error('❌ Error in AI loading process', error: e, tag: 'AILoadingPage');
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
          _logger.info('📝 Marking onboarding as completed...', tag: 'AILoadingPage');
          await _markOnboardingCompleted();
          _logger.info('✅ Onboarding marked as completed', tag: 'AILoadingPage');
          
          // Longer delay to ensure database write completes (especially on web IndexedDB)
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Navigate to home using go_router
          if (mounted) {
            _logger.info('🏠 Navigating to home...', tag: 'AILoadingPage');
            context.go('/home');
            _logger.info('✅ Onboarding completed, navigated to home', tag: 'AILoadingPage');
          }
        } catch (e, stackTrace) {
          _logger.error('❌ Error completing onboarding', error: e, tag: 'AILoadingPage');
          _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
          // Fallback: use the callback
          if (mounted) {
            try {
              widget.onLoadingComplete();
            } catch (callbackError) {
              _logger.error('❌ Callback also failed', error: callbackError, tag: 'AILoadingPage');
            }
          }
        }
      }
    } else {
      _logger.warn('⚠️ Widget not mounted, cannot complete onboarding', tag: 'AILoadingPage');
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
                        'AI is creating your personalized lists...',
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
          _logger.debug('Attempt ${i + 1}/5 to get auth state failed: $e', tag: 'AILoadingPage');
        }
        if (i < 4) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      if (authState != null && authState.user.id.isNotEmpty) {
        final userId = authState.user.id;
        _logger.info('📝 Marking onboarding completed for user: $userId', tag: 'AILoadingPage');
        
        try {
          await OnboardingCompletionService.markOnboardingCompleted(userId);
          
          // Verify it was saved - try multiple times with delays for web IndexedDB
          bool isCompleted = false;
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(milliseconds: 200));
            isCompleted = await OnboardingCompletionService.isOnboardingCompleted(userId);
            if (isCompleted) {
              break;
            }
          }
          
          if (isCompleted) {
            _logger.info('✅ Onboarding successfully marked as completed for user $userId', tag: 'AILoadingPage');
          } else {
            _logger.error('❌ Onboarding completion was NOT saved! Verification failed for user $userId after 5 attempts', tag: 'AILoadingPage');
            // Still continue - the write might have succeeded but verification is failing
          }
        } catch (e, stackTrace) {
          _logger.error('❌ Error during onboarding completion process', error: e, tag: 'AILoadingPage');
          _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
          // Continue anyway - don't block navigation
        }
      } else {
        _logger.error('❌ Cannot mark onboarding completed: user not authenticated or user ID is empty', tag: 'AILoadingPage');
        _logger.debug('Auth state: ${authBloc?.state}', tag: 'AILoadingPage');
      }
    } catch (e, stackTrace) {
      _logger.error('❌ Error marking onboarding completed', error: e, tag: 'AILoadingPage');
      _logger.debug('Stack trace: $stackTrace', tag: 'AILoadingPage');
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }
}
