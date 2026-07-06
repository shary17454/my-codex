import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}
