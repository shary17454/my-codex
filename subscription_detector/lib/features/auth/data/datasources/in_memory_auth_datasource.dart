import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import 'auth_datasource.dart';

class InMemoryAuthDataSource implements AuthDataSource {
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const AppException('Email and password are required.');
    }

    return _setUser(email.trim(), 'Email User');
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    return _setUser('google.user@example.com', 'Google User');
  }

  @override
  Future<AppUser> signInWithApple() async {
    return _setUser('apple.user@example.com', 'Apple User');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  AppUser _setUser(String email, String displayName) {
    _currentUser = AppUser(
      id: email.hashCode.toString(),
      email: email,
      displayName: displayName,
    );

    return _currentUser!;
  }
}
