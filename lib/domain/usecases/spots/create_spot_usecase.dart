import 'package:spots/core/models/spot.dart';
import 'package:spots/domain/repositories/spots_repository.dart';

class CreateSpotUseCase {
  final SpotsRepository repository;

  CreateSpotUseCase(this.repository);

  Future<Spot> call(Spot spot) async {
    return await repository.createSpot(spot);
  }
}
