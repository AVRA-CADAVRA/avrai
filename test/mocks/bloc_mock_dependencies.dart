/// BLoC Mock Dependencies - Phase 4: BLoC State Management Testing
///
/// Comprehensive mocks for all BLoC dependencies to ensure isolated testing
/// Follows mocktail patterns for optimal development and deployment testing
library;

import 'package:mocktail/mocktail.dart';
import 'package:avrai/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai/domain/usecases/auth/update_password_usecase.dart';
import 'package:avrai/domain/usecases/spots/get_spots_usecase.dart';
import 'package:avrai/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:avrai/domain/usecases/spots/create_spot_usecase.dart';
import 'package:avrai/domain/usecases/spots/update_spot_usecase.dart';
import 'package:avrai/domain/usecases/spots/delete_spot_usecase.dart';
import 'package:avrai/domain/usecases/lists/get_lists_usecase.dart';
import 'package:avrai/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai/domain/usecases/lists/delete_list_usecase.dart';
import 'package:avrai/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:avrai/core/services/search_cache_service.dart';
import 'package:avrai/core/services/ai_search_suggestions_service.dart';
import 'package:avrai/data/repositories/hybrid_search_repository.dart';
import '../helpers/bloc_test_helpers.dart';

// Auth Use Case Mocks
class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockUpdatePasswordUseCase extends Mock implements UpdatePasswordUseCase {}

// Spots Use Case Mocks
class MockGetSpotsUseCase extends Mock implements GetSpotsUseCase {}

class MockGetSpotsFromRespectedListsUseCase extends Mock
    implements GetSpotsFromRespectedListsUseCase {}

class MockCreateSpotUseCase extends Mock implements CreateSpotUseCase {}

class MockUpdateSpotUseCase extends Mock implements UpdateSpotUseCase {}

class MockDeleteSpotUseCase extends Mock implements DeleteSpotUseCase {}

// Lists Use Case Mocks
class MockGetListsUseCase extends Mock implements GetListsUseCase {}

class MockCreateListUseCase extends Mock implements CreateListUseCase {}

class MockUpdateListUseCase extends Mock implements UpdateListUseCase {}

class MockDeleteListUseCase extends Mock implements DeleteListUseCase {}

// Search Use Case and Service Mocks
class MockHybridSearchUseCase extends Mock implements HybridSearchUseCase {}

class MockSearchCacheService extends Mock implements SearchCacheService {}

class MockAISearchSuggestionsService extends Mock
    implements AISearchSuggestionsService {}

class MockHybridSearchRepository extends Mock
    implements HybridSearchRepository {}

/// Mock dependency factory for creating all BLoC dependencies
class BlocMockFactory {
  // Auth mocks
  static MockSignInUseCase signInUseCase = MockSignInUseCase();
  static MockSignUpUseCase signUpUseCase = MockSignUpUseCase();
  static MockSignOutUseCase signOutUseCase = MockSignOutUseCase();
  static MockGetCurrentUserUseCase getCurrentUserUseCase =
      MockGetCurrentUserUseCase();
  static MockUpdatePasswordUseCase updatePasswordUseCase =
      MockUpdatePasswordUseCase();

  // Spots mocks
  static MockGetSpotsUseCase getSpotsUseCase = MockGetSpotsUseCase();
  static MockGetSpotsFromRespectedListsUseCase
      getSpotsFromRespectedListsUseCase =
      MockGetSpotsFromRespectedListsUseCase();
  static MockCreateSpotUseCase createSpotUseCase = MockCreateSpotUseCase();
  static MockUpdateSpotUseCase updateSpotUseCase = MockUpdateSpotUseCase();
  static MockDeleteSpotUseCase deleteSpotUseCase = MockDeleteSpotUseCase();

  // Lists mocks
  static MockGetListsUseCase getListsUseCase = MockGetListsUseCase();
  static MockCreateListUseCase createListUseCase = MockCreateListUseCase();
  static MockUpdateListUseCase updateListUseCase = MockUpdateListUseCase();
  static MockDeleteListUseCase deleteListUseCase = MockDeleteListUseCase();

  // Search mocks
  static MockHybridSearchUseCase hybridSearchUseCase =
      MockHybridSearchUseCase();
  static MockSearchCacheService searchCacheService = MockSearchCacheService();
  static MockAISearchSuggestionsService aiSearchSuggestionsService =
      MockAISearchSuggestionsService();

  /// Resets all mocks - call this in setUp() for each test
  static void resetAll() {
    // Auth mocks
    reset(signInUseCase);
    reset(signUpUseCase);
    reset(signOutUseCase);
    reset(getCurrentUserUseCase);
    reset(updatePasswordUseCase);

    // Spots mocks
    reset(getSpotsUseCase);
    reset(getSpotsFromRespectedListsUseCase);
    reset(createSpotUseCase);
    reset(updateSpotUseCase);
    reset(deleteSpotUseCase);

    // Lists mocks
    reset(getListsUseCase);
    reset(createListUseCase);
    reset(updateListUseCase);
    reset(deleteListUseCase);

    // Search mocks
    reset(hybridSearchUseCase);
    reset(searchCacheService);
    reset(aiSearchSuggestionsService);
  }

  /// Registers fallback values for mocktail - call this in setUpAll()
  static void registerFallbacks() {
    // Register fallback values that mocktail needs for type safety
    registerFallbackValue('');
    registerFallbackValue(0);
    registerFallbackValue(false);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<int>[]);
    registerFallbackValue(DateTime.now());
  }
}

/// Mock behavior setup helpers for common scenarios
class MockBehaviorSetup {
  /// Sets up successful auth flow for testing
  static void setupSuccessfulAuth() {
    when(() => BlocMockFactory.signInUseCase.call(any(), any()))
        .thenAnswer((_) async => TestDataFactory.createTestUser());

    when(() => BlocMockFactory.signUpUseCase.call(any(), any(), any()))
        .thenAnswer((_) async => TestDataFactory.createTestUser());

    when(() => BlocMockFactory.signOutUseCase.call()).thenAnswer((_) async {
      return;
    });

    when(() => BlocMockFactory.getCurrentUserUseCase.call())
        .thenAnswer((_) async => TestDataFactory.createTestUser());
  }

  /// Sets up auth failure scenarios
  static void setupAuthFailure() {
    when(() => BlocMockFactory.signInUseCase.call(any(), any()))
        .thenThrow(Exception('Invalid credentials'));

    when(() => BlocMockFactory.signUpUseCase.call(any(), any(), any()))
        .thenThrow(Exception('Failed to create account'));

    when(() => BlocMockFactory.getCurrentUserUseCase.call())
        .thenAnswer((_) async => null);
  }

  /// Sets up successful spots operations
  static void setupSuccessfulSpots() {
    when(() => BlocMockFactory.getSpotsUseCase.call())
        .thenAnswer((_) async => TestDataFactory.createTestSpots(5));

    when(() => BlocMockFactory.getSpotsFromRespectedListsUseCase.call())
        .thenAnswer((_) async => TestDataFactory.createTestSpots(3));

    when(() => BlocMockFactory.createSpotUseCase.call(any()))
        .thenAnswer((_) async => TestDataFactory.createTestSpot());

    when(() => BlocMockFactory.updateSpotUseCase.call(any()))
        .thenAnswer((_) async => TestDataFactory.createTestSpot());

    when(() => BlocMockFactory.deleteSpotUseCase.call(any()))
        .thenAnswer((_) async {
      return;
    });
  }

  /// Sets up spots operation failures
  static void setupSpotsFailure() {
    when(() => BlocMockFactory.getSpotsUseCase.call())
        .thenThrow(Exception('Failed to load spots'));

    when(() => BlocMockFactory.createSpotUseCase.call(any()))
        .thenThrow(Exception('Failed to create spot'));

    when(() => BlocMockFactory.updateSpotUseCase.call(any()))
        .thenThrow(Exception('Failed to update spot'));

    when(() => BlocMockFactory.deleteSpotUseCase.call(any()))
        .thenThrow(Exception('Failed to delete spot'));
  }

  /// Sets up successful lists operations
  static void setupSuccessfulLists() {
    when(() => BlocMockFactory.getListsUseCase.call())
        .thenAnswer((_) async => TestDataFactory.createTestLists(5));

    when(() => BlocMockFactory.createListUseCase.call(any()))
        .thenAnswer((_) async => TestDataFactory.createTestList());

    when(() => BlocMockFactory.updateListUseCase.call(any()))
        .thenAnswer((_) async => TestDataFactory.createTestList());

    when(() => BlocMockFactory.deleteListUseCase.call(any()))
        .thenAnswer((_) async {
      return;
    });
  }

  /// Sets up lists operation failures
  static void setupListsFailure() {
    when(() => BlocMockFactory.getListsUseCase.call())
        .thenThrow(Exception('Failed to load lists'));

    when(() => BlocMockFactory.createListUseCase.call(any()))
        .thenThrow(Exception('Failed to create list'));
  }

  /// Sets up successful search operations
  static void setupSuccessfulSearch({bool includeFilters = false}) {
    when(() => BlocMockFactory.hybridSearchUseCase.searchSpots(
          query: any(named: 'query'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          maxResults: any(named: 'maxResults'),
          includeExternal: any(named: 'includeExternal'),
          filters: any(named: 'filters'),
          sortOption: any(named: 'sortOption'),
        )).thenAnswer((_) async => HybridSearchResult(
          spots: TestDataFactory.createTestSpots(10),
          communityCount: 5,
          externalCount: 5,
          totalCount: 10,
          searchDuration: const Duration(milliseconds: 150),
          sources: {'community': 5, 'external': 5},
        ));

    when(() => BlocMockFactory.hybridSearchUseCase.searchNearbySpots(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          radius: any(named: 'radius'),
          maxResults: any(named: 'maxResults'),
          includeExternal: any(named: 'includeExternal'),
        )).thenAnswer((_) async => HybridSearchResult(
          spots: TestDataFactory.createTestSpots(5),
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: const Duration(milliseconds: 100),
          sources: {'community': 3, 'external': 2},
        ));

    when(() => BlocMockFactory.searchCacheService.getCachedResult(
          query: any(named: 'query'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          maxResults: any(named: 'maxResults'),
          includeExternal: any(named: 'includeExternal'),
        )).thenAnswer((_) async => null); // No cache by default

    when(() => BlocMockFactory.searchCacheService.cacheResult(
          query: any(named: 'query'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          maxResults: any(named: 'maxResults'),
          includeExternal: any(named: 'includeExternal'),
          result: any(named: 'result'),
        )).thenAnswer((_) async {
      return;
    });

    when(() => BlocMockFactory.aiSearchSuggestionsService.learnFromSearch(
          query: any(named: 'query'),
          results: any(named: 'results'),
        )).thenReturn(null);

    when(() => BlocMockFactory.aiSearchSuggestionsService.generateSuggestions(
          query: any(named: 'query'),
          userLocation: any(named: 'userLocation'),
          communityTrends: any(named: 'communityTrends'),
        )).thenAnswer((_) async => [
          SearchSuggestion(
            text: 'coffee shop',
            type: SuggestionType.completion,
            confidence: 0.9,
            icon: '☕',
          ),
          SearchSuggestion(
            text: 'restaurant',
            type: SuggestionType.contextual,
            confidence: 0.8,
            icon: '🍽️',
          ),
        ]);

    when(() => BlocMockFactory.aiSearchSuggestionsService.getSearchPatterns())
        .thenReturn({
      'recent': ['coffee', 'food'],
      'popular': ['restaurant', 'bar']
    });

    when(() => BlocMockFactory.searchCacheService.getCacheStatistics())
        .thenReturn({'hitRate': 0.75, 'totalQueries': 100});

    when(() => BlocMockFactory.searchCacheService.prefetchPopularSearches(
          searchFunction: any(named: 'searchFunction'),
        )).thenAnswer((_) async {
      return;
    });

    when(() => BlocMockFactory.searchCacheService.warmLocationCache(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          nearbySearchFunction: any(named: 'nearbySearchFunction'),
        )).thenAnswer((_) async {
      return;
    });

    when(() => BlocMockFactory.searchCacheService.clearCache(
          preserveOffline: any(named: 'preserveOffline'),
        )).thenAnswer((_) async {
      return;
    });

    when(() => BlocMockFactory.aiSearchSuggestionsService.clearLearningData())
        .thenReturn(null);
  }

  /// Sets up search operation failures
  static void setupSearchFailure() {
    when(() => BlocMockFactory.hybridSearchUseCase.searchSpots(
          query: any(named: 'query'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          maxResults: any(named: 'maxResults'),
          includeExternal: any(named: 'includeExternal'),
          filters: any(named: 'filters'),
          sortOption: any(named: 'sortOption'),
        )).thenThrow(Exception('Search failed'));
  }
}
