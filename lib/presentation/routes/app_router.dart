import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:spots/presentation/pages/auth/auth_wrapper.dart';
import 'package:spots/presentation/pages/auth/login_page.dart';
import 'package:spots/presentation/pages/auth/signup_page.dart';
import 'package:spots/presentation/pages/home/home_page.dart';
import 'package:spots/presentation/pages/spots/spots_page.dart';
import 'package:spots/presentation/pages/lists/lists_page.dart';
import 'package:spots/presentation/pages/map/map_page.dart';
import 'package:spots/presentation/pages/profile/profile_page.dart';
import 'package:spots/presentation/pages/profile/ai_personality_status_page.dart';
import 'package:spots/presentation/pages/expertise/expertise_dashboard_page.dart';
import 'package:spots/presentation/pages/onboarding/onboarding_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spots/presentation/pages/onboarding/ai_loading_page.dart';
import 'package:spots/presentation/pages/supabase_test_page.dart';
import 'package:spots/presentation/pages/search/hybrid_search_page.dart';
import 'package:spots/presentation/pages/admin/ai2ai_admin_dashboard.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/injection_container.dart' as di;
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/data/datasources/local/onboarding_completion_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
// Phase 1 Integration: Device Discovery & AI2AI Connections
import 'package:spots/presentation/pages/network/device_discovery_page.dart';
import 'package:spots/presentation/pages/network/ai2ai_connections_page.dart';
import 'package:spots/presentation/pages/settings/discovery_settings_page.dart';
// Phase 2.1: Federated Learning
import 'package:spots/presentation/pages/settings/federated_learning_page.dart';
// Phase 7, Week 37: AI Self-Improvement Visibility
import 'package:spots/presentation/pages/settings/ai_improvement_page.dart';
// Phase 7, Week 38: AI2AI Learning Methods UI
import 'package:spots/presentation/pages/settings/ai2ai_learning_methods_page.dart';
// Phase 7, Section 39: Continuous Learning UI
import 'package:spots/presentation/pages/settings/continuous_learning_page.dart';
// Phase 4.5: Partnerships Page
import 'package:spots/presentation/pages/profile/partnerships_page.dart';
// Phase 6, Week 29: Communities & Clubs
import 'package:spots/presentation/pages/communities/community_page.dart';
import 'package:spots/presentation/pages/clubs/club_page.dart';

class AppRouter {
  // Route path helpers for legacy Navigator.pushNamed usages
  static const String home = '/home';
  static const String signup = '/signup';

  static GoRouter build({required AuthBloc authBloc}) {
    const bool goToSupabaseTest = bool.fromEnvironment('GO_TO_SUPABASE_TEST');
    const bool autoDriveSupabase = bool.fromEnvironment('AUTO_DRIVE_SUPABASE_TEST');
    final analytics = FirebaseAnalytics.instance;
    return GoRouter(
      initialLocation: goToSupabaseTest
          ? (autoDriveSupabase ? '/supabase-test?auto=1' : '/supabase-test')
          : '/',
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) async {
        final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isRoot = state.matchedLocation == '/';
        final isSupabaseTest = state.matchedLocation.startsWith('/supabase-test');

        // When test flag is enabled, always allow and prefer the Supabase test page
        if (goToSupabaseTest) {
          if (!isSupabaseTest) {
            return autoDriveSupabase ? '/supabase-test?auto=1' : '/supabase-test';
          }
          return null;
        }

        final authState = authBloc.state;

        if (authState is Authenticated) {
          // Allow ai-loading page to proceed without redirect
          if (state.matchedLocation == '/ai-loading') {
            return null;
          }
          // If authenticated, ensure onboarding completed for this specific user
          // Add a small delay on web to allow IndexedDB writes to complete
          if (kIsWeb) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          final onboardingDone = await OnboardingCompletionService.isOnboardingCompleted(authState.user.id);
          if (!onboardingDone && !isOnboarding && state.matchedLocation != '/ai-loading') {
            return '/onboarding';
          }
          // After onboarding, ensure critical permissions present
          if (!await _hasCriticalPermissions() && state.matchedLocation != '/onboarding' && state.matchedLocation != '/ai-loading') {
            return '/onboarding?reason=permissions_required';
          }
          // Prevent going back to auth pages
          if (isLoggingIn || isRoot) {
            return '/home';
          }
          return null;
        }

        // Unauthenticated: allow login/signup/onboarding/root; also allow supabase-test when running in test mode
        if (!(isLoggingIn || isOnboarding || isRoot || isSupabaseTest)) {
          return '/login';
        }
        return null;
      },
      observers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthWrapper(),
          routes: [
            GoRoute(path: 'login', builder: (c, s) => const LoginPage()),
            GoRoute(path: 'signup', builder: (c, s) => const SignupPage()),
            GoRoute(path: 'home', builder: (c, s) => const HomePage()),
            GoRoute(path: 'spots', builder: (c, s) => const SpotsPage()),
            GoRoute(path: 'lists', builder: (c, s) => const ListsPage()),
            GoRoute(
              path: 'map',
              redirect: (context, state) async {
                // Skip permission check on web
                if (kIsWeb) {
                  return null;
                }
                try {
                  final locWhenInUse = await Permission.locationWhenInUse.status;
                  if (!locWhenInUse.isGranted && !locWhenInUse.isLimited) {
                    return '/onboarding?reason=location_required';
                  }
                } catch (e) {
                  // If permission check fails, allow access
                }
                return null;
              },
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: BlocProvider.of<ListsBloc>(context)),
                  BlocProvider.value(value: BlocProvider.of<SpotsBloc>(context)),
                ],
                child: const MapPage(),
              ),
            ),
            GoRoute(path: 'profile', builder: (c, s) => const ProfilePage()),
            GoRoute(
              path: 'profile/ai-status',
              builder: (c, s) => const AIPersonalityStatusPage(),
            ),
            GoRoute(
              path: 'profile/expertise-dashboard',
              builder: (c, s) => const ExpertiseDashboardPage(),
            ),
            // Phase 4.5: Partnerships Page
            GoRoute(
              path: 'profile/partnerships',
              builder: (c, s) => const PartnershipsPage(),
            ),
            // Phase 6, Week 29: Communities & Clubs
            GoRoute(
              path: 'community/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return CommunityPage(communityId: id);
              },
            ),
            GoRoute(
              path: 'club/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return ClubPage(clubId: id);
              },
            ),
            GoRoute(
              path: 'admin/ai2ai',
              builder: (c, s) => const AI2AIAdminDashboard(),
            ),
            // Phase 1 Integration: Device Discovery & AI2AI Routes
            GoRoute(
              path: 'device-discovery',
              builder: (c, s) => const DeviceDiscoveryPage(),
            ),
            GoRoute(
              path: 'ai2ai-connections',
              builder: (c, s) => const AI2AIConnectionsPage(),
            ),
            GoRoute(
              path: 'discovery-settings',
              builder: (c, s) => const DiscoverySettingsPage(),
            ),
            // Phase 2.1: Federated Learning
            GoRoute(
              path: 'federated-learning',
              builder: (c, s) => const FederatedLearningPage(),
            ),
            // Phase 7, Week 37: AI Self-Improvement Visibility
            GoRoute(
              path: 'ai-improvement',
              builder: (c, s) => const AIImprovementPage(),
            ),
            // Phase 7, Week 38: AI2AI Learning Methods UI
            GoRoute(
              path: 'ai2ai-learning-methods',
              builder: (c, s) => const AI2AILearningMethodsPage(),
            ),
            // Phase 7, Section 39: Continuous Learning UI
            GoRoute(
              path: 'continuous-learning',
              builder: (c, s) => const ContinuousLearningPage(),
            ),
            GoRoute(
              path: 'supabase-test',
              builder: (c, s) {
                final auto = s.uri.queryParameters['auto'] == '1';
                return SupabaseTestPage(auto: auto);
              },
            ),
            GoRoute(
              path: 'onboarding',
              builder: (context, state) {
                final reason = state.uri.queryParameters['reason'];
                if (reason != null && reason.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final text = switch (reason) {
                      'permissions_required' => 'Permissions required for ai2ai connectivity. Please enable to continue.',
                      'location_required' => 'Location permission required to use the map.',
                      _ => 'Additional permissions are required.'
                    };
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(text)),
                    );
                  });
                }
                return const OnboardingPage();
              },
            ),
            GoRoute(
              path: 'ai-loading',
              builder: (c, s) {
                // Extract onboarding data from query parameters or state
                final extra = s.extra as Map<String, dynamic>?;
                // Parse birthday if provided
                DateTime? birthday;
                if (extra?['birthday'] != null) {
                  try {
                    birthday = DateTime.parse(extra!['birthday'] as String);
                  } catch (e) {
                    // Invalid date, ignore
                  }
                }
                final age = extra?['age'] as int?;

                return AILoadingPage(
                  userName: extra?['userName'] as String? ?? 'User',
                  birthday: birthday,
                  age: age,
                  homebase: extra?['homebase'] as String?,
                  favoritePlaces: (extra?['favoritePlaces'] as List<dynamic>?)?.cast<String>() ?? const [],
                  preferences: (extra?['preferences'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as List<dynamic>).cast<String>())) ?? const {},
                  onLoadingComplete: () {
                    // Mark onboarding as completed and navigate to home
                    c.go('/home');
                  },
                );
              },
            ),
            GoRoute(
              path: 'hybrid-search',
              builder: (context, state) => BlocProvider(
                create: (context) => di.sl<HybridSearchBloc>(),
                child: const HybridSearchPage(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Simple adapter to notify GoRouter when the auth bloc emits a new state
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Future<bool> _hasCriticalPermissions() async {
  // On web, many permissions are not supported, so we skip the check
  // Web browsers handle permissions differently (e.g., geolocation API)
  if (kIsWeb) {
    return true; // Allow web to proceed without mobile-specific permissions
  }

  try {
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ].request();

    bool ok(PermissionStatus s) => s.isGranted || s.isLimited || s.isProvisional;

    return statuses.values.where((s) => !ok(s)).isEmpty;
  } catch (e) {
    // If permission check fails, allow to proceed (don't block navigation)
    return true;
  }
}
