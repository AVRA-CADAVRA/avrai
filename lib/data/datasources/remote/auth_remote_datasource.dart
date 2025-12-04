import 'package:spots/core/models/user.dart';
abstract class AuthRemoteDataSource {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User?> updateUser(User user);
}
