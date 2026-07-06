import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Future<AppUser> signInWithGoogle() {
    return _dataSource.signInWithGoogle();
  }

  @override
  Future<AppUser> signInWithApple() {
    return _dataSource.signInWithApple();
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _dataSource.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _dataSource.signOut();
  }
}
