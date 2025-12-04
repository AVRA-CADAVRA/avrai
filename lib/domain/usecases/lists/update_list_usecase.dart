import 'package:spots/core/models/list.dart';
import 'package:spots/domain/repositories/lists_repository.dart';

class UpdateListUseCase {
  final ListsRepository repository;

  UpdateListUseCase(this.repository);

  Future<SpotList> call(SpotList list) async {
    return await repository.updateList(list);
  }
}
