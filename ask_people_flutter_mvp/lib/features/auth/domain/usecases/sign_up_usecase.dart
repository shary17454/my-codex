import 'package:ask_people/features/auth/domain/entities/app_user.dart';
import 'package:ask_people/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String displayName,
    required String email,
    required String password,
  }) {
    return _repository.signUp(
      displayName: displayName,
      email: email,
      password: password,
    );
  }
}
