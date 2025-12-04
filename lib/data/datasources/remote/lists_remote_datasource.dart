import 'package:spots/core/models/list.dart';
abstract class ListsRemoteDataSource {
  Future<List<SpotList>> getLists();
  Future<List<SpotList>> getPublicLists({int? limit});
  Future<SpotList> createList(SpotList list);
  Future<SpotList> updateList(SpotList list);
  Future<void> deleteList(String listId);
}
