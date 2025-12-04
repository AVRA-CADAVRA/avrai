import 'package:spots/domain/repositories/lists_repository.dart';
class DeleteListUseCase {
  final ListsRepository repository;

  DeleteListUseCase(this.repository);

  Future<void> call(String listId) async {
    return await repository.deleteList(listId);
  }
}
