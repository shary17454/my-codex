import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SignInWithApple {
  const SignInWithApple(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() {
    return _repository.signInWithApple();
  }
}
