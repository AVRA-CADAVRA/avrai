import 'package:spots/core/models/user.dart';
import 'package:spots/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<User?> call(String email, String password) async {
    return await repository.signIn(email, password);
  }
}
