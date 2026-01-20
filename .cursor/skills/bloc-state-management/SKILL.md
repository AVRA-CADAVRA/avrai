---
name: bloc-state-management
description: Guides BLoC state management implementation patterns. Use when creating new BLoCs, handling state changes, or managing application state.
---

# BLoC State Management

## Core Pattern

All BLoCs must extend `Bloc<Event, State>` and follow the event/state pattern.

## Basic Structure

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class MyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadData extends MyEvent {}
class UpdateData extends MyEvent {
  final String data;
  UpdateData(this.data);
  
  @override
  List<Object?> get props => [data];
}

// States
abstract class MyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyInitial extends MyState {}
class MyLoading extends MyState {}
class MyLoaded extends MyState {
  final String data;
  MyLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}
class MyError extends MyState {
  final String message;
  MyError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class MyBloc extends Bloc<MyEvent, MyState> {
  final MyUseCase useCase;
  
  MyBloc({required this.useCase}) : super(MyInitial()) {
    on<LoadData>(_onLoadData);
    on<UpdateData>(_onUpdateData);
  }
  
  Future<void> _onLoadData(
    LoadData event,
    Emitter<MyState> emit,
  ) async {
    emit(MyLoading());
    try {
      final data = await useCase.getData();
      emit(MyLoaded(data));
    } catch (e) {
      emit(MyError(e.toString()));
    }
  }
  
  Future<void> _onUpdateData(
    UpdateData event,
    Emitter<MyState> emit,
  ) async {
    // Handle update
  }
}
```

## Key Rules

1. **Use `emit()` not `yield`** - Modern BLoC API
2. **Never mutate state directly** - Always emit new state
3. **Handle all events** - Register handlers in constructor with `on<EventType>()`
4. **Keep BLoCs focused** - One BLoC per feature/domain
5. **Use Equatable** - For state/event comparison
6. **Close BLoCs** - Use `BlocProvider` auto-disposal or dispose manually

## Dependency Injection

```dart
// In widget tree
BlocProvider(
  create: (context) => MyBloc(
    useCase: sl<MyUseCase>(),
  ),
  child: MyWidget(),
)

// Or with existing instance
BlocProvider.value(
  value: existingBloc,
  child: MyWidget(),
)
```

## UI Integration

```dart
// BlocBuilder - Rebuilds UI on state changes
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) {
    if (state is MyLoading) return CircularProgressIndicator();
    if (state is MyError) return Text(state.message);
    if (state is MyLoaded) return Text(state.data);
    return Container();
  },
)

// BlocListener - Reacts to state changes (side effects)
BlocListener<MyBloc, MyState>(
  listener: (context, state) {
    if (state is MyError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: MyWidget(),
)

// BlocConsumer - Combines Builder + Listener
BlocConsumer<MyBloc, MyState>(
  listener: (context, state) { /* side effects */ },
  builder: (context, state) { /* UI */ },
)
```

## Error Handling

Always handle errors in event handlers:

```dart
Future<void> _onLoadData(
  LoadData event,
  Emitter<MyState> emit,
) async {
  emit(MyLoading());
  try {
    final data = await useCase.getData();
    emit(MyLoaded(data));
  } on NetworkException catch (e) {
    emit(MyError('Network error: ${e.message}'));
  } catch (e, st) {
    developer.log('Unexpected error', error: e, stackTrace: st, name: 'MyBloc');
    emit(MyError('Something went wrong'));
  }
}
```

## Reference Examples

See existing BLoCs in:
- `lib/presentation/blocs/auth/auth_bloc.dart`
- `lib/presentation/blocs/spots/spots_bloc.dart`
- `lib/presentation/blocs/search/hybrid_search_bloc.dart`
