import 'package:spots/core/models/user.dart';
abstract class AuthLocalDataSource {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password, User user);
  Future<void> saveUser(User user);
  Future<User?> getCurrentUser();
  Future<void> clearUser();
  Future<bool> isOnboardingCompleted();
  Future<void> markOnboardingCompleted();
}
