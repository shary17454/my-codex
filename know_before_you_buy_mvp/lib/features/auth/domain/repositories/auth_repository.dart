import '../entities/app_user.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
