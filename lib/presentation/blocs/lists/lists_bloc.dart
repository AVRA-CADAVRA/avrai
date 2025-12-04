import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/domain/usecases/lists/create_list_usecase.dart';
import 'package:spots/domain/usecases/lists/delete_list_usecase.dart';
import 'package:spots/domain/usecases/lists/get_lists_usecase.dart';
import 'package:spots/domain/usecases/lists/update_list_usecase.dart';

// Events
abstract class ListsEvent {}

class LoadLists extends ListsEvent {}

class CreateList extends ListsEvent {
  final SpotList list;

  CreateList(this.list);
}

class UpdateList extends ListsEvent {
  final SpotList list;

  UpdateList(this.list);
}

class DeleteList extends ListsEvent {
  final String id;

  DeleteList(this.id);
}

class SearchLists extends ListsEvent {
  final String query;

  SearchLists(this.query);
}

// States
abstract class ListsState {}

class ListsInitial extends ListsState {}

class ListsLoading extends ListsState {}

class ListsLoaded extends ListsState {
  final List<SpotList> lists;
  final List<SpotList> filteredLists;

  ListsLoaded(this.lists, this.filteredLists);
}

class ListsError extends ListsState {
  final String message;

  ListsError(this.message);
}

class ListsBloc extends Bloc<ListsEvent, ListsState> {
  final GetListsUseCase getListsUseCase;
  final CreateListUseCase createListUseCase;
  final UpdateListUseCase updateListUseCase;
  final DeleteListUseCase deleteListUseCase;

  ListsBloc({
    required this.getListsUseCase,
    required this.createListUseCase,
    required this.updateListUseCase,
    required this.deleteListUseCase,
  }) : super(ListsInitial()) {
    on<LoadLists>(_onLoadLists);
    on<CreateList>(_onCreateList);
    on<UpdateList>(_onUpdateList);
    on<DeleteList>(_onDeleteList);
    on<SearchLists>(_onSearchLists);
  }

  Future<void> _onLoadLists(
    LoadLists event,
    Emitter<ListsState> emit,
  ) async {
    emit(ListsLoading());
    try {
      final lists = await getListsUseCase();
      emit(ListsLoaded(lists, lists));
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onCreateList(
    CreateList event,
    Emitter<ListsState> emit,
  ) async {
    try {
      await createListUseCase(event.list);
      add(LoadLists());
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onUpdateList(
    UpdateList event,
    Emitter<ListsState> emit,
  ) async {
    try {
      await updateListUseCase(event.list);
      add(LoadLists());
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onDeleteList(
    DeleteList event,
    Emitter<ListsState> emit,
  ) async {
    try {
      await deleteListUseCase(event.id);
      add(LoadLists());
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onSearchLists(
    SearchLists event,
    Emitter<ListsState> emit,
  ) async {
    if (state is ListsLoaded) {
      final currentState = state as ListsLoaded;
      final query = event.query.toLowerCase();
      final filteredLists = currentState.lists.where((list) {
        return list.title.toLowerCase().contains(query) ||
               list.description.toLowerCase().contains(query) ||
               (list.category?.toLowerCase().contains(query) ?? false);
      }).toList();
      emit(ListsLoaded(currentState.lists, filteredLists));
    }
  }
}
