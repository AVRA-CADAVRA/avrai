import 'package:spots/core/models/list.dart';
import 'package:spots/domain/repositories/lists_repository.dart';

class CreateListUseCase {
  final ListsRepository repository;

  CreateListUseCase(this.repository);

  Future<SpotList> call(SpotList list) async {
    return await repository.createList(list);
  }
}
