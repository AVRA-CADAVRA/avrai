import 'package:spots/core/models/user.dart';
import 'package:spots/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User?> call(String email, String password, String name) async {
    return await repository.signUp(email, password, name);
  }
}
