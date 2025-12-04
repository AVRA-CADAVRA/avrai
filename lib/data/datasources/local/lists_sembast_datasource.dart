import 'dart:developer' as developer;
import 'package:sembast/sembast.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/data/datasources/local/lists_local_datasource.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';

class ListsSembastDataSource implements ListsLocalDataSource {
  final StoreRef<String, Map<String, dynamic>> _store;

  ListsSembastDataSource() : _store = SembastDatabase.listsStore;

  @override
  Future<List<SpotList>> getLists() async {
    try {
      final db = await SembastDatabase.database;
      final records = await _store.find(db);
      return records.map((record) {
        final data = record.value;
        return SpotList.fromMap(data);
      }).toList();
    } catch (e) {
      developer.log('Error getting lists: $e', name: 'ListsSembastDataSource');
      return [];
    }
  }

  @override
  Future<SpotList?> saveList(SpotList list) async {
    try {
      final db = await SembastDatabase.database;
      final listData = list.toMap();
      
      if (list.id.isEmpty) {
        // Create new list
        final key = await _store.add(db, listData);
        return list.copyWith(id: key);
      } else {
        // Update existing list
        await _store.record(list.id).put(db, listData);
        return list;
      }
    } catch (e) {
      developer.log('Error saving list: $e', name: 'ListsSembastDataSource');
      return null;
    }
  }

  @override
  Future<void> deleteList(String id) async {
    try {
      final db = await SembastDatabase.database;
      await _store.record(id).delete(db);
    } catch (e) {
      developer.log('Error deleting list: $e', name: 'ListsSembastDataSource');
    }
  }
}
