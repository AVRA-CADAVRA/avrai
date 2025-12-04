import 'package:spots/core/models/list.dart';
import 'package:spots/domain/repositories/lists_repository.dart';

class GetListsUseCase {
  final ListsRepository repository;

  GetListsUseCase(this.repository);

  Future<List<SpotList>> call() async {
    return await repository.getLists();
  }
}
