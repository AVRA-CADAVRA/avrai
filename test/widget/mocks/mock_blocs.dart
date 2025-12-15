import 'package:mockito/mockito.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/models/user.dart';

/// Mock AuthBloc for widget testing
class MockAuthBloc extends Mock implements AuthBloc {
  AuthState? _state;
  Stream<AuthState>? _stream;
  bool _isClosed = false;
  final List<AuthEvent> addedEvents = [];

  @override
  AuthState get state => _state ?? AuthInitial();

  @override
  Stream<AuthState> get stream => _stream?.asBroadcastStream() ?? Stream.value(AuthInitial()).asBroadcastStream();

  @override
  Future<void> close() async {
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  @override
  void add(AuthEvent event) {
    addedEvents.add(event);
  }

  void setState(AuthState state) {
    _state = state;
    _stream = Stream.value(state).asBroadcastStream();
  }

  void setStream(Stream<AuthState> stream) {
    _stream = stream.asBroadcastStream();
  }
}

/// Mock ListsBloc for widget testing
class MockListsBloc extends Mock implements ListsBloc {
  ListsState? _state;
  Stream<ListsState>? _stream;
  bool _isClosed = false;
  final List<ListsEvent> addedEvents = [];

  @override
  ListsState get state => _state ?? ListsInitial();

  @override
  Stream<ListsState> get stream =>
      _stream?.asBroadcastStream() ?? Stream.value(ListsInitial()).asBroadcastStream();

  @override
  Future<void> close() async {
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  @override
  void add(ListsEvent event) {
    addedEvents.add(event);
  }

  void setState(ListsState state) {
    _state = state;
    _stream = Stream.value(state).asBroadcastStream();
  }

  void setStream(Stream<ListsState> stream) {
    _stream = stream.asBroadcastStream();
  }
}

/// Mock SpotsBloc for widget testing
class MockSpotsBloc extends Mock implements SpotsBloc {
  SpotsState? _state;
  Stream<SpotsState>? _stream;
  bool _isClosed = false;

  @override
  SpotsState get state => _state ?? SpotsInitial();

  @override
  Stream<SpotsState> get stream =>
      _stream?.asBroadcastStream() ?? Stream.value(SpotsInitial()).asBroadcastStream();

  @override
  Future<void> close() async {
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  void setState(SpotsState state) {
    _state = state;
    _stream = Stream.value(state).asBroadcastStream();
  }
}

/// Mock HybridSearchBloc for widget testing
class MockHybridSearchBloc extends Mock implements HybridSearchBloc {
  HybridSearchState? _state;
  Stream<HybridSearchState>? _stream;
  bool _isClosed = false;

  @override
  HybridSearchState get state => _state ?? HybridSearchInitial();

  @override
  Stream<HybridSearchState> get stream => _stream?.asBroadcastStream() ??
      Stream.value(HybridSearchInitial()).asBroadcastStream();

  @override
  Future<void> close() async {
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  void setState(HybridSearchState state) {
    _state = state;
    _stream = Stream.value(state).asBroadcastStream();
  }
}

/// Helper class to create mock blocs with predefined states
class MockBlocFactory {
  /// Creates an authenticated mock auth bloc
  static MockAuthBloc createAuthenticatedAuthBloc({UserRole role = UserRole.user, bool isAgeVerified = true}) {
    final mockBloc = MockAuthBloc();
    final user = MockBlocFactory._createTestUser(role: role, isAgeVerified: isAgeVerified);
    final authenticatedState = Authenticated(user: user);
    mockBloc.setState(authenticatedState);
    return mockBloc;
  }

  /// Creates an unauthenticated mock auth bloc
  static MockAuthBloc createUnauthenticatedAuthBloc() {
    final mockBloc = MockAuthBloc();
    final unauthenticatedState = Unauthenticated();
    mockBloc.setState(unauthenticatedState);
    return mockBloc;
  }

  /// Creates a loading mock auth bloc
  static MockAuthBloc createLoadingAuthBloc() {
    final mockBloc = MockAuthBloc();
    final loadingState = AuthLoading();
    mockBloc.setState(loadingState);
    return mockBloc;
  }

  /// Creates an error mock auth bloc
  static MockAuthBloc createErrorAuthBloc(String message) {
    final mockBloc = MockAuthBloc();
    final errorState = AuthError(message);
    mockBloc.setState(errorState);
    return mockBloc;
  }

  /// Creates a mock lists bloc with loaded state
  static MockListsBloc createLoadedListsBloc(List<SpotList> lists) {
    final mockBloc = MockListsBloc();
    mockBloc.setState(ListsLoaded(lists, lists));
    return mockBloc;
  }

  /// Creates a mock lists bloc with loading state
  static MockListsBloc createLoadingListsBloc() {
    final mockBloc = MockListsBloc();
    mockBloc.setState(ListsLoading());
    return mockBloc;
  }

  /// Creates a mock lists bloc with error state
  static MockListsBloc createErrorListsBloc(String message) {
    final mockBloc = MockListsBloc();
    mockBloc.setState(ListsError(message));
    return mockBloc;
  }

  /// Creates a mock spots bloc with loaded state
  static MockSpotsBloc createLoadedSpotsBloc(List<Spot> spots) {
    final mockBloc = MockSpotsBloc();
    mockBloc.setState(SpotsLoaded(spots));
    return mockBloc;
  }

  /// Creates a mock spots bloc with loading state
  static MockSpotsBloc createLoadingSpotsBloc() {
    final mockBloc = MockSpotsBloc();
    mockBloc.setState(SpotsLoading());
    return mockBloc;
  }

  /// Creates a mock search bloc with results
  static MockHybridSearchBloc createSearchResultsBloc(List<Spot> results) {
    final mockBloc = MockHybridSearchBloc();
    mockBloc.setState(HybridSearchLoaded(
      spots: results,
      communityCount: results.length,
      externalCount: 0,
      totalCount: results.length,
      searchDuration: const Duration(milliseconds: 100),
      sources: const {},
    ));
    return mockBloc;
  }

  /// Creates a test user for mocking purposes
  static User _createTestUser({UserRole role = UserRole.user, bool isAgeVerified = true}) {
    final now = DateTime.now();
    return User(
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      displayName: 'Test User Display',
      role: role,
      createdAt: now,
      updatedAt: now,
    );
  }
}
