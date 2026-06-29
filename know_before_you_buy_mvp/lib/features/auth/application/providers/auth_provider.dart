import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../usecases/sign_in_with_apple.dart';
import '../usecases/sign_in_with_email.dart';
import '../usecases/sign_in_with_google.dart';
import '../usecases/sign_out.dart';

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDataSourceProvider));
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final signInWithAppleProvider = Provider<SignInWithApple>((ref) {
  return SignInWithApple(ref.watch(authRepositoryProvider));
});

final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppUser?>>(
      AuthController.new,
    );

class AuthController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    return AsyncData(ref.watch(authRepositoryProvider).currentUser);
  }

  Future<void> signInWithGoogle() {
    return _runAuthAction(ref.read(signInWithGoogleProvider).call);
  }

  Future<void> signInWithApple() {
    return _runAuthAction(ref.read(signInWithAppleProvider).call);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      () => ref
          .read(signInWithEmailProvider)
          .call(email: email, password: password),
    );
  }

  void continueAsPreview() {
    state = const AsyncData(
      AppUser(
        id: 'mvp-preview',
        email: null,
        displayName: 'MVP Preview',
        photoUrl: null,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await ref.read(signOutProvider).call();
    state = const AsyncData(null);
  }

  Future<void> _runAuthAction(Future<AppUser> Function() action) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await action());
    } on AppFailure catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError(AppFailure(error.toString()), stackTrace);
    }
  }

  void restoreCurrentUser() {
    state = AsyncData(ref.read(authRepositoryProvider).currentUser);
  }
}
