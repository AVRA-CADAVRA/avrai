import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/domain/usecases/spots/get_spots_usecase.dart';
import 'package:spots/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:spots/domain/usecases/spots/create_spot_usecase.dart';
import 'package:spots/domain/usecases/spots/update_spot_usecase.dart';
import 'package:spots/domain/usecases/spots/delete_spot_usecase.dart';

// Events
abstract class SpotsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSpots extends SpotsEvent {}

class LoadSpotsWithRespected extends SpotsEvent {}

class SearchSpots extends SpotsEvent {
  final String query;

  SearchSpots({required this.query});

  @override
  List<Object?> get props => [query];
}

class CreateSpot extends SpotsEvent {
  final Spot spot;

  CreateSpot(this.spot);

  @override
  List<Object?> get props => [spot];
}

class UpdateSpot extends SpotsEvent {
  final Spot spot;

  UpdateSpot(this.spot);

  @override
  List<Object?> get props => [spot];
}

class DeleteSpot extends SpotsEvent {
  final String spotId;

  DeleteSpot(this.spotId);

  @override
  List<Object?> get props => [spotId];
}

// States
abstract class SpotsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SpotsInitial extends SpotsState {}

class SpotsLoading extends SpotsState {}

class SpotsLoaded extends SpotsState {
  final List<Spot> spots;
  final List<Spot> filteredSpots;
  final String? searchQuery;
  final List<Spot> respectedSpots;

  SpotsLoaded(this.spots,
      {List<Spot>? filteredSpots, this.searchQuery, List<Spot>? respectedSpots})
      : filteredSpots = filteredSpots ?? spots,
        respectedSpots = respectedSpots ?? [];

  @override
  List<Object?> get props =>
      [spots, filteredSpots, searchQuery, respectedSpots];
}

class SpotsError extends SpotsState {
  final String message;

  SpotsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class SpotsBloc extends Bloc<SpotsEvent, SpotsState> {
  final GetSpotsUseCase getSpotsUseCase;
  final GetSpotsFromRespectedListsUseCase getSpotsFromRespectedListsUseCase;
  final CreateSpotUseCase createSpotUseCase;
  final UpdateSpotUseCase updateSpotUseCase;
  final DeleteSpotUseCase deleteSpotUseCase;

  SpotsBloc({
    required this.getSpotsUseCase,
    required this.getSpotsFromRespectedListsUseCase,
    required this.createSpotUseCase,
    required this.updateSpotUseCase,
    required this.deleteSpotUseCase,
  }) : super(SpotsInitial()) {
    on<LoadSpots>(_onLoadSpots);
    on<LoadSpotsWithRespected>(_onLoadSpotsWithRespected);
    on<SearchSpots>(_onSearchSpots);
    on<CreateSpot>(_onCreateSpot);
    on<UpdateSpot>(_onUpdateSpot);
    on<DeleteSpot>(_onDeleteSpot);
  }

  Future<void> _onLoadSpots(LoadSpots event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    try {
      final spots = await getSpotsUseCase();
      emit(SpotsLoaded(spots));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onLoadSpotsWithRespected(
      LoadSpotsWithRespected event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    try {
      final spots = await getSpotsUseCase();
      final respectedSpots = await getSpotsFromRespectedListsUseCase();
      emit(SpotsLoaded(spots, respectedSpots: respectedSpots));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  void _onSearchSpots(SearchSpots event, Emitter<SpotsState> emit) {
    if (state is SpotsLoaded) {
      final currentState = state as SpotsLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(SpotsLoaded(currentState.spots, respectedSpots: currentState.respectedSpots));
      } else {
        // Search in both user spots and respected spots
        final allSpots = [...currentState.spots, ...currentState.respectedSpots];
        final filteredSpots = allSpots.where((spot) {
          return spot.name.toLowerCase().contains(query) ||
              (spot.description.toLowerCase().contains(query) ?? false) ||
              spot.category.toLowerCase().contains(query) ||
              (spot.address?.toLowerCase().contains(query) ?? false);
        }).toList();

        emit(SpotsLoaded(currentState.spots,
            filteredSpots: filteredSpots, searchQuery: query, respectedSpots: currentState.respectedSpots));
      }
    }
  }

  Future<void> _onCreateSpot(CreateSpot event, Emitter<SpotsState> emit) async {
    try {
      await createSpotUseCase(event.spot);
      add(LoadSpots());
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onUpdateSpot(UpdateSpot event, Emitter<SpotsState> emit) async {
    try {
      await updateSpotUseCase(event.spot);
      add(LoadSpots());
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onDeleteSpot(DeleteSpot event, Emitter<SpotsState> emit) async {
    try {
      await deleteSpotUseCase(event.spotId);
      add(LoadSpots());
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
}
