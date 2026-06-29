import 'package:ask_people/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:ask_people/features/auth/data/models/app_user_dto.dart';
import 'package:ask_people/features/auth/domain/entities/app_user.dart';
import 'package:ask_people/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<AppUser?> watchAuthState() {
    return _dataSource.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }

      return AppUserDto.fromFirebaseUser(user).toDomain();
    });
  }

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentUser;
    if (user == null) {
      return null;
    }

    return AppUserDto.fromFirebaseUser(user).toDomain();
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.signIn(email: email, password: password);
    return AppUserDto.fromFirebaseUser(user).toDomain();
  }

  @override
  Future<AppUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.signUp(
      displayName: displayName,
      email: email,
      password: password,
    );
    return AppUserDto.fromFirebaseUser(user).toDomain();
  }

  @override
  Future<void> signOut() {
    return _dataSource.signOut();
  }
}
