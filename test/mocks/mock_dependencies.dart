import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';
import 'package:spots/data/datasources/local/lists_local_datasource.dart';
import 'package:spots/data/datasources/remote/lists_remote_datasource.dart';
import 'package:spots/data/datasources/local/auth_local_datasource.dart';
import 'package:spots/data/datasources/remote/auth_remote_datasource.dart';
import 'package:spots/core/services/storage_service.dart';

import 'mock_dependencies.mocks.dart';

// Generate mocks for all repository dependencies
@GenerateMocks([
  // Connectivity
  Connectivity,
  
  // Spots data sources
  SpotsLocalDataSource,
  SpotsRemoteDataSource,
  
  // Lists data sources
  ListsLocalDataSource,
  ListsRemoteDataSource,
  
  // Auth data sources
  AuthLocalDataSource,
  AuthRemoteDataSource,
  
  // Services
  StorageService,
])
void main() {}

/// Mock factory for creating configured mock instances
class MockFactory {
  /// Creates a mock connectivity instance with common setup
  static MockConnectivity createMockConnectivity() {
    final mock = MockConnectivity();
    // Default to online connectivity
    when(mock.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    return mock;
  }

  /// Creates a mock spots local data source with common setup
  static MockSpotsLocalDataSource createMockSpotsLocalDataSource() {
    final mock = MockSpotsLocalDataSource();
    // Setup common default behaviors
    when(mock.getAllSpots()).thenAnswer((_) async => []);
    when(mock.getSpotsFromRespectedLists()).thenAnswer((_) async => []);
    return mock;
  }

  /// Creates a mock spots remote data source with common setup
  static MockSpotsRemoteDataSource createMockSpotsRemoteDataSource() {
    final mock = MockSpotsRemoteDataSource();
    // Setup common default behaviors
    when(mock.getSpots()).thenAnswer((_) async => []);
    return mock;
  }

  /// Creates a mock lists local data source with common setup
  static MockListsLocalDataSource createMockListsLocalDataSource() {
    final mock = MockListsLocalDataSource();
    // Setup common default behaviors
    when(mock.getLists()).thenAnswer((_) async => []);
    return mock;
  }

  /// Creates a mock lists remote data source with common setup
  static MockListsRemoteDataSource createMockListsRemoteDataSource() {
    final mock = MockListsRemoteDataSource();
    // Setup common default behaviors
    when(mock.getLists()).thenAnswer((_) async => []);
    return mock;
  }

  /// Creates a mock auth local data source with common setup
  static MockAuthLocalDataSource createMockAuthLocalDataSource() {
    final mock = MockAuthLocalDataSource();
    // Setup common default behaviors
    when(mock.getCurrentUser()).thenAnswer((_) async => null);
    return mock;
  }

  /// Creates a mock auth remote data source with common setup
  static MockAuthRemoteDataSource createMockAuthRemoteDataSource() {
    final mock = MockAuthRemoteDataSource();
    // Setup common default behaviors
    when(mock.getCurrentUser()).thenAnswer((_) async => null);
    return mock;
  }
}

/// Utility class for common mock verification patterns
class MockVerifications {
  /// Verifies that a method was called exactly once
  static void verifyCalledOnce(Mock mock, String methodName, [List? arguments]) {
    if (arguments != null) {
      verify(mock.noSuchMethod(
        Invocation.method(Symbol(methodName), arguments),
      )).called(1);
    } else {
      verify(mock.noSuchMethod(
        Invocation.method(Symbol(methodName), []),
      )).called(1);
    }
  }

  /// Verifies that a method was never called
  static void verifyNeverCalled(Mock mock, String methodName, [List? arguments]) {
    if (arguments != null) {
      verifyNever(mock.noSuchMethod(
        Invocation.method(Symbol(methodName), arguments),
      ));
    } else {
      verifyNever(mock.noSuchMethod(
        Invocation.method(Symbol(methodName), []),
      ));
    }
  }

  /// Verifies connectivity was checked
  static void verifyConnectivityChecked(MockConnectivity connectivity) {
    verify(connectivity.checkConnectivity()).called(1);
  }

  /// Verifies no more interactions on all common mocks
  static void verifyNoMoreInteractionsOnAll(List<Mock> mocks) {
    for (final mock in mocks) {
      verifyNoMoreInteractions(mock);
    }
  }
}

/// Mock configurations for different test scenarios
class MockConfigurations {
  /// Configures mocks for offline scenario
  static void configureOfflineScenario({
    required MockConnectivity connectivity,
    MockSpotsLocalDataSource? spotsLocal,
    MockListsLocalDataSource? listsLocal,
    MockAuthLocalDataSource? authLocal,
  }) {
    when(connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);
  }

  /// Configures mocks for online scenario
  static void configureOnlineScenario({
    required MockConnectivity connectivity,
    MockSpotsRemoteDataSource? spotsRemote,
    MockListsRemoteDataSource? listsRemote,
    MockAuthRemoteDataSource? authRemote,
  }) {
    when(connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  /// Configures mocks for remote failure scenario (online but remote fails)
  static void configureRemoteFailureScenario({
    required MockConnectivity connectivity,
    MockSpotsRemoteDataSource? spotsRemote,
    MockListsRemoteDataSource? listsRemote,
    MockAuthRemoteDataSource? authRemote,
    required Exception error,
  }) {
    when(connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    
    if (spotsRemote != null) {
      when(spotsRemote.getSpots()).thenThrow(error);
      when(spotsRemote.createSpot(any)).thenThrow(error);
      when(spotsRemote.updateSpot(any)).thenThrow(error);
      when(spotsRemote.deleteSpot(any)).thenThrow(error);
    }
    
    if (listsRemote != null) {
      when(listsRemote.getLists()).thenThrow(error);
      when(listsRemote.createList(any)).thenThrow(error);
      when(listsRemote.updateList(any)).thenThrow(error);
      when(listsRemote.deleteList(any)).thenThrow(error);
    }
    
    if (authRemote != null) {
      when(authRemote.signIn(any, any)).thenThrow(error);
      when(authRemote.signUp(any, any, any)).thenThrow(error);
      when(authRemote.getCurrentUser()).thenThrow(error);
      when(authRemote.updateUser(any)).thenThrow(error);
    }
  }
}