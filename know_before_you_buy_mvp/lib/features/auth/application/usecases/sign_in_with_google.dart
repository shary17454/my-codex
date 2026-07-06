import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() {
    return _repository.signInWithGoogle();
  }
}
