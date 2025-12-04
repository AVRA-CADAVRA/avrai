import 'package:spots/core/models/spot.dart';
import 'package:spots/domain/repositories/spots_repository.dart';

class GetSpotsUseCase {
  final SpotsRepository repository;

  GetSpotsUseCase(this.repository);

  Future<List<Spot>> call() async {
    return await repository.getSpots();
  }
}
