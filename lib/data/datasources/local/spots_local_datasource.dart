import 'package:spots/core/models/spot.dart';
abstract class SpotsLocalDataSource {
  Future<List<Spot>> getAllSpots();
  Future<Spot?> getSpotById(String id);
  Future<String> createSpot(Spot spot);
  Future<Spot> updateSpot(Spot spot);
  Future<void> deleteSpot(String id);
  Future<List<Spot>> getSpotsByCategory(String category);
  Future<List<Spot>> getSpotsFromRespectedLists();
  Future<List<Spot>> searchSpots(String query);
}
