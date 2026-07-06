import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/in_memory_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';

final authDataSourceProvider = Provider<AuthDataSource>(
  (ref) => Firebase.apps.isEmpty ? InMemoryAuthDataSource() : FirebaseAuthDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)),
);

final signInWithEmailProvider = Provider<SignInWithEmail>(
  (ref) => SignInWithEmail(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleProvider = Provider<SignInWithGoogle>(
  (ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)),
);

final signInWithAppleProvider = Provider<SignInWithApple>(
  (ref) => SignInWithApple(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.watch(authRepositoryProvider).currentUser;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signInWithEmailProvider).call(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(signInWithGoogleProvider).call);
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(signInWithAppleProvider).call);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await ref.read(signOutProvider).call();
    state = const AsyncData(null);
  }
}
