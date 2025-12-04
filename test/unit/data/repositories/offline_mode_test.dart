import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/data/repositories/spots_repository_impl.dart';
import 'package:spots/data/repositories/lists_repository_impl.dart';
import 'package:spots/data/repositories/auth_repository_impl.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/data/datasources/local/lists_local_datasource.dart';
import 'package:spots/data/datasources/local/auth_local_datasource.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';
import 'package:spots/data/datasources/remote/lists_remote_datasource.dart';
import 'package:spots/data/datasources/remote/auth_remote_datasource.dart';

import 'offline_mode_test.mocks.dart';

@GenerateMocks([
  SpotsLocalDataSource,
  SpotsRemoteDataSource,
  ListsLocalDataSource,
  ListsRemoteDataSource,
  AuthLocalDataSource,
  AuthRemoteDataSource,
  Connectivity,
])
void main() {
  group('Offline Mode Tests', () {
    late MockSpotsLocalDataSource mockSpotsLocal;
    late MockSpotsRemoteDataSource mockSpotsRemote;
    late MockListsLocalDataSource mockListsLocal;
    late MockListsRemoteDataSource mockListsRemote;
    late MockAuthLocalDataSource mockAuthLocal;
    late MockAuthRemoteDataSource mockAuthRemote;
    late MockConnectivity mockConnectivity;
    late SpotsRepositoryImpl spotsRepository;
    late ListsRepositoryImpl listsRepository;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      mockSpotsLocal = MockSpotsLocalDataSource();
      mockSpotsRemote = MockSpotsRemoteDataSource();
      mockListsLocal = MockListsLocalDataSource();
      mockListsRemote = MockListsRemoteDataSource();
      mockAuthLocal = MockAuthLocalDataSource();
      mockAuthRemote = MockAuthRemoteDataSource();
      mockConnectivity = MockConnectivity();

      spotsRepository = SpotsRepositoryImpl(
        remoteDataSource: mockSpotsRemote,
        localDataSource: mockSpotsLocal,
        connectivity: mockConnectivity,
      );

      listsRepository = ListsRepositoryImpl(
        remoteDataSource: mockListsRemote,
        localDataSource: mockListsLocal,
        connectivity: mockConnectivity,
      );

      authRepository = AuthRepositoryImpl(
        remoteDataSource: mockAuthRemote,
        localDataSource: mockAuthLocal,
        connectivity: mockConnectivity,
      );
      
      // Setup default mock responses to prevent unexpected interactions
      when(mockAuthRemote.signIn(any, any)).thenThrow(Exception('Should not call remote when offline'));
      when(mockAuthRemote.signUp(any, any, any)).thenThrow(Exception('Should not call remote when offline'));
      when(mockListsRemote.createList(any)).thenThrow(Exception('Should not call remote when offline'));
      when(mockListsRemote.getLists()).thenThrow(Exception('Should not call remote when offline'));
    });

    group('Spots Repository - Offline Mode', () {
      test('creates spot locally when offline', () async {
        final spot = Spot(
          id: '1',
          name: 'Test Spot',
          description: 'A test spot',
          category: 'Cafe',
          latitude: 1.0,
          longitude: 2.0,
          rating: 4.5,
          createdBy: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSpotsLocal.createSpot(spot)).thenAnswer((_) async => '1');
        when(mockSpotsLocal.getSpotById('1')).thenAnswer((_) async => spot);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await spotsRepository.createSpot(spot);

        expect(result, spot);
        verify(mockSpotsLocal.createSpot(spot)).called(1);
        verify(mockSpotsLocal.getSpotById('1')).called(1);
        verifyZeroInteractions(mockSpotsRemote);
      });

      test('gets spots from local storage when offline', () async {
        final spots = [
          Spot(
            id: '1',
            name: 'Test Spot 1',
            description: 'A test spot',
            category: 'Cafe',
            latitude: 1.0,
            longitude: 2.0,
            rating: 4.5,
            createdBy: 'user1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockSpotsLocal.getAllSpots()).thenAnswer((_) async => spots);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await spotsRepository.getSpots();

        expect(result, spots);
        verify(mockSpotsLocal.getAllSpots()).called(1);
        verifyZeroInteractions(mockSpotsRemote);
      });

      test('updates spot locally when offline', () async {
        final spot = Spot(
          id: '1',
          name: 'Updated Spot',
          description: 'An updated test spot',
          category: 'Restaurant',
          latitude: 1.0,
          longitude: 2.0,
          rating: 4.8,
          createdBy: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updatedSpot = spot.copyWith(
          name: 'Updated Test Spot',
          rating: 4.8,
          updatedAt: DateTime.now(),
        );

        when(mockSpotsLocal.updateSpot(updatedSpot)).thenAnswer((_) async => updatedSpot);
        when(mockSpotsLocal.getSpotById('1')).thenAnswer((_) async => updatedSpot);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await spotsRepository.updateSpot(updatedSpot);

        expect(result, updatedSpot);
        verify(mockSpotsLocal.updateSpot(updatedSpot)).called(1);
        verify(mockSpotsLocal.getSpotById('1')).called(1);
        verifyZeroInteractions(mockSpotsRemote);
      });
    });

    group('Lists Repository - Offline Mode', () {
      test('creates list locally when offline', () async {
        final list = SpotList(
          id: '1',
          title: 'Test List',
          description: 'A test list',
          category: 'Food',
          spots: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isPublic: true,
          spotIds: const [],
        );

        when(mockListsLocal.saveList(list)).thenAnswer((_) async => list);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await listsRepository.createList(list);

        expect(result, list);
        verify(mockListsLocal.saveList(list)).called(1);
        verifyZeroInteractions(mockListsRemote);
      });

      test('gets lists from local storage when offline', () async {
        final lists = [
          SpotList(
            id: '1',
            title: 'Test List 1',
            description: 'A test list',
            category: 'Food',
            spots: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isPublic: true,
            spotIds: const [],
          ),
        ];

        when(mockListsLocal.getLists()).thenAnswer((_) async => lists);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await listsRepository.getLists();

        expect(result, lists);
        verify(mockListsLocal.getLists()).called(1);
        verifyZeroInteractions(mockListsRemote);
      });
    });

    group('Auth Repository - Offline Mode', () {
      test('signs in with local user when offline', () async {
        final localUser = User(
          id: 'user1',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthLocal.signIn('test@example.com', 'password')).thenAnswer((_) async => localUser);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result =
            await authRepository.signIn('test@example.com', 'password');

        expect(result?.email, 'test@example.com');
        verify(mockAuthLocal.signIn('test@example.com', 'password')).called(1);
        verifyZeroInteractions(mockAuthRemote);
      });

      test('throws error when signing up offline', () async {
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        expect(
          () => authRepository.signUp(
              'test@example.com', 'password', 'Test User'),
          throwsA(isA<Exception>()),
        );

        // Should not interact with any datasource when offline
        verifyNever(mockAuthLocal.signUp(any, any, any));
        verifyNever(mockAuthRemote.signUp(any, any, any));
      });

      test('returns offline user when getting current user offline', () async {
        final localUser = User(
          id: 'user2',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthLocal.getCurrentUser()).thenAnswer((_) async => localUser);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await authRepository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.email, 'test@example.com');
        verify(mockAuthLocal.getCurrentUser()).called(1);
      });
    });
  });
}
