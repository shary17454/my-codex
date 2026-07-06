import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AppException('Email and password are required');
    }

    _currentUser = AppUser(id: normalizedEmail, email: normalizedEmail);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
