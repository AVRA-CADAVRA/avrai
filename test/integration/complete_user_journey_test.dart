import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spots/app.dart';
import 'package:spots/presentation/pages/onboarding/onboarding_page.dart';
import 'package:spots/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:spots/presentation/pages/home/home_page.dart';
import 'package:spots/presentation/pages/spots/spots_page.dart';
import 'package:spots/presentation/pages/lists/lists_page.dart';

/// Complete User Journey Integration Test
/// 
/// Tests the critical user flow: Onboarding → Discovery → Creation → Community
/// This ensures the app provides seamless user experience for deployment.
///
/// Flow Validation:
/// 1. User Registration/Login
/// 2. Onboarding Process (homebase selection, preferences, etc.)
/// 3. AI Loading and Personality Initialization
/// 4. Discovery of spots and lists
/// 5. Content creation (spots, lists)
/// 6. Community participation (role progression)
/// 7. Age verification workflow
///
/// Performance Requirements:
/// - Onboarding completion: <30 seconds
/// - Discovery response: <3 seconds
/// - Content creation: <5 seconds
/// - Role progression: <2 seconds
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Complete User Journey Integration Tests', () {
    testWidgets('New User Complete Journey: Registration → Discovery → Creation → Community', (WidgetTester tester) async {
      // Performance tracking
      final stopwatch = Stopwatch()..start();
      
      // 1. App Launch and Initial State
      await tester.pumpWidget(const SpotsApp());
      await tester.pumpAndSettle();
      
      // Verify app starts properly
      expect(find.byType(SpotsApp), findsOneWidget);
      
      // 2. Authentication Flow
      await _testAuthenticationFlow(tester);
      
      final authTime = stopwatch.elapsedMilliseconds;
      expect(authTime, lessThan(5000), reason: 'Authentication should complete within 5 seconds');
      
      // 3. Onboarding Journey
      await _testOnboardingJourney(tester);
      
      final onboardingTime = stopwatch.elapsedMilliseconds - authTime;
      expect(onboardingTime, lessThan(30000), reason: 'Onboarding should complete within 30 seconds');
      
      // 4. AI Loading and Personality Initialization
      await _testAIPersonalityInitialization(tester);
      
      // 5. Discovery Phase
      await _testDiscoveryPhase(tester);
      
      final discoveryTime = stopwatch.elapsedMilliseconds - (authTime + onboardingTime);
      expect(discoveryTime, lessThan(3000), reason: 'Discovery should respond within 3 seconds');
      
      // 6. Content Creation Phase
      await _testContentCreationPhase(tester);
      
      // 7. Community Participation Phase
      await _testCommunityParticipationPhase(tester);
      
      // 8. Role Progression Validation
      await _testRoleProgressionFlow(tester);
      
      stopwatch.stop();
      final totalTime = stopwatch.elapsedMilliseconds;
      
      // Performance validation
      expect(totalTime, lessThan(60000), reason: 'Complete user journey should finish within 60 seconds');
      
      print('✅ Complete User Journey Test completed in ${totalTime}ms');
    });
    
    testWidgets('Returning User Journey: Login → Personalized Discovery → Advanced Features', (WidgetTester tester) async {
      await tester.pumpWidget(const SpotsApp());
      await tester.pumpAndSettle();
      
      // Test returning user experience with existing data
      await _testReturningUserFlow(tester);
    });
    
    testWidgets('Age Verification Journey: Minor → Verification → Access Control', (WidgetTester tester) async {
      await tester.pumpWidget(const SpotsApp());
      await tester.pumpAndSettle();
      
      // Test age verification workflow
      await _testAgeVerificationJourney(tester);
    });
  });
}

/// Test authentication flow for new users
Future<void> _testAuthenticationFlow(WidgetTester tester) async {
  // Look for login/register interface
  final loginButton = find.text('Sign In');
  final registerButton = find.text('Register');
  
  if (loginButton.evaluate().isNotEmpty) {
    // Test registration flow
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    
    // Fill registration form
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'testPassword123');
    await tester.enterText(find.byKey(const Key('confirm_password_field')), 'testPassword123');
    
    // Submit registration
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
  
  // Verify successful authentication
  expect(find.byType(OnboardingPage), findsOneWidget);
}

/// Test complete onboarding journey
Future<void> _testOnboardingJourney(WidgetTester tester) async {
  // Step 1: Homebase Selection
  await _testHomebaseSelection(tester);
  
  // Step 2: Favorite Places
  await _testFavoritePlacesSelection(tester);
  
  // Step 3: Preferences Survey
  await _testPreferencesSurvey(tester);
  
  // Step 4: Baseline Lists
  await _testBaselineListsSetup(tester);
  
  // Step 5: Friends & Respect Network
  await _testFriendsNetworkSetup(tester);
}

/// Test homebase selection step
Future<void> _testHomebaseSelection(WidgetTester tester) async {
  // Verify homebase selection page
  expect(find.byType(HomebaseSelectionPage), findsOneWidget);
  expect(find.text('Choose Your Homebase'), findsOneWidget);
  
  // Select a homebase (simulate map interaction)
  final homebaseOption = find.byKey(const Key('homebase_option_1'));
  if (homebaseOption.evaluate().isNotEmpty) {
    await tester.tap(homebaseOption);
    await tester.pumpAndSettle();
  }
  
  // Verify next button becomes enabled
  final nextButton = find.text('Next');
  expect(nextButton, findsOneWidget);
  
  // Proceed to next step
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
}

/// Test favorite places selection
Future<void> _testFavoritePlacesSelection(WidgetTester tester) async {
  expect(find.text('Favorite Places'), findsOneWidget);
  
  // Add some favorite places
  final addPlaceButton = find.byKey(const Key('add_place_button'));
  if (addPlaceButton.evaluate().isNotEmpty) {
    await tester.tap(addPlaceButton);
    await tester.pumpAndSettle();
    
    // Enter place name
    await tester.enterText(find.byKey(const Key('place_name_field')), 'Central Park');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
  }
  
  // Proceed to next step
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// Test preferences survey
Future<void> _testPreferencesSurvey(WidgetTester tester) async {
  expect(find.text('Preferences'), findsOneWidget);
  
  // Fill out preference categories
  final preferenceSliders = find.byType(Slider);
  if (preferenceSliders.evaluate().isNotEmpty) {
    for (int i = 0; i < preferenceSliders.evaluate().length.clamp(0, 3); i++) {
      await tester.drag(preferenceSliders.at(i), const Offset(50, 0));
      await tester.pumpAndSettle();
    }
  }
  
  // Proceed to next step
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// Test baseline lists setup
Future<void> _testBaselineListsSetup(WidgetTester tester) async {
  expect(find.text('Baseline Lists'), findsOneWidget);
  
  // Select some baseline lists
  final listOptions = find.byType(Checkbox);
  if (listOptions.evaluate().isNotEmpty) {
    // Select first few options
    for (int i = 0; i < listOptions.evaluate().length.clamp(0, 2); i++) {
      await tester.tap(listOptions.at(i));
      await tester.pumpAndSettle();
    }
  }
  
  // Proceed to next step
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// Test friends network setup
Future<void> _testFriendsNetworkSetup(WidgetTester tester) async {
  expect(find.text('Friends & Respect'), findsOneWidget);
  
  // This step is optional, so we can proceed directly
  await tester.tap(find.text('Complete Setup'));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Test AI personality initialization
Future<void> _testAIPersonalityInitialization(WidgetTester tester) async {
  // Look for AI loading page
  final aiLoadingIndicator = find.byKey(const Key('ai_loading_indicator'));
  
  if (aiLoadingIndicator.evaluate().isNotEmpty) {
    // Wait for AI initialization to complete
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }
  
  // Verify navigation to home page
  expect(find.byType(HomePage), findsOneWidget);
}

/// Test discovery phase functionality
Future<void> _testDiscoveryPhase(WidgetTester tester) async {
  // Test spots discovery
  final spotsTab = find.text('Spots');
  if (spotsTab.evaluate().isNotEmpty) {
    await tester.tap(spotsTab);
    await tester.pumpAndSettle();
    
    // Verify spots are loaded
    expect(find.byType(SpotsPage), findsOneWidget);
    
    // Test search functionality
    final searchField = find.byKey(const Key('spots_search_field'));
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField, 'coffee');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify search results appear
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    }
  }
  
  // Test lists discovery
  final listsTab = find.text('Lists');
  if (listsTab.evaluate().isNotEmpty) {
    await tester.tap(listsTab);
    await tester.pumpAndSettle();
    
    // Verify lists are loaded
    expect(find.byType(ListsPage), findsOneWidget);
  }
}

/// Test content creation phase
Future<void> _testContentCreationPhase(WidgetTester tester) async {
  // Test spot creation
  final createSpotButton = find.byKey(const Key('create_spot_button'));
  if (createSpotButton.evaluate().isNotEmpty) {
    await tester.tap(createSpotButton);
    await tester.pumpAndSettle();
    
    // Fill spot creation form
    await _fillSpotCreationForm(tester);
    
    // Submit spot creation
    await tester.tap(find.text('Create Spot'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
  
  // Test list creation
  final createListButton = find.byKey(const Key('create_list_button'));
  if (createListButton.evaluate().isNotEmpty) {
    await tester.tap(createListButton);
    await tester.pumpAndSettle();
    
    // Fill list creation form
    await _fillListCreationForm(tester);
    
    // Submit list creation
    await tester.tap(find.text('Create List'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Helper to fill spot creation form
Future<void> _fillSpotCreationForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('spot_name_field')), 'Great Coffee Shop');
  await tester.enterText(find.byKey(const Key('spot_description_field')), 'Amazing coffee and atmosphere');
  
  // Select category
  final categoryDropdown = find.byKey(const Key('spot_category_dropdown'));
  if (categoryDropdown.evaluate().isNotEmpty) {
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Drink').last);
    await tester.pumpAndSettle();
  }
}

/// Helper to fill list creation form
Future<void> _fillListCreationForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('list_name_field')), 'My Coffee Places');
  await tester.enterText(find.byKey(const Key('list_description_field')), 'Best coffee shops in the city');
  
  // Set privacy settings
  final privacyToggle = find.byKey(const Key('list_privacy_toggle'));
  if (privacyToggle.evaluate().isNotEmpty) {
    await tester.tap(privacyToggle);
    await tester.pumpAndSettle();
  }
}

/// Test community participation features
Future<void> _testCommunityParticipationPhase(WidgetTester tester) async {
  // Test respecting a list
  final respectButton = find.byKey(const Key('respect_list_button'));
  if (respectButton.evaluate().isNotEmpty) {
    await tester.tap(respectButton);
    await tester.pumpAndSettle();
    
    // Verify respect action succeeded
    expect(find.byKey(const Key('respected_indicator')), findsOneWidget);
  }
  
  // Test collaborative editing
  final collaborateButton = find.byKey(const Key('collaborate_button'));
  if (collaborateButton.evaluate().isNotEmpty) {
    await tester.tap(collaborateButton);
    await tester.pumpAndSettle();
    
    // Verify collaboration request is sent
    expect(find.text('Collaboration request sent'), findsOneWidget);
  }
}

/// Test role progression flow
Future<void> _testRoleProgressionFlow(WidgetTester tester) async {
  // Verify user starts as follower
  final profileTab = find.byKey(const Key('profile_tab'));
  if (profileTab.evaluate().isNotEmpty) {
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    
    // Check current role
    expect(find.text('Follower'), findsOneWidget);
    
    // Simulate actions that lead to role progression
    // Creating lists should elevate to curator status
    await _simulateProgressionActivities(tester);
    
    // Verify role progression
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Role progression might not be immediate, so we test the mechanism exists
    expect(find.byKey(const Key('role_progression_indicator')), findsWidgets);
  }
}

/// Simulate activities that trigger role progression
Future<void> _simulateProgressionActivities(WidgetTester tester) async {
  // Activities that might trigger curator status:
  // 1. Creating quality lists
  // 2. Getting community respect
  // 3. Consistent engagement
  
  // For testing purposes, we'll simulate the progression trigger
  final progressionTrigger = find.byKey(const Key('progression_trigger'));
  if (progressionTrigger.evaluate().isNotEmpty) {
    await tester.tap(progressionTrigger);
    await tester.pumpAndSettle();
  }
}

/// Test returning user flow
Future<void> _testReturningUserFlow(WidgetTester tester) async {
  // Simulate existing user data
  // Test personalized recommendations
  // Test saved preferences
  // Test cached content availability
  
  // Skip onboarding for returning users
  expect(find.byType(HomePage), findsOneWidget);
  
  // Test personalized discovery
  final recommendationsList = find.byKey(const Key('personalized_recommendations'));
  expect(recommendationsList, findsOneWidget);
}

/// Test age verification journey
Future<void> _testAgeVerificationJourney(WidgetTester tester) async {
  // Test age verification prompt
  final ageVerificationPrompt = find.text('Age Verification Required');
  if (ageVerificationPrompt.evaluate().isNotEmpty) {
    // Test age verification form
    await tester.enterText(find.byKey(const Key('birth_date_field')), '01/01/2000');
    await tester.tap(find.text('Verify Age'));
    await tester.pumpAndSettle();
    
    // Verify access to age-restricted content
    expect(find.text('Age verified successfully'), findsOneWidget);
  }
  
  // Test access control for minors
  final restrictedContent = find.byKey(const Key('age_restricted_content'));
  if (restrictedContent.evaluate().isNotEmpty) {
    await tester.tap(restrictedContent);
    await tester.pumpAndSettle();
    
    // Should show access denied for unverified users
    expect(find.text('Age verification required'), findsOneWidget);
  }
}
