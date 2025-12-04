import 'package:spots/core/models/user.dart' as app_user;
import 'package:spots/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<app_user.User?> call() async {
    return await repository.getCurrentUser();
  }
}
